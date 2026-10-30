import { describe, expect, it } from 'vitest';

import { updateProfileSchema } from '../src/validation/profile';

describe('updateProfileSchema', () => {
  it('accepts a partial update and trims text', () => {
    const r = updateProfileSchema.parse({ fullName: '  Asha  ' });
    expect(r).toEqual({ fullName: 'Asha' });
  });

  it('accepts every allowed experience level', () => {
    for (const level of ['fresher', 'junior', 'mid', 'senior']) {
      expect(updateProfileSchema.safeParse({ experienceLevel: level }).success).toBe(true);
    }
  });

  it('rejects an empty object', () => {
    expect(updateProfileSchema.safeParse({}).success).toBe(false);
  });

  it('rejects an unknown experience level', () => {
    expect(updateProfileSchema.safeParse({ experienceLevel: 'wizard' }).success).toBe(false);
  });

  it('rejects blank and overlong values', () => {
    expect(updateProfileSchema.safeParse({ fullName: '   ' }).success).toBe(false);
    expect(updateProfileSchema.safeParse({ targetRole: 'x'.repeat(101) }).success).toBe(false);
  });
});