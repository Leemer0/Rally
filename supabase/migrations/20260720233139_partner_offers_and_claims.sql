-- Outly offers, founder-managed partner campaigns, and location-verified claims.
--
-- Standard venue offers and partner offers deliberately share this complete
-- path. Presentation metadata changes how a client renders an approved offer;
-- it never changes the check-in, eligibility, capacity, or claim guarantees.

create table public.offers (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references public.venues (id) on delete restrict,
  creator_type text not null,
  offer_kind text not null default 'standard',
  lifecycle_status text not null default 'draft',
  display_priority smallint not null default 0,
  current_approved_version_id uuid,
  paused_reason text,
  created_by uuid references auth.users (id) on delete set null,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint offers_creator_type_valid check (creator_type in ('venue', 'outly')),
  constraint offers_kind_valid check (offer_kind in ('standard', 'partner')),
  constraint offers_partner_creator_consistent check (
    offer_kind = 'standard' or creator_type = 'outly'
  ),
  constraint offers_lifecycle_valid check (
    lifecycle_status in (
      'draft',
      'pending_review',
      'changes_requested',
      'rejected',
      'approved',
      'scheduled',
      'live',
      'paused',
      'ended',
      'archived'
    )
  ),
  constraint offers_paused_reason_consistent check (
    (lifecycle_status = 'paused' and paused_reason is not null)
    or (lifecycle_status <> 'paused' and paused_reason is null)
  ),
  constraint offers_archived_at_consistent check (
    (lifecycle_status = 'archived' and archived_at is not null)
    or (lifecycle_status <> 'archived' and archived_at is null)
  ),
  constraint offers_same_venue_reference unique (id, venue_id)
);

comment on table public.offers is
  'Stable venue offer identity. Partner offers use the same versions and claims as standard offers.';
comment on column public.offers.display_priority is
  'Founder-controlled ordering. The MVP returns one highest-priority eligible offer per venue.';

create table public.offer_versions (
  id uuid primary key default gen_random_uuid(),
  offer_id uuid not null references public.offers (id) on delete restrict,
  version_number integer not null,
  public_title text not null,
  short_explanation text,
  staff_display_title text,
  staff_instruction text,
  fine_print text,
  cta_label text not null,
  redemption_mode text not null default 'staff_display',
  destination_url text,
  minimum_age smallint not null default 19,
  eligibility_mode text not null default 'verified_check_in',
  claim_duration_seconds integer,
  per_user_limit smallint not null default 1,
  total_claim_limit integer,
  presentation_kind text not null default 'standard',
  sponsor_display_name text,
  sponsor_logo_storage_path text,
  sponsor_logo_alt_text text,
  sponsor_disclosure text,
  discovery_treatment text not null default 'none',
  discovery_badge_label text,
  discovery_icon_key text,
  approval_state text not null default 'draft',
  submitted_by uuid references auth.users (id) on delete set null,
  approved_by uuid references auth.users (id) on delete set null,
  submitted_at timestamptz,
  approved_at timestamptz,
  created_at timestamptz not null default now(),

  constraint offer_versions_version_positive check (version_number > 0),
  constraint offer_versions_public_title_valid check (
    public_title = btrim(public_title)
    and char_length(public_title) between 1 and 140
  ),
  constraint offer_versions_optional_copy_valid check (
    (short_explanation is null or (
      short_explanation = btrim(short_explanation)
      and char_length(short_explanation) between 1 and 240
    ))
    and (staff_display_title is null or (
      staff_display_title = btrim(staff_display_title)
      and char_length(staff_display_title) between 1 and 140
    ))
    and (staff_instruction is null or (
      staff_instruction = btrim(staff_instruction)
      and char_length(staff_instruction) between 1 and 240
    ))
    and (fine_print is null or (
      fine_print = btrim(fine_print)
      and char_length(fine_print) between 1 and 1000
    ))
  ),
  constraint offer_versions_cta_label_valid check (
    cta_label = btrim(cta_label)
    and char_length(cta_label) between 1 and 60
  ),
  constraint offer_versions_redemption_mode_valid check (
    redemption_mode in ('staff_display', 'external_link')
  ),
  constraint offer_versions_redemption_destination_consistent check (
    (
      redemption_mode = 'staff_display'
      and destination_url is null
      and staff_display_title is not null
      and staff_instruction is not null
    )
    or (
      redemption_mode = 'external_link'
      and destination_url is not null
      and destination_url ~ '^https://'
    )
  ),
  constraint offer_versions_minimum_age_valid check (minimum_age between 19 and 99),
  constraint offer_versions_eligibility_mode_valid check (
    eligibility_mode in (
      'verified_check_in',
      'check_in_window',
      'check_in_before',
      'plan_before_and_check_in'
    )
  ),
  constraint offer_versions_duration_valid check (
    claim_duration_seconds is null
    or claim_duration_seconds > 0
  ),
  constraint offer_versions_limits_valid check (
    per_user_limit between 1 and 100
    and (total_claim_limit is null or total_claim_limit > 0)
  ),
  constraint offer_versions_presentation_kind_valid check (
    presentation_kind in ('standard', 'partner')
  ),
  constraint offer_versions_partner_snapshot_consistent check (
    (
      presentation_kind = 'partner'
      and sponsor_display_name is not null
      and sponsor_logo_storage_path is not null
      and sponsor_logo_alt_text is not null
      and sponsor_disclosure is not null
    )
    or (
      presentation_kind = 'standard'
      and sponsor_display_name is null
      and sponsor_logo_storage_path is null
      and sponsor_logo_alt_text is null
      and sponsor_disclosure is null
    )
  ),
  constraint offer_versions_discovery_treatment_valid check (
    discovery_treatment in ('none', 'outly_exclusive', 'partner_featured')
  ),
  constraint offer_versions_discovery_snapshot_consistent check (
    (
      discovery_treatment = 'none'
      and discovery_badge_label is null
      and discovery_icon_key is null
    )
    or (
      discovery_treatment <> 'none'
      and discovery_badge_label is not null
      and discovery_icon_key is not null
    )
  ),
  constraint offer_versions_approval_state_valid check (
    approval_state in ('draft', 'pending_review', 'changes_requested', 'approved', 'rejected')
  ),
  constraint offer_versions_approval_timestamps_consistent check (
    (
      approval_state = 'approved'
      and approved_by is not null
      and approved_at is not null
      and submitted_at is not null
    )
    or (
      approval_state <> 'approved'
      and approved_at is null
    )
  ),
  constraint offer_versions_number_unique unique (offer_id, version_number),
  constraint offer_versions_same_offer_reference unique (id, offer_id)
);

