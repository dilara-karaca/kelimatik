-- Allow the signed-in user to permanently delete their auth account.
-- profiles (and favorites / wrong_words) cascade from auth.users / profiles.

create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  -- Explicit cleanup (also covered by FK cascades).
  delete from public.wrong_words where user_id = uid;
  delete from public.favorites where user_id = uid;
  delete from public.profiles where id = uid;

  -- Removes Auth user; any remaining FKs to auth.users cascade.
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_own_account() from public;
grant execute on function public.delete_own_account() to authenticated;

comment on function public.delete_own_account() is
  'Deletes the caller auth.users row and cascaded profile/progress data.';
