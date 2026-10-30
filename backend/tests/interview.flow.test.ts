import { afterEach, describe, expect, it, vi } from 'vitest';

import { setAiProvider } from '../src/ai';
import type { AiProvider, GenerateRequest } from '../src/ai/types';
import {
  completeInterview,
  createInterview,
  deleteInterview,
  getProgress,
  submitAnswer,
} from '../src/services/interview.service';
import { interviewRow, memoryDb, messageRow } from './memoryDb';

const fakeAi = (...replies: (string | Error)[]) => {
  const queue = [...replies];
  const generate = vi.fn(async (_req: GenerateRequest) => {
    const next = queue.shift();
    if (next instanceof Error) throw next;
    return next ?? 'default reply';
  });
  setAiProvider({ generate } as AiProvider);
  return generate;
};

afterEach(() => setAiProvider(null));

const setup = {
  targetRole: 'Flutter Developer',
  interviewType: 'technical' as const,
  difficulty: 'beginner' as const,
  durationMinutes: 5,
  mode: 'text' as const,
};

const feedbackJson = JSON.stringify({
  communicationScore: 80,
  technicalScore: 70,
  relevanceScore: 60,
  strengths: ['Clear'],
  weaknesses: ['Short'],
  missedConcepts: ['State management'],
  improvedAnswers: [{ question: 'Q1', suggestion: 'Better A1' }],
  nextSteps: ['Practise'],
});

describe('createInterview', () => {
  it('stores the interview and the first AI question', async () => {
    const gen = fakeAi('Hi! What is a widget?');
    const { db, tables } = memoryDb();
    const r = await createInterview(db, 'u1', setup);

    expect(r.totalQuestions).toBe(3);
    expect(r.messages).toHaveLength(1);
    expect(r.messages[0]).toMatchObject({ seq: 1, role: 'interviewer', content: 'Hi! What is a widget?' });
    expect(tables.interviews).toHaveLength(1);
    expect(gen.mock.calls[0][0].system).toContain('question 1 of 3');
    expect(gen.mock.calls[0][0].turns[0].role).toBe('user'); // Gemini needs a user first turn
  });

  it('removes the interview again if the AI fails', async () => {
    fakeAi(new Error('boom'));
    const { db, tables } = memoryDb();
    await expect(createInterview(db, 'u1', setup)).rejects.toThrow('boom');
    expect(tables.interviews).toHaveLength(0);
  });

  it('fails fast with 503 and writes nothing when AI is not configured', async () => {
    setAiProvider(null); // vitest sets AI_API_KEY to ''
    const { db, tables } = memoryDb();
    await expect(createInterview(db, 'u1', setup)).rejects.toMatchObject({
      status: 503,
      code: 'ai_not_configured',
    });
    expect(tables.interviews).toHaveLength(0);
  });
});

describe('submitAnswer', () => {
  const seeded = () =>
    memoryDb({
      interviews: [interviewRow()],
      interview_messages: [messageRow(1, 'interviewer', 'Q1?')],
    });

  it('saves the answer and the next question, in order', async () => {
    const gen = fakeAi('Q2?');
    const { db, tables } = seeded();
    const r = await submitAnswer(db, 'u1', 'i1', 'My answer');

    expect(r.done).toBe(false);
    expect(r.messages.map((m) => [m.seq, m.role])).toEqual([
      [2, 'candidate'],
      [3, 'interviewer'],
    ]);
    expect(tables.interview_messages).toHaveLength(3);

    const req = gen.mock.calls[0][0];
    expect(req.system).toContain('question 2 of 3');
    expect(req.turns.map((t) => t.role)).toEqual(['user', 'model', 'user']);
    expect(req.turns[2].text).toBe('My answer');
  });

  it('finishes without calling the AI after the last answer', async () => {
    const gen = fakeAi();
    const { db, tables } = memoryDb({
      interviews: [interviewRow()],
      interview_messages: [
        messageRow(1, 'interviewer', 'Q1?'),
        messageRow(2, 'candidate', 'A1'),
        messageRow(3, 'interviewer', 'Q2?'),
        messageRow(4, 'candidate', 'A2'),
        messageRow(5, 'interviewer', 'Q3?'),
      ],
    });
    const r = await submitAnswer(db, 'u1', 'i1', 'A3');
    expect(r.done).toBe(true);
    expect(gen).not.toHaveBeenCalled();
    expect(tables.interview_messages).toHaveLength(6);
  });

  it('saves nothing when the AI fails, so the same answer can be resent', async () => {
    fakeAi(new Error('boom'));
    const { db, tables } = seeded();
    await expect(submitAnswer(db, 'u1', 'i1', 'x')).rejects.toThrow('boom');
    expect(tables.interview_messages).toHaveLength(1);
  });

  it('rejects answers when it is not the candidate turn', async () => {
    fakeAi();
    const { db } = memoryDb({
      interviews: [interviewRow()],
      interview_messages: [messageRow(1, 'interviewer', 'Q?'), messageRow(2, 'candidate', 'A')],
    });
    await expect(submitAnswer(db, 'u1', 'i1', 'again')).rejects.toMatchObject({
      status: 409,
      code: 'out_of_turn',
    });
  });

  it('rejects answers on a finished interview and on unknown ids', async () => {
    fakeAi();
    const { db } = memoryDb({ interviews: [interviewRow({ status: 'completed' })] });
    await expect(submitAnswer(db, 'u1', 'i1', 'x')).rejects.toMatchObject({ status: 409 });
    await expect(submitAnswer(db, 'u1', 'nope', 'x')).rejects.toMatchObject({ status: 404 });
  });
});

