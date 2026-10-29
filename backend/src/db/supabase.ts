import { createClient, type SupabaseClient, type User } from '@supabase/supabase-js';

import { env } from '../config/env';

const options = {
  auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
};

const anon = createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, options);

/** Asks Supabase Auth to validate the access token. Returns null if invalid/expired. */
export async function verifyToken(token: string): Promise<User | null> {
  const { data, error } = await anon.auth.getUser(token);
  if (error || !data.user) return null;
  return data.user;
}

/** A client that acts AS the user, so Row Level Security applies to every query. */
export function userClient(token: string): SupabaseClient {
  return createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, {
    ...options,
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
}