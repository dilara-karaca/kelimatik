-- Missed words / Yanlışlarım (SRS-ready).

create table if not exists public.wrong_words (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  word_id integer not null references public.words (id) on delete cascade,
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

create index if not exists wrong_words_user_next_review_idx
  on public.wrong_words (user_id, next_review_at)
  where next_review_at is not null;

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
  'Per-user mistake ledger for Yanlışlarım; includes SM-2 style fields for future SRS.';
