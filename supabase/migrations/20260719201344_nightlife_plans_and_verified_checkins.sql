-- Outly nightlife plans and server-verified check-ins.
--
-- Direct client writes are intentionally disabled. Trusted server operations
-- serialize plan changes and check-in attempts, calculate the venue-local
-- nightlife date, and discard raw coordinates after deriving the decision.

create table public.night_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete set null,
  venue_id uuid not null references public.venues (id) on delete restrict,
  nightlife_date date not null,
  plan_status text not null default 'planned',
  request_idempotency_key uuid not null,
  replaces_plan_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  cancelled_at timestamptz,
  replaced_at timestamptz,
  checked_in_at timestamptz,
  expired_at timestamptz,

  constraint night_plans_status_valid check (
    plan_status in ('planned', 'cancelled', 'replaced', 'checked_in', 'expired')
  ),
  constraint night_plans_active_user_present check (
    user_id is not null or plan_status not in ('planned', 'checked_in')
  ),
  constraint night_plans_transition_timestamp_consistent check (
    (
      plan_status = 'planned'
      and cancelled_at is null
      and replaced_at is null
      and checked_in_at is null
      and expired_at is null
    )
    or (
      plan_status = 'cancelled'
      and cancelled_at is not null
      and replaced_at is null
      and checked_in_at is null
      and expired_at is null
    )
    or (
      plan_status = 'replaced'
      and cancelled_at is null
      and replaced_at is not null
      and checked_in_at is null
      and expired_at is null
    )
    or (
      plan_status = 'checked_in'
      and cancelled_at is null
      and replaced_at is null
      and checked_in_at is not null
      and expired_at is null
    )
    or (
      plan_status = 'expired'
      and cancelled_at is null
      and replaced_at is null
      and checked_in_at is null
      and expired_at is not null
    )
  ),
  constraint night_plans_not_self_replacing check (
    replaces_plan_id is null or replaces_plan_id <> id
  ),
  constraint night_plans_idempotency_unique unique (
    user_id,
    request_idempotency_key
  ),
  constraint night_plans_replacement_reference unique (
    id,
    user_id,
    nightlife_date
  ),
  constraint night_plans_check_in_reference unique (
    id,
    user_id,
    venue_id,
    nightlife_date
  ),
  constraint night_plans_replaces_same_user_night_fk
    foreign key (replaces_plan_id, user_id, nightlife_date)
    references public.night_plans (id, user_id, nightlife_date)
    on delete restrict
);

comment on table public.night_plans is
  'Versioned consumer venue plans. Only planned and checked-in rows count as active; cancelled and replaced history is retained.';
comment on column public.night_plans.nightlife_date is
  'Venue-local calendar date after subtracting the 4:00 AM nightlife boundary.';

create unique index night_plans_one_active_per_user_night_idx
  on public.night_plans (user_id, nightlife_date)
  where user_id is not null
    and plan_status in ('planned', 'checked_in');
create index night_plans_venue_night_status_idx
  on public.night_plans (venue_id, nightlife_date, plan_status);
create index night_plans_user_night_created_idx
  on public.night_plans (user_id, nightlife_date, created_at desc)
  where user_id is not null;
create index night_plans_replaces_plan_id_idx
  on public.night_plans (replaces_plan_id)
  where replaces_plan_id is not null;

