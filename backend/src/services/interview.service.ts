import type { SupabaseClient } from '@supabase/supabase-js';

import { getAiProvider } from '../ai';
import { parseJsonLoose } from '../ai/json';
import {
  FEEDBACK_SYSTEM,
  START_TURN,
  feedbackUserText,
  interviewerSystem,
  type InterviewContext,
} from '../ai/prompts';
import type { ChatTurn } from '../ai/types';
import { HttpError } from '../middleware/errors';
import {
  feedbackSchema,
  overallScore,
  type CreateInterviewInput,
} from '../validation/interview';

const INTERVIEW_COLS =
  'id, target_role, interview_type, difficulty, duration_minutes, mode, status, started_at, completed_at';
const MESSAGE_COLS = 'id, seq, role, content, created_at';
const FEEDBACK_COLS =
  'overall_score, communication_score, technical_score, relevance_score, strengths, weaknesses, missed_concepts, improved_answers, next_steps, is_ai_estimate, created_at';

interface InterviewRow {
  id: string;
  target_role: string;
  interview_type: string;
  difficulty: string;
  duration_minutes: number;
  mode: string;
  status: string;
  started_at: string;
  completed_at: string | null;
}

interface MessageRow {
  id: string;
  seq: number;
  role: 'interviewer' | 'candidate';
  content: string;
  created_at: string;
}

interface FeedbackRow {
  overall_score: number;
  communication_score: number;
  technical_score: number;
  relevance_score: number;
  strengths: string[];
  weaknesses: string[];
  missed_concepts: string[];
  improved_answers: { question: string; suggestion: string }[];
  next_steps: string[];
  is_ai_estimate: boolean;
  created_at: string;
}

const interviewDto = (r: InterviewRow) => ({
  id: r.id,
  targetRole: r.target_role,
  interviewType: r.interview_type,
  difficulty: r.difficulty,
  durationMinutes: r.duration_minutes,
  mode: r.mode,
  status: r.status,
  startedAt: r.started_at,
  completedAt: r.completed_at,
});

const messageDto = (r: MessageRow) => ({
  id: r.id,
  seq: r.seq,
  role: r.role,
  content: r.content,
  createdAt: r.created_at,
});

const feedbackDto = (r: FeedbackRow) => ({
  overallScore: r.overall_score,
  communicationScore: r.communication_score,
  technicalScore: r.technical_score,
  relevanceScore: r.relevance_score,
  strengths: r.strengths,
  weaknesses: r.weaknesses,
  missedConcepts: r.missed_concepts,
  improvedAnswers: r.improved_answers,
  nextSteps: r.next_steps,
  // Scores come from an AI model reading the transcript: estimates, not facts.
  isAiEstimate: r.is_ai_estimate,
  createdAt: r.created_at,
});

const dbError = (message: string) => new HttpError(500, 'db_error', message);

/** Number of questions for a session length: about one per 3 minutes, 3 to 12. */
export const questionBudget = (minutes: number) =>
  Math.min(12, Math.max(3, Math.round(minutes / 3)));

const ctxOf = (r: InterviewRow): InterviewContext => ({
  targetRole: r.target_role,
  interviewType: r.interview_type,
  difficulty: r.difficulty,
});

const toTurn = (m: MessageRow): ChatTurn => ({
  role: m.role === 'interviewer' ? 'model' : 'user',
  text: m.content,
});

async function loadInterview(db: SupabaseClient, id: string): Promise<InterviewRow> {
  const { data, error } = await db
    .from('interviews')
    .select(INTERVIEW_COLS)
    .eq('id', id)
    .maybeSingle();
  if (error) throw dbError('Could not load the interview');
  if (!data) throw new HttpError(404, 'not_found', 'Interview not found');
  return data as InterviewRow;
}

async function loadMessages(db: SupabaseClient, id: string): Promise<MessageRow[]> {
  const { data, error } = await db
    .from('interview_messages')
    .select(MESSAGE_COLS)
    .eq('interview_id', id)
    .order('seq', { ascending: true });
  if (error) throw dbError('Could not load the transcript');
  return (data ?? []) as MessageRow[];
}