comment on table public.offer_versions is
  'Approved immutable consumer/staff snapshot. A material change creates a new version.';
comment on column public.offer_versions.claim_duration_seconds is
  'NULL means no consumer-facing countdown. Any positive number of seconds creates a server-controlled expiry.';
comment on column public.offer_versions.destination_url is
  'Founder-approved HTTPS universal link for external partner redemption. Never accept a client-provided URL.';

alter table public.offers
  add constraint offers_current_version_same_offer_fk
  foreign key (current_approved_version_id, id)
  references public.offer_versions (id, offer_id)
  on delete restrict;

create table public.offer_schedules (
  id uuid primary key default gen_random_uuid(),
  offer_version_id uuid not null references public.offer_versions (id) on delete restrict,
  nightlife_start_date date not null,
  nightlife_end_date date,
  eligible_weekdays smallint[] not null default array[0, 1, 2, 3, 4, 5, 6]::smallint[],
  daily_starts_at time,
  daily_ends_at time,
  check_in_starts_at time,
  check_in_cutoff_at time,
  plan_cutoff_at time,
  occurrence_claim_limit integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint offer_schedules_date_range_valid check (
    nightlife_end_date is null or nightlife_end_date >= nightlife_start_date
  ),
  constraint offer_schedules_weekdays_valid check (
    cardinality(eligible_weekdays) > 0
    and eligible_weekdays <@ array[0, 1, 2, 3, 4, 5, 6]::smallint[]
  ),
  constraint offer_schedules_daily_window_consistent check (
    (daily_starts_at is null) = (daily_ends_at is null)
  ),
  constraint offer_schedules_check_in_window_consistent check (
    check_in_cutoff_at is not null or check_in_starts_at is null
  ),
  constraint offer_schedules_occurrence_limit_valid check (
    occurrence_claim_limit is null or occurrence_claim_limit > 0
  ),
  constraint offer_schedules_same_version_reference unique (id, offer_version_id)
);

comment on table public.offer_schedules is
  'Venue-local offer occurrence rules. Cross-midnight windows are supported.';

create table private.partners (
  id uuid primary key default gen_random_uuid(),
  brand_name text not null,
  legal_name text not null,
  status text not null default 'draft',
  website_url text,
  industry text,
  approved_logo_storage_path text,
  approved_logo_alt_text text,
  internal_notes text,
  billing_address text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint partners_brand_name_valid check (
    brand_name = btrim(brand_name) and char_length(brand_name) between 1 and 120
  ),
  constraint partners_legal_name_valid check (
    legal_name = btrim(legal_name) and char_length(legal_name) between 1 and 180
  ),
  constraint partners_status_valid check (status in ('draft', 'active', 'paused', 'archived')),
  constraint partners_website_valid check (website_url is null or website_url ~ '^https://'),
  constraint partners_logo_consistent check (
    (approved_logo_storage_path is null) = (approved_logo_alt_text is null)
  )
);

