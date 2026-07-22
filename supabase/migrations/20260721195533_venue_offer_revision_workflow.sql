-- Venue-owned offer revision lifecycle.
--
-- Founder feedback remains attached to the exact version that was reviewed.
-- A requested change therefore creates a new version, while an unsubmitted
-- draft can be edited in place. All mutations are service-role-only and bind
-- the authenticated Auth user to the venue account inside the transaction.

create table private.venue_offer_mutations (
  user_id uuid not null references auth.users (id) on delete cascade,
  idempotency_key uuid not null,
  operation text not null,
  offer_id uuid not null references public.offers (id) on delete cascade,
  request_payload jsonb not null,
  result_payload jsonb not null,
  created_at timestamptz not null default now(),

  primary key (user_id, idempotency_key),
  constraint venue_offer_mutations_operation_valid check (
    operation in ('revise', 'set_status')
  ),
  constraint venue_offer_mutations_payloads_are_objects check (
    jsonb_typeof(request_payload) = 'object'
    and jsonb_typeof(result_payload) = 'object'
  )
);

create index venue_offer_mutations_offer_id_idx
  on private.venue_offer_mutations (offer_id);

alter table private.venue_offer_mutations enable row level security;
revoke all on table private.venue_offer_mutations
from public, anon, authenticated, service_role;
grant select, insert, update, delete on table private.venue_offer_mutations
to service_role;

create function public.get_venue_offer_management(p_user_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_venue_id uuid;
  v_result jsonb;
begin
  select account_record.venue_id
  into v_venue_id
  from public.venue_accounts as account_record
  where account_record.auth_user_id = p_user_id
    and account_record.account_status = 'active';

  if v_venue_id is null then
    raise exception using errcode = 'P0001', message = 'venue_account_ineligible';
  end if;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'offer_id', offer_record.id,
      'offer_version_id', latest_version.id,
      'version_number', latest_version.version_number,
      'title', latest_version.public_title,
      'lifecycle_status', offer_record.lifecycle_status,
      'approval_state', latest_version.approval_state,
      'claim_duration_seconds', latest_version.claim_duration_seconds,
      'can_edit', offer_record.creator_type = 'venue'
        and offer_record.offer_kind = 'standard'
        and offer_record.lifecycle_status in ('draft', 'changes_requested')
        and latest_version.approval_state in ('draft', 'changes_requested'),
      'can_end', offer_record.creator_type = 'venue'
        and offer_record.offer_kind = 'standard'
        and offer_record.lifecycle_status not in ('ended', 'archived'),
      'can_archive', offer_record.creator_type = 'venue'
        and offer_record.offer_kind = 'standard'
        and offer_record.lifecycle_status in ('draft', 'changes_requested', 'rejected', 'ended'),
      'latest_feedback', case
        when latest_review.id is null then null
        else jsonb_build_object(
          'decision', latest_review.decision,
          'public_response', latest_review.public_response,
          'created_at', latest_review.created_at
        )
      end
    ) order by offer_record.created_at desc
  ), '[]'::jsonb)
  into v_result
  from public.offers as offer_record
  join lateral (
    select version_record.*
    from public.offer_versions as version_record
    where version_record.offer_id = offer_record.id
    order by version_record.version_number desc
    limit 1
  ) as latest_version on true
  left join lateral (
    select review_record.id, review_record.decision,
      review_record.public_response, review_record.created_at
    from private.offer_reviews as review_record
    join public.offer_versions as reviewed_version
      on reviewed_version.id = review_record.offer_version_id
    where reviewed_version.offer_id = offer_record.id
      and review_record.public_response is not null
    order by review_record.created_at desc, review_record.id desc
    limit 1
  ) as latest_review on true
  where offer_record.venue_id = v_venue_id;

  return v_result;
end;
$$;

revoke execute on function public.get_venue_offer_management(uuid)
from public, anon, authenticated, service_role;
grant execute on function public.get_venue_offer_management(uuid)
to service_role;

