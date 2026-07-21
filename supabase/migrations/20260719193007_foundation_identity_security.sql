-- Outly foundation: security boundaries and account identity data.
-- This migration intentionally excludes venues, plans, check-ins, offers,
-- campaigns, and billing. Those domains build on these boundaries in later
-- migrations.

create extension if not exists postgis with schema extensions;

create schema if not exists private;
comment on schema private is
  'Server-only Outly data. This schema must never be added to the Data API exposed schemas.';

-- New objects are private by default. Every client-facing privilege must be
-- granted deliberately in the same migration that creates the object.
alter default privileges for role postgres in schema public
  revoke select, insert, update, delete on tables from anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  revoke usage, select on sequences from anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  revoke execute on functions from public, anon, authenticated, service_role;

alter default privileges for role postgres in schema private
  revoke all on tables from public, anon, authenticated, service_role;
alter default privileges for role postgres in schema private
  revoke all on sequences from public, anon, authenticated, service_role;
alter default privileges for role postgres in schema private
  revoke execute on functions from public, anon, authenticated, service_role;

revoke all on schema private from public, anon, authenticated, service_role;
grant usage on schema private to service_role;

create table public.consumer_profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  first_name text,
  onboarding_status text not null default 'incomplete',
  account_status text not null default 'active',
  onboarding_completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint consumer_profiles_first_name_valid check (
    first_name is null
    or (
      first_name = btrim(first_name)
      and char_length(first_name) between 1 and 50
    )
  ),
  constraint consumer_profiles_onboarding_status_valid check (
    onboarding_status in ('incomplete', 'complete', 'blocked')
  ),
  constraint consumer_profiles_account_status_valid check (
    account_status in ('active', 'deletion_pending', 'deleted', 'suspended')
  ),
  constraint consumer_profiles_completion_consistent check (
    (
      onboarding_status = 'complete'
      and first_name is not null
      and onboarding_completed_at is not null
    )
    or (
      onboarding_status <> 'complete'
      and onboarding_completed_at is null
    )
  )
);

comment on table public.consumer_profiles is
  'Consumer-visible profile shell. DOB, gender, and eligibility are isolated in private.consumer_eligibility.';
comment on column public.consumer_profiles.user_id is
  'Supabase Auth user ID. Consumers may read only their own row.';

create table private.consumer_eligibility (
  user_id uuid primary key references auth.users (id) on delete cascade,
  date_of_birth date not null,
  gender text not null,
  is_19_plus boolean not null,
  age_eligibility_checked_at timestamptz not null,
  age_eligibility_source text not null default 'self_reported_dob',
  corrected_at timestamptz,
  corrected_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint consumer_eligibility_gender_valid check (
    gender in ('man', 'woman', 'other')
  ),
  constraint consumer_eligibility_source_valid check (
    age_eligibility_source = 'self_reported_dob'
  ),
  constraint consumer_eligibility_birth_precedes_check check (
    date_of_birth <= (age_eligibility_checked_at at time zone 'America/Toronto')::date
  ),
  constraint consumer_eligibility_result_consistent check (
    is_19_plus = (
      date_of_birth
      <= (
        (age_eligibility_checked_at at time zone 'America/Toronto')::date
        - interval '19 years'
      )::date
    )
  )
);

comment on table private.consumer_eligibility is
  'Self-reported DOB and protected server-calculated 19+ eligibility. Never exposed through the Data API.';
comment on column private.consumer_eligibility.gender is
  'Required onboarding value: man, woman, or other (displayed as Another gender).';
comment on column private.consumer_eligibility.is_19_plus is
  'Calculated against the recorded check time in America/Toronto; never client-written.';

create index consumer_eligibility_corrected_by_idx
  on private.consumer_eligibility (corrected_by)
  where corrected_by is not null;

create table private.internal_admins (
  user_id uuid primary key references auth.users (id) on delete cascade,
  role text not null default 'founder_admin',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  revoked_at timestamptz,

  constraint internal_admins_role_valid check (role = 'founder_admin'),
  constraint internal_admins_active_state_consistent check (
    (active and revoked_at is null)
    or (not active and revoked_at is not null)
  )
);

comment on table private.internal_admins is
  'Server-side founder authorization allowlist. Never derive this authorization from user-editable metadata.';

