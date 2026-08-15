-- Allow ASCII punctuation in usernames while still rejecting A-Z, Turkish
-- letters, emoji, and other non-ASCII. UNIQUE(username) is unchanged.

alter table public.profiles
  drop constraint if exists profiles_username_charset;

alter table public.profiles
  add constraint profiles_username_charset
  check (
    username ~ '^[a-z0-9!"#$%&''()*+,\-./:;<=>?@\[\\\]^_`{|}~]+$'
  );

comment on constraint profiles_username_charset on public.profiles is
  'Lowercase a-z, digits, ASCII punctuation only. No A-Z, Turkish letters, or emoji.';
