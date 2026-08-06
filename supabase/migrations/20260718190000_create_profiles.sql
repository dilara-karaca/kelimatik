-- profiles: one row per auth user (Google Sign-In)
-- Run in Supabase Dashboard → SQL Editor (or via CLI migration).

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null unique,
  display_name text,
  avatar_url text,
  xp integer not null default 0,
  level integer not null default 1,
  correct_count integer not null default 0,
  wrong_count integer not null default 0,
  streak integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_xp_nonnegative check (xp >= 0),
  constraint profiles_level_positive check (level >= 1),
  constraint profiles_correct_count_nonnegative check (correct_count >= 0),
  constraint profiles_wrong_count_nonnegative check (wrong_count >= 0),
  constraint profiles_streak_nonnegative check (streak >= 0)
);

create index if not exists profiles_username_idx on public.profiles (username);

create or replace function public.set_profiles_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row
execute function public.set_profiles_updated_at();

alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles
for select
to authenticated
using (auth.uid() = id);

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

-- Optional: allow reading other profiles later for leaderboard (commented out)
-- drop policy if exists "profiles_select_authenticated" on public.profiles;
-- create policy "profiles_select_authenticated"
-- on public.profiles for select to authenticated using (true);