create table private.check_in_verification_config (
  singleton boolean primary key default true,
  maximum_sample_age_seconds smallint not null default 30,
  maximum_horizontal_accuracy_metres numeric(6, 2) not null default 75,
  nearest_venue_tie_tolerance_metres numeric(5, 2) not null default 1,
  attempt_window_seconds smallint not null default 300,
  maximum_attempts_per_window smallint not null default 5,
  verifier_version text not null default 'mvp-2026-07-1',
  updated_at timestamptz not null default now(),

  constraint check_in_verification_config_singleton check (singleton),
  constraint check_in_verification_config_sample_age_safe check (
    maximum_sample_age_seconds between 5 and 300
  ),
  constraint check_in_verification_config_accuracy_safe check (
    maximum_horizontal_accuracy_metres between 5 and 200
  ),
  constraint check_in_verification_config_tie_tolerance_safe check (
    nearest_venue_tie_tolerance_metres between 0 and 25
  ),
  constraint check_in_verification_config_attempt_window_safe check (
    attempt_window_seconds between 60 and 3600
  ),
  constraint check_in_verification_config_attempt_limit_safe check (
    maximum_attempts_per_window between 1 and 20
  ),
  constraint check_in_verification_config_version_valid check (
    verifier_version = btrim(verifier_version)
    and char_length(verifier_version) between 1 and 80
  )
);

insert into private.check_in_verification_config (singleton) values (true);

comment on table private.check_in_verification_config is
  'Server-only, versioned verification thresholds. Changes affect new attempts only because every check-in snapshots the applied rules.';

create table public.check_ins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete set null,
  venue_id uuid not null references public.venues (id) on delete restrict,
  plan_id uuid,
  nightlife_date date not null,
  request_idempotency_key uuid not null,
  client_location_captured_at timestamptz,
  server_requested_at timestamptz not null,
  server_verified_at timestamptz not null,
  horizontal_accuracy_metres numeric(8, 3),
  location_age_seconds numeric(9, 3),
  accuracy_authorization text not null,
  location_authorization text not null,
  distance_from_venue_metres numeric(10, 3),
  configured_radius_metres smallint not null,
  maximum_sample_age_seconds smallint not null,
  maximum_horizontal_accuracy_metres numeric(6, 2) not null,
  nearest_venue_tie_tolerance_metres numeric(5, 2) not null,
  outcome text not null,
  rejection_reason text,
  verifier_version text not null,
  created_at timestamptz not null default now(),

  constraint check_ins_idempotency_unique unique (
    user_id,
    request_idempotency_key
  ),
  constraint check_ins_plan_same_user_venue_night_fk
    foreign key (plan_id, user_id, venue_id, nightlife_date)
    references public.night_plans (id, user_id, venue_id, nightlife_date)
    on delete restrict,
  constraint check_ins_accuracy_authorization_valid check (
    accuracy_authorization in ('full', 'reduced', 'unknown')
  ),
  constraint check_ins_location_authorization_valid check (
    location_authorization in (
      'when_in_use',
      'always',
      'denied',
      'restricted',
      'not_determined',
      'unknown'
    )
  ),
  constraint check_ins_horizontal_accuracy_valid check (
    horizontal_accuracy_metres is null
    or horizontal_accuracy_metres between -1 and 100000
  ),
  constraint check_ins_location_age_valid check (
    location_age_seconds is null
    or location_age_seconds between -86400 and 86400
  ),
  constraint check_ins_distance_valid check (
    distance_from_venue_metres is null or distance_from_venue_metres >= 0
  ),
  constraint check_ins_radius_snapshot_safe check (
    configured_radius_metres between 25 and 200
  ),
  constraint check_ins_sample_age_snapshot_safe check (
    maximum_sample_age_seconds between 5 and 300
  ),
  constraint check_ins_accuracy_snapshot_safe check (
    maximum_horizontal_accuracy_metres between 5 and 200
  ),
  constraint check_ins_tie_snapshot_safe check (
    nearest_venue_tie_tolerance_metres between 0 and 25
  ),
  constraint check_ins_outcome_valid check (
    outcome in ('verified', 'rejected')
  ),
  constraint check_ins_rejection_reason_valid check (
    rejection_reason is null
    or rejection_reason in (
      'permission_denied',
      'reduced_accuracy',
      'insufficient_accuracy',
      'stale_sample',
      'future_sample',
      'outside_geofence',
      'ambiguous_nearest_venue',
      'venue_unavailable',
      'account_ineligible',
      'rate_limited',
      'already_checked_in',
      'invalid_request'
    )
  ),
  constraint check_ins_decision_consistent check (
    (
      outcome = 'verified'
      and rejection_reason is null
      and user_id is not null
      and client_location_captured_at is not null
      and horizontal_accuracy_metres is not null
      and horizontal_accuracy_metres >= 0
      and horizontal_accuracy_metres <= maximum_horizontal_accuracy_metres
      and location_age_seconds is not null
      and location_age_seconds >= 0
      and location_age_seconds <= maximum_sample_age_seconds
      and accuracy_authorization = 'full'
      and location_authorization in ('when_in_use', 'always')
      and distance_from_venue_metres is not null
      and distance_from_venue_metres <= configured_radius_metres
    )
    or (
      outcome = 'rejected'
      and rejection_reason is not null
    )
  ),
  constraint check_ins_server_timing_consistent check (
    server_verified_at >= server_requested_at
  ),
  constraint check_ins_verifier_version_valid check (
    verifier_version = btrim(verifier_version)
    and char_length(verifier_version) between 1 and 80
  )
);