create table private.partner_contacts (
  id uuid primary key default gen_random_uuid(),
  partner_id uuid not null references private.partners (id) on delete cascade,
  contact_name text not null,
  contact_role text,
  email text not null,
  phone text,
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint partner_contacts_name_valid check (
    contact_name = btrim(contact_name) and char_length(contact_name) between 1 and 120
  ),
  constraint partner_contacts_email_valid check (
    email = btrim(email) and char_length(email) between 3 and 254 and position('@' in email) > 1
  )
);

create unique index partner_contacts_one_primary_idx
  on private.partner_contacts (partner_id)
  where is_primary;

create table private.partner_campaigns (
  id uuid primary key default gen_random_uuid(),
  partner_id uuid not null references private.partners (id) on delete restrict,
  internal_name text not null,
  campaign_status text not null default 'draft',
  approval_status text not null default 'pending',
  starts_at timestamptz not null,
  ends_at timestamptz,
  market_code text,
  neighbourhoods text[] not null default array[]::text[],
  minimum_age smallint not null default 19,
  total_claim_limit integer,
  per_user_limit smallint not null default 1,
  public_sponsor_wording text not null,
  public_reward text not null,
  approved_disclosure text not null,
  public_terms text,
  budget_amount numeric(12, 2),
  compensation_model text,
  private_deal_terms text,
  contract_reference text,
  reporting_requirements text,
  created_by uuid references auth.users (id) on delete set null,
  approved_by uuid references auth.users (id) on delete set null,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint partner_campaigns_internal_name_valid check (
    internal_name = btrim(internal_name) and char_length(internal_name) between 1 and 180
  ),
  constraint partner_campaigns_status_valid check (
    campaign_status in ('draft', 'scheduled', 'live', 'paused', 'ended', 'cancelled')
  ),
  constraint partner_campaigns_approval_valid check (
    approval_status in ('pending', 'approved', 'rejected')
  ),
  constraint partner_campaigns_dates_valid check (ends_at is null or ends_at > starts_at),
  constraint partner_campaigns_age_valid check (minimum_age between 19 and 99),
  constraint partner_campaigns_limits_valid check (
    per_user_limit between 1 and 100
    and (total_claim_limit is null or total_claim_limit > 0)
  ),
  constraint partner_campaigns_live_approval_consistent check (
    campaign_status not in ('scheduled', 'live')
    or (
      approval_status = 'approved'
      and approved_by is not null
      and approved_at is not null
    )
  )
);

create table private.campaign_venues (
  campaign_id uuid not null references private.partner_campaigns (id) on delete cascade,
  venue_id uuid not null references public.venues (id) on delete restrict,
  starts_at timestamptz,
  ends_at timestamptz,
  claim_limit_override integer,
  compensation_override text,
  created_at timestamptz not null default now(),

  primary key (campaign_id, venue_id),
  constraint campaign_venues_dates_valid check (
    ends_at is null or (starts_at is not null and ends_at > starts_at)
  ),
  constraint campaign_venues_limit_valid check (
    claim_limit_override is null or claim_limit_override > 0
  )
);

create table private.offer_campaign_links (
  offer_id uuid primary key references public.offers (id) on delete cascade,
  campaign_id uuid not null references private.partner_campaigns (id) on delete restrict,
  created_at timestamptz not null default now()
);

create function private.enforce_partner_campaign_link()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if not exists (
    select 1
    from public.offers as linked_offer
    where linked_offer.id = new.offer_id
      and linked_offer.offer_kind = 'partner'
      and linked_offer.creator_type = 'outly'
  ) then
    raise exception using
      errcode = '23514',
      message = 'campaign_links_require_outly_partner_offers';
  end if;

  return new;
end;
$$;

revoke execute on function private.enforce_partner_campaign_link()
from public, anon, authenticated, service_role;

create trigger offer_campaign_links_require_partner
before insert or update on private.offer_campaign_links
for each row execute function private.enforce_partner_campaign_link();

create function private.prevent_linked_offer_kind_change()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if (
    new.offer_kind <> 'partner'
    or new.creator_type <> 'outly'
  ) and exists (
    select 1
    from private.offer_campaign_links as campaign_link
    where campaign_link.offer_id = old.id
  ) then
    raise exception using
      errcode = '23514',
      message = 'linked_campaign_offers_must_remain_outly_partner_offers';
  end if;

  return new;