export async function createInterview(
  db: SupabaseClient,
  userId: string,
  input: CreateInterviewInput,
) {
  const ai = getAiProvider(); // fail fast, before anything is written
  const { data, error } = await db
    .from('interviews')
    .insert({
      user_id: userId,
      target_role: input.targetRole,
      interview_type: input.interviewType,
      difficulty: input.difficulty,
      duration_minutes: input.durationMinutes,
      mode: input.mode,
    })
    .select(INTERVIEW_COLS)
    .single();
  if (error || !data) throw dbError('Could not start the interview');
  const row = data as InterviewRow;
  const total = questionBudget(row.duration_minutes);

  const discard = () => db.from('interviews').delete().eq('id', row.id);
  let question: string;
  try {
    question = await ai.generate({
      system: interviewerSystem(ctxOf(row), 1, total),
      turns: [START_TURN],
      temperature: 0.8,
      maxOutputTokens: 1024,
    });
  } catch (e) {
    await discard();
    throw e;
  }

  const first = await db
    .from('interview_messages')
    .insert({ interview_id: row.id, user_id: userId, seq: 1, role: 'interviewer', content: question })
    .select(MESSAGE_COLS)
    .single();
  if (first.error || !first.data) {
    await discard();
    throw dbError('Could not start the interview');
  }
  return {
    interview: interviewDto(row),
    messages: [messageDto(first.data as MessageRow)],
    totalQuestions: total,
  };
}

export async function submitAnswer(
  db: SupabaseClient,
  userId: string,
  id: string,
  answer: string,
) {
  const ai = getAiProvider();
  const interview = await loadInterview(db, id);
  if (interview.status !== 'in_progress') {
    throw new HttpError(409, 'interview_closed', 'This interview is already finished');
  }
  const messages = await loadMessages(db, id);
  const last = messages[messages.length - 1];
  if (!last || last.role !== 'interviewer') {
    throw new HttpError(409, 'out_of_turn', 'Wait for the next question');
  }

  const total = questionBudget(interview.duration_minutes);
  const answered = messages.filter((m) => m.role === 'candidate').length + 1;
  const candidateRow = {
    interview_id: id,
    user_id: userId,
    seq: last.seq + 1,
    role: 'candidate',
    content: answer,
  };

  const saveFailed = (e: { code?: string } | null) =>
    e?.code === '23505'
      ? new HttpError(409, 'out_of_turn', 'That answer was already submitted')
      : dbError('Could not save your answer');

  if (answered >= total) {
    const saved = await db.from('interview_messages').insert(candidateRow).select(MESSAGE_COLS).single();
    if (saved.error || !saved.data) throw saveFailed(saved.error);
    return { done: true, messages: [messageDto(saved.data as MessageRow)], answered, totalQuestions: total };
  }

  // Generate the next question BEFORE saving, so an AI failure leaves nothing
  // half-written and the user can simply resend the same answer.
  const question = await ai.generate({
    system: interviewerSystem(ctxOf(interview), answered + 1, total),
    turns: [START_TURN, ...messages.map(toTurn), { role: 'user', text: answer }],
    temperature: 0.8,
    maxOutputTokens: 1024,
  });

  const saved = await db
    .from('interview_messages')
    .insert([
      candidateRow,
      { interview_id: id, user_id: userId, seq: last.seq + 2, role: 'interviewer', content: question },
    ])
    .select(MESSAGE_COLS)
    .order('seq', { ascending: true });
  if (saved.error || !saved.data) throw saveFailed(saved.error);
  return {
    done: false,
    messages: (saved.data as MessageRow[]).map(messageDto),
    answered,
    totalQuestions: total,
  };
}

export async function getInterviewDetail(db: SupabaseClient, id: string) {
  const interview = await loadInterview(db, id);
  const messages = await loadMessages(db, id);
  const fb = await db
    .from('interview_feedback')
    .select(FEEDBACK_COLS)
    .eq('interview_id', id)
    .maybeSingle();
  if (fb.error) throw dbError('Could not load the feedback');
  return {
    interview: interviewDto(interview),
    messages: messages.map(messageDto),
    feedback: fb.data ? feedbackDto(fb.data as FeedbackRow) : null,
    totalQuestions: questionBudget(interview.duration_minutes),
  };
}