comment on table public.check_ins is
  'Authoritative check-in decisions and durable derived evidence. Raw latitude and longitude are intentionally not stored.';
comment on column public.check_ins.distance_from_venue_metres is
  'PostGIS distance derived inside the verification transaction, in metres.';

create unique index check_ins_one_verified_per_user_night_idx
  on public.check_ins (user_id, nightlife_date)
  where user_id is not null and outcome = 'verified';
create index check_ins_user_requested_at_idx
  on public.check_ins (user_id, server_requested_at desc)
  where user_id is not null;
create index check_ins_venue_night_outcome_idx
  on public.check_ins (venue_id, nightlife_date, outcome);
create index check_ins_plan_id_idx
  on public.check_ins (plan_id)
  where plan_id is not null;

create function private.nightlife_date_for(
  p_instant timestamptz,
  p_timezone text
)
returns date
language sql
stable
security invoker
set search_path = ''
as $$
  select ((p_instant at time zone p_timezone) - interval '4 hours')::date;
$$;

revoke execute on function private.nightlife_date_for(timestamptz, text)
from public, anon, authenticated, service_role;

create function public.set_night_plan(
  p_user_id uuid,
  p_venue_id uuid,
  p_idempotency_key uuid
)
returns public.night_plans
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := clock_timestamp();
  v_venue public.venues%rowtype;
  v_nightlife_date date;
  v_existing public.night_plans%rowtype;
  v_active public.night_plans%rowtype;
  v_result public.night_plans%rowtype;
begin
  if p_user_id is null or p_venue_id is null or p_idempotency_key is null then
    raise exception using errcode = '22023', message = 'missing_plan_parameter';
  end if;

  select * into v_venue
  from public.venues
  where id = p_venue_id;

  if not found then
    raise exception using errcode = 'P0001', message = 'venue_not_found';
  end if;

  v_nightlife_date := private.nightlife_date_for(v_now, v_venue.timezone);

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      p_user_id::text || ':' || v_nightlife_date::text,
      0
    )
  );

  select * into v_existing
  from public.night_plans
  where user_id = p_user_id
    and request_idempotency_key = p_idempotency_key;

  if found then
    return v_existing;
  end if;

  if not exists (
    select 1
    from public.consumer_profiles as profile
    join private.consumer_eligibility as eligibility
      on eligibility.user_id = profile.user_id
    where profile.user_id = p_user_id
      and profile.onboarding_status = 'complete'
      and profile.account_status = 'active'
      and eligibility.is_19_plus
  ) then
    raise exception using errcode = 'P0001', message = 'account_ineligible';
  end if;

  if v_venue.registration_status <> 'approved'
     or v_venue.publication_status <> 'published' then
    raise exception using errcode = 'P0001', message = 'venue_unavailable';
  end if;

  if exists (
    select 1
    from public.check_ins
    where user_id = p_user_id
      and nightlife_date = v_nightlife_date
      and outcome = 'verified'
  ) then
    raise exception using errcode = 'P0001', message = 'check_in_already_verified';
  end if;

  select * into v_active
  from public.night_plans
  where user_id = p_user_id
    and nightlife_date = v_nightlife_date
    and plan_status in ('planned', 'checked_in')
  order by created_at desc
  limit 1
  for update;

  if found and v_active.venue_id = p_venue_id then
    return v_active;
  end if;

  if found then
    update public.night_plans
    set
      plan_status = 'replaced',
      replaced_at = v_now
    where id = v_active.id;
  end if;

  insert into public.night_plans (
    user_id,
    venue_id,
    nightlife_date,
    plan_status,
    request_idempotency_key,
    replaces_plan_id,
    created_at,
    updated_at
  )
  values (
    p_user_id,
    p_venue_id,
    v_nightlife_date,
    'planned',
    p_idempotency_key,
    case when v_active.id is null then null else v_active.id end,
    v_now,
    v_now
  )
  returning * into v_result;

  return v_result;
