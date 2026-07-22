-- Outly MVP server contracts, privacy-safe analytics, and configurable venue
-- entitlements. Browser and iOS clients continue to receive only publishable
-- keys; every privileged operation in this migration is service-role only and
-- is intended to be called by the authenticated Outly Edge Function adapter.

-- Compare every time inside the 4:00 AM nightlife day instead of the calendar
-- day. Without normalization, 1:00 AM incorrectly satisfies a "before 10 PM"
-- cutoff simply because 01:00 is less than 22:00.
create or replace function private.time_is_in_window(
  p_value time,
  p_starts_at time,
  p_ends_at time
)
returns boolean
language sql
immutable
security invoker
set search_path = ''
as $$
  with normalized as (
    select
      extract(epoch from p_value)
        + case when p_value < time '04:00' then 86400 else 0 end as value_seconds,
      extract(epoch from p_starts_at)
        + case when p_starts_at < time '04:00' then 86400 else 0 end as start_seconds,
      extract(epoch from p_ends_at)
        + case when p_ends_at < time '04:00' then 86400 else 0 end as end_seconds
  )
  select case
    when p_value is null then false
    when p_starts_at is null and p_ends_at is null then true
    when p_starts_at is null then value_seconds <= end_seconds
    when p_ends_at is null then value_seconds >= start_seconds
    when start_seconds <= end_seconds then value_seconds between start_seconds and end_seconds
    else false
  end
  from normalized;
$$;

revoke execute on function private.time_is_in_window(time, time, time)
from public, anon, authenticated, service_role;
grant execute on function private.time_is_in_window(time, time, time)
to service_role;

-- Approved offer copy is an immutable claim snapshot. Material changes create
-- a new version and schedule instead of mutating proof that may already have
-- been shown to a guest or staff member.
alter table public.offer_versions
  drop constraint offer_versions_duration_valid,
  add constraint offer_versions_duration_valid check (
    claim_duration_seconds is null
    or claim_duration_seconds between 1 and 86400
  );

create function private.prevent_approved_offer_version_mutation()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if old.approval_state = 'approved' then
    raise exception using errcode = 'P0001', message = 'approved_offer_version_is_immutable';
  end if;
  return case when tg_op = 'DELETE' then old else new end;
end;
$$;

revoke execute on function private.prevent_approved_offer_version_mutation()
from public, anon, authenticated, service_role;

create trigger offer_versions_prevent_approved_mutation
before update or delete on public.offer_versions
for each row execute function private.prevent_approved_offer_version_mutation();

create function private.prevent_approved_offer_schedule_mutation()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if tg_op in ('UPDATE', 'DELETE') and exists (
    select 1 from public.offer_versions as version_record
    where version_record.id = old.offer_version_id
      and version_record.approval_state = 'approved'
  ) then
    raise exception using errcode = 'P0001', message = 'approved_offer_schedule_is_immutable';
  end if;

  if tg_op in ('INSERT', 'UPDATE') and exists (
    select 1 from public.offer_versions as version_record
    where version_record.id = new.offer_version_id
      and version_record.approval_state = 'approved'
  ) then
    raise exception using errcode = 'P0001', message = 'approved_offer_schedule_is_immutable';
  end if;

  return case when tg_op = 'DELETE' then old else new end;
end;
$$;

revoke execute on function private.prevent_approved_offer_schedule_mutation()
from public, anon, authenticated, service_role;

create trigger offer_schedules_prevent_approved_mutation
before insert or update or delete on public.offer_schedules
for each row execute function private.prevent_approved_offer_schedule_mutation();

-- Serialize every claim attempt for a check-in before running the existing
-- eligibility/capacity transaction. This turns concurrent retries into the
-- same idempotent claim rather than a unique-constraint race.
alter function public.unlock_offer_for_check_in(uuid, uuid, uuid, uuid)
rename to unlock_offer_for_check_in_unserialized;

revoke execute on function public.unlock_offer_for_check_in_unserialized(uuid, uuid, uuid, uuid)
from public, anon, authenticated, service_role;

create function public.unlock_offer_for_check_in(
  p_user_id uuid,
  p_check_in_id uuid,
  p_offer_id uuid,
  p_idempotency_key uuid
)
returns table (
  claim_id uuid,
  offer_id uuid,
  offer_version_id uuid,
  venue_id uuid,
  kind text,
  title text,
  explanation text,
  cta_label text,
  redemption_mode text,
  destination_url text,
  staff_display_title text,
  staff_instruction text,
  fine_print text,
  claim_duration_seconds integer,
  presentation_kind text,
  sponsor_display_name text,
  sponsor_logo_storage_path text,
  sponsor_logo_alt_text text,
  sponsor_disclosure text,
  discovery_treatment text,
  discovery_badge_label text,
  discovery_icon_key text,
  unlocked_at timestamptz,
  expires_at timestamptz,
  effective_status text,
  staff_reference text
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_offer_kind text;
  v_offer_venue_id uuid;
begin
  if p_check_in_id is null then
    raise exception using errcode = '22023', message = 'missing_offer_claim_parameter';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('offer-claim:' || p_check_in_id::text, 0)
  );

  select offer_record.offer_kind, offer_record.venue_id
  into v_offer_kind, v_offer_venue_id
  from public.offers as offer_record
  where offer_record.id = p_offer_id;

  if v_offer_kind = 'partner' and not exists (
    select 1
    from private.venue_subscriptions as subscription_record
    join private.plan_entitlements as entitlement_record
      on entitlement_record.plan_code = subscription_record.plan_code
     and entitlement_record.entitlement_key = 'partner_campaign_access'
     and entitlement_record.entitlement_value = 'true'::jsonb
    where subscription_record.venue_id = v_offer_venue_id
      and (
        subscription_record.stripe_status = 'active'
        or (
          subscription_record.stripe_status = 'trialing'
          and subscription_record.trial_ends_at > current_timestamp
        )
      )
  ) then
    raise exception using errcode = 'P0001', message = 'partner_offer_requires_pro_venue';
  end if;

  return query
  select *
  from public.unlock_offer_for_check_in_unserialized(
    p_user_id,
    p_check_in_id,
    p_offer_id,
    p_idempotency_key
  );
end;
$$;

revoke execute on function public.unlock_offer_for_check_in(uuid, uuid, uuid, uuid)
from public, anon, authenticated, service_role;
grant execute on function public.unlock_offer_for_check_in(uuid, uuid, uuid, uuid)
to service_role;

alter table public.offers
  add column submission_idempotency_key uuid;

create unique index offers_submission_idempotency_idx
  on public.offers (created_by, submission_idempotency_key)
  where created_by is not null and submission_idempotency_key is not null;

create table private.billing_plans (
  plan_code text primary key,
  display_name text not null,
  active boolean not null default true,
  stripe_price_id text unique,
  billing_interval text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint billing_plans_code_valid check (
    plan_code = lower(btrim(plan_code))
    and plan_code ~ '^[a-z0-9_]+$'
    and char_length(plan_code) between 2 and 40
  ),
  constraint billing_plans_name_valid check (
    display_name = btrim(display_name)
    and char_length(display_name) between 1 and 80
  ),
  constraint billing_plans_interval_valid check (
    billing_interval in ('none', 'month', 'year')
  )
);

create table private.plan_entitlements (
  plan_code text not null references private.billing_plans (plan_code) on delete restrict,
  entitlement_key text not null,
  entitlement_value jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  primary key (plan_code, entitlement_key),
  constraint plan_entitlements_key_valid check (
    entitlement_key in (
      'active_offer_limit',
      'analytics_history_days',
      'advanced_demographics',
      'custom_map_marker',
      'featured_placement',
      'campaign_customization',
      'neighbourhood_benchmarks',
      'repeat_visitor_insights',
      'detailed_attribution',
      'partner_campaign_access'
    )
  )
);

create table private.venue_subscriptions (
  venue_id uuid primary key references public.venues (id) on delete cascade,
  plan_code text not null default 'free' references private.billing_plans (plan_code) on delete restrict,
  stripe_customer_id text unique,
  stripe_subscription_id text unique,
  stripe_price_id text,
  stripe_status text not null default 'free',
  trial_ends_at timestamptz,
  current_period_ends_at timestamptz,
  cancel_at_period_end boolean not null default false,
  cancelled_at timestamptz,
  last_webhook_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint venue_subscriptions_status_valid check (
    stripe_status in (
      'free', 'trialing', 'active', 'past_due', 'unpaid',
      'paused', 'cancelled', 'incomplete', 'incomplete_expired'
    )
  ),
  constraint venue_subscriptions_trial_metadata_consistent check (
    stripe_status <> 'trialing' or trial_ends_at is not null
  ),
  constraint venue_subscriptions_free_consistent check (
    plan_code <> 'free'
    or (
      stripe_status = 'free'
      and stripe_subscription_id is null
      and stripe_price_id is null
    )
  )
);