create function public.get_venue_offer_editor(
  p_user_id uuid,
  p_offer_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_offer public.offers%rowtype;
  v_version public.offer_versions%rowtype;
  v_schedule public.offer_schedules%rowtype;
  v_feedback jsonb;
begin
  select offer_record.*
  into v_offer
  from public.offers as offer_record
  join public.venue_accounts as account_record
    on account_record.venue_id = offer_record.venue_id
  where account_record.auth_user_id = p_user_id
    and account_record.account_status = 'active'
    and offer_record.id = p_offer_id
    and offer_record.creator_type = 'venue'
    and offer_record.offer_kind = 'standard';

  if v_offer.id is null then
    raise exception using errcode = 'P0001', message = 'venue_offer_not_found';
  end if;

  select version_record.*
  into v_version
  from public.offer_versions as version_record
  where version_record.offer_id = v_offer.id
  order by version_record.version_number desc
  limit 1;

  select schedule_record.*
  into v_schedule
  from public.offer_schedules as schedule_record
  where schedule_record.offer_version_id = v_version.id
  order by schedule_record.created_at desc
  limit 1;

  if v_version.id is null or v_schedule.id is null then
    raise exception using errcode = 'P0001', message = 'venue_offer_revision_unavailable';
  end if;

  select jsonb_build_object(
    'decision', review_record.decision,
    'public_response', review_record.public_response,
    'created_at', review_record.created_at
  )
  into v_feedback
  from private.offer_reviews as review_record
  join public.offer_versions as reviewed_version
    on reviewed_version.id = review_record.offer_version_id
  where reviewed_version.offer_id = v_offer.id
    and review_record.public_response is not null
  order by review_record.created_at desc, review_record.id desc
  limit 1;

  return jsonb_build_object(
    'offer_id', v_offer.id,
    'offer_version_id', v_version.id,
    'version_number', v_version.version_number,
    'lifecycle_status', v_offer.lifecycle_status,
    'approval_state', v_version.approval_state,
    'can_edit', v_offer.lifecycle_status in ('draft', 'changes_requested')
      and v_version.approval_state in ('draft', 'changes_requested'),
    'public_title', v_version.public_title,
    'short_explanation', v_version.short_explanation,
    'staff_display_title', v_version.staff_display_title,
    'staff_instruction', v_version.staff_instruction,
    'claim_duration_seconds', v_version.claim_duration_seconds,
    'schedule', jsonb_build_object(
      'nightlife_start_date', v_schedule.nightlife_start_date,
      'nightlife_end_date', v_schedule.nightlife_end_date,
      'eligible_weekdays', v_schedule.eligible_weekdays,
      'daily_starts_at', v_schedule.daily_starts_at,
      'daily_ends_at', v_schedule.daily_ends_at,
      'check_in_starts_at', v_schedule.check_in_starts_at,
      'check_in_cutoff_at', v_schedule.check_in_cutoff_at,
      'plan_cutoff_at', v_schedule.plan_cutoff_at,
      'occurrence_claim_limit', v_schedule.occurrence_claim_limit
    ),
    'latest_feedback', v_feedback
  );
end;
$$;

revoke execute on function public.get_venue_offer_editor(uuid, uuid)
from public, anon, authenticated, service_role;
grant execute on function public.get_venue_offer_editor(uuid, uuid)
to service_role;

create function public.revise_venue_offer(
  p_user_id uuid,
  p_offer_id uuid,
  p_offer_version_id uuid,
  p_idempotency_key uuid,
  p_public_title text,
  p_short_explanation text,
  p_staff_display_title text,
  p_staff_instruction text,
  p_claim_duration_seconds integer,
  p_nightlife_start_date date,
  p_nightlife_end_date date,
  p_eligible_weekdays smallint[],
  p_daily_starts_at time,
  p_daily_ends_at time,
  p_check_in_starts_at time,
  p_check_in_cutoff_at time,
  p_plan_cutoff_at time,
  p_occurrence_claim_limit integer,
  p_submit_for_review boolean default false
)
returns table (
  offer_id uuid,
  offer_version_id uuid,
  schedule_id uuid,
  version_number integer,
  lifecycle_status text,
  approval_state text
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_offer public.offers%rowtype;
  v_version public.offer_versions%rowtype;
  v_schedule public.offer_schedules%rowtype;
  v_existing private.venue_offer_mutations%rowtype;
  v_request jsonb;
  v_result jsonb;
  v_now timestamptz := clock_timestamp();
  v_lifecycle text := case when p_submit_for_review then 'pending_review' else 'draft' end;
  v_approval text := case when p_submit_for_review then 'pending_review' else 'draft' end;
begin
  if p_user_id is null
     or p_offer_id is null
     or p_offer_version_id is null
     or p_idempotency_key is null
     or p_public_title is null
     or p_staff_display_title is null
     or p_staff_instruction is null
     or p_nightlife_start_date is null
     or p_eligible_weekdays is null
     or cardinality(p_eligible_weekdays) = 0
     or exists (
       select 1 from unnest(p_eligible_weekdays) as weekday(value)
       where value is null or value not between 0 and 6
     )
     or (p_nightlife_end_date is not null and p_nightlife_end_date < p_nightlife_start_date)
     or ((p_daily_starts_at is null) <> (p_daily_ends_at is null))
     or (p_check_in_starts_at is not null and p_check_in_cutoff_at is null)
     or (p_claim_duration_seconds is not null and p_claim_duration_seconds not between 1 and 86400)
     or (p_occurrence_claim_limit is not null and p_occurrence_claim_limit < 1) then
    raise exception using errcode = '22023', message = 'invalid_offer_revision_parameter';
  end if;

  v_request := jsonb_build_object(
    'operation', 'revise',
    'offer_id', p_offer_id,
    'offer_version_id', p_offer_version_id,
    'public_title', btrim(p_public_title),
    'short_explanation', nullif(btrim(p_short_explanation), ''),
    'staff_display_title', btrim(p_staff_display_title),
    'staff_instruction', btrim(p_staff_instruction),
    'claim_duration_seconds', p_claim_duration_seconds,
    'nightlife_start_date', p_nightlife_start_date,
    'nightlife_end_date', p_nightlife_end_date,
    'eligible_weekdays', to_jsonb(p_eligible_weekdays),
    'daily_starts_at', p_daily_starts_at,
    'daily_ends_at', p_daily_ends_at,
    'check_in_starts_at', p_check_in_starts_at,
    'check_in_cutoff_at', p_check_in_cutoff_at,
    'plan_cutoff_at', p_plan_cutoff_at,
    'occurrence_claim_limit', p_occurrence_claim_limit,
    'submit_for_review', p_submit_for_review
  );

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'venue-offer-mutation:' || p_user_id::text || ':' || p_idempotency_key::text,
      0
    )
  );

  select mutation_record.*
  into v_existing
  from private.venue_offer_mutations as mutation_record
  where mutation_record.user_id = p_user_id
    and mutation_record.idempotency_key = p_idempotency_key;

  if v_existing.user_id is not null then
    if v_existing.operation <> 'revise'
       or v_existing.offer_id <> p_offer_id
       or v_existing.request_payload <> v_request then
      raise exception using errcode = 'P0001', message = 'idempotency_key_conflict';
    end if;

    return query select
      (v_existing.result_payload ->> 'offer_id')::uuid,
      (v_existing.result_payload ->> 'offer_version_id')::uuid,
      (v_existing.result_payload ->> 'schedule_id')::uuid,
      (v_existing.result_payload ->> 'version_number')::integer,
      v_existing.result_payload ->> 'lifecycle_status',
      v_existing.result_payload ->> 'approval_state';
    return;
  end if;

  select offer_record.*
  into v_offer
  from public.offers as offer_record
  join public.venue_accounts as account_record
    on account_record.venue_id = offer_record.venue_id
  join public.venues as venue_record on venue_record.id = offer_record.venue_id
  where account_record.auth_user_id = p_user_id
    and account_record.account_status = 'active'
    and venue_record.registration_status = 'approved'
    and venue_record.publication_status in ('published', 'paused')
    and offer_record.id = p_offer_id
    and offer_record.creator_type = 'venue'
    and offer_record.offer_kind = 'standard'
  for update of offer_record;

  if v_offer.id is null then
    raise exception using errcode = 'P0001', message = 'venue_offer_not_found';
  end if;

  select version_record.*
  into v_version
  from public.offer_versions as version_record
  where version_record.offer_id = v_offer.id
  order by version_record.version_number desc
  limit 1
  for update;

  if v_version.id <> p_offer_version_id then
    raise exception using errcode = 'P0001', message = 'offer_revision_conflict';
  end if;

  if not (
    (v_offer.lifecycle_status = 'draft' and v_version.approval_state = 'draft')
    or (
      v_offer.lifecycle_status = 'changes_requested'
      and v_version.approval_state = 'changes_requested'
    )
  ) then
    raise exception using errcode = 'P0001', message = 'venue_offer_not_editable';
  end if;

  if v_version.approval_state = 'changes_requested' then
    insert into public.offer_versions (
      offer_id, version_number, public_title, short_explanation,
      staff_display_title, staff_instruction, cta_label, redemption_mode,
      minimum_age, eligibility_mode, claim_duration_seconds,
      presentation_kind, discovery_treatment, approval_state,
      submitted_by, submitted_at
    ) values (
      v_offer.id,
      v_version.version_number + 1,
      btrim(p_public_title),
      nullif(btrim(p_short_explanation), ''),
      btrim(p_staff_display_title),
      btrim(p_staff_instruction),
      'View offer',
      'staff_display',
      19,
      case
        when p_plan_cutoff_at is not null then 'plan_before_and_check_in'
        when p_check_in_starts_at is null and p_check_in_cutoff_at is not null then 'check_in_before'
        when p_check_in_starts_at is not null then 'check_in_window'
        else 'verified_check_in'
      end,
      p_claim_duration_seconds,
      'standard',
      'none',
      v_approval,
      p_user_id,
      case when p_submit_for_review then v_now else null end
    )
    returning * into v_version;

    insert into public.offer_schedules (
      offer_version_id, nightlife_start_date, nightlife_end_date,
      eligible_weekdays, daily_starts_at, daily_ends_at,
      check_in_starts_at, check_in_cutoff_at, plan_cutoff_at,
      occurrence_claim_limit
    ) values (
      v_version.id, p_nightlife_start_date, p_nightlife_end_date,
      p_eligible_weekdays, p_daily_starts_at, p_daily_ends_at,
      p_check_in_starts_at, p_check_in_cutoff_at, p_plan_cutoff_at,
      p_occurrence_claim_limit
    )
    returning * into v_schedule;
  else
    update public.offer_versions
    set
      public_title = btrim(p_public_title),
      short_explanation = nullif(btrim(p_short_explanation), ''),
      staff_display_title = btrim(p_staff_display_title),
      staff_instruction = btrim(p_staff_instruction),
      eligibility_mode = case
        when p_plan_cutoff_at is not null then 'plan_before_and_check_in'
        when p_check_in_starts_at is null and p_check_in_cutoff_at is not null then 'check_in_before'
        when p_check_in_starts_at is not null then 'check_in_window'
        else 'verified_check_in'
      end,
      claim_duration_seconds = p_claim_duration_seconds,
      approval_state = v_approval,
      submitted_by = p_user_id,
      submitted_at = case when p_submit_for_review then v_now else null end,
      approved_by = null,
      approved_at = null
    where id = v_version.id
    returning * into v_version;

    select schedule_record.*
    into v_schedule
    from public.offer_schedules as schedule_record
    where schedule_record.offer_version_id = v_version.id
    order by schedule_record.created_at desc
    limit 1
    for update;

    if v_schedule.id is null then
      raise exception using errcode = 'P0001', message = 'venue_offer_revision_unavailable';
    end if;

    update public.offer_schedules
    set
      nightlife_start_date = p_nightlife_start_date,
      nightlife_end_date = p_nightlife_end_date,
      eligible_weekdays = p_eligible_weekdays,
      daily_starts_at = p_daily_starts_at,
      daily_ends_at = p_daily_ends_at,
      check_in_starts_at = p_check_in_starts_at,
      check_in_cutoff_at = p_check_in_cutoff_at,
      plan_cutoff_at = p_plan_cutoff_at,
      occurrence_claim_limit = p_occurrence_claim_limit,
      updated_at = v_now
    where id = v_schedule.id
    returning * into v_schedule;
  end if;

  update public.offers
  set lifecycle_status = v_lifecycle, paused_reason = null,
    archived_at = null, updated_at = v_now
  where id = v_offer.id;

  v_result := jsonb_build_object(
    'offer_id', v_offer.id,
    'offer_version_id', v_version.id,
    'schedule_id', v_schedule.id,
    'version_number', v_version.version_number,
    'lifecycle_status', v_lifecycle,
    'approval_state', v_approval
  );

  insert into private.venue_offer_mutations (
    user_id, idempotency_key, operation, offer_id,
    request_payload, result_payload
  ) values (
    p_user_id, p_idempotency_key, 'revise', v_offer.id,
    v_request, v_result
  );

  return query select
    v_offer.id, v_version.id, v_schedule.id, v_version.version_number,
    v_lifecycle, v_approval;
