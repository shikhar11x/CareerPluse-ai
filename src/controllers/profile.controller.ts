import type { Request, Response } from 'express';

import { getAuth } from '../middleware/auth';
import { getProfile, updateProfile } from '../services/profile.service';
import { updateProfileSchema } from '../validation/profile';

export async function getMyProfile(_req: Request, res: Response) {
  const { db, userId } = getAuth(res);
  res.json({ profile: await getProfile(db, userId) });
}

export async function patchMyProfile(req: Request, res: Response) {
  const { db, userId } = getAuth(res);
  const input = updateProfileSchema.parse(req.body ?? {});
  res.json({ profile: await updateProfile(db, userId, input) });
}