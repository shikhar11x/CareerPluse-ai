import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    include: ['tests/**/*.test.ts'],
    env: {
      NODE_ENV: 'test',
      SUPABASE_URL: 'https://test.supabase.co',
      SUPABASE_ANON_KEY: 'test-anon-key',
      // Empty on purpose: tests must never depend on a real key from .env.
      AI_API_KEY: '',
      GEMINI_MODEL: 'test-model',
    },
  },
});