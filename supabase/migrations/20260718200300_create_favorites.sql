-- User favorites (Favoriler feature).

create table if not exists public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  word_id integer not null references public.words (id) on delete cascade,
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

-- No update policy: toggle is delete + insert (immutable row).

comment on table public.favorites is
  'Per-user bookmarked words for Favoriler study mode.';
