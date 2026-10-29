import { z } from 'zod';

export const updateProfileSchema = z
  .object({
    fullName: z.string().trim().min(1).max(100),
    education: z.string().trim().min(1).max(60),
    targetRole: z.string().trim().min(1).max(100),
    experienceLevel: z.enum(['fresher', 'junior', 'mid', 'senior']),
  })
  .partial()
  .refine((v) => Object.keys(v).length > 0, { message: 'Provide at least one field to update' });

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;