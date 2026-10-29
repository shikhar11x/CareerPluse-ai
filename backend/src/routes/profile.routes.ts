import { Router } from 'express';

import { getMyProfile, patchMyProfile } from '../controllers/profile.controller';
import { requireAuth } from '../middleware/auth';
import { asyncHandler } from '../middleware/errors';

export const profileRoutes = Router();

profileRoutes.use(requireAuth);
profileRoutes.get('/', asyncHandler(getMyProfile));
profileRoutes.patch('/', asyncHandler(patchMyProfile));
