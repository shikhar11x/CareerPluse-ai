import type { SupabaseClient } from '@supabase/supabase-js';

import { HttpError } from '../middleware/errors';
import type { UpdateProfileInput } from '../validation/profile';

const COLUMNS = 'id, full_name, education, target_role, experience_level';

interface ProfileRow {
  id: string;
  full_name: string;
  education: string;
  target_role: string;
  experience_level: string;
}

const toDto = (r: ProfileRow) => ({
  id: r.id,
  fullName: r.full_name,
  education: r.education,
  targetRole: r.target_role,
  experienceLevel: r.experience_level,
});

export async function getProfile(db: SupabaseClient, userId: string) {
  const { data, error } = await db
    .from('profiles')
    .select(COLUMNS)
    .eq('id', userId)
    .maybeSingle();
  if (error) throw new HttpError(500, 'db_error', 'Could not load your profile');
  if (data) return toDto(data as ProfileRow);

  // Fallback if the signup trigger did not run for this user.
  const created = await db.from('profiles').insert({ id: userId }).select(COLUMNS).single();
  if (created.error) throw new HttpError(500, 'db_error', 'Could not create your profile');
  return toDto(created.data as ProfileRow);
}

export async function updateProfile(
  db: SupabaseClient,
  userId: string,
  input: UpdateProfileInput,
) {
  const patch: Record<string, string> = {};
  if (input.fullName !== undefined) patch.full_name = input.fullName;
  if (input.education !== undefined) patch.education = input.education;
  if (input.targetRole !== undefined) patch.target_role = input.targetRole;
  if (input.experienceLevel !== undefined) patch.experience_level = input.experienceLevel;

  // upsert so it also works if the row was never created
  const { data, error } = await db
    .from('profiles')
    .upsert({ id: userId, ...patch }, { onConflict: 'id' })
    .select(COLUMNS)
    .single();
  if (error) throw new HttpError(500, 'db_error', 'Could not save your profile');
  return toDto(data as ProfileRow);
}