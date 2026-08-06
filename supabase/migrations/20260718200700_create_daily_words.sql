-- Word of the Day schedule (Günün kelimesi).

create table if not exists public.daily_words (
  id uuid primary key default gen_random_uuid(),
  word_date date not null,
  word_id integer not null references public.words (id) on delete restrict,
  created_at timestamptz not null default now(),
  constraint daily_words_word_date_unique unique (word_date)
);

create index if not exists daily_words_word_id_idx
  on public.daily_words (word_id);

create index if not exists daily_words_word_date_desc_idx
  on public.daily_words (word_date desc);

alter table public.daily_words enable row level security;

drop policy if exists "daily_words_select_authenticated" on public.daily_words;
create policy "daily_words_select_authenticated"
on public.daily_words
for select
to authenticated
using (true);

-- Writes via service role / SQL jobs only (no authenticated insert/update/delete).

comment on table public.daily_words is
  'Scheduled word-of-the-day. Populate via cron/admin; clients read by word_date.';