end;
$$;

revoke execute on function public.revise_venue_offer(
  uuid, uuid, uuid, uuid, text, text, text, text, integer, date, date,
  smallint[], time, time, time, time, time, integer, boolean
) from public, anon, authenticated, service_role;
grant execute on function public.revise_venue_offer(
  uuid, uuid, uuid, uuid, text, text, text, text, integer, date, date,
  smallint[], time, time, time, time, time, integer, boolean
) to service_role;

create function public.set_venue_offer_status(
  p_user_id uuid,
  p_offer_id uuid,
  p_idempotency_key uuid,
  p_target_status text
)
returns table (
  offer_id uuid,
  lifecycle_status text,
  archived_at timestamptz
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_offer public.offers%rowtype;
  v_existing private.venue_offer_mutations%rowtype;
  v_request jsonb;
  v_result jsonb;
  v_now timestamptz := clock_timestamp();
begin
  if p_user_id is null or p_offer_id is null or p_idempotency_key is null
     or p_target_status not in ('ended', 'archived') then
    raise exception using errcode = '22023', message = 'invalid_offer_status_parameter';
  end if;

  v_request := jsonb_build_object(
    'operation', 'set_status',
    'offer_id', p_offer_id,
    'target_status', p_target_status
  );

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'venue-offer-mutation:' || p_user_id::text || ':' || p_idempotency_key::text,
      0
    )
  );

  select mutation_record.*
  into v_existing
  from private.venue_offer_mutations as mutation_record
  where mutation_record.user_id = p_user_id
    and mutation_record.idempotency_key = p_idempotency_key;

  if v_existing.user_id is not null then
    if v_existing.operation <> 'set_status'
       or v_existing.offer_id <> p_offer_id
       or v_existing.request_payload <> v_request then
      raise exception using errcode = 'P0001', message = 'idempotency_key_conflict';
    end if;

    return query select
      (v_existing.result_payload ->> 'offer_id')::uuid,
      v_existing.result_payload ->> 'lifecycle_status',
      (v_existing.result_payload ->> 'archived_at')::timestamptz;
    return;
  end if;

  select offer_record.*
  into v_offer
  from public.offers as offer_record
  join public.venue_accounts as account_record
    on account_record.venue_id = offer_record.venue_id
  where account_record.auth_user_id = p_user_id
    and account_record.account_status = 'active'
    and offer_record.id = p_offer_id
    and offer_record.creator_type = 'venue'
    and offer_record.offer_kind = 'standard'
  for update of offer_record;

  if v_offer.id is null then
    raise exception using errcode = 'P0001', message = 'venue_offer_not_found';
  end if;

  if p_target_status = 'ended' then
    if v_offer.lifecycle_status = 'archived' then
      raise exception using errcode = 'P0001', message = 'venue_offer_already_archived';
    end if;

    if v_offer.lifecycle_status <> 'ended' then
      update public.offers
      set lifecycle_status = 'ended', paused_reason = null,
        archived_at = null, updated_at = v_now
      where id = v_offer.id
      returning * into v_offer;
    end if;
  else
    if v_offer.lifecycle_status <> 'archived'
       and v_offer.lifecycle_status not in ('draft', 'changes_requested', 'rejected', 'ended') then
      raise exception using errcode = 'P0001', message = 'venue_offer_must_be_ended_before_archive';
    end if;

    if v_offer.lifecycle_status <> 'archived' then
      update public.offers
      set lifecycle_status = 'archived', paused_reason = null,
        archived_at = v_now, updated_at = v_now
      where id = v_offer.id
      returning * into v_offer;
    end if;
  end if;

  v_result := jsonb_build_object(
    'offer_id', v_offer.id,
    'lifecycle_status', v_offer.lifecycle_status,
    'archived_at', v_offer.archived_at
  );

  insert into private.venue_offer_mutations (
    user_id, idempotency_key, operation, offer_id,
    request_payload, result_payload
  ) values (
    p_user_id, p_idempotency_key, 'set_status', v_offer.id,
    v_request, v_result
  );

  return query select v_offer.id, v_offer.lifecycle_status, v_offer.archived_at;