end;
$$;

revoke execute on function private.prevent_linked_offer_kind_change()
from public, anon, authenticated, service_role;

create trigger offers_preserve_linked_partner_kind
before update of creator_type, offer_kind on public.offers
for each row execute function private.prevent_linked_offer_kind_change();

create table private.offer_claim_config (
  singleton boolean primary key default true,
  maximum_unlock_delay_seconds integer not null default 900,
  maximum_claim_lifetime_seconds integer not null default 43200,
  updated_at timestamptz not null default now(),

  constraint offer_claim_config_singleton check (singleton),
  constraint offer_claim_config_unlock_delay_safe check (
    maximum_unlock_delay_seconds between 60 and 3600
  ),
  constraint offer_claim_config_lifetime_safe check (
    maximum_claim_lifetime_seconds between 3600 and 86400
  )
);

insert into private.offer_claim_config (singleton) values (true);

comment on table private.offer_claim_config is
  'Server-only claim safeguards. Idempotent retries of an existing claim remain valid after the initial unlock window.';

create table public.offer_claims (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete set null,
  venue_id uuid not null references public.venues (id) on delete restrict,
  offer_id uuid not null,
  offer_version_id uuid not null,
  schedule_id uuid not null,
  check_in_id uuid not null references public.check_ins (id) on delete restrict,
  nightlife_date date not null,
  request_idempotency_key uuid not null,
  unlocked_at timestamptz not null default now(),
  expires_at timestamptz not null,
  status text not null default 'active',
  expired_at timestamptz,
  voided_at timestamptz,
  void_reason text,
  staff_reference text not null,
  created_at timestamptz not null default now(),

  constraint offer_claims_idempotency_unique unique (user_id, request_idempotency_key),
  constraint offer_claims_one_per_check_in unique (check_in_id),
  constraint offer_claims_offer_same_venue_fk
    foreign key (offer_id, venue_id)
    references public.offers (id, venue_id)
    on delete restrict,
  constraint offer_claims_version_same_offer_fk
    foreign key (offer_version_id, offer_id)
    references public.offer_versions (id, offer_id)
    on delete restrict,
  constraint offer_claims_schedule_same_version_fk
    foreign key (schedule_id, offer_version_id)
    references public.offer_schedules (id, offer_version_id)
    on delete restrict,
  constraint offer_claims_status_valid check (status in ('active', 'expired', 'voided')),
  constraint offer_claims_expiry_valid check (
    expires_at > unlocked_at
  ),
  constraint offer_claims_state_timestamps_consistent check (
    (
      status = 'active'
      and expired_at is null
      and voided_at is null
      and void_reason is null
    )
    or (
      status = 'expired'
      and expires_at is not null
      and expired_at is not null
      and voided_at is null
      and void_reason is null
    )
    or (
      status = 'voided'
      and expired_at is null
      and voided_at is not null
      and void_reason is not null
    )
  ),
  constraint offer_claims_staff_reference_valid check (
    staff_reference ~ '^[A-Z0-9]{8}$'
  )
);

comment on table public.offer_claims is
  'Server-created entitlement unlocked only by a verified check-in. No QR or staff confirmation is implied.';
comment on column public.offer_claims.expires_at is
  'Server validity is always finite. A NULL offer duration suppresses the consumer countdown but the claim still ends at the configured maximum lifetime.';

-- Index every foreign-key and primary catalogue path explicitly.
create index offers_venue_status_priority_idx
  on public.offers (venue_id, lifecycle_status, display_priority desc);
create index offers_created_by_idx on public.offers (created_by) where created_by is not null;
create index offers_current_version_idx
  on public.offers (current_approved_version_id)
  where current_approved_version_id is not null;
create index offer_versions_submitted_by_idx
  on public.offer_versions (submitted_by) where submitted_by is not null;
create index offer_versions_approved_by_idx
  on public.offer_versions (approved_by) where approved_by is not null;
create index offer_schedules_version_dates_idx
  on public.offer_schedules (offer_version_id, nightlife_start_date, nightlife_end_date);
create index partner_contacts_partner_idx on private.partner_contacts (partner_id);
create index partner_campaigns_partner_status_idx
  on private.partner_campaigns (partner_id, campaign_status, approval_status, starts_at, ends_at);
create index partner_campaigns_created_by_idx
  on private.partner_campaigns (created_by) where created_by is not null;
create index partner_campaigns_approved_by_idx
  on private.partner_campaigns (approved_by) where approved_by is not null;
create index campaign_venues_venue_campaign_idx
  on private.campaign_venues (venue_id, campaign_id);