create table private.stripe_webhook_events (
  stripe_event_id text primary key,
  event_type text not null,
  processing_status text not null default 'received',
  failure_code text,
  received_at timestamptz not null default now(),
  processed_at timestamptz,

  constraint stripe_webhook_events_id_valid check (
    stripe_event_id = btrim(stripe_event_id)
    and char_length(stripe_event_id) between 4 and 255
  ),
  constraint stripe_webhook_events_status_valid check (
    processing_status in ('received', 'processing', 'processed', 'failed', 'ignored')
  ),
  constraint stripe_webhook_events_processed_consistent check (
    (processing_status in ('processed', 'ignored') and processed_at is not null)
    or (processing_status not in ('processed', 'ignored') and processed_at is null)
  )
);

create table private.analytics_config (
  singleton boolean primary key default true,
  minimum_demographic_cohort smallint not null default 20,
  repeat_visitor_window_days smallint not null default 90,
  maximum_client_event_age_seconds integer not null default 86400,
  updated_at timestamptz not null default now(),

  constraint analytics_config_singleton check (singleton),
  constraint analytics_config_cohort_safe check (minimum_demographic_cohort between 20 and 100),
  constraint analytics_config_repeat_window_safe check (repeat_visitor_window_days between 7 and 365),
  constraint analytics_config_event_age_safe check (maximum_client_event_age_seconds between 300 and 604800)
);

create table private.analytics_events (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users (id) on delete cascade,
  anonymous_session_id uuid,
  event_name text not null,
  venue_id uuid not null references public.venues (id) on delete restrict,
  offer_id uuid references public.offers (id) on delete set null,
  nightlife_date date not null,
  request_idempotency_key uuid not null unique,
  source text not null,
  app_version text,
  client_occurred_at timestamptz not null,
  server_received_at timestamptz not null default now(),

  constraint analytics_events_actor_present check (
    user_id is not null or anonymous_session_id is not null
  ),
  constraint analytics_events_name_valid check (
    event_name in ('venue_impression', 'venue_detail_view', 'offer_cta_opened')
  ),
  constraint analytics_events_source_valid check (source in ('ios', 'web')),
  constraint analytics_events_version_valid check (
    app_version is null
    or (
      app_version = btrim(app_version)
      and char_length(app_version) between 1 and 80
    )
  )
);

create index analytics_events_venue_night_name_idx
  on private.analytics_events (venue_id, nightlife_date, event_name, server_received_at);
create index analytics_events_user_venue_idx
  on private.analytics_events (user_id, venue_id, server_received_at desc)
  where user_id is not null;
create index analytics_events_offer_id_idx
  on private.analytics_events (offer_id)
  where offer_id is not null;
create index venue_subscriptions_plan_status_idx
  on private.venue_subscriptions (plan_code, stripe_status);

insert into private.billing_plans (plan_code, display_name, billing_interval)
values
  ('free', 'Free', 'none'),
  ('pro', 'Pro', 'month');

insert into private.plan_entitlements (plan_code, entitlement_key, entitlement_value)
values
  ('free', 'active_offer_limit', '1'::jsonb),
  ('free', 'analytics_history_days', '30'::jsonb),
  ('free', 'advanced_demographics', 'false'::jsonb),
  ('free', 'custom_map_marker', 'false'::jsonb),
  ('free', 'featured_placement', 'false'::jsonb),
  ('free', 'campaign_customization', 'false'::jsonb),
  ('free', 'neighbourhood_benchmarks', 'false'::jsonb),
  ('free', 'repeat_visitor_insights', 'false'::jsonb),
  ('free', 'detailed_attribution', 'false'::jsonb),
  ('free', 'partner_campaign_access', 'false'::jsonb),
  ('pro', 'active_offer_limit', '10'::jsonb),
  ('pro', 'analytics_history_days', '365'::jsonb),
  ('pro', 'advanced_demographics', 'true'::jsonb),
  ('pro', 'custom_map_marker', 'true'::jsonb),
  ('pro', 'featured_placement', 'true'::jsonb),
  ('pro', 'campaign_customization', 'true'::jsonb),
  ('pro', 'neighbourhood_benchmarks', 'true'::jsonb),
  ('pro', 'repeat_visitor_insights', 'true'::jsonb),
  ('pro', 'detailed_attribution', 'true'::jsonb),
  ('pro', 'partner_campaign_access', 'true'::jsonb);

insert into private.analytics_config (singleton) values (true);

insert into private.venue_subscriptions (venue_id, plan_code, stripe_status)
select venue_record.id, 'free', 'free'
from public.venues as venue_record
on conflict (venue_id) do nothing;

create function private.ensure_free_venue_subscription()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into private.venue_subscriptions (venue_id, plan_code, stripe_status)
  values (new.id, 'free', 'free')
  on conflict (venue_id) do nothing;
  return new;
end;
$$;

revoke execute on function private.ensure_free_venue_subscription()
from public, anon, authenticated, service_role;

create trigger venues_ensure_free_subscription
after insert on public.venues
for each row execute function private.ensure_free_venue_subscription();

create trigger billing_plans_set_updated_at
before update on private.billing_plans
for each row execute function private.set_updated_at();

create trigger plan_entitlements_set_updated_at
before update on private.plan_entitlements
for each row execute function private.set_updated_at();

create trigger venue_subscriptions_set_updated_at
before update on private.venue_subscriptions
for each row execute function private.set_updated_at();

create trigger analytics_config_set_updated_at
before update on private.analytics_config
for each row execute function private.set_updated_at();

alter table private.billing_plans enable row level security;
alter table private.plan_entitlements enable row level security;
alter table private.venue_subscriptions enable row level security;
alter table private.stripe_webhook_events enable row level security;
alter table private.analytics_config enable row level security;
alter table private.analytics_events enable row level security;

revoke all on table
  private.billing_plans,
  private.plan_entitlements,
  private.venue_subscriptions,
  private.stripe_webhook_events,
  private.analytics_config,
  private.analytics_events
from public, anon, authenticated, service_role;

grant select, insert, update, delete on table
  private.billing_plans,
  private.plan_entitlements,
  private.venue_subscriptions,
  private.stripe_webhook_events,
  private.analytics_config,
  private.analytics_events
to service_role;

grant usage, select on sequence private.analytics_events_id_seq to service_role;

-- Historical attendance remains useful after a consumer deletes their Auth
-- identity, but it must no longer identify that person. Snapshot an explicit
-- anonymization time before ON DELETE SET NULL runs so existing integrity
-- constraints do not prevent permanent Auth deletion.
alter table public.night_plans add column anonymized_at timestamptz;
alter table public.check_ins add column anonymized_at timestamptz;
alter table public.offer_claims add column anonymized_at timestamptz;

alter table public.night_plans
  drop constraint night_plans_active_user_present,
  add constraint night_plans_actor_state_consistent check (
    user_id is not null or anonymized_at is not null
  );

