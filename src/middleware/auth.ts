import type { NextFunction, Request, Response } from 'express';
import type { SupabaseClient } from '@supabase/supabase-js';

import { WrappedAuth } from './auth.types';
import { userClient, verifyToken } from '../db/supabase';
import { HttpError } from './errors';

export async function requireAuth(req: Request, res: Response, next: NextFunction) {
  try {
    const header = req.headers.authorization ?? '';
    const token = header.startsWith('Bearer ') ? header.slice(7).trim() : '';
    if (!token) throw new HttpError(401, 'unauthorized', 'Missing access token');

    const user = await verifyToken(token);
    if (!user) throw new HttpError(401, 'unauthorized', 'Invalid or expired session');

    const auth: WrappedAuth = { userId: user.id, db: userClient(token) };
    res.locals.auth = auth;
    next();
  } catch (e) {
    next(e);
  }
}

export function getAuth(res: Response): { userId: string; db: SupabaseClient } {
  return res.locals.auth as WrappedAuth;
}