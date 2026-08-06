-- Extend profiles for daily streak, quiz streak, and activity metrics.
-- Keeps existing columns; clarifies semantics for future app sync.

alter table public.profiles
  add column if not exists best_quiz_streak integer not null default 0,
  add column if not exists daily_streak integer not null default 0,
  add column if not exists last_daily_login_date date,
  add column if not exists total_sessions integer not null default 0,
  add column if not exists last_played_at timestamptz,
  add column if not exists is_premium boolean not null default false;

alter table public.profiles
  drop constraint if exists profiles_best_quiz_streak_nonnegative,
  drop constraint if exists profiles_daily_streak_nonnegative,
  drop constraint if exists profiles_total_sessions_nonnegative;

alter table public.profiles
  add constraint profiles_best_quiz_streak_nonnegative check (best_quiz_streak >= 0),
  add constraint profiles_daily_streak_nonnegative check (daily_streak >= 0),
  add constraint profiles_total_sessions_nonnegative check (total_sessions >= 0);

comment on column public.profiles.streak is
  'Legacy counter; prefer daily_streak for login streak and best_quiz_streak for Seri Modu.';
comment on column public.profiles.daily_streak is
  'Consecutive daily login streak (Daily Streak feature).';
comment on column public.profiles.best_quiz_streak is
  'Best run length achieved in Seri Modu.';
comment on column public.profiles.correct_count is
  'Lifetime correct answers (performance summary).';
comment on column public.profiles.wrong_count is
  'Lifetime wrong answers (performance summary).';

-- Leaderboard / public profile cards need read access for authenticated users.
drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_select_authenticated" on public.profiles;

create policy "profiles_select_authenticated"
on public.profiles
for select
to authenticated
using (true);

-- Keep write scoped to owner
drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles
for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

-- Hot paths for leaderboard-style sorts
create index if not exists profiles_xp_desc_idx
  on public.profiles (xp desc, correct_count desc);

create index if not exists profiles_daily_streak_desc_idx
  on public.profiles (daily_streak desc)
  where daily_streak > 0;

create index if not exists profiles_last_played_at_idx
  on public.profiles (last_played_at desc nulls last);
