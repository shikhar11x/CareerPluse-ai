import path from 'node:path';

import dotenv from 'dotenv';
import { z } from 'zod';

// Always load backend/.env, regardless of the folder the command runs from.
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const schema = z.object({
  PORT: z.coerce.number().default(4000),
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  SUPABASE_URL: z.string().url(),
  SUPABASE_ANON_KEY: z.string().min(1),
  // Needed from Phase 3 onwards.
  AI_API_KEY: z.string().optional(),
});

const parsed = schema.safeParse(process.env);
if (!parsed.success) {
  console.error('Invalid environment variables:', parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsed.data;