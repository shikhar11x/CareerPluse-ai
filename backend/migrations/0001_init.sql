-- CareerPulse AI: initial schema (8 tables, RLS, triggers)

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

-- 1. profiles (one row per auth user)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  education text not null default '',
  target_role text not null default '',
  experience_level text not null default ''
    check (experience_level in ('', 'fresher', 'junior', 'mid', 'senior')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger profiles_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();

-- Auto-create an empty profile when a user signs up.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id) values (new.id) on conflict do nothing;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- 2. resumes
create table if not exists public.resumes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  file_name text not null,
  extracted_text text not null,
  created_at timestamptz not null default now()
);
create index if not exists resumes_user_idx on public.resumes (user_id, created_at desc);

-- 3. job_matches (match_score stays NULL unless a defined formula produced it)
create table if not exists public.job_matches (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  resume_id uuid not null references public.resumes(id) on delete cascade,
  job_title text not null default '',
  job_description text not null,
  matched_skills text[] not null default '{}',
  missing_skills text[] not null default '{}',
  suggestions text[] not null default '{}',
  match_score numeric(5,2) check (match_score between 0 and 100),
  score_method text,
  created_at timestamptz not null default now()
);
create index if not exists job_matches_user_idx on public.job_matches (user_id, created_at desc);
create index if not exists job_matches_resume_idx on public.job_matches (resume_id);

-- 4. interviews
create table if not exists public.interviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  target_role text not null,
  interview_type text not null check (interview_type in ('technical', 'hr', 'behavioral', 'mixed')),
  difficulty text not null check (difficulty in ('beginner', 'intermediate', 'advanced')),
  duration_minutes int not null check (duration_minutes between 5 and 60),
  mode text not null check (mode in ('text', 'voice')),
  status text not null default 'in_progress'
    check (status in ('in_progress', 'completed', 'abandoned')),
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists interviews_user_idx on public.interviews (user_id, created_at desc);

-- 5. interview_messages (transcript; no raw audio is stored)
create table if not exists public.interview_messages (
  id uuid primary key default gen_random_uuid(),
  interview_id uuid not null references public.interviews(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  seq int not null,
  role text not null check (role in ('interviewer', 'candidate')),
  content text not null,
  created_at timestamptz not null default now(),
  unique (interview_id, seq)
);
create index if not exists interview_messages_user_idx on public.interview_messages (user_id);

-- 6. interview_feedback (scores are AI estimates, flagged as such)
create table if not exists public.interview_feedback (
  id uuid primary key default gen_random_uuid(),
  interview_id uuid not null unique references public.interviews(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  overall_score smallint not null check (overall_score between 0 and 100),
  communication_score smallint not null check (communication_score between 0 and 100),
  technical_score smallint not null check (technical_score between 0 and 100),
  relevance_score smallint not null check (relevance_score between 0 and 100),
  strengths text[] not null default '{}',
  weaknesses text[] not null default '{}',
  missed_concepts text[] not null default '{}',
  improved_answers jsonb not null default '[]'::jsonb,
  next_steps text[] not null default '{}',
  is_ai_estimate boolean not null default true,
  created_at timestamptz not null default now()
);
create index if not exists interview_feedback_user_idx on public.interview_feedback (user_id, created_at desc);

-- 7. skill_progress
create table if not exists public.skill_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  skill text not null,
  level smallint not null default 0 check (level between 0 and 100),
  updated_at timestamptz not null default now(),
  unique (user_id, skill)
);
create trigger skill_progress_updated_at before update on public.skill_progress
  for each row execute function public.set_updated_at();

-- 8. learning_tasks
create table if not exists public.learning_tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text not null default '',
  skill text,
  source_interview_id uuid references public.interviews(id) on delete set null,
  is_done boolean not null default false,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists learning_tasks_user_idx on public.learning_tasks (user_id, is_done, created_at desc);

-- Row Level Security: profiles
alter table public.profiles enable row level security;
drop policy if exists "profiles select own" on public.profiles;
drop policy if exists "profiles insert own" on public.profiles;
drop policy if exists "profiles update own" on public.profiles;
drop policy if exists "profiles delete own" on public.profiles;
create policy "profiles select own" on public.profiles for select to authenticated
  using (id = (select auth.uid()));
create policy "profiles insert own" on public.profiles for insert to authenticated
  with check (id = (select auth.uid()));
create policy "profiles update own" on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy "profiles delete own" on public.profiles for delete to authenticated
  using (id = (select auth.uid()));

-- Row Level Security: every other table is owner-only
do $$
declare t text;
begin
  foreach t in array array[
    'resumes', 'job_matches', 'interviews', 'interview_messages',
    'interview_feedback', 'skill_progress', 'learning_tasks'
  ]
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "own rows" on public.%I', t);
    execute format(
      'create policy "own rows" on public.%I for all to authenticated '
      'using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()))', t);
  end loop;
end $$;