end;
$$;

create function public.cancel_night_plan(
  p_user_id uuid,
  p_plan_id uuid
)
returns public.night_plans
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := clock_timestamp();
  v_plan public.night_plans%rowtype;
begin
  select * into v_plan
  from public.night_plans
  where id = p_plan_id
    and user_id = p_user_id;

  if not found then
    raise exception using errcode = 'P0001', message = 'plan_not_found';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      p_user_id::text || ':' || v_plan.nightlife_date::text,
      0
    )
  );

  select * into v_plan
  from public.night_plans
  where id = p_plan_id
    and user_id = p_user_id
  for update;

  if v_plan.plan_status = 'cancelled' then
    return v_plan;
  end if;

  if v_plan.plan_status <> 'planned' then
    raise exception using errcode = 'P0001', message = 'plan_not_cancellable';
  end if;

  update public.night_plans
  set
    plan_status = 'cancelled',
    cancelled_at = v_now
  where id = v_plan.id
  returning * into v_plan;

  return v_plan;
end;
$$;

create function public.verify_venue_check_in(
  p_user_id uuid,
  p_venue_id uuid,
  p_idempotency_key uuid,
  p_latitude double precision,
  p_longitude double precision,
  p_horizontal_accuracy_metres double precision,
  p_location_captured_at timestamptz,
  p_accuracy_authorization text,
  p_location_authorization text,
  p_plan_id uuid default null
)
returns public.check_ins
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := clock_timestamp();
  v_venue public.venues%rowtype;
  v_config private.check_in_verification_config%rowtype;
  v_nightlife_date date;
  v_existing public.check_ins%rowtype;
  v_active_plan public.night_plans%rowtype;
  v_result public.check_ins%rowtype;
  v_sample extensions.geography(Point, 4326);
  v_location_age_seconds double precision;
  v_distance_metres double precision;
  v_rejection_reason text;
  v_linked_plan_id uuid;
  v_attempt_count integer;