describe('completeInterview', () => {
  const answered = () =>
    memoryDb({
      interviews: [interviewRow()],
      interview_messages: [messageRow(1, 'interviewer', 'Q1?'), messageRow(2, 'candidate', 'A1')],
    });

  it('stores feedback with a server-computed overall score and closes the interview', async () => {
    fakeAi('```json\n' + feedbackJson + '\n```');
    const { db, tables } = answered();
    const r = await completeInterview(db, 'u1', 'i1');

    expect(r.interview.status).toBe('completed');
    expect(r.feedback).toMatchObject({
      overallScore: 70, // 0.3*80 + 0.4*70 + 0.3*60
      communicationScore: 80,
      isAiEstimate: true,
      missedConcepts: ['State management'],
    });
    expect(tables.interview_feedback).toHaveLength(1);
  });

  it('is idempotent: a second call does not call the AI again', async () => {
    const gen = fakeAi(feedbackJson);
    const { db, tables } = answered();
    await completeInterview(db, 'u1', 'i1');
    const again = await completeInterview(db, 'u1', 'i1');
    expect(gen).toHaveBeenCalledTimes(1);
    expect(again.feedback?.overallScore).toBe(70);
    expect(tables.interview_feedback).toHaveLength(1);
  });

  it('refuses to score an interview with no answers', async () => {
    const gen = fakeAi();
    const { db } = memoryDb({
      interviews: [interviewRow()],
      interview_messages: [messageRow(1, 'interviewer', 'Q1?')],
    });
    await expect(completeInterview(db, 'u1', 'i1')).rejects.toMatchObject({
      status: 400,
      code: 'no_answers',
    });
    expect(gen).not.toHaveBeenCalled();
  });

  it('returns 502 and keeps the interview open when the AI output is unusable', async () => {
    fakeAi('definitely not json');
    const { db, tables } = answered();
    await expect(completeInterview(db, 'u1', 'i1')).rejects.toMatchObject({
      status: 502,
      code: 'ai_bad_output',
    });
    expect(tables.interviews[0].status).toBe('in_progress');
    expect(tables.interview_feedback).toHaveLength(0);
  });
});

describe('deleteInterview and getProgress', () => {
  it('deletes an interview with its transcript, and 404s on unknown ids', async () => {
    const { db, tables } = memoryDb({
      interviews: [interviewRow()],
      interview_messages: [messageRow(1, 'interviewer', 'Q?')],
    });
    await deleteInterview(db, 'i1');
    expect(tables.interviews).toHaveLength(0);
    expect(tables.interview_messages).toHaveLength(0);
    await expect(deleteInterview(db, 'i1')).rejects.toMatchObject({ status: 404 });
  });

  it('averages scores and reports counts', async () => {
    const fb = (id: string, o: number, c: number, t: number, r: number, at: string) => ({
      interview_id: id,
      overall_score: o,
      communication_score: c,
      technical_score: t,
      relevance_score: r,
      created_at: at,
    });
    const { db } = memoryDb({
      interviews: [interviewRow({ id: 'a' }), interviewRow({ id: 'b' }), interviewRow({ id: 'c' })],
      interview_feedback: [
        fb('a', 60, 60, 60, 60, '2026-01-01'),
        fb('b', 80, 90, 70, 80, '2026-01-02'),
      ],
    });
    const p = await getProgress(db);
    expect(p).toMatchObject({
      interviewCount: 3,
      completedCount: 2,
      averageScore: 70,
      averages: { communication: 75, technical: 65, relevance: 70 },
      recentScores: [60, 80], // oldest -> newest
    });
  });

  it('reports no averages before the first completed interview', async () => {
    const { db } = memoryDb();
    expect(await getProgress(db)).toMatchObject({
      interviewCount: 0,
      averageScore: null,
      averages: null,
      recentScores: [],
    });
  });
});