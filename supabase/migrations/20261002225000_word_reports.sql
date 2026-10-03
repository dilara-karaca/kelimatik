-- Learner reports about a spelling pair.
-- Clients cannot read or write this table. The report-word edge function
-- calls the functions below with the service role, then emails support.

create table if not exists public.word_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  word_id integer not null,
  correct text not null,
  wrong text not null,
  reason text not null,
  note text,
  delivered boolean not null default false,
  created_at timestamptz not null default now(),
  constraint word_reports_word_id_positive check (word_id > 0),
  constraint word_reports_reason_known check (
    reason in ('wrong_marked_is_correct', 'both_incorrect', 'other')
  ),
  constraint word_reports_spellings_bounded check (
    length(btrim(correct)) between 1 and 200
    and length(btrim(wrong)) between 1 and 200
  ),
  constraint word_reports_note_matches_reason check (
    (
      reason = 'other'
      and note is not null
      and length(btrim(note)) > 0
      and length(note) <= 280
    )
    or (
      reason <> 'other'
      and note is null
    )
  )
);

create index if not exists word_reports_user_created_idx
  on public.word_reports (user_id, created_at desc);

alter table public.word_reports enable row level security;

revoke all on table public.word_reports from anon, authenticated;

comment on table public.word_reports is
  'Spelling-issue reports. Written only by submit_word_report (service role).';

create or replace function public.submit_word_report(
  p_user_id uuid,
  p_word_id integer,
  p_correct text,
  p_wrong text,
  p_reason text,
  p_note text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  existing_id uuid;
  existing_delivered boolean;
  new_id uuid;
  recent_count integer;
  clean_correct text;
  clean_wrong text;
  clean_note text;
begin
  if p_user_id is null
     or p_word_id is null
     or p_word_id <= 0
     or p_reason not in (
       'wrong_marked_is_correct',
       'both_incorrect',
       'other'
     ) then
    raise exception 'word_report_invalid';
  end if;

  clean_correct := btrim(coalesce(p_correct, ''));
  clean_wrong := btrim(coalesce(p_wrong, ''));
  if length(clean_correct) = 0
     or length(clean_correct) > 200
     or length(clean_wrong) = 0
     or length(clean_wrong) > 200 then
    raise exception 'word_report_invalid';
  end if;

  if p_reason = 'other' then
    clean_note := btrim(coalesce(p_note, ''));
    if length(clean_note) = 0 or length(clean_note) > 280 then
      raise exception 'word_report_invalid';
    end if;
  else
    clean_note := null;
  end if;

  select id, delivered
    into existing_id, existing_delivered
  from public.word_reports
  where user_id = p_user_id
    and word_id = p_word_id
    and reason = p_reason
    and created_at > now() - interval '30 days'
    and (
      p_reason <> 'other'
      or note = clean_note
    )
  order by created_at desc
  limit 1;

  if existing_id is not null then
    return jsonb_build_object(
      'id', existing_id,
      'created', false,
      'delivered', existing_delivered
    );
  end if;

  select count(*)
    into recent_count
  from public.word_reports
  where user_id = p_user_id
    and created_at > now() - interval '1 day';

  if recent_count >= 10 then
    raise exception 'word_report_rate_limited';
  end if;

  insert into public.word_reports (
    user_id,
    word_id,
    correct,
    wrong,
    reason,
    note
  )
  values (
    p_user_id,
    p_word_id,
    clean_correct,
    clean_wrong,
    p_reason,
    clean_note
  )
  returning id into new_id;

  return jsonb_build_object(
    'id', new_id,
    'created', true,
    'delivered', false
  );
end;
$$;

revoke all on function public.submit_word_report(uuid, integer, text, text, text, text)
  from public, anon, authenticated;
grant execute on function public.submit_word_report(uuid, integer, text, text, text, text)
  to service_role;

comment on function public.submit_word_report(uuid, integer, text, text, text, text) is
  'Inserts a word report for the given auth user. Service role only.';

create or replace function public.mark_word_report_delivered(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_id is null then
    raise exception 'word_report_invalid';
  end if;

  update public.word_reports
  set delivered = true
  where id = p_id;
end;
$$;

revoke all on function public.mark_word_report_delivered(uuid)
  from public, anon, authenticated;
grant execute on function public.mark_word_report_delivered(uuid)
  to service_role;

comment on function public.mark_word_report_delivered(uuid) is
  'Marks a stored report as emailed. Service role only.';
