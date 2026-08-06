-- Canonical word catalog (aligns with assets/data/words.json ids).
-- Seed later from the app/asset pipeline; FKs keep favorites/mistakes consistent at scale.

create table if not exists public.words (
  id integer primary key,
  correct text not null,
  wrong text not null,
  example text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint words_correct_not_blank check (length(trim(correct)) > 0),
  constraint words_wrong_not_blank check (length(trim(wrong)) > 0)
);

create index if not exists words_active_id_idx
  on public.words (id)
  where is_active;

create index if not exists words_correct_lower_idx
  on public.words (lower(correct));

drop trigger if exists words_set_updated_at on public.words;
create trigger words_set_updated_at
before update on public.words
for each row
execute function public.set_updated_at();

alter table public.words enable row level security;

-- Words are learning content: readable by signed-in users; writes via service role / admin only.
drop policy if exists "words_select_authenticated" on public.words;
create policy "words_select_authenticated"
on public.words
for select
to authenticated
using (is_active = true);

comment on table public.words is
  'Spelling pairs catalog. Primary key matches local JSON word ids for migration compatibility.';
