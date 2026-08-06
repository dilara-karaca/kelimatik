-- Shared helpers + enums used by gameplay tables.

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
begin
  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where t.typname = 'game_mode' and n.nspname = 'public'
  ) then
    create type public.game_mode as enum (
      'classic',
      'challenge',
      'mistakes',
      'streak',
      'infinite',
      'favorites'
    );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where t.typname = 'leaderboard_period' and n.nspname = 'public'
  ) then
    create type public.leaderboard_period as enum (
      'all_time',
      'weekly',
      'monthly',
      'daily'
    );
  end if;
end
$$;
