import { describe, expect, it } from 'vitest';

import { HttpError } from '../src/middleware/errors';
import { getProfile, updateProfile } from '../src/services/profile.service';
import { fail, fakeDb, ok, profileRow } from './helpers';

describe('getProfile', () => {
  it('maps database columns to camelCase', async () => {
    const { db } = fakeDb({ select: ok(profileRow) });
    expect(await getProfile(db, 'user-1')).toEqual({
      id: 'user-1',
      fullName: 'Asha Rao',
      education: "Bachelor's",
      targetRole: 'Flutter Developer',
      experienceLevel: 'fresher',
    });
  });

  it('creates an empty profile when the row is missing', async () => {
    const { db, calls } = fakeDb({
      select: ok(null),
      insert: ok({ ...profileRow, full_name: '', education: '', target_role: '', experience_level: '' }),
    });
    const profile = await getProfile(db, 'user-1');
    expect(calls.insert).toEqual([{ id: 'user-1' }]);
    expect(profile.fullName).toBe('');
  });

  it('throws a 500 HttpError when the query fails', async () => {
    const { db } = fakeDb({ select: fail() });
    await expect(getProfile(db, 'user-1')).rejects.toMatchObject({
      status: 500,
      code: 'db_error',
    });
    await expect(getProfile(db, 'user-1')).rejects.toBeInstanceOf(HttpError);
  });
});

describe('updateProfile', () => {
  it('sends only the provided fields, as snake_case', async () => {
    const { db, calls } = fakeDb({ upsert: ok({ ...profileRow, experience_level: 'mid' }) });
    const profile = await updateProfile(db, 'user-1', { experienceLevel: 'mid' });
    expect(calls.upsert).toEqual([{ id: 'user-1', experience_level: 'mid' }]);
    expect(profile.experienceLevel).toBe('mid');
  });

  it('throws a 500 HttpError when saving fails', async () => {
    const { db } = fakeDb({ upsert: fail() });
    await expect(updateProfile(db, 'user-1', { fullName: 'A' })).rejects.toMatchObject({
      status: 500,
    });
  });
});