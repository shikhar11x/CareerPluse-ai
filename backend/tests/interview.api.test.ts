import request from 'supertest';
import { beforeEach, describe, expect, it, vi } from 'vitest';

vi.mock('../src/db/supabase', () => ({
  verifyToken: vi.fn(),
  userClient: vi.fn(),
}));

import { setAiProvider } from '../src/ai';
import { app } from '../src/app';
import { userClient, verifyToken } from '../src/db/supabase';
import { interviewRow, memoryDb, messageRow } from './memoryDb';

const ID = '3f2b8c1e-5d4a-4b7e-9c11-0a1b2c3d4e5f';
const auth = { Authorization: 'Bearer t' };
const setup = {
  targetRole: 'Flutter Developer',
  interviewType: 'technical',
  difficulty: 'beginner',
  durationMinutes: 5,
  mode: 'text',
};

function signIn(seed = {}) {
  const mem = memoryDb(seed);
  vi.mocked(verifyToken).mockResolvedValue({ id: 'u1' } as never);
  vi.mocked(userClient).mockReturnValue(mem.db as never);
  return mem;
}

beforeEach(() => {
  vi.resetAllMocks();
  setAiProvider(null);
});

describe('auth and validation', () => {
  it.each([
    ['get', '/api/v1/interviews'],
    ['post', '/api/v1/interviews'],
    ['get', `/api/v1/interviews/${ID}`],
    ['post', `/api/v1/interviews/${ID}/answers`],
    ['post', `/api/v1/interviews/${ID}/complete`],
    ['delete', `/api/v1/interviews/${ID}`],
    ['get', '/api/v1/progress'],
  ] as const)('%s %s needs a token', async (method, url) => {
    const res = await request(app)[method](url);
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('unauthorized');
  });

  it('rejects an invalid interview setup with 400', async () => {
    signIn();
    const res = await request(app)
      .post('/api/v1/interviews')
      .set(auth)
      .send({ ...setup, durationMinutes: 1 });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('validation_error');
  });

  it('rejects a non-uuid id with 400', async () => {
    signIn();
    const res = await request(app).get('/api/v1/interviews/not-a-uuid').set(auth);
    expect(res.status).toBe(400);
  });

  it('rejects an empty or oversized answer with 400', async () => {
    signIn();
    const empty = await request(app).post(`/api/v1/interviews/${ID}/answers`).set(auth).send({ answer: '  ' });
    const big = await request(app)
      .post(`/api/v1/interviews/${ID}/answers`)
      .set(auth)
      .send({ answer: 'x'.repeat(2001) });
    expect(empty.status).toBe(400);
    expect(big.status).toBe(400);
  });
});

describe('interview endpoints', () => {
  it('POST /interviews returns 503 when AI is not configured', async () => {
    const { tables } = signIn();
    const res = await request(app).post('/api/v1/interviews').set(auth).send(setup);
    expect(res.status).toBe(503);
    expect(res.body.error.code).toBe('ai_not_configured');
    expect(tables.interviews).toHaveLength(0);
  });

  it('POST /interviews creates an interview with its first question', async () => {
    signIn();
    setAiProvider({ generate: async () => 'Welcome! Tell me about Flutter.' });
    const res = await request(app).post('/api/v1/interviews').set(auth).send(setup);
    expect(res.status).toBe(201);
    expect(res.body.interview.targetRole).toBe('Flutter Developer');
    expect(res.body.messages[0].content).toBe('Welcome! Tell me about Flutter.');
    expect(res.body.totalQuestions).toBe(3);
  });

  it('GET /interviews/:id returns the transcript and null feedback', async () => {
    signIn({
      interviews: [interviewRow({ id: ID })],
      interview_messages: [{ ...messageRow(1, 'interviewer', 'Q?'), interview_id: ID }],
    });
    const res = await request(app).get(`/api/v1/interviews/${ID}`).set(auth);
    expect(res.status).toBe(200);
    expect(res.body.messages).toHaveLength(1);
    expect(res.body.feedback).toBeNull();
  });

  it('GET /interviews/:id returns 404 for someone else\'s or a missing interview', async () => {
    signIn();
    const res = await request(app).get(`/api/v1/interviews/${ID}`).set(auth);
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('not_found');
  });

  it('DELETE /interviews/:id returns 204', async () => {
    signIn({ interviews: [interviewRow({ id: ID })] });
    const res = await request(app).delete(`/api/v1/interviews/${ID}`).set(auth);
    expect(res.status).toBe(204);
  });

  it('GET /progress returns zeros for a new user', async () => {
    signIn();
    const res = await request(app).get('/api/v1/progress').set(auth);
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ interviewCount: 0, completedCount: 0, averageScore: null });
  });
});