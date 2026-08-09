-- Character onboarding fields for first-time Google users.
alter table public.profiles
  add column if not exists selected_character text,
  add column if not exists onboarding_completed boolean not null default false;

comment on column public.profiles.selected_character is
  'Character asset id (e.g. erkek1, kadin3). Null until onboarding.';

comment on column public.profiles.onboarding_completed is
  'True after character + username onboarding is finished.';

-- Only profiles that already picked a character are treated as done.
-- Everyone else (including existing accounts without a character) must onboard.
update public.profiles
set onboarding_completed = true
where selected_character is not null
  and length(trim(selected_character)) > 0;

update public.profiles
set onboarding_completed = false
where selected_character is null
   or length(trim(selected_character)) = 0;
