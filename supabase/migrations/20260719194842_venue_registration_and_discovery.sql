-- Outly venue registration and discovery domain.
--
-- Venue dashboard clients receive read-only access to their own registration
-- records. Registration, moderation, publication, and media promotion are
-- trusted server workflows. Consumers receive only approved, published venue
-- data and approved media.

create table public.venues (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  display_name text not null,
  registration_status text not null default 'draft',
  publication_status text not null default 'unpublished',
  address_line_1 text,
  address_line_2 text,
  market_code text not null default 'toronto',
  neighbourhood text,
  city text,
  province_code text,
  postal_code text,
  country_code text not null default 'CA',
  location extensions.geography(Point, 4326),
  geofence_radius_metres smallint not null default 75,
  timezone text not null default 'America/Toronto',
  public_phone text,
  public_email text,
  website_url text,
  instagram_handle text,
  current_hero_asset_id uuid,
  current_marker_asset_id uuid,
  placement_state text not null default 'standard',
  approved_at timestamptz,
  suspended_at timestamptz,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint venues_slug_valid check (
    slug = btrim(slug)
    and slug = lower(slug)
    and slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'
    and char_length(slug) between 2 and 80
  ),
  constraint venues_display_name_valid check (
    display_name = btrim(display_name)
    and char_length(display_name) between 1 and 100
  ),
  constraint venues_registration_status_valid check (
    registration_status in (
      'draft',
      'pending_review',
      'changes_requested',
      'approved',
      'rejected',
      'suspended',
      'archived'
    )
  ),
  constraint venues_publication_status_valid check (
    publication_status in ('unpublished', 'published', 'paused')
  ),
  constraint venues_market_code_valid check (
    market_code = btrim(market_code)
    and market_code = lower(market_code)
    and char_length(market_code) between 2 and 40
  ),
  constraint venues_country_code_valid check (
    country_code ~ '^[A-Z]{2}$'
  ),
  constraint venues_province_code_valid check (
    province_code is null or province_code ~ '^[A-Z]{2,3}$'
  ),
  constraint venues_geofence_radius_safe check (
    geofence_radius_metres between 25 and 200
  ),
  constraint venues_timezone_valid check (
    timezone = btrim(timezone)
    and char_length(timezone) between 3 and 64
    and timezone ~ '^[A-Za-z_+-]+(?:/[A-Za-z0-9_+-]+)+$'
  ),
  constraint venues_optional_text_trimmed check (
    (address_line_1 is null or address_line_1 = btrim(address_line_1))
    and (address_line_2 is null or address_line_2 = btrim(address_line_2))
    and (neighbourhood is null or neighbourhood = btrim(neighbourhood))
    and (city is null or city = btrim(city))
    and (postal_code is null or postal_code = btrim(postal_code))
    and (public_phone is null or public_phone = btrim(public_phone))
    and (public_email is null or public_email = btrim(public_email))
    and (website_url is null or website_url = btrim(website_url))
    and (instagram_handle is null or instagram_handle = btrim(instagram_handle))
  ),
  constraint venues_optional_text_lengths check (
    (address_line_1 is null or char_length(address_line_1) between 1 and 160)
    and (address_line_2 is null or char_length(address_line_2) between 1 and 160)
    and (neighbourhood is null or char_length(neighbourhood) between 1 and 80)
    and (city is null or char_length(city) between 1 and 80)
    and (postal_code is null or char_length(postal_code) between 2 and 16)
    and (public_phone is null or char_length(public_phone) between 7 and 32)
    and (public_email is null or char_length(public_email) between 3 and 254)
    and (website_url is null or char_length(website_url) between 8 and 2048)
    and (instagram_handle is null or char_length(instagram_handle) between 1 and 30)
  ),
  constraint venues_public_email_shape check (
    public_email is null or position('@' in public_email) > 1
  ),
  constraint venues_website_scheme check (
    website_url is null or website_url ~ '^https://'
  ),
  constraint venues_instagram_handle_shape check (
    instagram_handle is null or instagram_handle ~ '^[A-Za-z0-9._]+$'
  ),
  constraint venues_placement_state_valid check (
    placement_state in ('standard', 'featured')
  ),
  constraint venues_approval_timestamp_consistent check (
    registration_status not in ('approved', 'suspended', 'archived')
    or approved_at is not null
  ),
  constraint venues_suspension_timestamp_consistent check (
    (registration_status = 'suspended' and suspended_at is not null)
    or (registration_status <> 'suspended' and suspended_at is null)
  ),
  constraint venues_archive_timestamp_consistent check (
    (registration_status = 'archived' and archived_at is not null)
    or (registration_status <> 'archived' and archived_at is null)
  ),
  constraint venues_publication_consistent check (
    publication_status <> 'published'
    or (
      registration_status = 'approved'
      and approved_at is not null
      and address_line_1 is not null
      and neighbourhood is not null
      and city is not null
      and province_code is not null
      and postal_code is not null
      and location is not null
    )
  )
);