alter table public.check_ins
  drop constraint check_ins_decision_consistent,
  add constraint check_ins_actor_state_consistent check (
    user_id is not null or anonymized_at is not null
  ),
  add constraint check_ins_decision_consistent check (
    (
      outcome = 'verified'
      and rejection_reason is null
      and (user_id is not null or anonymized_at is not null)
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
  );

alter table public.offer_claims
  add constraint offer_claims_actor_state_consistent check (
    user_id is not null or anonymized_at is not null
  );

alter table public.venues
  drop constraint venues_approval_timestamp_consistent,
  add constraint venues_approval_timestamp_consistent check (
    registration_status not in ('approved', 'suspended')
    or approved_at is not null
  );

alter table private.account_deletion_requests
  add column request_idempotency_key uuid,
  add column requester_user_id uuid;

create unique index account_deletion_requests_idempotency_idx
  on private.account_deletion_requests (requester_user_id, request_idempotency_key)
  where requester_user_id is not null and request_idempotency_key is not null;

-- Auth deletion and application-data deletion cannot be one cross-service
-- transaction. Completing the prepared audit from an Auth delete trigger
-- makes the operation durable even if the Edge response is interrupted after
-- the identity has already been removed.
create function private.complete_prepared_account_deletion_on_auth_delete()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update private.account_deletion_requests as request_record
  set
    state = 'completed',
    completed_at = clock_timestamp(),
    subject_reference = case
      when request_record.subject_type = 'consumer' then null
      else request_record.subject_reference
    end,
    requester_user_id = null
  where request_record.requester_user_id = old.id
    and request_record.state = 'processing';

  return old;
end;
$$;

revoke execute on function private.complete_prepared_account_deletion_on_auth_delete()
from public, anon, authenticated, service_role;

create trigger complete_prepared_account_deletion_after_auth_delete
after delete on auth.users
for each row execute function private.complete_prepared_account_deletion_on_auth_delete();

-- Keep partner inventory on the same offer/claim path, but expose it only at
-- venues whose current plan grants partner campaign access.
alter function public.list_eligible_offers(uuid, uuid[], timestamptz)
rename to list_eligible_offers_without_entitlement;

revoke execute on function public.list_eligible_offers_without_entitlement(uuid, uuid[], timestamptz)
from public, anon, authenticated, service_role;

create function public.list_eligible_offers(
  p_user_id uuid,
  p_venue_ids uuid[],
  p_at timestamptz default now()
)
returns table (
  offer_id uuid,
  offer_version_id uuid,
  schedule_id uuid,
  venue_id uuid,
  kind text,
  title text,
  explanation text,
  cta_label text,
  redemption_mode text,
  destination_url text,
  staff_display_title text,
  staff_instruction text,
  fine_print text,
  claim_duration_seconds integer,
  presentation_kind text,
  sponsor_display_name text,
  sponsor_logo_storage_path text,
  sponsor_logo_alt_text text,
  sponsor_disclosure text,
  discovery_treatment text,
  discovery_badge_label text,
  discovery_icon_key text
)
language sql
stable
security definer
set search_path = ''
as $$
  select distinct on (candidate.venue_id) candidate.*
  from public.list_eligible_offers_without_entitlement(
    p_user_id,
    p_venue_ids,
    p_at
  ) as candidate
  join public.offers as offer_record on offer_record.id = candidate.offer_id
  join public.offer_versions as version_record
    on version_record.id = candidate.offer_version_id
  where candidate.kind = 'standard'
    or exists (
      select 1
      from private.venue_subscriptions as subscription_record
      join private.plan_entitlements as entitlement_record
        on entitlement_record.plan_code = subscription_record.plan_code
       and entitlement_record.entitlement_key = 'partner_campaign_access'
       and entitlement_record.entitlement_value = 'true'::jsonb
      where subscription_record.venue_id = candidate.venue_id
        and (
          subscription_record.stripe_status = 'active'
          or (
            subscription_record.stripe_status = 'trialing'
            and subscription_record.trial_ends_at > p_at
          )
        )
    )
  order by
    candidate.venue_id,
    offer_record.display_priority desc,
    (candidate.kind = 'partner') desc,
    version_record.approved_at desc;
$$;

revoke execute on function public.list_eligible_offers(uuid, uuid[], timestamptz)
from public, anon, authenticated, service_role;
grant execute on function public.list_eligible_offers(uuid, uuid[], timestamptz)
to service_role;

create function public.complete_consumer_onboarding(
  p_user_id uuid,
  p_first_name text,
  p_date_of_birth date,
  p_gender text,
  p_terms_version text,
  p_privacy_version text
)
returns table (
  user_id uuid,
  first_name text,
  onboarding_status text,
  account_status text,
  onboarding_completed_at timestamptz,
  is_19_plus boolean
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := clock_timestamp();
  v_today date := (v_now at time zone 'America/Toronto')::date;
  v_first_name text := btrim(p_first_name);
  v_existing_profile public.consumer_profiles%rowtype;
  v_existing_eligibility private.consumer_eligibility%rowtype;
begin
  if p_user_id is null
     or p_date_of_birth is null
     or p_gender is null
     or p_terms_version is null
     or p_privacy_version is null then
    raise exception using errcode = '22023', message = 'missing_onboarding_parameter';
  end if;

  if v_first_name is null or char_length(v_first_name) not between 1 and 50 then
    raise exception using errcode = '22023', message = 'invalid_first_name';
  end if;
  if p_gender not in ('man', 'woman', 'other') then
    raise exception using errcode = '22023', message = 'invalid_gender';
  end if;
  if p_date_of_birth > (v_today - interval '19 years')::date then
    raise exception using errcode = 'P0001', message = 'age_requirement_not_met';
  end if;
  if p_date_of_birth < (v_today - interval '120 years')::date then
    raise exception using errcode = '22023', message = 'invalid_date_of_birth';
  end if;
  if not exists (select 1 from auth.users as auth_user where auth_user.id = p_user_id) then
    raise exception using errcode = 'P0001', message = 'auth_user_not_found';
  end if;
  if exists (
    select 1
    from public.venue_accounts as venue_account
    where venue_account.auth_user_id = p_user_id
      and venue_account.account_status <> 'deleted'
  ) then
    raise exception using errcode = 'P0001', message = 'account_type_conflict';
  end if;

  select * into v_existing_profile
  from public.consumer_profiles as profile_record
  where profile_record.user_id = p_user_id
  for update;

  if v_existing_profile.user_id is not null
     and v_existing_profile.account_status <> 'active' then
    raise exception using errcode = 'P0001', message = 'account_inactive';
  end if;
  if v_existing_profile.onboarding_status = 'complete'
     and v_existing_profile.first_name is distinct from v_first_name then
    raise exception using errcode = 'P0001', message = 'onboarding_already_complete';
  end if;

  select * into v_existing_eligibility
  from private.consumer_eligibility as eligibility_record
  where eligibility_record.user_id = p_user_id
  for update;

  if v_existing_eligibility.user_id is not null
     and (
       v_existing_eligibility.date_of_birth is distinct from p_date_of_birth
       or v_existing_eligibility.gender is distinct from p_gender
     ) then
    raise exception using errcode = 'P0001', message = 'protected_profile_is_immutable';
  end if;

  insert into private.consumer_eligibility (
    user_id,
    date_of_birth,
    gender,
    is_19_plus,
    age_eligibility_checked_at
  )
  values (
    p_user_id,
    p_date_of_birth,
    p_gender,
    true,
    v_now
  )
  on conflict on constraint consumer_eligibility_pkey do nothing;

  insert into public.consumer_profiles (
    user_id,
    first_name,
    onboarding_status,
    account_status,
    onboarding_completed_at
  )
  values (
    p_user_id,
    v_first_name,
    'complete',
    'active',
    v_now
  )
  on conflict on constraint consumer_profiles_pkey do update
  set
    first_name = excluded.first_name,
    onboarding_status = 'complete',
    onboarding_completed_at = coalesce(
      public.consumer_profiles.onboarding_completed_at,
      excluded.onboarding_completed_at
    );

  insert into private.legal_acceptances (
    subject_user_id,
    subject_type,
    document_type,
    document_version,
    source
  )
  values
    (p_user_id, 'consumer', 'terms_of_service', btrim(p_terms_version), 'ios'),
    (p_user_id, 'consumer', 'privacy_policy', btrim(p_privacy_version), 'ios')
  on conflict on constraint legal_acceptances_once_per_version do nothing;

  return query
  select
    profile_record.user_id,
    profile_record.first_name,
    profile_record.onboarding_status,
    profile_record.account_status,
    profile_record.onboarding_completed_at,
    eligibility_record.is_19_plus
  from public.consumer_profiles as profile_record
  join private.consumer_eligibility as eligibility_record
    on eligibility_record.user_id = profile_record.user_id
  where profile_record.user_id = p_user_id;
end;
$$;

revoke execute on function public.complete_consumer_onboarding(
  uuid, text, date, text, text, text
) from public, anon, authenticated, service_role;
grant execute on function public.complete_consumer_onboarding(
  uuid, text, date, text, text, text
) to service_role;

create function public.register_venue_account(
  p_auth_user_id uuid,
  p_display_name text,
  p_venue_address text,
  p_legal_business_name text,
  p_legal_address text,
  p_primary_contact_name text,
  p_primary_contact_title text,
  p_business_email text,
  p_business_phone text,
  p_venue_agreement_version text
)
returns table (
  venue_id uuid,
  venue_slug text,
  registration_status text,
  account_status text
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := clock_timestamp();
  v_auth_email text;
  v_display_name text := btrim(p_display_name);
  v_slug_base text;
  v_slug text;
  v_venue_id uuid := gen_random_uuid();
begin
  if p_auth_user_id is null
     or v_display_name is null
     or p_venue_address is null
     or p_legal_business_name is null
     or p_legal_address is null
     or p_primary_contact_name is null
     or p_business_email is null
     or p_business_phone is null
     or p_venue_agreement_version is null then
    raise exception using errcode = '22023', message = 'missing_venue_registration_parameter';
  end if;

  select lower(auth_user.email) into v_auth_email
  from auth.users as auth_user
  where auth_user.id = p_auth_user_id;

  if v_auth_email is null then
    raise exception using errcode = 'P0001', message = 'auth_user_not_found';
  end if;
  if v_auth_email <> lower(btrim(p_business_email)) then
    raise exception using errcode = 'P0001', message = 'business_email_mismatch';
  end if;
  if exists (
    select 1
    from public.consumer_profiles as consumer_profile
    where consumer_profile.user_id = p_auth_user_id
      and consumer_profile.account_status <> 'deleted'
  ) then
    raise exception using errcode = 'P0001', message = 'account_type_conflict';
  end if;

  if exists (
    select 1
    from public.venue_accounts as existing_account
    where existing_account.auth_user_id = p_auth_user_id
  ) then
    return query
    select
      existing_venue.id,
      existing_venue.slug,
      existing_venue.registration_status,
      existing_account.account_status
    from public.venue_accounts as existing_account
    join public.venues as existing_venue on existing_venue.id = existing_account.venue_id
    where existing_account.auth_user_id = p_auth_user_id;
    return;
  end if;

  if char_length(v_display_name) not between 1 and 100 then
    raise exception using errcode = '22023', message = 'invalid_venue_name';
  end if;

  v_slug_base := trim(both '-' from lower(
    regexp_replace(v_display_name, '[^A-Za-z0-9]+', '-', 'g')
  ));
  if char_length(v_slug_base) < 2 then
    v_slug_base := 'venue';
  end if;
  v_slug := left(v_slug_base, 67) || '-' || substr(replace(v_venue_id::text, '-', ''), 1, 8);

  insert into public.venues (
    id,
    slug,
    display_name,
    registration_status,
    publication_status,
    address_line_1,
    market_code,
    city,
    province_code,
    country_code
  )
  values (
    v_venue_id,
    v_slug,
    v_display_name,
    'pending_review',
    'unpublished',
    btrim(p_venue_address),
    'toronto',
    'Toronto',
    'ON',
    'CA'
  );

  insert into public.venue_accounts (
    auth_user_id,
    venue_id,
    account_status
  )
  values (p_auth_user_id, v_venue_id, 'draft');

  insert into private.venue_business_details (
    venue_id,
    legal_business_name,
    legal_address,
    primary_contact_name,
    primary_contact_title,
    business_email,
    business_phone,
    authority_to_represent_affirmed,
    venue_agreement_version,
    registration_submitted_at
  )
  values (
    v_venue_id,
    btrim(p_legal_business_name),
    btrim(p_legal_address),
    btrim(p_primary_contact_name),
    nullif(btrim(p_primary_contact_title), ''),
    btrim(p_business_email),
    btrim(p_business_phone),
    true,
    btrim(p_venue_agreement_version),
    v_now
  );

  insert into private.venue_subscriptions (venue_id, plan_code, stripe_status)
  values (v_venue_id, 'free', 'free')
  on conflict on constraint venue_subscriptions_pkey do nothing;

  insert into private.legal_acceptances (
    subject_user_id,
    subject_type,
    document_type,
    document_version,
    source
  )
  values (
    p_auth_user_id,
    'venue',
    'venue_agreement',
    btrim(p_venue_agreement_version),
    'web'
  )
  on conflict on constraint legal_acceptances_once_per_version do nothing;

  return query
  select v_venue_id, v_slug, 'pending_review'::text, 'draft'::text;
end;
$$;

revoke execute on function public.register_venue_account(
  uuid, text, text, text, text, text, text, text, text, text
) from public, anon, authenticated, service_role;
grant execute on function public.register_venue_account(
  uuid, text, text, text, text, text, text, text, text, text
) to service_role;

create function public.submit_venue_offer(
  p_user_id uuid,
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
  lifecycle_status text,
  approval_state text
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_venue_id uuid;
  v_offer_id uuid;
  v_version_id uuid;
  v_schedule_id uuid;
  v_active_offer_limit integer;
  v_lifecycle text := case when p_submit_for_review then 'pending_review' else 'draft' end;
  v_approval text := case when p_submit_for_review then 'pending_review' else 'draft' end;
begin
  if p_user_id is null
     or p_idempotency_key is null
     or p_public_title is null
     or p_staff_display_title is null
     or p_staff_instruction is null
     or p_nightlife_start_date is null
     or p_eligible_weekdays is null then
    raise exception using errcode = '22023', message = 'missing_offer_parameter';
  end if;

  select venue_account.venue_id into v_venue_id
  from public.venue_accounts as venue_account
  join public.venues as venue_record on venue_record.id = venue_account.venue_id
  where venue_account.auth_user_id = p_user_id
    and venue_account.account_status = 'active'
    and venue_record.registration_status = 'approved'
    and venue_record.publication_status in ('published', 'paused')
  for update of venue_account;

  if v_venue_id is null then
    raise exception using errcode = 'P0001', message = 'venue_account_ineligible';
  end if;

  select existing_offer.id into v_offer_id
  from public.offers as existing_offer
  where existing_offer.created_by = p_user_id
    and existing_offer.submission_idempotency_key = p_idempotency_key;

  if v_offer_id is not null then
    return query
    select
      existing_offer.id,
      existing_version.id,
      existing_schedule.id,
      existing_offer.lifecycle_status,
      existing_version.approval_state
    from public.offers as existing_offer
    join public.offer_versions as existing_version on existing_version.offer_id = existing_offer.id
    join public.offer_schedules as existing_schedule on existing_schedule.offer_version_id = existing_version.id
    where existing_offer.id = v_offer_id
    order by existing_version.version_number desc, existing_schedule.created_at desc
    limit 1;
    return;
  end if;

  select (entitlement_record.entitlement_value #>> '{}')::integer
  into v_active_offer_limit
  from private.venue_subscriptions as subscription_record
  join private.plan_entitlements as entitlement_record
    on entitlement_record.plan_code = subscription_record.plan_code
   and entitlement_record.entitlement_key = 'active_offer_limit'
  where subscription_record.venue_id = v_venue_id
    and (
      subscription_record.stripe_status = 'free'
      or subscription_record.stripe_status = 'active'
      or (
        subscription_record.stripe_status = 'trialing'
        and subscription_record.trial_ends_at > current_timestamp
      )
    );

  if v_active_offer_limit is null then
    raise exception using errcode = 'P0001', message = 'venue_entitlement_missing';
  end if;

  if (
    select count(*)
    from public.offers as active_offer
    where active_offer.venue_id = v_venue_id
      and active_offer.lifecycle_status in (
        'draft', 'pending_review', 'changes_requested', 'approved', 'scheduled', 'live', 'paused'
      )
  ) >= v_active_offer_limit then
    raise exception using errcode = 'P0001', message = 'active_offer_limit_reached';
  end if;

  insert into public.offers (
    venue_id,
    creator_type,
    offer_kind,
    lifecycle_status,
    display_priority,
    created_by,
    submission_idempotency_key
  )
  values (
    v_venue_id,
    'venue',
    'standard',
    v_lifecycle,
    0,
    p_user_id,
    p_idempotency_key
  )
  returning id into v_offer_id;

  insert into public.offer_versions (
    offer_id,
    version_number,
    public_title,
    short_explanation,
    staff_display_title,
    staff_instruction,
    cta_label,
    redemption_mode,
    minimum_age,
    eligibility_mode,
    claim_duration_seconds,
    presentation_kind,
    discovery_treatment,
    approval_state,
    submitted_by,
    submitted_at
  )
  values (
    v_offer_id,
    1,
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
    case when p_submit_for_review then clock_timestamp() else null end
  )
  returning id into v_version_id;

  insert into public.offer_schedules (
    offer_version_id,
    nightlife_start_date,
    nightlife_end_date,
    eligible_weekdays,
    daily_starts_at,
    daily_ends_at,
    check_in_starts_at,
    check_in_cutoff_at,
    plan_cutoff_at,
    occurrence_claim_limit
  )
  values (
    v_version_id,
    p_nightlife_start_date,
    p_nightlife_end_date,
    p_eligible_weekdays,
    p_daily_starts_at,
    p_daily_ends_at,
    p_check_in_starts_at,
    p_check_in_cutoff_at,
    p_plan_cutoff_at,
    p_occurrence_claim_limit
  )
  returning id into v_schedule_id;

  return query
  select v_offer_id, v_version_id, v_schedule_id, v_lifecycle, v_approval;
end;
$$;

revoke execute on function public.submit_venue_offer(
  uuid, uuid, text, text, text, text, integer, date, date, smallint[],
  time, time, time, time, time, integer, boolean
) from public, anon, authenticated, service_role;
grant execute on function public.submit_venue_offer(
  uuid, uuid, text, text, text, text, integer, date, date, smallint[],
  time, time, time, time, time, integer, boolean
) to service_role;

create function public.ingest_analytics_event(
  p_user_id uuid,
  p_event_name text,
  p_venue_id uuid,
  p_offer_id uuid,
  p_client_occurred_at timestamptz,
  p_source text,
  p_app_version text,
  p_idempotency_key uuid
)
returns bigint
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := clock_timestamp();
  v_config private.analytics_config%rowtype;
  v_venue public.venues%rowtype;
  v_existing private.analytics_events%rowtype;
  v_event_id bigint;
begin
  if p_user_id is null
     or p_event_name is null
     or p_venue_id is null
     or p_client_occurred_at is null
     or p_source is null
     or p_idempotency_key is null then
    raise exception using errcode = '22023', message = 'missing_analytics_parameter';
  end if;

  if p_event_name not in ('venue_impression', 'venue_detail_view', 'offer_cta_opened') then
    raise exception using errcode = '22023', message = 'analytics_event_not_allowed';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('analytics-event:' || p_idempotency_key::text, 0)
  );

  select * into v_existing
  from private.analytics_events as existing_event
  where existing_event.request_idempotency_key = p_idempotency_key;

  if v_existing.id is not null then
    if v_existing.user_id is distinct from p_user_id
       or v_existing.event_name is distinct from p_event_name
       or v_existing.venue_id is distinct from p_venue_id
       or v_existing.offer_id is distinct from p_offer_id
       or v_existing.source is distinct from p_source then
      raise exception using errcode = 'P0001', message = 'idempotency_key_conflict';
    end if;
    return v_existing.id;
  end if;

  select * into strict v_config
  from private.analytics_config
  where singleton;

  select * into v_venue
  from public.venues as venue_record
  where venue_record.id = p_venue_id
    and venue_record.registration_status = 'approved'
    and venue_record.publication_status = 'published';

  if v_venue.id is null then
    raise exception using errcode = 'P0001', message = 'venue_unavailable';
  end if;
  if not exists (
    select 1
    from public.consumer_profiles as profile_record
    join private.consumer_eligibility as eligibility_record
      on eligibility_record.user_id = profile_record.user_id
    where profile_record.user_id = p_user_id
      and profile_record.onboarding_status = 'complete'
      and profile_record.account_status = 'active'
      and eligibility_record.is_19_plus
  ) then
    raise exception using errcode = 'P0001', message = 'account_ineligible';
  end if;
  if p_client_occurred_at > v_now + interval '5 minutes'
     or p_client_occurred_at < v_now - make_interval(secs => v_config.maximum_client_event_age_seconds) then
    raise exception using errcode = '22023', message = 'analytics_event_time_invalid';
  end if;
  if p_offer_id is not null and not exists (
    select 1
    from public.offers as offer_record
    where offer_record.id = p_offer_id
      and offer_record.venue_id = p_venue_id
  ) then
    raise exception using errcode = '22023', message = 'analytics_offer_venue_mismatch';
  end if;
  if p_event_name = 'offer_cta_opened' and (
    p_offer_id is null or not exists (
      select 1
      from public.offer_claims as claim_record
      where claim_record.user_id = p_user_id
        and claim_record.venue_id = p_venue_id
        and claim_record.offer_id = p_offer_id
        and claim_record.status = 'active'
        and claim_record.expires_at > p_client_occurred_at
    )
  ) then
    raise exception using errcode = 'P0001', message = 'active_offer_claim_required';
  end if;

  insert into private.analytics_events (
    user_id,
    event_name,
    venue_id,
    offer_id,
    nightlife_date,
    request_idempotency_key,
    source,
    app_version,
    client_occurred_at,
    server_received_at
  )
  values (
    p_user_id,
    p_event_name,
    p_venue_id,
    p_offer_id,
    private.nightlife_date_for(p_client_occurred_at, v_venue.timezone),
    p_idempotency_key,
    p_source,
    nullif(btrim(p_app_version), ''),
    p_client_occurred_at,
    v_now
  )
  on conflict (request_idempotency_key) do nothing
  returning id into v_event_id;

  if v_event_id is null then
    select existing_event.id into v_event_id
    from private.analytics_events as existing_event
    where existing_event.request_idempotency_key = p_idempotency_key;
  end if;

  return v_event_id;
end;
$$;

revoke execute on function public.ingest_analytics_event(
  uuid, text, uuid, uuid, timestamptz, text, text, uuid
) from public, anon, authenticated, service_role;
grant execute on function public.ingest_analytics_event(
  uuid, text, uuid, uuid, timestamptz, text, text, uuid
) to service_role;

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
  v_minimum_cohort integer;
  v_result jsonb;
begin
  if p_user_id is null then
    raise exception using errcode = '22023', message = 'missing_user_id';
  end if;

  if not exists (
    select 1
    from public.consumer_profiles as profile_record
    join private.consumer_eligibility as eligibility_record
      on eligibility_record.user_id = profile_record.user_id
    where profile_record.user_id = p_user_id
      and profile_record.onboarding_status = 'complete'
      and profile_record.account_status = 'active'
      and eligibility_record.is_19_plus
  ) then
    raise exception using errcode = 'P0001', message = 'account_ineligible';
  end if;

  select minimum_demographic_cohort into v_minimum_cohort
  from private.analytics_config
  where singleton;

  with visible_venues as (
    select venue_record.*
    from public.venues as venue_record
    where venue_record.registration_status = 'approved'
      and venue_record.publication_status = 'published'
      and venue_record.location is not null
  ),
  eligible_offers as (
    select *
    from public.list_eligible_offers(
      p_user_id,
      coalesce((select array_agg(venue_record.id) from visible_venues as venue_record), array[]::uuid[]),
      p_at
    )
  ),
  crowd_users as (
    select plan_record.venue_id, plan_record.user_id
    from public.night_plans as plan_record
    join visible_venues as venue_record on venue_record.id = plan_record.venue_id
    where plan_record.user_id is not null
      and plan_record.nightlife_date = private.nightlife_date_for(p_at, venue_record.timezone)
      and plan_record.plan_status in ('planned', 'checked_in')
    union
    select check_in_record.venue_id, check_in_record.user_id
    from public.check_ins as check_in_record
    join visible_venues as venue_record on venue_record.id = check_in_record.venue_id
    where check_in_record.user_id is not null
      and check_in_record.nightlife_date = private.nightlife_date_for(p_at, venue_record.timezone)
      and check_in_record.outcome = 'verified'
  ),
  crowd_demographics as (
    select
      crowd_user.venue_id,
      count(*)::integer as cohort_size,
      round(avg(
        extract(year from age(
          (p_at at time zone venue_record.timezone)::date,
          eligibility_record.date_of_birth
        ))
      ))::integer as average_age,
      count(*) filter (where eligibility_record.gender = 'man')::integer as men_count,
      count(*) filter (where eligibility_record.gender = 'woman')::integer as women_count,
      count(*) filter (where eligibility_record.gender = 'other')::integer as other_count
    from crowd_users as crowd_user
    join visible_venues as venue_record on venue_record.id = crowd_user.venue_id
    join private.consumer_eligibility as eligibility_record
      on eligibility_record.user_id = crowd_user.user_id
    group by crowd_user.venue_id
  ),
  crowd_age_buckets as (
    select
      crowd_user.venue_id,
      case
        when age_years between 19 and 21 then '19–21'
        when age_years between 22 and 24 then '22–24'
        when age_years between 25 and 27 then '25–27'
        when age_years between 28 and 30 then '28–30'
        when age_years between 31 and 34 then '31–34'
        when age_years between 35 and 39 then '35–39'
        else '40+'
      end as label,
      case
        when age_years between 19 and 21 then 1
        when age_years between 22 and 24 then 2
        when age_years between 25 and 27 then 3
        when age_years between 28 and 30 then 4
        when age_years between 31 and 34 then 5
        when age_years between 35 and 39 then 6
        else 7
      end as sort_order,
      count(*)::integer as user_count
    from (
      select
        crowd_user.venue_id,
        extract(year from age(
          (p_at at time zone venue_record.timezone)::date,
          eligibility_record.date_of_birth
        ))::integer as age_years
      from crowd_users as crowd_user
      join visible_venues as venue_record on venue_record.id = crowd_user.venue_id
      join private.consumer_eligibility as eligibility_record
        on eligibility_record.user_id = crowd_user.user_id
    ) as crowd_user
    group by crowd_user.venue_id, label, sort_order
  ),
  current_plan as (
    select jsonb_build_object(
      'id', plan_record.id,
      'venue_id', plan_record.venue_id,
      'venue_slug', venue_record.slug,
      'nightlife_date', plan_record.nightlife_date,
      'status', plan_record.plan_status,
      'created_at', plan_record.created_at
    ) as payload
    from public.night_plans as plan_record
    join public.venues as venue_record on venue_record.id = plan_record.venue_id
    where plan_record.user_id = p_user_id
      and plan_record.plan_status in ('planned', 'checked_in')
      and plan_record.nightlife_date = private.nightlife_date_for(p_at, venue_record.timezone)
    order by plan_record.created_at desc
    limit 1
  ),
  active_claim as (
    select jsonb_build_object(
      'claim_id', claim_record.id,
      'check_in_id', claim_record.check_in_id,
      'venue_id', claim_record.venue_id,
      'venue_slug', venue_record.slug,
      'unlocked_at', claim_record.unlocked_at,
      'countdown_ends_at', case
        when version_record.claim_duration_seconds is null then null
        else claim_record.expires_at
      end,
      'entitlement_expires_at', claim_record.expires_at,
      'status', case
        when claim_record.status = 'active' and claim_record.expires_at <= p_at then 'expired'
        else claim_record.status
      end,
      'staff_reference', claim_record.staff_reference,
      'offer', jsonb_build_object(
        'offer_id', offer_record.id,
        'offer_version_id', version_record.id,
        'kind', offer_record.offer_kind,
        'title', version_record.public_title,
        'explanation', version_record.short_explanation,
        'cta_label', version_record.cta_label,
        'redemption_mode', version_record.redemption_mode,
        'destination_url', version_record.destination_url,
        'staff_display_title', version_record.staff_display_title,
        'staff_instruction', version_record.staff_instruction,
        'fine_print', version_record.fine_print,
        'claim_duration_seconds', version_record.claim_duration_seconds,
        'sponsor_display_name', version_record.sponsor_display_name,
        'sponsor_logo_storage_path', version_record.sponsor_logo_storage_path,
        'sponsor_logo_alt_text', version_record.sponsor_logo_alt_text,
        'sponsor_disclosure', version_record.sponsor_disclosure,
        'discovery_treatment', version_record.discovery_treatment,
        'discovery_badge_label', version_record.discovery_badge_label,
        'discovery_icon_key', version_record.discovery_icon_key
      )
    ) as payload
    from public.offer_claims as claim_record
    join public.offers as offer_record on offer_record.id = claim_record.offer_id
    join public.offer_versions as version_record on version_record.id = claim_record.offer_version_id
    join public.venues as venue_record on venue_record.id = claim_record.venue_id
    where claim_record.user_id = p_user_id
      and claim_record.status = 'active'
      and claim_record.expires_at > p_at
    order by claim_record.unlocked_at desc
    limit 1
  )
  select jsonb_build_object(
    'server_time', p_at,
    'profile', (
      select jsonb_build_object(
        'user_id', profile_record.user_id,
        'first_name', profile_record.first_name,
        'onboarding_status', profile_record.onboarding_status,
        'account_status', profile_record.account_status
      )
      from public.consumer_profiles as profile_record
      where profile_record.user_id = p_user_id
    ),
    'current_plan', (select current_plan.payload from current_plan),
    'active_claim', (select active_claim.payload from active_claim),
    'venues', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', venue_record.id,
          'slug', venue_record.slug,
          'name', venue_record.display_name,
          'neighbourhood', venue_record.neighbourhood,
          'address', concat_ws(', ',
            venue_record.address_line_1,
            venue_record.address_line_2,
            venue_record.city
          ),
          'latitude', extensions.st_y(venue_record.location::extensions.geometry),
          'longitude', extensions.st_x(venue_record.location::extensions.geometry),
          'timezone', venue_record.timezone,
          'placement_state', venue_record.placement_state,
          'hero_storage_path', hero_asset.storage_path,
          'marker_storage_path', marker_asset.storage_path,
          'hours', coalesce((
            select jsonb_agg(
              jsonb_build_object(
                'weekday', hour_record.weekday,
                'interval_number', hour_record.interval_number,
                'opens_at', hour_record.opens_at,
                'closes_at', hour_record.closes_at,
                'is_closed', hour_record.is_closed
              ) order by hour_record.weekday, hour_record.interval_number
            )
            from public.venue_hours as hour_record
            where hour_record.venue_id = venue_record.id
          ), '[]'::jsonb),
          'tonights_crowd', jsonb_build_object(
            'going_count', coalesce(crowd_data.cohort_size, 0),
            'demographics_available', coalesce(crowd_data.cohort_size, 0) >= v_minimum_cohort,
            'average_age', case
              when coalesce(crowd_data.cohort_size, 0) >= v_minimum_cohort
              then crowd_data.average_age
              else null
            end,
            'age_distribution', case
              when coalesce(crowd_data.cohort_size, 0) >= v_minimum_cohort
              then coalesce((
                select jsonb_agg(
                  jsonb_build_object(
                    'label', age_bucket.label,
                    'percentage', (
                      round(
                        (age_bucket.user_count * 100.0 / crowd_data.cohort_size) / 5.0
                      )::integer * 5
                    )
                  ) order by age_bucket.sort_order
                )
                from crowd_age_buckets as age_bucket
                where age_bucket.venue_id = venue_record.id
              ), '[]'::jsonb)
              else null
            end,
            'gender', case
              when coalesce(crowd_data.cohort_size, 0) >= v_minimum_cohort
              then jsonb_build_object(
                'man', round(
                  (crowd_data.men_count * 100.0 / crowd_data.cohort_size) / 5.0
                )::integer * 5,
                'woman', round(
                  (crowd_data.women_count * 100.0 / crowd_data.cohort_size) / 5.0
                )::integer * 5,
                'other', round(
                  (crowd_data.other_count * 100.0 / crowd_data.cohort_size) / 5.0
                )::integer * 5
              )
              else null
            end
          ),
          'offer', case when eligible_offer.offer_id is null then null else jsonb_build_object(
            'offer_id', eligible_offer.offer_id,
            'offer_version_id', eligible_offer.offer_version_id,
            'kind', eligible_offer.kind,
            'title', eligible_offer.title,
            'explanation', eligible_offer.explanation,
            'cta_label', eligible_offer.cta_label,
            'fine_print', eligible_offer.fine_print,
            'claim_duration_seconds', eligible_offer.claim_duration_seconds,
            'sponsor_display_name', eligible_offer.sponsor_display_name,
            'sponsor_logo_storage_path', eligible_offer.sponsor_logo_storage_path,
            'sponsor_logo_alt_text', eligible_offer.sponsor_logo_alt_text,
            'sponsor_disclosure', eligible_offer.sponsor_disclosure,
            'discovery_treatment', eligible_offer.discovery_treatment,
            'discovery_badge_label', eligible_offer.discovery_badge_label,
            'discovery_icon_key', eligible_offer.discovery_icon_key
          ) end
        ) order by
          (venue_record.placement_state = 'featured') desc,
          coalesce(crowd_data.cohort_size, 0) desc,
          venue_record.display_name
      )
      from visible_venues as venue_record
      left join crowd_demographics as crowd_data on crowd_data.venue_id = venue_record.id
      left join eligible_offers as eligible_offer on eligible_offer.venue_id = venue_record.id
      left join public.venue_assets as hero_asset
        on hero_asset.id = venue_record.current_hero_asset_id
       and hero_asset.moderation_status = 'approved'
      left join public.venue_assets as marker_asset
        on marker_asset.id = venue_record.current_marker_asset_id
       and marker_asset.moderation_status = 'approved'
    ), '[]'::jsonb)
  ) into v_result;

  return v_result;
