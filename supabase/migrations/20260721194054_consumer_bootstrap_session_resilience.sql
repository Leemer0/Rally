-- Preserve a durable check-in session independently from an offer claim so a
-- client can recover after location verification succeeds but claiming fails.
-- Also separate a normal first-run onboarding state from an ineligible account.

create index check_ins_user_night_session_idx
  on public.check_ins (
    user_id,
    nightlife_date,
    outcome,
    server_verified_at desc,
    id desc
  )
  where user_id is not null;

alter function public.get_consumer_bootstrap(uuid, timestamptz)
  rename to get_consumer_bootstrap_without_session;

alter function public.get_consumer_bootstrap_without_session(uuid, timestamptz)
  set schema private;

revoke execute on function private.get_consumer_bootstrap_without_session(uuid, timestamptz)
from public, anon, authenticated, service_role;

create function public.get_consumer_bootstrap(
  p_user_id uuid,
  p_at timestamptz default now()
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_profile public.consumer_profiles%rowtype;
  v_result jsonb;
  v_current_check_in jsonb;
begin
  if p_user_id is null then
    raise exception using errcode = '22023', message = 'missing_user_id';
  end if;

  select * into v_profile
  from public.consumer_profiles as profile_record
  where profile_record.user_id = p_user_id;

  if v_profile.user_id is null then
    raise exception using errcode = 'P0001', message = 'onboarding_required';
  end if;
  if v_profile.account_status <> 'active'
     or v_profile.onboarding_status = 'blocked' then
    raise exception using errcode = 'P0001', message = 'account_ineligible';
  end if;
  if v_profile.onboarding_status = 'incomplete' then
    raise exception using errcode = 'P0001', message = 'onboarding_required';
  end if;
  if not exists (
    select 1
    from private.consumer_eligibility as eligibility_record
    where eligibility_record.user_id = p_user_id
      and eligibility_record.is_19_plus
  ) then
    raise exception using errcode = 'P0001', message = 'account_ineligible';
  end if;

  v_result := private.get_consumer_bootstrap_without_session(p_user_id, p_at);

  select jsonb_build_object(
    'id', check_in_record.id,
    'venue_id', check_in_record.venue_id,
    'server_verified_at', check_in_record.server_verified_at,
    'outcome', check_in_record.outcome
  ) into v_current_check_in
  from public.check_ins as check_in_record
  join public.venues as venue_record on venue_record.id = check_in_record.venue_id
  where check_in_record.user_id = p_user_id
    and check_in_record.nightlife_date = private.nightlife_date_for(
      p_at,
      venue_record.timezone
    )
  order by
    (check_in_record.outcome = 'verified') desc,
    check_in_record.server_verified_at desc,
    check_in_record.id desc
  limit 1;

  return v_result || jsonb_build_object(
    'current_check_in', v_current_check_in
  );
end;
$$;

revoke execute on function public.get_consumer_bootstrap(uuid, timestamptz)
from public, anon, authenticated, service_role;
grant execute on function public.get_consumer_bootstrap(uuid, timestamptz)
to service_role;