create table private.legal_acceptances (
  id bigint generated always as identity primary key,
  subject_user_id uuid not null references auth.users (id) on delete cascade,
  subject_type text not null,
  document_type text not null,
  document_version text not null,
  source text not null,
  accepted_at timestamptz not null default now(),

  constraint legal_acceptances_subject_type_valid check (
    subject_type in ('consumer', 'venue')
  ),
  constraint legal_acceptances_document_type_valid check (
    document_type in ('terms_of_service', 'privacy_policy', 'venue_agreement')
  ),
  constraint legal_acceptances_document_version_valid check (
    document_version = btrim(document_version)
    and char_length(document_version) between 1 and 80
  ),
  constraint legal_acceptances_source_valid check (source in ('ios', 'web')),
  constraint legal_acceptances_once_per_version unique (
    subject_user_id,
    subject_type,
    document_type,
    document_version
  )
);

comment on table private.legal_acceptances is
  'Versioned consumer and venue legal acceptances. Exact retention is pending legal review.';

create table private.device_push_tokens (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  token text not null unique,
  environment text not null,
  bundle_id text not null,
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  disabled_at timestamptz,

  constraint device_push_tokens_environment_valid check (
    environment in ('sandbox', 'production')
  ),
  constraint device_push_tokens_token_valid check (
    token = btrim(token) and char_length(token) between 16 and 512
  ),
  constraint device_push_tokens_bundle_id_valid check (
    bundle_id = btrim(bundle_id) and char_length(bundle_id) between 3 and 255
  )
);

create index device_push_tokens_user_id_idx
  on private.device_push_tokens (user_id);
create index device_push_tokens_active_user_idx
  on private.device_push_tokens (user_id, last_seen_at desc)
  where disabled_at is null;

comment on table private.device_push_tokens is
  'Private APNs delivery tokens. Tokens are removed during consumer account deletion.';

create table private.account_deletion_requests (
  id bigint generated always as identity primary key,
  subject_type text not null,
  auth_user_id uuid references auth.users (id) on delete set null,
  subject_reference uuid,
  state text not null default 'requested',
  failure_code text,
  retention_basis text,
  requested_at timestamptz not null default now(),
  confirmed_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,

  constraint account_deletion_requests_subject_type_valid check (
    subject_type in ('consumer', 'venue')
  ),
  constraint account_deletion_requests_state_valid check (
    state in ('requested', 'confirmed', 'processing', 'completed', 'failed')
  ),
  constraint account_deletion_requests_subject_present check (
    state = 'completed'
    or subject_reference is not null
  ),
  constraint account_deletion_requests_completion_consistent check (
    (state = 'completed' and completed_at is not null)
    or (state <> 'completed' and completed_at is null)
  )
);

create index account_deletion_requests_auth_user_id_idx
  on private.account_deletion_requests (auth_user_id)
  where auth_user_id is not null;
create index account_deletion_requests_pending_idx
  on private.account_deletion_requests (state, requested_at)
  where state <> 'completed';

comment on table private.account_deletion_requests is
  'Resumable deletion workflow audit. Subject references must be cleared when no longer legally required.';

create function private.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke execute on function private.set_updated_at() from public, anon, authenticated, service_role;

create trigger consumer_profiles_set_updated_at
before update on public.consumer_profiles
for each row execute function private.set_updated_at();

create trigger consumer_eligibility_set_updated_at
before update on private.consumer_eligibility
for each row execute function private.set_updated_at();

-- RLS remains enabled even on the private schema as defense in depth.
alter table public.consumer_profiles enable row level security;
alter table private.consumer_eligibility enable row level security;
alter table private.internal_admins enable row level security;
alter table private.legal_acceptances enable row level security;
alter table private.device_push_tokens enable row level security;
alter table private.account_deletion_requests enable row level security;

create policy consumer_profiles_select_own
on public.consumer_profiles
for select
to authenticated
using ((select auth.uid()) = user_id);

-- The app can read only the authenticated consumer's public profile shell.
revoke all on table public.consumer_profiles from public, anon, authenticated, service_role;
grant select on table public.consumer_profiles to authenticated;
grant select, insert, update, delete on table public.consumer_profiles to service_role;

-- Private records are available only to trusted server code. The schema is not
-- part of the Data API exposed schemas, so these grants do not create REST or
-- GraphQL endpoints.
revoke all on table
  private.consumer_eligibility,
  private.internal_admins,
  private.legal_acceptances,
  private.device_push_tokens,
  private.account_deletion_requests
from public, anon, authenticated, service_role;

grant select, insert, update, delete on table
  private.consumer_eligibility,
  private.internal_admins,
  private.legal_acceptances,
  private.device_push_tokens,
  private.account_deletion_requests
to service_role;

grant usage, select on sequence
  private.legal_acceptances_id_seq,
  private.device_push_tokens_id_seq,
  private.account_deletion_requests_id_seq
to service_role;