export async function completeInterview(db: SupabaseClient, userId: string, id: string) {
  const interview = await loadInterview(db, id);
  if (interview.status === 'completed') return getInterviewDetail(db, id); // idempotent

  const messages = await loadMessages(db, id);
  if (!messages.some((m) => m.role === 'candidate')) {
    throw new HttpError(400, 'no_answers', 'Answer at least one question before finishing');
  }

  const ai = getAiProvider();
  const raw = await ai.generate({
    system: FEEDBACK_SYSTEM,
    turns: [{ role: 'user', text: feedbackUserText(ctxOf(interview), messages) }],
    json: true,
    temperature: 0.3,
    maxOutputTokens: 4096,
  });

  let parsed;
  try {
    parsed = feedbackSchema.parse(parseJsonLoose(raw));
  } catch {
    throw new HttpError(
      502,
      'ai_bad_output',
      'The AI returned feedback in an unexpected format. Please try finishing again.',
    );
  }

  const inserted = await db.from('interview_feedback').insert({
    interview_id: id,
    user_id: userId,
    overall_score: overallScore(parsed),
    communication_score: parsed.communicationScore,
    technical_score: parsed.technicalScore,
    relevance_score: parsed.relevanceScore,
    strengths: parsed.strengths,
    weaknesses: parsed.weaknesses,
    missed_concepts: parsed.missedConcepts,
    improved_answers: parsed.improvedAnswers,
    next_steps: parsed.nextSteps,
    is_ai_estimate: true,
  });
  // 23505 = a parallel request already saved feedback; just return it.
  if (inserted.error && inserted.error.code !== '23505') {
    throw dbError('Could not save your results');
  }

  const closed = await db
    .from('interviews')
    .update({ status: 'completed', completed_at: new Date().toISOString() })
    .eq('id', id);
  if (closed.error) throw dbError('Could not finish the interview');
  return getInterviewDetail(db, id);
}

export async function listInterviews(db: SupabaseClient) {
  const { data, error } = await db
    .from('interviews')
    .select(`${INTERVIEW_COLS}, interview_feedback(overall_score)`)
    .order('created_at', { ascending: false })
    .limit(20);
  if (error) throw dbError('Could not load your interviews');
  type Row = InterviewRow & {
    interview_feedback: { overall_score: number } | { overall_score: number }[] | null;
  };
  return ((data ?? []) as Row[]).map((r) => {
    const fb = Array.isArray(r.interview_feedback) ? r.interview_feedback[0] : r.interview_feedback;
    return { ...interviewDto(r), overallScore: fb?.overall_score ?? null };
  });
}

export async function deleteInterview(db: SupabaseClient, id: string) {
  const { data, error } = await db.from('interviews').delete().eq('id', id).select('id');
  if (error) throw dbError('Could not delete the interview');
  if (!data || data.length === 0) throw new HttpError(404, 'not_found', 'Interview not found');
}

export async function getProgress(db: SupabaseClient) {
  const total = await db.from('interviews').select('id', { count: 'exact', head: true });
  if (total.error) throw dbError('Could not load your progress');

  const fb = await db
    .from('interview_feedback')
    .select('overall_score, communication_score, technical_score, relevance_score', {
      count: 'exact',
    })
    .order('created_at', { ascending: false })
    .limit(50);
  if (fb.error) throw dbError('Could not load your progress');

  const rows = (fb.data ?? []) as Pick<
    FeedbackRow,
    'overall_score' | 'communication_score' | 'technical_score' | 'relevance_score'
  >[];
  const avg = (pick: (r: (typeof rows)[number]) => number) =>
    rows.length === 0 ? null : Math.round(rows.reduce((s, r) => s + pick(r), 0) / rows.length);

  return {
    interviewCount: total.count ?? 0,
    completedCount: fb.count ?? rows.length,
    averageScore: avg((r) => r.overall_score),
    averages:
      rows.length === 0
        ? null
        : {
            communication: avg((r) => r.communication_score),
            technical: avg((r) => r.technical_score),
            relevance: avg((r) => r.relevance_score),
          },
    // oldest -> newest, last 10, for a trend chart
    recentScores: rows
      .slice(0, 10)
      .map((r) => r.overall_score)
      .reverse(),
  };
}