end;
$$;

revoke execute on function public.set_venue_offer_status(uuid, uuid, uuid, text)
from public, anon, authenticated, service_role;
grant execute on function public.set_venue_offer_status(uuid, uuid, uuid, text)
to service_role;

-- A founder may act only on the current submitted version. Once changes are
-- requested, the reviewed snapshot is kept for audit and cannot be approved
-- after the venue has submitted a replacement.
create or replace function public.review_offer_version(
  p_user_id uuid,
  p_offer_version_id uuid,
  p_decision text,
  p_public_response text default null,
  p_private_note text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := clock_timestamp();
  v_version public.offer_versions%rowtype;
  v_offer public.offers%rowtype;
begin
  perform private.require_founder_admin(p_user_id);

  if p_decision not in ('approved', 'changes_requested', 'rejected') then
    raise exception using errcode = '22023', message = 'invalid_offer_review_decision';
  end if;

  select version_record.*
  into v_version
  from public.offer_versions as version_record
  where version_record.id = p_offer_version_id
  for update;

  if v_version.id is null then
    raise exception using errcode = 'P0001', message = 'offer_version_not_found';
  end if;

  select offer_record.*
  into v_offer
  from public.offers as offer_record
  where offer_record.id = v_version.offer_id
  for update;

  if v_version.approval_state <> 'pending_review'
     or v_offer.lifecycle_status <> 'pending_review'
     or v_version.id <> (
       select candidate_version.id
       from public.offer_versions as candidate_version
       where candidate_version.offer_id = v_offer.id
       order by candidate_version.version_number desc
       limit 1
     ) then
    raise exception using errcode = 'P0001', message = 'offer_not_pending_review';
  end if;

  if not exists (
    select 1 from public.offer_schedules as schedule_record
    where schedule_record.offer_version_id = v_version.id
  ) or v_version.submitted_at is null then
    raise exception using errcode = 'P0001', message = 'offer_not_ready_for_approval';
  end if;

  if p_decision = 'approved' then
    update public.offer_versions
    set approval_state = 'approved', approved_by = p_user_id, approved_at = v_now
    where id = v_version.id
    returning * into v_version;

    update public.offers
    set current_approved_version_id = v_version.id,
      lifecycle_status = 'live', paused_reason = null,
      archived_at = null, updated_at = v_now
    where id = v_offer.id
    returning * into v_offer;
  else
    update public.offer_versions
    set approval_state = p_decision, approved_by = null, approved_at = null
    where id = v_version.id
    returning * into v_version;

    update public.offers
    set lifecycle_status = p_decision, paused_reason = null,
      archived_at = null, updated_at = v_now
    where id = v_offer.id
    returning * into v_offer;
  end if;

  insert into private.offer_reviews (
    offer_version_id, reviewer_id, decision, public_response, private_note
  ) values (
    v_version.id,
    p_user_id,
    p_decision,
    nullif(btrim(p_public_response), ''),
    nullif(btrim(p_private_note), '')
  );

  return jsonb_build_object(
    'offer_id', v_offer.id,
    'offer_version_id', v_version.id,
    'lifecycle_status', v_offer.lifecycle_status,
    'approval_state', v_version.approval_state
  );
end;
$$;

revoke execute on function public.review_offer_version(uuid, uuid, text, text, text)
from public, anon, authenticated, service_role;
grant execute on function public.review_offer_version(uuid, uuid, text, text, text)
to service_role;