comment on table public.venues is
  'Current venue record. Consumers receive only founder-approved, published rows through RLS.';
comment on column public.venues.location is
  'Authoritative venue point, longitude first and latitude second. Never supplied by the consumer check-in client.';
comment on column public.venues.geofence_radius_metres is
  'Server-controlled check-in radius. Defaults to 75 metres and is constrained to 25-200 metres.';
comment on column public.venues.current_marker_asset_id is
  'Current approved paid custom marker, if any. Entitlement enforcement belongs to the publishing workflow.';

create index venues_location_gix
  on public.venues using gist (location);
create index venues_discovery_idx
  on public.venues (market_code, neighbourhood, display_name)
  where registration_status = 'approved'
    and publication_status = 'published';
create index venues_review_queue_idx
  on public.venues (registration_status, created_at)
  where registration_status in ('pending_review', 'changes_requested');
create index venues_current_hero_asset_id_idx
  on public.venues (current_hero_asset_id)
  where current_hero_asset_id is not null;
create index venues_current_marker_asset_id_idx
  on public.venues (current_marker_asset_id)
  where current_marker_asset_id is not null;

create table public.venue_accounts (
  auth_user_id uuid primary key references auth.users (id) on delete cascade,
  venue_id uuid not null unique references public.venues (id) on delete cascade,
  account_status text not null default 'draft',
  last_login_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint venue_accounts_status_valid check (
    account_status in ('draft', 'active', 'suspended', 'deletion_pending', 'deleted')
  )
);

comment on table public.venue_accounts is
  'One business Auth login per venue for the MVP. Passwords and canonical login emails remain in Supabase Auth.';

create table private.venue_business_details (
  venue_id uuid primary key references public.venues (id) on delete cascade,
  legal_business_name text not null,
  legal_address text not null,
  primary_contact_name text not null,
  primary_contact_title text,
  business_email text not null,
  business_phone text not null,
  authority_to_represent_affirmed boolean not null default false,
  venue_agreement_version text not null,
  registration_submitted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint venue_business_details_required_text_valid check (
    legal_business_name = btrim(legal_business_name)
    and char_length(legal_business_name) between 1 and 160
    and legal_address = btrim(legal_address)
    and char_length(legal_address) between 5 and 300
    and primary_contact_name = btrim(primary_contact_name)
    and char_length(primary_contact_name) between 1 and 120
    and business_email = btrim(business_email)
    and char_length(business_email) between 3 and 254
    and position('@' in business_email) > 1
    and business_phone = btrim(business_phone)
    and char_length(business_phone) between 7 and 32
    and venue_agreement_version = btrim(venue_agreement_version)
    and char_length(venue_agreement_version) between 1 and 80
  ),
  constraint venue_business_details_optional_title_valid check (
    primary_contact_title is null
    or (
      primary_contact_title = btrim(primary_contact_title)
      and char_length(primary_contact_title) between 1 and 100
    )
  ),
  constraint venue_business_details_submission_consistent check (
    registration_submitted_at is null
    or authority_to_represent_affirmed
  )
);

comment on table private.venue_business_details is
  'Private legal, registration, and primary business-contact data. Never exposed through the Data API.';

create table public.venue_hours (
  id bigint generated always as identity primary key,
  venue_id uuid not null references public.venues (id) on delete cascade,
  weekday smallint not null,
  interval_number smallint not null default 1,
  opens_at time,
  closes_at time,
  is_closed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint venue_hours_weekday_valid check (weekday between 0 and 6),
  constraint venue_hours_interval_number_valid check (interval_number between 1 and 2),
  constraint venue_hours_time_state_consistent check (
    (is_closed and opens_at is null and closes_at is null)
    or (not is_closed and opens_at is not null and closes_at is not null)
  ),
  constraint venue_hours_once_per_interval unique (venue_id, weekday, interval_number)
);

