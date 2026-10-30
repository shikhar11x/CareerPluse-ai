import { env } from '../config/env';
import { HttpError } from '../middleware/errors';
import { GeminiProvider } from './gemini';
import type { AiProvider } from './types';

let provider: AiProvider | null = null;

/** Throws a clear 503 instead of crashing when no key is configured. */
export function getAiProvider(): AiProvider {
  if (provider) return provider;
  if (!env.AI_API_KEY) {
    throw new HttpError(
      503,
      'ai_not_configured',
      'AI is not configured on the server (missing AI_API_KEY).',
    );
  }
  provider = new GeminiProvider(env.AI_API_KEY, env.GEMINI_MODEL);
  return provider;
}

/** Test hook: inject a fake provider (or null to reset). */
export function setAiProvider(p: AiProvider | null) {
  provider = p;
}