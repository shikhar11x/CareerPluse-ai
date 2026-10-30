import request from 'supertest';
import { beforeEach, describe, expect, it, vi } from 'vitest';

vi.mock('../src/db/supabase', () => ({
  verifyToken: vi.fn(),
  userClient: vi.fn(),
}));

import { app } from '../src/app';
import { userClient, verifyToken } from '../src/db/supabase';
import { fail, fakeDb, ok, profileRow } from './helpers';

const signedIn = (db: ReturnType<typeof fakeDb>['db']) => {
  vi.mocked(verifyToken).mockResolvedValue({ id: 'user-1' } as never);
  vi.mocked(userClient).mockReturnValue(db as never);
};

beforeEach(() => {
  vi.resetAllMocks();
});

describe('infrastructure', () => {
  it('GET /health returns ok', async () => {
    const res = await request(app).get('/api/v1/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });

  it('unknown routes return the standard error shape', async () => {
    const res = await request(app).get('/api/v1/nope');
    expect(res.status).toBe(404);
    expect(res.body).toEqual({ error: { code: 'not_found', message: 'Route not found' } });
  });
});

describe('authentication', () => {
  it('rejects requests with no token', async () => {
    const res = await request(app).get('/api/v1/profile');
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('unauthorized');
    expect(verifyToken).not.toHaveBeenCalled();
  });

  it('rejects an invalid or expired token', async () => {
    vi.mocked(verifyToken).mockResolvedValue(null);
    const res = await request(app).get('/api/v1/profile').set('Authorization', 'Bearer bad');
    expect(res.status).toBe(401);
  });
});

describe('GET /profile', () => {
  it('returns the signed-in user profile', async () => {
    signedIn(fakeDb({ select: ok(profileRow) }).db);
    const res = await request(app).get('/api/v1/profile').set('Authorization', 'Bearer t');
    expect(res.status).toBe(200);
    expect(res.body.profile).toMatchObject({
      id: 'user-1',
      fullName: 'Asha Rao',
      targetRole: 'Flutter Developer',
    });
  });

  it('returns 500 with a safe message when the database fails', async () => {
    signedIn(fakeDb({ select: fail('secret db detail') }).db);
    const res = await request(app).get('/api/v1/profile').set('Authorization', 'Bearer t');
    expect(res.status).toBe(500);
    expect(res.body.error.code).toBe('db_error');
    expect(JSON.stringify(res.body)).not.toContain('secret db detail');
  });
});

describe('PATCH /profile', () => {
  it('saves valid changes', async () => {
    const { db, calls } = fakeDb({ upsert: ok({ ...profileRow, full_name: 'Asha' }) });
    signedIn(db);
    const res = await request(app)
      .patch('/api/v1/profile')
      .set('Authorization', 'Bearer t')
      .send({ fullName: '  Asha  ' });
    expect(res.status).toBe(200);
    expect(calls.upsert).toEqual([{ id: 'user-1', full_name: 'Asha' }]);
    expect(res.body.profile.fullName).toBe('Asha');
  });

  it('returns 400 for an empty body', async () => {
    signedIn(fakeDb().db);
    const res = await request(app)
      .patch('/api/v1/profile')
      .set('Authorization', 'Bearer t')
      .send({});
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('validation_error');
  });

  it('returns 400 for an invalid experience level', async () => {
    signedIn(fakeDb().db);
    const res = await request(app)
      .patch('/api/v1/profile')
      .set('Authorization', 'Bearer t')
      .send({ experienceLevel: 'wizard' });
    expect(res.status).toBe(400);
  });

  it('returns 400 for malformed JSON', async () => {
    signedIn(fakeDb().db);
    const res = await request(app)
      .patch('/api/v1/profile')
      .set('Authorization', 'Bearer t')
      .set('Content-Type', 'application/json')
      .send('{bad json');
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('bad_json');
  });
});