comment on table public.venue_hours is
  'Recurring venue-local hours. Weekday 0 is Sunday; a close earlier than open crosses midnight.';

create table public.venue_hour_exceptions (
  id bigint generated always as identity primary key,
  venue_id uuid not null references public.venues (id) on delete cascade,
  local_date date not null,
  interval_number smallint not null default 1,
  opens_at time,
  closes_at time,
  is_closed boolean not null default false,
  public_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint venue_hour_exceptions_interval_number_valid check (
    interval_number between 1 and 2
  ),
  constraint venue_hour_exceptions_time_state_consistent check (
    (is_closed and opens_at is null and closes_at is null)
    or (not is_closed and opens_at is not null and closes_at is not null)
  ),
  constraint venue_hour_exceptions_public_note_valid check (
    public_note is null
    or (
      public_note = btrim(public_note)
      and char_length(public_note) between 1 and 120
    )
  ),
  constraint venue_hour_exceptions_once_per_interval unique (
    venue_id,
    local_date,
    interval_number
  )
);

create table public.venue_assets (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references public.venues (id) on delete cascade,
  asset_kind text not null,
  storage_bucket text not null,
  storage_path text not null,
  alt_text text not null,
  moderation_status text not null default 'pending_review',
  uploaded_by uuid references auth.users (id) on delete set null,
  requires_paid_entitlement boolean not null default false,
  pixel_width integer,
  pixel_height integer,
  mime_type text not null,
  reviewed_by uuid references auth.users (id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint venue_assets_kind_valid check (
    asset_kind in ('hero', 'gallery', 'marker')
  ),
  constraint venue_assets_storage_bucket_valid check (
    storage_bucket in ('venue-media-submissions', 'venue-media')
  ),
  constraint venue_assets_storage_path_valid check (
    storage_path = btrim(storage_path)
    and char_length(storage_path) between 38 and 1024
    and storage_path like venue_id::text || '/%'
  ),
  constraint venue_assets_alt_text_valid check (
    alt_text = btrim(alt_text)
    and char_length(alt_text) between 1 and 180
  ),
  constraint venue_assets_moderation_status_valid check (
    moderation_status in ('pending_review', 'approved', 'rejected', 'removed')
  ),
  constraint venue_assets_bucket_matches_moderation check (
    (moderation_status = 'approved' and storage_bucket = 'venue-media')
    or (
      moderation_status <> 'approved'
      and storage_bucket = 'venue-media-submissions'
    )
  ),
  constraint venue_assets_review_timestamp_consistent check (
    (moderation_status = 'pending_review' and reviewed_at is null)
    or (moderation_status <> 'pending_review' and reviewed_at is not null)
  ),
  constraint venue_assets_paid_marker_consistent check (
    (asset_kind = 'marker' and requires_paid_entitlement)
    or (asset_kind <> 'marker' and not requires_paid_entitlement)
  ),
  constraint venue_assets_dimensions_consistent check (
    (pixel_width is null and pixel_height is null)
    or (pixel_width between 1 and 12000 and pixel_height between 1 and 12000)
  ),
  constraint venue_assets_mime_type_valid check (
    mime_type in ('image/jpeg', 'image/png', 'image/webp')
  ),
  constraint venue_assets_storage_object_unique unique (storage_bucket, storage_path),
  constraint venue_assets_same_venue_reference unique (id, venue_id)
);

comment on table public.venue_assets is
  'Metadata for submitted and approved venue media. Only approved objects are promoted into the public venue-media bucket.';

create index venue_assets_venue_moderation_kind_idx
  on public.venue_assets (venue_id, moderation_status, asset_kind);
create index venue_assets_uploaded_by_idx
  on public.venue_assets (uploaded_by)
  where uploaded_by is not null;
create index venue_assets_reviewed_by_idx
  on public.venue_assets (reviewed_by)
  where reviewed_by is not null;

create table public.venue_profile_revisions (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references public.venues (id) on delete cascade,
  submitted_by uuid references auth.users (id) on delete set null,
  display_name text,
  address_line_1 text,
  address_line_2 text,
  market_code text,
  neighbourhood text,
  city text,
  province_code text,
  postal_code text,
  country_code text,
  location extensions.geography(Point, 4326),
  requested_marker_asset_id uuid,
  revision_status text not null default 'draft',
  public_review_response text,
  reviewed_by uuid references auth.users (id) on delete set null,
  submitted_at timestamptz,
  reviewed_at timestamptz,
  applied_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint venue_profile_revisions_status_valid check (
    revision_status in (
      'draft',
      'pending_review',
      'changes_requested',
      'approved',
      'rejected',
      'superseded'
    )
  ),
  constraint venue_profile_revisions_display_name_valid check (
    display_name is null
    or (
      display_name = btrim(display_name)
      and char_length(display_name) between 1 and 100
    )
  ),
  constraint venue_profile_revisions_text_trimmed check (
    (address_line_1 is null or address_line_1 = btrim(address_line_1))
    and (address_line_2 is null or address_line_2 = btrim(address_line_2))
    and (market_code is null or market_code = lower(btrim(market_code)))
    and (neighbourhood is null or neighbourhood = btrim(neighbourhood))
    and (city is null or city = btrim(city))
    and (postal_code is null or postal_code = btrim(postal_code))
  ),
  constraint venue_profile_revisions_country_code_valid check (
    country_code is null or country_code ~ '^[A-Z]{2}$'
  ),
  constraint venue_profile_revisions_province_code_valid check (
    province_code is null or province_code ~ '^[A-Z]{2,3}$'
  ),
  constraint venue_profile_revisions_review_response_valid check (
    public_review_response is null
    or (
      public_review_response = btrim(public_review_response)
      and char_length(public_review_response) between 1 and 1000
    )
  ),
  constraint venue_profile_revisions_submission_consistent check (
    revision_status = 'draft'
    or (
      display_name is not null
      and address_line_1 is not null
      and market_code is not null
      and neighbourhood is not null
      and city is not null
      and province_code is not null
      and postal_code is not null
      and country_code is not null
      and location is not null
      and submitted_at is not null
    )
  ),
  constraint venue_profile_revisions_review_consistent check (
    (
      revision_status in ('approved', 'rejected', 'changes_requested')
      and reviewed_at is not null
    )
    or (
      revision_status not in ('approved', 'rejected', 'changes_requested')
      and reviewed_at is null
    )
  ),
  constraint venue_profile_revisions_applied_consistent check (
    (revision_status = 'approved' and applied_at is not null)
    or (revision_status <> 'approved' and applied_at is null)
  )
);

comment on table public.venue_profile_revisions is
  'Review queue for critical public name, address, coordinate, and custom-marker changes while the approved venue stays live.';

create index venue_profile_revisions_venue_status_created_idx
  on public.venue_profile_revisions (venue_id, revision_status, created_at desc);
create index venue_profile_revisions_submitted_by_idx
  on public.venue_profile_revisions (submitted_by)
  where submitted_by is not null;
create index venue_profile_revisions_reviewed_by_idx
  on public.venue_profile_revisions (reviewed_by)
  where reviewed_by is not null;
create index venue_profile_revisions_marker_asset_idx
  on public.venue_profile_revisions (requested_marker_asset_id)
  where requested_marker_asset_id is not null;

create table public.venue_events (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references public.venues (id) on delete cascade,
  title text not null,
  short_description text,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  image_asset_id uuid,
  external_url text,
  event_status text not null default 'draft',
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint venue_events_title_valid check (
    title = btrim(title) and char_length(title) between 1 and 120
  ),
  constraint venue_events_short_description_valid check (
    short_description is null
    or (
      short_description = btrim(short_description)
      and char_length(short_description) between 1 and 500
    )
  ),
  constraint venue_events_timing_valid check (ends_at > starts_at),
  constraint venue_events_external_url_valid check (
    external_url is null
    or (
      external_url = btrim(external_url)
      and char_length(external_url) between 8 and 2048
      and external_url ~ '^https://'
    )
  ),
  constraint venue_events_status_valid check (
    event_status in ('draft', 'published', 'cancelled', 'ended')
  )
);

comment on table public.venue_events is
  'Venue-created events. Consumers receive only published events belonging to approved, published venues.';

create index venue_events_venue_status_start_idx
  on public.venue_events (venue_id, event_status, starts_at);
create index venue_events_created_by_idx
  on public.venue_events (created_by)
  where created_by is not null;
create index venue_events_image_asset_id_idx
  on public.venue_events (image_asset_id)
  where image_asset_id is not null;

create table private.venue_reviews (
  id bigint generated always as identity primary key,
  venue_id uuid not null references public.venues (id) on delete cascade,
  revision_id uuid references public.venue_profile_revisions (id) on delete set null,
  reviewer_id uuid references auth.users (id) on delete set null,
  decision text not null,
  public_response text,
  private_note text,
  created_at timestamptz not null default now(),

  constraint venue_reviews_decision_valid check (
    decision in (
      'approved',
      'changes_requested',
      'rejected',
      'suspended',
      'reinstated',
      'archived'
    )
  ),
  constraint venue_reviews_public_response_valid check (
    public_response is null
    or (
      public_response = btrim(public_response)
      and char_length(public_response) between 1 and 1000
    )
  ),
  constraint venue_reviews_private_note_valid check (
    private_note is null
    or (
      private_note = btrim(private_note)
      and char_length(private_note) between 1 and 4000
    )
  )
);

comment on table private.venue_reviews is
  'Founder-only review history, including private moderation notes.';

create index venue_reviews_venue_created_idx
  on private.venue_reviews (venue_id, created_at desc);
create index venue_reviews_revision_id_idx
  on private.venue_reviews (revision_id)
  where revision_id is not null;
create index venue_reviews_reviewer_id_idx
  on private.venue_reviews (reviewer_id)
  where reviewer_id is not null;

-- Composite references prevent a venue from selecting another venue's asset.
alter table public.venues
  add constraint venues_current_hero_asset_same_venue_fk
  foreign key (current_hero_asset_id, id)
  references public.venue_assets (id, venue_id);

alter table public.venues
  add constraint venues_current_marker_asset_same_venue_fk
  foreign key (current_marker_asset_id, id)
  references public.venue_assets (id, venue_id);

alter table public.venue_profile_revisions
  add constraint venue_profile_revisions_marker_same_venue_fk
  foreign key (requested_marker_asset_id, venue_id)
  references public.venue_assets (id, venue_id);

alter table public.venue_events
  add constraint venue_events_image_same_venue_fk
  foreign key (image_asset_id, venue_id)
  references public.venue_assets (id, venue_id);

-- Reuse the security-invoker timestamp trigger created in the foundation.
create trigger venues_set_updated_at
before update on public.venues
for each row execute function private.set_updated_at();

create trigger venue_accounts_set_updated_at
before update on public.venue_accounts
for each row execute function private.set_updated_at();

create trigger venue_business_details_set_updated_at
before update on private.venue_business_details
for each row execute function private.set_updated_at();

create trigger venue_hours_set_updated_at
before update on public.venue_hours
for each row execute function private.set_updated_at();

create trigger venue_hour_exceptions_set_updated_at
before update on public.venue_hour_exceptions
for each row execute function private.set_updated_at();

create trigger venue_assets_set_updated_at
before update on public.venue_assets
for each row execute function private.set_updated_at();

create trigger venue_profile_revisions_set_updated_at
before update on public.venue_profile_revisions
for each row execute function private.set_updated_at();

create trigger venue_events_set_updated_at
before update on public.venue_events
for each row execute function private.set_updated_at();

-- RLS is the row boundary; explicit grants below are the API boundary.
alter table public.venues enable row level security;
alter table public.venue_accounts enable row level security;
alter table private.venue_business_details enable row level security;
alter table public.venue_hours enable row level security;
alter table public.venue_hour_exceptions enable row level security;
alter table public.venue_assets enable row level security;
alter table public.venue_profile_revisions enable row level security;
alter table public.venue_events enable row level security;
alter table private.venue_reviews enable row level security;

create policy venue_accounts_select_own
on public.venue_accounts
for select
to authenticated
using ((select auth.uid()) = auth_user_id);

create policy venues_select_published_or_owned
on public.venues
for select
to authenticated
using (
  (
    registration_status = 'approved'
    and publication_status = 'published'
  )
  or exists (
    select 1
    from public.venue_accounts as own_account
    where own_account.venue_id = venues.id
      and own_account.auth_user_id = (select auth.uid())
      and own_account.account_status <> 'deleted'
  )
);

create policy venue_hours_select_visible_venue
on public.venue_hours
for select
to authenticated
using (
  exists (
    select 1
    from public.venues as parent_venue
    where parent_venue.id = venue_hours.venue_id
      and (
        (
          parent_venue.registration_status = 'approved'
          and parent_venue.publication_status = 'published'
        )
        or exists (
          select 1
          from public.venue_accounts as own_account
          where own_account.venue_id = parent_venue.id
            and own_account.auth_user_id = (select auth.uid())
            and own_account.account_status <> 'deleted'
        )
      )
  )
);

create policy venue_hour_exceptions_select_visible_venue
on public.venue_hour_exceptions
for select
to authenticated
using (
  exists (
    select 1
    from public.venues as parent_venue
    where parent_venue.id = venue_hour_exceptions.venue_id
      and (
        (
          parent_venue.registration_status = 'approved'
          and parent_venue.publication_status = 'published'
        )
        or exists (
          select 1
          from public.venue_accounts as own_account
          where own_account.venue_id = parent_venue.id
            and own_account.auth_user_id = (select auth.uid())
            and own_account.account_status <> 'deleted'
        )
      )
  )
);

create policy venue_assets_select_approved_or_owned
on public.venue_assets
for select
to authenticated
using (
  (
    moderation_status = 'approved'
    and storage_bucket = 'venue-media'
    and exists (
      select 1
      from public.venues as parent_venue
      where parent_venue.id = venue_assets.venue_id
        and parent_venue.registration_status = 'approved'
        and parent_venue.publication_status = 'published'
    )
  )
  or exists (
    select 1
    from public.venue_accounts as own_account
    where own_account.venue_id = venue_assets.venue_id
      and own_account.auth_user_id = (select auth.uid())
      and own_account.account_status <> 'deleted'
  )
);

create policy venue_profile_revisions_select_owned
on public.venue_profile_revisions
for select
to authenticated
using (
  exists (
    select 1
    from public.venue_accounts as own_account
    where own_account.venue_id = venue_profile_revisions.venue_id
      and own_account.auth_user_id = (select auth.uid())
      and own_account.account_status <> 'deleted'
  )
);

create policy venue_events_select_published_or_owned
on public.venue_events
for select
to authenticated
using (
  (
    event_status = 'published'
    and exists (
      select 1
      from public.venues as parent_venue
      where parent_venue.id = venue_events.venue_id
        and parent_venue.registration_status = 'approved'
        and parent_venue.publication_status = 'published'
    )
  )
  or exists (
    select 1
    from public.venue_accounts as own_account
    where own_account.venue_id = venue_events.venue_id
      and own_account.auth_user_id = (select auth.uid())
      and own_account.account_status <> 'deleted'
  )
);

-- Opt in only the reads needed by the authenticated iOS and dashboard clients.
revoke all on table
  public.venues,
  public.venue_accounts,
  public.venue_hours,
  public.venue_hour_exceptions,
  public.venue_assets,
  public.venue_profile_revisions,
  public.venue_events
from public, anon, authenticated, service_role;

grant select on table
  public.venues,
  public.venue_accounts,
  public.venue_hours,
  public.venue_hour_exceptions,
  public.venue_assets,
  public.venue_profile_revisions,
  public.venue_events
to authenticated;

grant select, insert, update, delete on table
  public.venues,
  public.venue_accounts,
  public.venue_hours,
  public.venue_hour_exceptions,
  public.venue_assets,
  public.venue_profile_revisions,
  public.venue_events
to service_role;

grant usage, select on sequence
  public.venue_hours_id_seq,
  public.venue_hour_exceptions_id_seq
to service_role;

revoke all on table
  private.venue_business_details,
  private.venue_reviews
from public, anon, authenticated, service_role;

grant select, insert, update, delete on table
  private.venue_business_details,
  private.venue_reviews
to service_role;

grant usage, select on sequence private.venue_reviews_id_seq to service_role;

-- Submitted files stay private. Only server-approved copies enter the public
-- bucket, so a pending or rejected upload never gains a public URL.
insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values
  (
    'venue-media-submissions',
    'venue-media-submissions',
    false,
    15728640,
    array['image/jpeg', 'image/png', 'image/webp']::text[]
  ),
  (
    'venue-media',
    'venue-media',
    true,
    15728640,
    array['image/jpeg', 'image/png', 'image/webp']::text[]
  )
on conflict (id) do update
set
  name = excluded.name,
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- No authenticated storage.objects policy is created here. Uploads and media
-- promotion are trusted server operations, not direct browser writes.
