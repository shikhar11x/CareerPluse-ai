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
  // Google AI Studio key. Server-side only.
  AI_API_KEY: z.string().optional(),
  // Model IDs change often, so this is configurable (check AI Studio for the current list).
  GEMINI_MODEL: z.string().min(1).default('gemini-3.8-flash'),
});

const parsed = schema.safeParse(process.env);
if (!parsed.success) {
  console.error('Invalid environment variables:', parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsed.data;