begin
  if p_user_id is null or p_venue_id is null or p_idempotency_key is null then
    raise exception using errcode = '22023', message = 'missing_check_in_parameter';
  end if;

  select * into v_existing
  from public.check_ins
  where user_id = p_user_id
    and request_idempotency_key = p_idempotency_key;

  if found then
    return v_existing;
  end if;

  select * into v_venue
  from public.venues
  where id = p_venue_id;

  if not found then
    raise exception using errcode = 'P0001', message = 'venue_not_found';
  end if;

  select * into strict v_config
  from private.check_in_verification_config
  where singleton;

  v_nightlife_date := private.nightlife_date_for(v_now, v_venue.timezone);

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      p_user_id::text || ':' || v_nightlife_date::text,
      0
    )
  );

  select * into v_existing
  from public.check_ins
  where user_id = p_user_id
    and request_idempotency_key = p_idempotency_key;

  if found then
    return v_existing;
  end if;

  if p_latitude is not null
     and p_longitude is not null
     and p_latitude between -90 and 90
     and p_longitude between -180 and 180 then
    v_sample := extensions.st_setsrid(
      extensions.st_makepoint(p_longitude, p_latitude),
      4326
    )::extensions.geography;
  end if;

  if p_location_captured_at is not null then
    v_location_age_seconds := extract(epoch from (v_now - p_location_captured_at));
  end if;

  if v_sample is not null and v_venue.location is not null then
    v_distance_metres := extensions.st_distance(v_venue.location, v_sample);
  end if;

  select count(*)::integer into v_attempt_count
  from public.check_ins
  where user_id = p_user_id
    and server_requested_at >= (
      v_now - pg_catalog.make_interval(secs => v_config.attempt_window_seconds)
    );

  if not exists (
    select 1
    from public.consumer_profiles as profile
    join private.consumer_eligibility as eligibility
      on eligibility.user_id = profile.user_id
    where profile.user_id = p_user_id
      and profile.onboarding_status = 'complete'
      and profile.account_status = 'active'
      and eligibility.is_19_plus
  ) then
    v_rejection_reason := 'account_ineligible';
  elsif v_venue.registration_status <> 'approved'
        or v_venue.publication_status <> 'published'
        or v_venue.location is null then
    v_rejection_reason := 'venue_unavailable';
  elsif exists (
    select 1
    from public.check_ins
    where user_id = p_user_id
      and nightlife_date = v_nightlife_date
      and outcome = 'verified'
  ) then
    v_rejection_reason := 'already_checked_in';
  elsif v_attempt_count >= v_config.maximum_attempts_per_window then
    v_rejection_reason := 'rate_limited';
  elsif p_location_authorization not in ('when_in_use', 'always') then
    v_rejection_reason := 'permission_denied';
  elsif p_accuracy_authorization <> 'full' then
    v_rejection_reason := 'reduced_accuracy';
  elsif v_sample is null
        or p_location_captured_at is null
        or p_horizontal_accuracy_metres is null then
    v_rejection_reason := 'invalid_request';
  elsif v_location_age_seconds < 0 then
    v_rejection_reason := 'future_sample';
  elsif v_location_age_seconds > v_config.maximum_sample_age_seconds then
    v_rejection_reason := 'stale_sample';
  elsif p_horizontal_accuracy_metres < 0
        or p_horizontal_accuracy_metres > v_config.maximum_horizontal_accuracy_metres then
    v_rejection_reason := 'insufficient_accuracy';
  elsif not extensions.st_dwithin(
    v_venue.location,
    v_sample,
    v_venue.geofence_radius_metres
  ) then
    v_rejection_reason := 'outside_geofence';
  elsif exists (
    select 1
    from public.venues as competitor
    where competitor.id <> v_venue.id
      and competitor.registration_status = 'approved'
      and competitor.publication_status = 'published'
      and competitor.location is not null
      and extensions.st_dwithin(
        competitor.location,
        v_sample,
        v_distance_metres + v_config.nearest_venue_tie_tolerance_metres
      )
      and extensions.st_distance(competitor.location, v_sample)
        <= v_distance_metres + v_config.nearest_venue_tie_tolerance_metres
  ) then
    v_rejection_reason := 'ambiguous_nearest_venue';
  end if;

  select * into v_active_plan
  from public.night_plans
  where user_id = p_user_id
    and nightlife_date = v_nightlife_date
    and plan_status in ('planned', 'checked_in')
  order by created_at desc
  limit 1
  for update;

  if p_plan_id is not null then
    if v_active_plan.id is null
       or v_active_plan.id <> p_plan_id
       or v_active_plan.venue_id <> p_venue_id then
      v_rejection_reason := coalesce(v_rejection_reason, 'invalid_request');
    else
      v_linked_plan_id := v_active_plan.id;
    end if;
  elsif v_active_plan.id is not null and v_active_plan.venue_id = p_venue_id then
    v_linked_plan_id := v_active_plan.id;
  end if;

  insert into public.check_ins (
    user_id,
    venue_id,
    plan_id,
    nightlife_date,
    request_idempotency_key,
    client_location_captured_at,
    server_requested_at,
    server_verified_at,
    horizontal_accuracy_metres,
    location_age_seconds,
    accuracy_authorization,
    location_authorization,
    distance_from_venue_metres,
    configured_radius_metres,
    maximum_sample_age_seconds,
    maximum_horizontal_accuracy_metres,
    nearest_venue_tie_tolerance_metres,
    outcome,
    rejection_reason,
    verifier_version,
    created_at
  )
  values (
    p_user_id,
    p_venue_id,
    v_linked_plan_id,
    v_nightlife_date,
    p_idempotency_key,
    p_location_captured_at,
    v_now,
    clock_timestamp(),
    p_horizontal_accuracy_metres,
    v_location_age_seconds,
    coalesce(p_accuracy_authorization, 'unknown'),
    coalesce(p_location_authorization, 'unknown'),
    v_distance_metres,
    v_venue.geofence_radius_metres,
    v_config.maximum_sample_age_seconds,
    v_config.maximum_horizontal_accuracy_metres,
    v_config.nearest_venue_tie_tolerance_metres,
    case when v_rejection_reason is null then 'verified' else 'rejected' end,
    v_rejection_reason,
    v_config.verifier_version,
    v_now
  )
  returning * into v_result;

  if v_result.outcome = 'verified' and v_active_plan.id is not null then
    if v_active_plan.venue_id = p_venue_id then
      update public.night_plans
      set
        plan_status = 'checked_in',
        checked_in_at = v_result.server_verified_at
      where id = v_active_plan.id;
    elsif p_plan_id is null and v_active_plan.plan_status = 'planned' then
      update public.night_plans
      set
        plan_status = 'replaced',
        replaced_at = v_result.server_verified_at
      where id = v_active_plan.id;
    end if;
  end if;

  return v_result;