end;
$$;

revoke execute on function public.get_consumer_bootstrap(uuid, timestamptz)
from public, anon, authenticated, service_role;
grant execute on function public.get_consumer_bootstrap(uuid, timestamptz)
to service_role;

create function public.get_venue_dashboard_snapshot(
  p_user_id uuid,
  p_period_start date default null,
  p_period_end date default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_venue public.venues%rowtype;
  v_account public.venue_accounts%rowtype;
  v_billed_plan_code text;
  v_plan_code text;
  v_subscription_status text;
  v_trial_ends_at timestamptz;
  v_history_days integer;
  v_repeat_insights boolean;
  v_advanced_demographics boolean;
  v_minimum_cohort integer;
  v_repeat_window integer;
  v_period_end date := coalesce(p_period_end, (current_timestamp at time zone 'America/Toronto')::date);
  v_period_start date;
  v_result jsonb;
begin
  select account_record.*
  into v_account
  from public.venue_accounts as account_record
  where account_record.auth_user_id = p_user_id
    and account_record.account_status <> 'deleted';

  if v_account.auth_user_id is null then
    raise exception using errcode = 'P0001', message = 'venue_account_not_found';
  end if;

  select venue_record.*
  into v_venue
  from public.venues as venue_record
  where venue_record.id = v_account.venue_id;

  select
    subscription_record.plan_code,
    subscription_record.stripe_status,
    subscription_record.trial_ends_at
  into v_billed_plan_code, v_subscription_status, v_trial_ends_at
  from private.venue_subscriptions as subscription_record
  where subscription_record.venue_id = v_venue.id;

  -- Paid capabilities are effective only while Stripe says the subscription is
  -- usable. A stale plan_code must never leave Pro analytics enabled after a
  -- failed or cancelled payment.
  v_plan_code := case
    when v_billed_plan_code <> 'free'
     and (
       v_subscription_status = 'active'
       or (
         v_subscription_status = 'trialing'
         and v_trial_ends_at > current_timestamp
       )
     )
    then v_billed_plan_code
    else 'free'
  end;

  select
    max((entitlement_value #>> '{}')::integer)
      filter (where entitlement_key = 'analytics_history_days'),
    coalesce(bool_or((entitlement_value #>> '{}')::boolean)
      filter (where entitlement_key = 'repeat_visitor_insights'), false),
    coalesce(bool_or((entitlement_value #>> '{}')::boolean)
      filter (where entitlement_key = 'advanced_demographics'), false)
  into v_history_days, v_repeat_insights, v_advanced_demographics
  from private.plan_entitlements
  where plan_code = v_plan_code;

  if v_history_days is null then
    raise exception using errcode = 'P0001', message = 'venue_entitlement_missing';
  end if;

  v_period_start := greatest(
    coalesce(p_period_start, v_period_end - least(v_history_days - 1, 6)),
    v_period_end - (v_history_days - 1)
  );

  if v_period_start > v_period_end then
    raise exception using errcode = '22023', message = 'invalid_analytics_period';
  end if;

  select minimum_demographic_cohort, repeat_visitor_window_days
  into v_minimum_cohort, v_repeat_window
  from private.analytics_config
  where singleton;

  with period_plans as (
    select distinct plan_record.user_id, plan_record.nightlife_date
    from public.night_plans as plan_record
    where plan_record.venue_id = v_venue.id
      and plan_record.user_id is not null
      and plan_record.nightlife_date between v_period_start and v_period_end
      and plan_record.plan_status in ('planned', 'checked_in', 'replaced', 'cancelled')
  ),
  period_check_ins as (
    select check_in_record.*
    from public.check_ins as check_in_record
    where check_in_record.venue_id = v_venue.id
      and check_in_record.nightlife_date between v_period_start and v_period_end
  ),
  verified_check_ins as (
    select *
    from period_check_ins
    where outcome = 'verified' and user_id is not null
  ),
  period_claims as (
    select claim_record.*
    from public.offer_claims as claim_record
    where claim_record.venue_id = v_venue.id
      and claim_record.nightlife_date between v_period_start and v_period_end
      and claim_record.status <> 'voided'
  ),
  repeat_visitors as (
    select current_visit.user_id
    from verified_check_ins as current_visit
    where exists (
      select 1
      from public.check_ins as prior_visit
      where prior_visit.venue_id = current_visit.venue_id
        and prior_visit.user_id = current_visit.user_id
        and prior_visit.outcome = 'verified'
        and prior_visit.server_verified_at < current_visit.server_verified_at
        and prior_visit.server_verified_at >= current_visit.server_verified_at
          - make_interval(days => v_repeat_window)
    )
    group by current_visit.user_id
  ),
  demographic_users as (
    select distinct verified_visit.user_id
    from verified_check_ins as verified_visit
  ),
  demographic_summary as (
    select
      count(*)::integer as cohort_size,
      round(avg(extract(year from age(v_period_end, eligibility_record.date_of_birth))))::integer as average_age,
      count(*) filter (where eligibility_record.gender = 'man')::integer as men_count,
      count(*) filter (where eligibility_record.gender = 'woman')::integer as women_count,
      count(*) filter (where eligibility_record.gender = 'other')::integer as other_count
    from demographic_users as demographic_user
    join private.consumer_eligibility as eligibility_record
      on eligibility_record.user_id = demographic_user.user_id
  ),
  daily_activity as (
    select jsonb_agg(
      jsonb_build_object(
        'date', day_record.day,
        'impressions', (
          select count(distinct event_record.user_id)
          from private.analytics_events as event_record
          where event_record.venue_id = v_venue.id
            and event_record.nightlife_date = day_record.day
            and event_record.event_name = 'venue_impression'
        ),
        'detail_viewers', (
          select count(distinct event_record.user_id)
          from private.analytics_events as event_record
          where event_record.venue_id = v_venue.id
            and event_record.nightlife_date = day_record.day
            and event_record.event_name = 'venue_detail_view'
        ),
        'plans', (
          select count(distinct plan_record.user_id)
          from period_plans as plan_record
          where plan_record.nightlife_date = day_record.day
        ),
        'verified_check_ins', (
          select count(distinct check_in_record.user_id)
          from verified_check_ins as check_in_record
          where check_in_record.nightlife_date = day_record.day
        ),
        'offers_unlocked', (
          select count(*)
          from period_claims as claim_record
          where claim_record.nightlife_date = day_record.day
        )
      ) order by day_record.day
    ) as payload
    from generate_series(v_period_start, v_period_end, interval '1 day')
      as day_record(day)
  ),
  hourly_check_ins as (
    select coalesce(jsonb_agg(
      jsonb_build_object('hour', hour_value, 'count', check_in_count)
      order by hour_value
    ), '[]'::jsonb) as payload
    from (
      select
        extract(hour from verified_visit.server_verified_at at time zone v_venue.timezone)::integer as hour_value,
        count(*)::integer as check_in_count
      from verified_check_ins as verified_visit
      group by 1
    ) as hourly
  ),
  offer_summary as (
    select coalesce(jsonb_agg(
      jsonb_build_object(
        'offer_id', offer_record.id,
        'title', coalesce(version_record.public_title, 'Draft offer'),
        'status', offer_record.lifecycle_status,
        'approval_state', version_record.approval_state,
        'claim_duration_seconds', version_record.claim_duration_seconds,
        'unlocked_count', (
          select count(*)
          from period_claims as claim_record
          where claim_record.offer_id = offer_record.id
        )
      ) order by offer_record.created_at desc
    ), '[]'::jsonb) as payload
    from public.offers as offer_record
    left join public.offer_versions as version_record
      on version_record.offer_id = offer_record.id
     and version_record.version_number = (
       select max(candidate_version.version_number)
       from public.offer_versions as candidate_version
       where candidate_version.offer_id = offer_record.id
     )
    where offer_record.venue_id = v_venue.id
  )
  select jsonb_build_object(
    'server_time', current_timestamp,
    'period', jsonb_build_object(
      'start', v_period_start,
      'end', v_period_end,
      'maximum_history_days', v_history_days
    ),
    'venue', jsonb_build_object(
      'id', v_venue.id,
      'slug', v_venue.slug,
      'name', v_venue.display_name,
      'registration_status', v_venue.registration_status,
      'publication_status', v_venue.publication_status,
      'account_status', v_account.account_status,
      'neighbourhood', v_venue.neighbourhood,
      'address', concat_ws(', ', v_venue.address_line_1, v_venue.address_line_2, v_venue.city)
    ),
    'subscription', jsonb_build_object(
      'plan_code', v_plan_code,
      'billing_plan_code', v_billed_plan_code,
      'status', v_subscription_status,
      'entitlements', (
        select coalesce(jsonb_object_agg(entitlement_key, entitlement_value), '{}'::jsonb)
        from private.plan_entitlements
        where plan_code = v_plan_code
      )
    ),
    'metrics', jsonb_build_object(
      'impressions', (
        select count(distinct event_record.user_id)
        from private.analytics_events as event_record
        where event_record.venue_id = v_venue.id
          and event_record.nightlife_date between v_period_start and v_period_end
          and event_record.event_name = 'venue_impression'
      ),
      'detail_viewers', (
        select count(distinct event_record.user_id)
        from private.analytics_events as event_record
        where event_record.venue_id = v_venue.id
          and event_record.nightlife_date between v_period_start and v_period_end
          and event_record.event_name = 'venue_detail_view'
      ),
      'plans', (select count(*) from period_plans),
      'check_in_attempts', (select count(*) from period_check_ins),
      'verified_check_ins', (select count(distinct user_id) from verified_check_ins),
      'offers_unlocked', (select count(*) from period_claims),
      'returning_visitors', case
        when v_repeat_insights then (select count(*) from repeat_visitors)
        else null
      end
    ),
    'daily_activity', (select payload from daily_activity),
    'check_ins_by_hour', (select payload from hourly_check_ins),
    'demographics', case
      when v_advanced_demographics
       and coalesce((select cohort_size from demographic_summary), 0) >= v_minimum_cohort
      then (
        select jsonb_build_object(
          'cohort_size', cohort_size,
          'average_age', average_age,
          'gender', jsonb_build_object(
            'man', round((men_count * 100.0 / cohort_size) / 5.0)::integer * 5,
            'woman', round((women_count * 100.0 / cohort_size) / 5.0)::integer * 5,
            'other', round((other_count * 100.0 / cohort_size) / 5.0)::integer * 5
          )
        )
        from demographic_summary
      )
      else null
    end,
    'demographics_suppressed', not (
      v_advanced_demographics
      and coalesce((select cohort_size from demographic_summary), 0) >= v_minimum_cohort
    ),
    'offers', (select payload from offer_summary)
  ) into v_result;

  return v_result;
end;
$$;

revoke execute on function public.get_venue_dashboard_snapshot(uuid, date, date)
from public, anon, authenticated, service_role;
grant execute on function public.get_venue_dashboard_snapshot(uuid, date, date)
to service_role;

create function public.prepare_account_deletion(
  p_user_id uuid,
  p_subject_type text,
  p_idempotency_key uuid
)
returns table (
  deletion_request_id bigint,
  deletion_state text,
  subject_type text
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := clock_timestamp();
  v_request private.account_deletion_requests%rowtype;
  v_venue_id uuid;
begin
  if p_user_id is null or p_idempotency_key is null then
    raise exception using errcode = '22023', message = 'missing_deletion_parameter';
  end if;
  if p_subject_type not in ('consumer', 'venue') then
    raise exception using errcode = '22023', message = 'invalid_deletion_subject_type';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('account-deletion:' || p_user_id::text, 0)
  );

  select * into v_request
  from private.account_deletion_requests as request_record
  where request_record.requester_user_id = p_user_id
    and request_record.request_idempotency_key = p_idempotency_key;

  if v_request.id is not null then
    return query select v_request.id, v_request.state, v_request.subject_type;
    return;
  end if;

  -- A client can lose the response after preparation but before Auth cleanup.
  -- Resume the single in-progress request even when that retry generated a new
  -- idempotency key, so deletion never becomes stranded behind the requester
  -- uniqueness constraint.
  select * into v_request
  from private.account_deletion_requests as request_record
  where request_record.requester_user_id = p_user_id
    and request_record.state in ('requested', 'confirmed', 'processing')
  order by request_record.requested_at desc
  limit 1;

  if v_request.id is not null then
    if v_request.subject_type <> p_subject_type then
      raise exception using errcode = '22023', message = 'deletion_subject_type_mismatch';
    end if;
    return query select v_request.id, v_request.state, v_request.subject_type;
    return;
  end if;

  if p_subject_type = 'consumer' then
    if not exists (
      select 1
      from public.consumer_profiles as profile_record
      where profile_record.user_id = p_user_id
        and profile_record.account_status <> 'deleted'
    ) then
      raise exception using errcode = 'P0001', message = 'consumer_account_not_found';
    end if;

    update public.consumer_profiles
    set account_status = 'deletion_pending'
    where user_id = p_user_id;

    update public.offer_claims
    set
      status = case when status = 'active' then 'voided' else status end,
      voided_at = case when status = 'active' then v_now else voided_at end,
      void_reason = case when status = 'active' then 'account_deleted' else void_reason end,
      anonymized_at = v_now,
      user_id = null
    where user_id = p_user_id;

    update public.check_ins
    set anonymized_at = v_now, user_id = null
    where user_id = p_user_id;

    update public.night_plans
    set
      plan_status = case when plan_status = 'planned' then 'cancelled' else plan_status end,
      cancelled_at = case when plan_status = 'planned' then v_now else cancelled_at end,
      anonymized_at = v_now,
      user_id = null
    where user_id = p_user_id;

    delete from private.analytics_events where user_id = p_user_id;
    delete from private.device_push_tokens where user_id = p_user_id;

    insert into private.account_deletion_requests (
      subject_type,
      auth_user_id,
      requester_user_id,
      subject_reference,
      state,
      request_idempotency_key,
      requested_at,
      confirmed_at,
      started_at
    )
    values (
      'consumer',
      p_user_id,
      p_user_id,
      p_user_id,
      'processing',
      p_idempotency_key,
      v_now,
      v_now,
      v_now
    )
    returning * into v_request;
  else
    select venue_account.venue_id into v_venue_id
    from public.venue_accounts as venue_account
    where venue_account.auth_user_id = p_user_id
      and venue_account.account_status <> 'deleted'
    for update;

    if v_venue_id is null then
      raise exception using errcode = 'P0001', message = 'venue_account_not_found';
    end if;

    if exists (
      select 1
      from private.venue_subscriptions as subscription_record
      where subscription_record.venue_id = v_venue_id
        and subscription_record.stripe_subscription_id is not null
        and (
          subscription_record.stripe_status in ('active', 'past_due')
          or (
            subscription_record.stripe_status = 'trialing'
            and subscription_record.trial_ends_at > v_now
          )
        )
    ) then
      raise exception using
        errcode = 'P0001',
        message = 'active_subscription_cancellation_required';
    end if;

    update public.venue_accounts
    set account_status = 'deletion_pending'
    where auth_user_id = p_user_id;

    update public.venues
    set
      registration_status = 'archived',
      publication_status = 'unpublished',
      public_phone = null,
      public_email = null,
      website_url = null,
      instagram_handle = null,
      suspended_at = null,
      archived_at = v_now
    where id = v_venue_id;

    update public.offers
    set lifecycle_status = 'archived', archived_at = v_now, paused_reason = null
    where venue_id = v_venue_id
      and lifecycle_status <> 'archived';

    delete from private.venue_business_details where venue_id = v_venue_id;

    insert into private.account_deletion_requests (
      subject_type,
      auth_user_id,
      requester_user_id,
      subject_reference,
      state,
      request_idempotency_key,
      requested_at,
      confirmed_at,
      started_at
    )
    values (
      'venue',
      p_user_id,
      p_user_id,
      v_venue_id,
      'processing',
      p_idempotency_key,
      v_now,
      v_now,
      v_now
    )
    returning * into v_request;
  end if;

  return query select v_request.id, v_request.state, v_request.subject_type;
end;
$$;

revoke execute on function public.prepare_account_deletion(uuid, text, uuid)
from public, anon, authenticated, service_role;
grant execute on function public.prepare_account_deletion(uuid, text, uuid)
to service_role;

create function public.complete_account_deletion(
  p_deletion_request_id bigint
)
returns table (
  deletion_request_id bigint,
  deletion_state text,
  subject_type text
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_request private.account_deletion_requests%rowtype;
begin
  select * into v_request
  from private.account_deletion_requests as request_record
  where request_record.id = p_deletion_request_id
  for update;

  if v_request.id is null then
    raise exception using errcode = 'P0001', message = 'deletion_request_not_found';
  end if;
  if v_request.state = 'completed' then
    return query select v_request.id, v_request.state, v_request.subject_type;
    return;
  end if;
  if v_request.state <> 'processing' then
    raise exception using errcode = 'P0001', message = 'deletion_request_not_processing';
  end if;
  if v_request.auth_user_id is not null and exists (
    select 1 from auth.users as auth_user where auth_user.id = v_request.auth_user_id
  ) then
    raise exception using errcode = 'P0001', message = 'auth_user_still_exists';
  end if;

  update private.account_deletion_requests as request_record
  set
    state = 'completed',
    completed_at = clock_timestamp(),
    subject_reference = case
      when request_record.subject_type = 'consumer' then null
      else request_record.subject_reference
    end,
    requester_user_id = null
  where request_record.id = v_request.id
  returning * into v_request;

  return query select v_request.id, v_request.state, v_request.subject_type;
end;
$$;

revoke execute on function public.complete_account_deletion(bigint)
from public, anon, authenticated, service_role;
grant execute on function public.complete_account_deletion(bigint)
to service_role;
