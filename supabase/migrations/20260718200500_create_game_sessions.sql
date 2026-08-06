-- Completed / ended play sessions for all modes (analytics + leaderboard feeds).

create table if not exists public.game_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  mode public.game_mode not null,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  duration_seconds integer,
  correct_count integer not null default 0,
  wrong_count integer not null default 0,
  answered_count integer not null default 0,
  max_streak integer not null default 0,
  challenge_time_limit_seconds integer,
  challenge_target_count integer,
  xp_earned integer not null default 0,
  success_rate numeric(5, 2),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint game_sessions_counts_nonnegative check (
    correct_count >= 0
    and wrong_count >= 0
    and answered_count >= 0
    and max_streak >= 0
    and xp_earned >= 0
  ),
  constraint game_sessions_duration_nonnegative check (
    duration_seconds is null or duration_seconds >= 0
  ),
  constraint game_sessions_ended_after_start check (
    ended_at is null or ended_at >= started_at
  )
);

create index if not exists game_sessions_user_started_at_idx
  on public.game_sessions (user_id, started_at desc);

create index if not exists game_sessions_user_mode_started_at_idx
  on public.game_sessions (user_id, mode, started_at desc);

create index if not exists game_sessions_mode_started_at_idx
  on public.game_sessions (mode, started_at desc);

-- Hot filter for recent global activity / weekly leaderboard rebuilds
create index if not exists game_sessions_started_at_brin
  on public.game_sessions using brin (started_at);

alter table public.game_sessions enable row level security;

drop policy if exists "game_sessions_select_own" on public.game_sessions;
create policy "game_sessions_select_own"
on public.game_sessions
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "game_sessions_insert_own" on public.game_sessions;
create policy "game_sessions_insert_own"
on public.game_sessions
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "game_sessions_update_own" on public.game_sessions;
create policy "game_sessions_update_own"
on public.game_sessions
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Deletes usually unnecessary for analytics; omit client delete policy.

comment on table public.game_sessions is
  'One row per finished (or abandoned) quiz run across classic/challenge/streak/etc.';
comment on column public.game_sessions.metadata is
  'Forward-compatible bag for package ids, device info, A/B flags, etc.';
