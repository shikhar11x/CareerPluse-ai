import type { SupabaseClient } from '@supabase/supabase-js';

type Result = { data: unknown; error: { message: string } | null };

export const ok = (data: unknown): Result => ({ data, error: null });
export const fail = (message = 'boom'): Result => ({ data: null, error: { message } });

/** Minimal chainable stand-in for the Supabase query builder. */
export function fakeDb(opts: { select?: Result; insert?: Result; upsert?: Result } = {}) {
  const calls = { insert: [] as unknown[], upsert: [] as unknown[] };

  const chain = (result: Result) => {
    const q: Record<string, unknown> = {};
    q.select = () => q;
    q.eq = () => q;
    q.maybeSingle = async () => result;
    q.single = async () => result;
    return q;
  };

  const db = {
    from: () => ({
      select: () => chain(opts.select ?? ok(null)),
      insert: (v: unknown) => {
        calls.insert.push(v);
        return chain(opts.insert ?? ok(null));
      },
      upsert: (v: unknown) => {
        calls.upsert.push(v);
        return chain(opts.upsert ?? ok(null));
      },
    }),
  };

  return { db: db as unknown as SupabaseClient, calls };
}

export const profileRow = {
  id: 'user-1',
  full_name: 'Asha Rao',
  education: "Bachelor's",
  target_role: 'Flutter Developer',
  experience_level: 'fresher',
};