create index offer_campaign_links_campaign_idx
  on private.offer_campaign_links (campaign_id);
create index offer_claims_user_unlocked_idx
  on public.offer_claims (user_id, unlocked_at desc) where user_id is not null;
create index offer_claims_version_night_status_idx
  on public.offer_claims (offer_version_id, nightlife_date, status);
create index offer_claims_offer_idx on public.offer_claims (offer_id);
create index offer_claims_venue_idx on public.offer_claims (venue_id);
create index offer_claims_schedule_idx on public.offer_claims (schedule_id);

create trigger offers_set_updated_at
before update on public.offers
for each row execute function private.set_updated_at();

create trigger offer_schedules_set_updated_at
before update on public.offer_schedules
for each row execute function private.set_updated_at();

create trigger partners_set_updated_at
before update on private.partners
for each row execute function private.set_updated_at();

create trigger partner_contacts_set_updated_at
before update on private.partner_contacts
for each row execute function private.set_updated_at();

create trigger partner_campaigns_set_updated_at
before update on private.partner_campaigns
for each row execute function private.set_updated_at();

create trigger offer_claim_config_set_updated_at
before update on private.offer_claim_config
for each row execute function private.set_updated_at();

create function private.time_is_in_window(
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
  select case
    when p_starts_at is null and p_ends_at is null then true
    when p_starts_at is null or p_ends_at is null then false
    when p_starts_at <= p_ends_at then p_value between p_starts_at and p_ends_at
    else p_value >= p_starts_at or p_value <= p_ends_at
  end;
$$;

revoke execute on function private.time_is_in_window(time, time, time)
from public, anon, authenticated, service_role;
grant execute on function private.time_is_in_window(time, time, time)
to service_role;

create function public.list_eligible_offers(
  p_user_id uuid,
  p_venue_ids uuid[],
  p_at timestamptz default clock_timestamp()
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
  select distinct on (offer_record.venue_id)
    offer_record.id,
    version_record.id,
    schedule_record.id,
    offer_record.venue_id,
    offer_record.offer_kind,
    version_record.public_title,
    version_record.short_explanation,
    version_record.cta_label,
    version_record.redemption_mode,
    version_record.destination_url,
    version_record.staff_display_title,
    version_record.staff_instruction,
    version_record.fine_print,
    version_record.claim_duration_seconds,
    version_record.presentation_kind,
    version_record.sponsor_display_name,
    version_record.sponsor_logo_storage_path,
    version_record.sponsor_logo_alt_text,
    version_record.sponsor_disclosure,
    version_record.discovery_treatment,
    version_record.discovery_badge_label,
    version_record.discovery_icon_key
  from public.offers as offer_record
  join public.venues as venue_record
    on venue_record.id = offer_record.venue_id
  join public.offer_versions as version_record
    on version_record.id = offer_record.current_approved_version_id
    and version_record.offer_id = offer_record.id
  join lateral (
    select candidate_schedule.*
    from public.offer_schedules as candidate_schedule
    where candidate_schedule.offer_version_id = version_record.id
      and private.nightlife_date_for(p_at, venue_record.timezone)
        between candidate_schedule.nightlife_start_date
        and coalesce(candidate_schedule.nightlife_end_date, 'infinity'::date)
      and extract(dow from private.nightlife_date_for(p_at, venue_record.timezone))::smallint
        = any (candidate_schedule.eligible_weekdays)
      and private.time_is_in_window(
        (p_at at time zone venue_record.timezone)::time,
        candidate_schedule.daily_starts_at,
        candidate_schedule.daily_ends_at
      )
      and private.time_is_in_window(
        (p_at at time zone venue_record.timezone)::time,
        candidate_schedule.check_in_starts_at,
        candidate_schedule.check_in_cutoff_at
      )
    order by candidate_schedule.nightlife_start_date desc, candidate_schedule.created_at desc
    limit 1
  ) as schedule_record on true
  join public.consumer_profiles as profile_record
    on profile_record.user_id = p_user_id
    and profile_record.onboarding_status = 'complete'
    and profile_record.account_status = 'active'
  join private.consumer_eligibility as eligibility_record
    on eligibility_record.user_id = p_user_id
    and eligibility_record.is_19_plus
    and eligibility_record.date_of_birth <= (
      (p_at at time zone venue_record.timezone)::date
      - make_interval(years => version_record.minimum_age)
    )::date
  where offer_record.venue_id = any (p_venue_ids)
    and offer_record.lifecycle_status = 'live'
    and offer_record.current_approved_version_id is not null
    and version_record.approval_state = 'approved'
    and offer_record.offer_kind = version_record.presentation_kind
    and venue_record.registration_status = 'approved'
    and venue_record.publication_status = 'published'
    and (
      version_record.eligibility_mode <> 'plan_before_and_check_in'
      or exists (
        select 1
        from public.night_plans as plan_record
        where plan_record.user_id = p_user_id
          and plan_record.venue_id = offer_record.venue_id
          and plan_record.nightlife_date = private.nightlife_date_for(p_at, venue_record.timezone)
          and plan_record.plan_status in ('planned', 'checked_in')
          and (
            schedule_record.plan_cutoff_at is null
            or (plan_record.created_at at time zone venue_record.timezone)::time
              <= schedule_record.plan_cutoff_at
          )
      )
    )
    and (
      select count(*)
      from public.offer_claims as user_claim
      where user_claim.user_id = p_user_id
        and user_claim.offer_version_id = version_record.id
        and user_claim.status <> 'voided'
    ) < version_record.per_user_limit
    and (
      version_record.total_claim_limit is null
      or (
        select count(*)
        from public.offer_claims as version_claim
        where version_claim.offer_version_id = version_record.id
          and version_claim.status <> 'voided'
      ) < version_record.total_claim_limit
    )
    and (
      schedule_record.occurrence_claim_limit is null
      or (
        select count(*)
        from public.offer_claims as schedule_claim
        where schedule_claim.schedule_id = schedule_record.id
          and schedule_claim.status <> 'voided'
      ) < schedule_record.occurrence_claim_limit
    )
    and (
      version_record.presentation_kind = 'standard'
      or exists (
        select 1
        from private.offer_campaign_links as campaign_link
        join private.partner_campaigns as campaign_record
          on campaign_record.id = campaign_link.campaign_id
        join private.partners as partner_record
          on partner_record.id = campaign_record.partner_id
        where campaign_link.offer_id = offer_record.id
          and partner_record.status = 'active'
          and campaign_record.campaign_status = 'live'
          and campaign_record.approval_status = 'approved'
          and eligibility_record.date_of_birth <= (
            (p_at at time zone venue_record.timezone)::date
            - make_interval(years => campaign_record.minimum_age)
          )::date
          and p_at >= campaign_record.starts_at
          and (campaign_record.ends_at is null or p_at < campaign_record.ends_at)
          and (campaign_record.market_code is null or campaign_record.market_code = venue_record.market_code)
          and (
            cardinality(campaign_record.neighbourhoods) = 0
            or venue_record.neighbourhood = any (campaign_record.neighbourhoods)
          )
          and (
            not exists (
              select 1
              from private.campaign_venues as any_campaign_venue
              where any_campaign_venue.campaign_id = campaign_record.id
            )
            or exists (
              select 1
              from private.campaign_venues as selected_campaign_venue
              where selected_campaign_venue.campaign_id = campaign_record.id
                and selected_campaign_venue.venue_id = venue_record.id
                and (selected_campaign_venue.starts_at is null or p_at >= selected_campaign_venue.starts_at)
                and (selected_campaign_venue.ends_at is null or p_at < selected_campaign_venue.ends_at)
                and (
                  selected_campaign_venue.claim_limit_override is null
                  or (
                    select count(*)
                    from public.offer_claims as campaign_venue_claim
                    join private.offer_campaign_links as campaign_venue_link
                      on campaign_venue_link.offer_id = campaign_venue_claim.offer_id
                    where campaign_venue_link.campaign_id = campaign_record.id
                      and campaign_venue_claim.venue_id = venue_record.id
                      and campaign_venue_claim.status <> 'voided'
                  ) < selected_campaign_venue.claim_limit_override
                )
            )
          )
          and (
            campaign_record.total_claim_limit is null
            or (
              select count(*)
              from public.offer_claims as campaign_claim
              join private.offer_campaign_links as claim_campaign_link
                on claim_campaign_link.offer_id = campaign_claim.offer_id
              where claim_campaign_link.campaign_id = campaign_record.id
                and campaign_claim.status <> 'voided'
            ) < campaign_record.total_claim_limit
          )
          and (
            select count(*)
            from public.offer_claims as user_campaign_claim
            join private.offer_campaign_links as user_campaign_link
              on user_campaign_link.offer_id = user_campaign_claim.offer_id
            where user_campaign_link.campaign_id = campaign_record.id
              and user_campaign_claim.user_id = p_user_id
              and user_campaign_claim.status <> 'voided'
          ) < campaign_record.per_user_limit
      )
    )
  order by
    offer_record.venue_id,
    offer_record.display_priority desc,
    (offer_record.offer_kind = 'partner') desc,
    version_record.approved_at desc;
$$;

revoke execute on function public.list_eligible_offers(uuid, uuid[], timestamptz)
from public, anon, authenticated, service_role;
grant execute on function public.list_eligible_offers(uuid, uuid[], timestamptz)
to service_role;

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
  v_now timestamptz := clock_timestamp();
  v_maximum_unlock_delay_seconds integer;
  v_maximum_claim_lifetime_seconds integer;
  v_check_in public.check_ins%rowtype;
  v_offer record;
  v_claim public.offer_claims%rowtype;
  v_claim_id uuid;
  v_unlocked_at timestamptz;
begin
  if p_user_id is null or p_check_in_id is null or p_offer_id is null or p_idempotency_key is null then
    raise exception using errcode = '22023', message = 'missing_offer_claim_parameter';
  end if;

  select * into v_claim
  from public.offer_claims as existing_claim
  where existing_claim.user_id = p_user_id
    and existing_claim.request_idempotency_key = p_idempotency_key;

  if v_claim.id is not null then
    if v_claim.check_in_id <> p_check_in_id or v_claim.offer_id <> p_offer_id then
      raise exception using errcode = 'P0001', message = 'idempotency_key_conflict';
    end if;
  else
    select * into v_check_in
    from public.check_ins as check_in_record
    where check_in_record.id = p_check_in_id
    for share;

    if v_check_in.id is null then
      raise exception using errcode = 'P0001', message = 'check_in_not_found';
    end if;
    if v_check_in.user_id is distinct from p_user_id then
      raise exception using errcode = 'P0001', message = 'check_in_user_mismatch';
    end if;
    if v_check_in.outcome <> 'verified' then
      raise exception using errcode = 'P0001', message = 'check_in_not_verified';
    end if;

    select
      claim_config.maximum_unlock_delay_seconds,
      claim_config.maximum_claim_lifetime_seconds
    into
      v_maximum_unlock_delay_seconds,
      v_maximum_claim_lifetime_seconds
    from private.offer_claim_config as claim_config
    where claim_config.singleton;

    if v_maximum_unlock_delay_seconds is null or v_maximum_claim_lifetime_seconds is null then
      raise exception using errcode = 'P0001', message = 'offer_claim_config_missing';
    end if;
    if v_check_in.server_verified_at > v_now + interval '5 seconds' then
      raise exception using errcode = 'P0001', message = 'check_in_timestamp_invalid';
    end if;
    if v_check_in.server_verified_at < (
      v_now - make_interval(secs => v_maximum_unlock_delay_seconds)
    ) then
      raise exception using errcode = 'P0001', message = 'check_in_too_old_to_unlock_offer';
    end if;

    select * into v_claim
    from public.offer_claims as check_in_claim
    where check_in_claim.check_in_id = p_check_in_id;

    if v_claim.id is not null then
      if v_claim.user_id is distinct from p_user_id then
        raise exception using errcode = 'P0001', message = 'check_in_claim_user_mismatch';
      end if;
      if v_claim.offer_id <> p_offer_id then
        raise exception using errcode = 'P0001', message = 'check_in_offer_already_unlocked';
      end if;
    else

      select * into v_offer
      from public.list_eligible_offers(
        p_user_id,
        array[v_check_in.venue_id],
        v_check_in.server_verified_at
      ) as eligible_offer
      where eligible_offer.offer_id = p_offer_id;

      if v_offer.offer_id is null then
        raise exception using errcode = 'P0001', message = 'offer_not_eligible';
      end if;

      perform 1
      from public.offer_versions as locked_version
      where locked_version.id = v_offer.offer_version_id
      for update;

      perform 1
      from private.partner_campaigns as locked_campaign
      join private.offer_campaign_links as locked_link
        on locked_link.campaign_id = locked_campaign.id
      where locked_link.offer_id = p_offer_id
      for update of locked_campaign;

      -- Re-run the complete eligibility and capacity predicate after acquiring
      -- the serializing version/campaign locks.
      select * into v_offer
      from public.list_eligible_offers(
        p_user_id,
        array[v_check_in.venue_id],
        v_check_in.server_verified_at
      ) as eligible_offer
      where eligible_offer.offer_id = p_offer_id;

      if v_offer.offer_id is null then
        raise exception using errcode = 'P0001', message = 'offer_no_longer_available';
      end if;

      v_claim_id := gen_random_uuid();
      v_unlocked_at := clock_timestamp();
      insert into public.offer_claims (
        id,
        user_id,
        venue_id,
        offer_id,
        offer_version_id,
        schedule_id,
        check_in_id,
        nightlife_date,
        request_idempotency_key,
        unlocked_at,
        expires_at,
        status,
        staff_reference
      )
      values (
        v_claim_id,
        p_user_id,
        v_check_in.venue_id,
        p_offer_id,
        v_offer.offer_version_id,
        v_offer.schedule_id,
        p_check_in_id,
        v_check_in.nightlife_date,
        p_idempotency_key,
        v_unlocked_at,
        v_unlocked_at + make_interval(
          secs => least(
            coalesce(v_offer.claim_duration_seconds, v_maximum_claim_lifetime_seconds),
            v_maximum_claim_lifetime_seconds
          )
        ),
        'active',
        upper(substr(replace(v_claim_id::text, '-', ''), 1, 8))
      )
      returning * into v_claim;
    end if;
  end if;

  return query
  select
    v_claim.id,
    offer_record.id,
    version_record.id,
    offer_record.venue_id,
    offer_record.offer_kind,
    version_record.public_title,
    version_record.short_explanation,
    version_record.cta_label,
    version_record.redemption_mode,
    version_record.destination_url,
    version_record.staff_display_title,
    version_record.staff_instruction,
    version_record.fine_print,
    version_record.claim_duration_seconds,
    version_record.presentation_kind,
    version_record.sponsor_display_name,
    version_record.sponsor_logo_storage_path,
    version_record.sponsor_logo_alt_text,
    version_record.sponsor_disclosure,
    version_record.discovery_treatment,
    version_record.discovery_badge_label,
    version_record.discovery_icon_key,
    v_claim.unlocked_at,
    v_claim.expires_at,
    case
      when v_claim.status = 'active'
        and v_claim.expires_at is not null
        and v_claim.expires_at <= clock_timestamp()
        then 'expired'
      else v_claim.status
    end,
    v_claim.staff_reference
  from public.offers as offer_record
  join public.offer_versions as version_record
    on version_record.id = v_claim.offer_version_id
    and version_record.offer_id = offer_record.id
  where offer_record.id = v_claim.offer_id;
end;
$$;

revoke execute on function public.unlock_offer_for_check_in(uuid, uuid, uuid, uuid)
from public, anon, authenticated, service_role;
grant execute on function public.unlock_offer_for_check_in(uuid, uuid, uuid, uuid)
to service_role;

alter table public.offers enable row level security;
alter table public.offer_versions enable row level security;
alter table public.offer_schedules enable row level security;
alter table public.offer_claims enable row level security;
alter table private.partners enable row level security;
alter table private.partner_contacts enable row level security;
alter table private.partner_campaigns enable row level security;
alter table private.campaign_venues enable row level security;
alter table private.offer_campaign_links enable row level security;
alter table private.offer_claim_config enable row level security;

create policy offers_select_own_venue
on public.offers
for select
to authenticated
using (
  venue_id in (
    select own_account.venue_id
    from public.venue_accounts as own_account
    where own_account.auth_user_id = (select auth.uid())
      and own_account.account_status = 'active'
  )
);

create policy offer_versions_select_own_venue
on public.offer_versions
for select
to authenticated
using (
  offer_id in (
    select own_offer.id
    from public.offers as own_offer
    join public.venue_accounts as own_account
      on own_account.venue_id = own_offer.venue_id
    where own_account.auth_user_id = (select auth.uid())
      and own_account.account_status = 'active'
  )
);

create policy offer_schedules_select_own_venue
on public.offer_schedules
for select
to authenticated
using (
  offer_version_id in (
    select own_version.id
    from public.offer_versions as own_version
    join public.offers as own_offer on own_offer.id = own_version.offer_id
    join public.venue_accounts as own_account on own_account.venue_id = own_offer.venue_id
    where own_account.auth_user_id = (select auth.uid())
      and own_account.account_status = 'active'
  )
);

create policy offer_claims_select_own
on public.offer_claims
for select
to authenticated
using ((select auth.uid()) = user_id);

revoke all on table
  public.offers,
  public.offer_versions,
  public.offer_schedules,
  public.offer_claims
from public, anon, authenticated, service_role;

grant select on table
  public.offers,
  public.offer_versions,
  public.offer_schedules,
  public.offer_claims
to authenticated;

grant select, insert, update, delete on table
  public.offers,
  public.offer_versions,
  public.offer_schedules,
  public.offer_claims
to service_role;

revoke all on table
  private.partners,
  private.partner_contacts,
  private.partner_campaigns,
  private.campaign_venues,
  private.offer_campaign_links,
  private.offer_claim_config
from public, anon, authenticated, service_role;

grant select, insert, update, delete on table
  private.partners,
  private.partner_contacts,
  private.partner_campaigns,
  private.campaign_venues,
  private.offer_campaign_links,
  private.offer_claim_config
to service_role;
