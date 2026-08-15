-- User progress cloud sync: profiles progress columns + favorites/wrong_words
-- without requiring a remote words catalog (word_id matches local assets/data/words.json).

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Progress / lives / streak columns on profiles
alter table public.profiles
  add column if not exists best_quiz_streak integer not null default 0,
  add column if not exists daily_streak integer not null default 0,
  add column if not exists last_daily_login_date date,
  add column if not exists total_sessions integer not null default 0,
  add column if not exists last_played_at timestamptz,
  add column if not exists is_premium boolean not null default false,
  add column if not exists lives_current integer not null default 5,
  add column if not exists lives_regen_started_at timestamptz;

alter table public.profiles
  drop constraint if exists profiles_best_quiz_streak_nonnegative,
  drop constraint if exists profiles_daily_streak_nonnegative,
  drop constraint if exists profiles_total_sessions_nonnegative,
  drop constraint if exists profiles_lives_current_range,
  drop constraint if exists profiles_username_charset;

alter table public.profiles
  add constraint profiles_best_quiz_streak_nonnegative check (best_quiz_streak >= 0),
  add constraint profiles_daily_streak_nonnegative check (daily_streak >= 0),
  add constraint profiles_total_sessions_nonnegative check (total_sessions >= 0),
  add constraint profiles_lives_current_range check (lives_current >= 0 and lives_current <= 5),
  add constraint profiles_username_charset check (username ~ '^[a-z0-9]+$');

comment on column public.profiles.best_quiz_streak is
  'Best run length achieved in Seri Modu.';
comment on column public.profiles.daily_streak is
  'Consecutive daily activity streak.';
comment on column public.profiles.lives_current is
  'Current lives (0–5). Source of truth across devices.';
comment on column public.profiles.lives_regen_started_at is
  'UTC timestamp when the current missing-life regen cycle started.';

-- Leaderboard: authenticated users may read public profile cards.
drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_select_authenticated" on public.profiles;

create policy "profiles_select_authenticated"
on public.profiles
for select
to authenticated
using (true);

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

create index if not exists profiles_xp_desc_idx
  on public.profiles (xp desc, correct_count desc);

create index if not exists profiles_daily_streak_desc_idx
  on public.profiles (daily_streak desc)
  where daily_streak > 0;

-- Favorites (Favoriler) — word_id is local catalog id, no FK to words table.
create table if not exists public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  word_id integer not null,
  created_at timestamptz not null default now(),
  constraint favorites_user_word_unique unique (user_id, word_id)
);

create index if not exists favorites_user_created_at_idx
  on public.favorites (user_id, created_at desc);

create index if not exists favorites_word_id_idx
  on public.favorites (word_id);

alter table public.favorites enable row level security;

drop policy if exists "favorites_select_own" on public.favorites;
create policy "favorites_select_own"
on public.favorites
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "favorites_insert_own" on public.favorites;
create policy "favorites_insert_own"
on public.favorites
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "favorites_delete_own" on public.favorites;
create policy "favorites_delete_own"
on public.favorites
for delete
to authenticated
using (auth.uid() = user_id);

comment on table public.favorites is
  'Per-user bookmarked words; word_id matches client words.json ids.';

-- Wrong words (Yanlışlarım)
create table if not exists public.wrong_words (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  word_id integer not null,
  wrong_count integer not null default 1,
  correct_since_miss_count integer not null default 0,
  first_missed_at timestamptz not null default now(),
  last_missed_at timestamptz not null default now(),
  last_correct_at timestamptz,
  easiness numeric(4, 2) not null default 2.50,
  interval_days integer not null default 0,
  repetition integer not null default 0,
  next_review_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint wrong_words_user_word_unique unique (user_id, word_id),
  constraint wrong_words_wrong_count_positive check (wrong_count >= 1),
  constraint wrong_words_correct_since_nonnegative check (correct_since_miss_count >= 0),
  constraint wrong_words_interval_nonnegative check (interval_days >= 0),
  constraint wrong_words_repetition_nonnegative check (repetition >= 0),
  constraint wrong_words_easiness_positive check (easiness > 0)
);

create index if not exists wrong_words_user_last_missed_idx
  on public.wrong_words (user_id, last_missed_at desc);

create index if not exists wrong_words_word_id_idx
  on public.wrong_words (word_id);

drop trigger if exists wrong_words_set_updated_at on public.wrong_words;
create trigger wrong_words_set_updated_at
before update on public.wrong_words
for each row
execute function public.set_updated_at();

alter table public.wrong_words enable row level security;

drop policy if exists "wrong_words_select_own" on public.wrong_words;
create policy "wrong_words_select_own"
on public.wrong_words
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "wrong_words_insert_own" on public.wrong_words;
create policy "wrong_words_insert_own"
on public.wrong_words
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "wrong_words_update_own" on public.wrong_words;
create policy "wrong_words_update_own"
on public.wrong_words
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "wrong_words_delete_own" on public.wrong_words;
create policy "wrong_words_delete_own"
on public.wrong_words
for delete
to authenticated
using (auth.uid() = user_id);

comment on table public.wrong_words is
  'Per-user mistake ledger for Yanlışlarım; word_id matches client words.json ids.';
