-- Daily login check-ins (Daily Streak). One row per user per calendar day (UTC).

create table if not exists public.daily_logins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  login_date date not null,
  streak_count integer not null default 1,
  created_at timestamptz not null default now(),
  constraint daily_logins_user_date_unique unique (user_id, login_date),
  constraint daily_logins_streak_positive check (streak_count >= 1)
);

create index if not exists daily_logins_user_login_date_idx
  on public.daily_logins (user_id, login_date desc);

alter table public.daily_logins enable row level security;

drop policy if exists "daily_logins_select_own" on public.daily_logins;
create policy "daily_logins_select_own"
on public.daily_logins
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "daily_logins_insert_own" on public.daily_logins;
create policy "daily_logins_insert_own"
on public.daily_logins
for insert
to authenticated
with check (auth.uid() = user_id);

-- Immutable check-in rows: no update/delete from clients.

comment on table public.daily_logins is
  'UTC calendar-day login ledger. Profiles.daily_streak is the denormalized current streak.';
comment on column public.daily_logins.login_date is
  'Calendar date in UTC. App may later switch to user timezone via metadata.';