end;
$$;

-- Function execution is opt-in. These RPCs are for trusted server code using
-- the service role; publishable clients cannot call them directly.
revoke execute on function public.set_night_plan(uuid, uuid, uuid)
from public, anon, authenticated, service_role;
revoke execute on function public.cancel_night_plan(uuid, uuid)
from public, anon, authenticated, service_role;
revoke execute on function public.verify_venue_check_in(
  uuid,
  uuid,
  uuid,
  double precision,
  double precision,
  double precision,
  timestamptz,
  text,
  text,
  uuid
)
from public, anon, authenticated, service_role;

grant execute on function public.set_night_plan(uuid, uuid, uuid)
to service_role;
grant execute on function public.cancel_night_plan(uuid, uuid)
to service_role;
grant execute on function public.verify_venue_check_in(
  uuid,
  uuid,
  uuid,
  double precision,
  double precision,
  double precision,
  timestamptz,
  text,
  text,
  uuid
)
to service_role;

create trigger night_plans_set_updated_at
before update on public.night_plans
for each row execute function private.set_updated_at();

create trigger check_in_verification_config_set_updated_at
before update on private.check_in_verification_config
for each row execute function private.set_updated_at();

alter table public.night_plans enable row level security;
alter table private.check_in_verification_config enable row level security;
alter table public.check_ins enable row level security;

create policy night_plans_select_own
on public.night_plans
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy check_ins_select_own
on public.check_ins
for select
to authenticated
using ((select auth.uid()) = user_id);

revoke all on table public.night_plans, public.check_ins
from public, anon, authenticated, service_role;

grant select on table public.night_plans, public.check_ins
to authenticated;

grant select, insert, update, delete on table public.night_plans, public.check_ins
to service_role;

revoke all on table private.check_in_verification_config
from public, anon, authenticated, service_role;

grant select, insert, update, delete on table private.check_in_verification_config
to service_role;

-- Raw coordinates are deliberately absent. A short-lived location-evidence
-- table will not be added unless its retention period receives explicit legal
-- and product approval.
