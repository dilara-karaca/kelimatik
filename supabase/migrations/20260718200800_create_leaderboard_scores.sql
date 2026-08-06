-- Denormalized leaderboard scores for fast global ranking without full table scans.

create table if not exists public.leaderboard_scores (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  period public.leaderboard_period not null default 'all_time',
  score integer not null default 0,
  rank integer,
  correct_count integer not null default 0,
  sessions_count integer not null default 0,
  updated_at timestamptz not null default now(),
  constraint leaderboard_scores_user_period_unique unique (user_id, period),
  constraint leaderboard_scores_score_nonnegative check (score >= 0),
  constraint leaderboard_scores_correct_nonnegative check (correct_count >= 0),
  constraint leaderboard_scores_sessions_nonnegative check (sessions_count >= 0),
  constraint leaderboard_scores_rank_positive check (rank is null or rank >= 1)
);

create index if not exists leaderboard_scores_period_score_idx
  on public.leaderboard_scores (period, score desc, correct_count desc);

create index if not exists leaderboard_scores_period_rank_idx
  on public.leaderboard_scores (period, rank)
  where rank is not null;

drop trigger if exists leaderboard_scores_set_updated_at on public.leaderboard_scores;
create trigger leaderboard_scores_set_updated_at
before update on public.leaderboard_scores
for each row
execute function public.set_updated_at();

alter table public.leaderboard_scores enable row level security;

-- Everyone signed-in can read rankings; users upsert only their own row.
drop policy if exists "leaderboard_scores_select_authenticated" on public.leaderboard_scores;
create policy "leaderboard_scores_select_authenticated"
on public.leaderboard_scores
for select
to authenticated
using (true);

drop policy if exists "leaderboard_scores_insert_own" on public.leaderboard_scores;
create policy "leaderboard_scores_insert_own"
on public.leaderboard_scores
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "leaderboard_scores_update_own" on public.leaderboard_scores;
create policy "leaderboard_scores_update_own"
on public.leaderboard_scores
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

comment on table public.leaderboard_scores is
  'Cached ranking rows. Prefer updating from session completion jobs for scale.';

-- Convenient join view for UI (security_invoker respects underlying RLS).
create or replace view public.leaderboard_public
with (security_invoker = true)
as
select
  ls.period,
  ls.rank,
  ls.score,
  ls.correct_count,
  ls.sessions_count,
  ls.updated_at,
  p.id as user_id,
  p.username,
  p.display_name,
  p.avatar_url,
  p.level,
  p.xp
from public.leaderboard_scores ls
join public.profiles p on p.id = ls.user_id;

grant select on public.leaderboard_public to authenticated;
