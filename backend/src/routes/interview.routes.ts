import { Router } from 'express';
import rateLimit from 'express-rate-limit';

import {
  answer,
  complete,
  create,
  detail,
  list,
  progress,
  remove,
} from '../controllers/interview.controller';
import { requireAuth } from '../middleware/auth';
import { asyncHandler } from '../middleware/errors';

// AI calls cost quota, so they get a tighter limit than the global one.
const aiLimiter = rateLimit({
  windowMs: 60_000,
  limit: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: { code: 'rate_limited', message: 'Too many requests. Slow down a little.' } },
});

export const interviewRoutes = Router();
interviewRoutes.use(requireAuth);
interviewRoutes.get('/', asyncHandler(list));
interviewRoutes.post('/', aiLimiter, asyncHandler(create));
interviewRoutes.get('/:id', asyncHandler(detail));
interviewRoutes.post('/:id/answers', aiLimiter, asyncHandler(answer));
interviewRoutes.post('/:id/complete', aiLimiter, asyncHandler(complete));
interviewRoutes.delete('/:id', asyncHandler(remove));

export const progressRoutes = Router();
progressRoutes.use(requireAuth);
progressRoutes.get('/', asyncHandler(progress));