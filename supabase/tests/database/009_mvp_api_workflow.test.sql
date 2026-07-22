begin;

set local role postgres;
set local search_path = public, extensions, pgtap;

create extension if not exists pgtap with schema extensions;

select plan(60);

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
select
  user_record.id,
  '00000000-0000-0000-0000-000000000000'::uuid,
  'authenticated',
  'authenticated',
  user_record.email,
  '',
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{}'::jsonb,
  now(),
  now()
from (
  values
    ('90000000-0000-4000-8000-000000000001'::uuid, 'founder-mvp@example.test'),
    ('90000000-0000-4000-8000-000000000002'::uuid, 'consumer-mvp@example.test'),
    ('90000000-0000-4000-8000-000000000003'::uuid, 'underage-mvp@example.test'),
    ('90000000-0000-4000-8000-000000000004'::uuid, 'venue-mvp@example.test')
) as user_record(id, email);

insert into private.internal_admins (user_id)
values ('90000000-0000-4000-8000-000000000001');

set local role service_role;

-- Consumer onboarding: DOB, required gender, server-calculated 19+, and legal
-- acceptance idempotency all live in one privileged transaction.
-- 01
select lives_ok(
  $$
    select * from public.complete_consumer_onboarding(
      '90000000-0000-4000-8000-000000000002',
      'Avery',
      '2000-01-01',
      'other',
      'terms-2026-07',
      'privacy-2026-07'
    )
  $$,
  'eligible consumer onboarding completes through the trusted RPC'
);
-- 02
select is(
  (select onboarding_status from public.consumer_profiles where user_id = '90000000-0000-4000-8000-000000000002'),
  'complete',
  'onboarding marks the consumer profile complete'
);
-- 03
select is(
  (select gender from private.consumer_eligibility where user_id = '90000000-0000-4000-8000-000000000002'),
  'other',
  'Another gender is stored using the protected other value'
);
-- 04
select ok(
  (select is_19_plus from private.consumer_eligibility where user_id = '90000000-0000-4000-8000-000000000002'),
  '19+ eligibility is calculated and stored server-side'
);
-- 05
select is(
  (select count(*)::integer from private.legal_acceptances where subject_user_id = '90000000-0000-4000-8000-000000000002'),
  2,
  'consumer onboarding records terms and privacy acceptance'
);
-- 06
select lives_ok(
  $$
    select * from public.complete_consumer_onboarding(
      '90000000-0000-4000-8000-000000000002',
      'Avery',
      '2000-01-01',
      'other',
      'terms-2026-07',
      'privacy-2026-07'
    )
  $$,
  'an identical onboarding retry is idempotent'
);
-- 07
select is(
  (select count(*)::integer from private.legal_acceptances where subject_user_id = '90000000-0000-4000-8000-000000000002'),
  2,
  'an onboarding retry does not duplicate legal acceptances'
);
-- 08
select throws_ok(
  $$
    select * from public.complete_consumer_onboarding(
      '90000000-0000-4000-8000-000000000003',
      'Jamie',
      ((clock_timestamp() at time zone 'America/Toronto')::date - interval '18 years')::date,
      'prefer_not_to_say',
      'terms-2026-07',
      'privacy-2026-07'
    )
  $$,
  '22023',
  'invalid_gender',
  'onboarding accepts only man, woman, or another gender'
);
-- 09
select throws_ok(
  $$
    select * from public.complete_consumer_onboarding(
      '90000000-0000-4000-8000-000000000003',
      'Jamie',
      ((clock_timestamp() at time zone 'America/Toronto')::date - interval '18 years')::date,
      'other',
      'terms-2026-07',
      'privacy-2026-07'
    )
  $$,
  'P0001',
  'age_requirement_not_met',
  'the backend rejects an under-19 account'
);

-- Venue self-registration creates the pending public shell, private business
-- record, legal acceptance, account, and default free entitlement atomically.
-- 10
select lives_ok(
  $$
    select * from public.register_venue_account(
      '90000000-0000-4000-8000-000000000004',
      'Signal House',
      '101 Queen St W',
      'Signal House Hospitality Inc.',
      '101 Queen St W, Toronto, ON',
      'Morgan Lee',
      'General Manager',
      'venue-mvp@example.test',
      '+1 416 555 0199',
      'venue-terms-2026-07'
    )
  $$,
  'venue self-registration completes through the trusted RPC'
);
-- 11
select is(
  (select count(*)::integer from public.venue_accounts where auth_user_id = '90000000-0000-4000-8000-000000000004'),
  1,
  'one venue account is created for the business login'
);
-- 12
select is(
  (
    select venue_record.registration_status
    from public.venues as venue_record
    join public.venue_accounts as account_record on account_record.venue_id = venue_record.id
    where account_record.auth_user_id = '90000000-0000-4000-8000-000000000004'
  ),
  'pending_review',
  'a self-registered venue waits for founder approval'
);
-- 13
select is(
  (select account_status from public.venue_accounts where auth_user_id = '90000000-0000-4000-8000-000000000004'),
  'draft',
  'the new venue login remains draft while review is pending'
);
-- 14
select ok(
  (
    select business_record.authority_to_represent_affirmed
    from private.venue_business_details as business_record
    join public.venue_accounts as account_record on account_record.venue_id = business_record.venue_id
    where account_record.auth_user_id = '90000000-0000-4000-8000-000000000004'
  ),
  'venue registration records authority to represent the business'
);
-- 15
select is(
  (
    select subscription_record.plan_code
    from private.venue_subscriptions as subscription_record
    join public.venue_accounts as account_record on account_record.venue_id = subscription_record.venue_id
    where account_record.auth_user_id = '90000000-0000-4000-8000-000000000004'
  ),
  'free',
  'every registered venue receives the free subscription by default'
);
-- 16
select is(
  (select count(*)::integer from private.legal_acceptances where subject_user_id = '90000000-0000-4000-8000-000000000004'),
  1,
  'venue registration records the venue agreement acceptance'
);
-- 17
select lives_ok(
  $$
    select * from public.register_venue_account(
      '90000000-0000-4000-8000-000000000004',
      'Signal House',
      '101 Queen St W',
      'Signal House Hospitality Inc.',
      '101 Queen St W, Toronto, ON',
      'Morgan Lee',
      'General Manager',
      'venue-mvp@example.test',
      '+1 416 555 0199',
      'venue-terms-2026-07'
    )
  $$,
  'venue registration safely retries for the same Auth account'
);
-- 18
select is(
  (select count(*)::integer from public.venue_accounts where auth_user_id = '90000000-0000-4000-8000-000000000004'),
  1,
  'a venue registration retry does not create a second venue'
);

update public.venues as venue_record
set
  registration_status = 'approved',
  publication_status = 'published',
  neighbourhood = 'Queen West',
  postal_code = 'M5H 2N2',
  location = extensions.st_setsrid(
    extensions.st_makepoint(-79.3840, 43.6520),
    4326
  )::extensions.geography,
  approved_at = clock_timestamp()
from public.venue_accounts as account_record
where account_record.venue_id = venue_record.id
  and account_record.auth_user_id = '90000000-0000-4000-8000-000000000004';

update public.venue_accounts
set account_status = 'active'
where auth_user_id = '90000000-0000-4000-8000-000000000004';

-- The free dashboard exposes only base history and suppresses demographic and
-- repeat-visitor detail. Analytics ingestion is idempotent and server-scoped.
-- 19
select lives_ok(
  $$
    select public.ingest_analytics_event(
      '90000000-0000-4000-8000-000000000002',
      'venue_impression',
      (select venue_id from public.venue_accounts where auth_user_id = '90000000-0000-4000-8000-000000000004'),
      null,
      clock_timestamp(),
      'ios',
      '1.0-test',
      'a9000000-0000-4000-8000-000000000001'
    )
  $$,
  'trusted analytics ingestion accepts an eligible venue impression'
);
-- 20
select is(
  (select count(*)::integer from private.analytics_events where user_id = '90000000-0000-4000-8000-000000000002'),
  1,
  'the analytics event is stored once'
);
-- 21
select is(
  public.get_venue_dashboard_snapshot(
    '90000000-0000-4000-8000-000000000004', null, null
  ) #>> '{subscription,plan_code}',
  'free',
  'the free dashboard resolves the effective free plan'
);
-- 22
select is(
  (public.get_venue_dashboard_snapshot(
    '90000000-0000-4000-8000-000000000004', null, null
  ) #>> '{period,maximum_history_days}')::integer,
  30,
  'the free dashboard is limited to thirty days of history'
);
-- 23
select ok(
  public.get_venue_dashboard_snapshot(
    '90000000-0000-4000-8000-000000000004', null, null
  ) #> '{demographics}' = 'null'::jsonb
  and (public.get_venue_dashboard_snapshot(
    '90000000-0000-4000-8000-000000000004', null, null
  ) #>> '{demographics_suppressed}')::boolean,
  'demographics stay suppressed below the configured privacy cohort'
);
-- 24
select is(
  public.get_venue_dashboard_snapshot(
    '90000000-0000-4000-8000-000000000004', null, null
  ) #> '{metrics,returning_visitors}',
  'null'::jsonb,
  'repeat-visitor insight is unavailable on the free plan'
);

update private.venue_subscriptions as subscription_record
set plan_code = 'pro', stripe_status = 'active'
from public.venue_accounts as account_record
where account_record.venue_id = subscription_record.venue_id
  and account_record.auth_user_id = '90000000-0000-4000-8000-000000000004';

-- 25
select is(
  public.get_venue_dashboard_snapshot(
    '90000000-0000-4000-8000-000000000004', null, null
  ) #>> '{subscription,plan_code}',
  'pro',
  'an active paid subscription enables the Pro dashboard'
);
-- 26
select is(
  (public.get_venue_dashboard_snapshot(
    '90000000-0000-4000-8000-000000000004', null, null
  ) #>> '{period,maximum_history_days}')::integer,
  365,
  'the Pro dashboard receives one year of analytics history'
);
-- 27
select ok(
  public.get_venue_dashboard_snapshot(
    '90000000-0000-4000-8000-000000000004', null, null
  ) #> '{demographics}' = 'null'::jsonb
  and (public.get_venue_dashboard_snapshot(
    '90000000-0000-4000-8000-000000000004', null, null
  ) #>> '{demographics_suppressed}')::boolean,
  'Pro never bypasses the minimum demographic cohort'
);
-- 28
select is(
  (public.get_venue_dashboard_snapshot(
    '90000000-0000-4000-8000-000000000004', null, null
  ) #>> '{metrics,returning_visitors}')::integer,
  0,
  'repeat-visitor insight becomes available on Pro without exposing identities'
);

-- Venue offer creation accepts arbitrary countdowns and NULL for no visible
-- countdown; neither path contains a ten-minute assumption.
-- 29
select lives_ok(
  $$
    select * from public.submit_venue_offer(
      '90000000-0000-4000-8000-000000000004',
      'aa000000-0000-4000-8000-000000000001',
      'Forty-five minute welcome offer',
      'Available after verified check-in.',
      'Forty-five minute welcome offer',
      'Show this active offer to your server.',
      2700,
      ((clock_timestamp() at time zone 'America/Toronto') - interval '4 hours')::date - 1,
      ((clock_timestamp() at time zone 'America/Toronto') - interval '4 hours')::date + 1,
      array[0, 1, 2, 3, 4, 5, 6]::smallint[],
      null, null, null, null, null, null,
      false
    )
  $$,
  'venue offer creation accepts a forty-five minute duration'
);
-- 30
select lives_ok(
  $$
    select * from public.submit_venue_offer(
      '90000000-0000-4000-8000-000000000004',
      'aa000000-0000-4000-8000-000000000002',
      'Open display offer',
      'Available after verified check-in.',
      'Open display offer',
      'Show this active offer to your server.',
      null,
      ((clock_timestamp() at time zone 'America/Toronto') - interval '4 hours')::date - 1,
      ((clock_timestamp() at time zone 'America/Toronto') - interval '4 hours')::date + 1,
      array[0, 1, 2, 3, 4, 5, 6]::smallint[],
      null, null, null, null, null, null,
      false
    )
  $$,
  'venue offer creation accepts NULL for no visible countdown'
);
-- 31
select is(
  (
    select version_record.claim_duration_seconds
    from public.offer_versions as version_record
    join public.offers as offer_record on offer_record.id = version_record.offer_id
    where offer_record.submission_idempotency_key = 'aa000000-0000-4000-8000-000000000001'
  ),
  2700,
  'the arbitrary duration is preserved in the immutable version'
);
-- 32
select is(
  (
    select version_record.claim_duration_seconds
    from public.offer_versions as version_record
    join public.offers as offer_record on offer_record.id = version_record.offer_id
    where offer_record.submission_idempotency_key = 'aa000000-0000-4000-8000-000000000002'
  ),
  null::integer,
  'NULL duration remains distinct from a timed offer'
);
-- 33
select lives_ok(
  $$
    select * from public.submit_venue_offer(
      '90000000-0000-4000-8000-000000000004',
      'aa000000-0000-4000-8000-000000000001',
      'Forty-five minute welcome offer',
      'Available after verified check-in.',
      'Forty-five minute welcome offer',
      'Show this active offer to your server.',
      2700,
      ((clock_timestamp() at time zone 'America/Toronto') - interval '4 hours')::date - 1,
      ((clock_timestamp() at time zone 'America/Toronto') - interval '4 hours')::date + 1,
      array[0, 1, 2, 3, 4, 5, 6]::smallint[],
      null, null, null, null, null, null,
      false
    )
  $$,
  'venue offer creation safely retries with its idempotency key'
);
-- 34
select is(
  (select count(*)::integer from public.offers where submission_idempotency_key = 'aa000000-0000-4000-8000-000000000001'),
  1,
  'an offer retry does not create a duplicate draft'
);

update public.offer_versions as version_record
set
  approval_state = 'approved',
  submitted_at = clock_timestamp(),
  approved_by = '90000000-0000-4000-8000-000000000001',
  approved_at = clock_timestamp()
from public.offers as offer_record
where offer_record.id = version_record.offer_id
  and offer_record.submission_idempotency_key = 'aa000000-0000-4000-8000-000000000001';

update public.offers as offer_record
set
  lifecycle_status = 'live',
  current_approved_version_id = version_record.id
from public.offer_versions as version_record
where version_record.offer_id = offer_record.id
  and offer_record.submission_idempotency_key = 'aa000000-0000-4000-8000-000000000001';

-- Founder-managed partner inventory is hidden on Free and appears through the
-- same eligibility contract only when the destination venue has Pro access.
insert into public.venues (
  id, slug, display_name, registration_status, publication_status,
  address_line_1, market_code, neighbourhood, city, province_code,
  postal_code, country_code, location, approved_at
)
values (
  '93000000-0000-4000-8000-000000000001',
  'afterglow-social-mvp',
  'Afterglow Social',
  'approved',
  'published',
  '220 Ossington Ave',
  'toronto',
  'Ossington',
  'Toronto',
  'ON',
  'M6J 2Z7',
  'CA',
  extensions.st_setsrid(extensions.st_makepoint(-79.4210, 43.6480), 4326)::extensions.geography,
  clock_timestamp()
);

insert into private.partners (
  id, brand_name, legal_name, status, website_url,
  approved_logo_storage_path, approved_logo_alt_text
)
values (
  '94000000-0000-4000-8000-000000000001',
  'Northline',
  'Northline Mobility Inc.',
  'active',
  'https://example.test/northline',
  'partner-media/northline/logo.webp',
  'Northline logo'
);

insert into private.partner_campaigns (
  id, partner_id, internal_name, campaign_status, approval_status,
  starts_at, ends_at, market_code, neighbourhoods, minimum_age,
  per_user_limit, public_sponsor_wording, public_reward,
  approved_disclosure, created_by, approved_by, approved_at
)
values (
  '95000000-0000-4000-8000-000000000001',
  '94000000-0000-4000-8000-000000000001',
  'Northline new rider offer',
  'live',
  'approved',
  clock_timestamp() - interval '1 day',
  clock_timestamp() + interval '1 day',
  'toronto',
  array['Ossington'],
  19,
  1,
  'Northline',
  '50% off your ride home',
  'Outly partner · New Northline riders only',
  '90000000-0000-4000-8000-000000000001',
  '90000000-0000-4000-8000-000000000001',
  clock_timestamp()
);

insert into private.campaign_venues (campaign_id, venue_id)
values (
  '95000000-0000-4000-8000-000000000001',
  '93000000-0000-4000-8000-000000000001'
);

insert into public.offers (
  id, venue_id, creator_type, offer_kind, lifecycle_status, display_priority
)
values (
  '96000000-0000-4000-8000-000000000001',
  '93000000-0000-4000-8000-000000000001',
  'outly',
  'partner',
  'live',
  100
);

insert into public.offer_versions (
  id, offer_id, version_number, public_title, short_explanation,
  cta_label, redemption_mode, destination_url, minimum_age,
  claim_duration_seconds, per_user_limit, presentation_kind,
  sponsor_display_name, sponsor_logo_storage_path, sponsor_logo_alt_text,
  sponsor_disclosure, discovery_treatment, discovery_badge_label,
  discovery_icon_key, approval_state, submitted_by, submitted_at
)
values (
  '97000000-0000-4000-8000-000000000001',
  '96000000-0000-4000-8000-000000000001',
  1,
  '50% off your ride home',
  'For new Northline riders.',
  'Unlock ride offer',
  'external_link',
  'https://getoutly.app/partners/northline',
  19,
  1200,
  1,
  'partner',
  'Northline',
  'partner-media/northline/logo.webp',
  'Northline logo',
  'Outly partner',
  'partner_featured',
  'Ride home offer',
  'northline-mark',
  'pending_review',
  '90000000-0000-4000-8000-000000000001',
  clock_timestamp()
);

insert into public.offer_schedules (
  id, offer_version_id, nightlife_start_date, nightlife_end_date
)
values (
  '98000000-0000-4000-8000-000000000001',
  '97000000-0000-4000-8000-000000000001',
  ((clock_timestamp() at time zone 'America/Toronto') - interval '4 hours')::date - 1,
  ((clock_timestamp() at time zone 'America/Toronto') - interval '4 hours')::date + 1
);

update public.offer_versions
set
  approval_state = 'approved',
  approved_by = '90000000-0000-4000-8000-000000000001',
  approved_at = clock_timestamp()
where id = '97000000-0000-4000-8000-000000000001';

update public.offers
set current_approved_version_id = '97000000-0000-4000-8000-000000000001'
where id = '96000000-0000-4000-8000-000000000001';

insert into private.offer_campaign_links (offer_id, campaign_id)
values (
  '96000000-0000-4000-8000-000000000001',
  '95000000-0000-4000-8000-000000000001'
);

-- 35
select is(
  (
    select count(*)::integer
    from public.list_eligible_offers(
      '90000000-0000-4000-8000-000000000002',
      array['93000000-0000-4000-8000-000000000001'::uuid],
      clock_timestamp()
    )
  ),
  0,
  'a partner offer stays hidden at a free venue'
);

update private.venue_subscriptions
set plan_code = 'pro', stripe_status = 'active'
where venue_id = '93000000-0000-4000-8000-000000000001';

-- 36
select is(
  (
    select count(*)::integer
    from public.list_eligible_offers(
      '90000000-0000-4000-8000-000000000002',
      array['93000000-0000-4000-8000-000000000001'::uuid],
      clock_timestamp()
    )
  ),
  1,
  'the same partner offer becomes eligible when the venue is Pro'
);
-- 37
select is(
  (
    select claim_duration_seconds
    from public.list_eligible_offers(
      '90000000-0000-4000-8000-000000000002',
      array['93000000-0000-4000-8000-000000000001'::uuid],
      clock_timestamp()
    )
  ),
  1200,
  'partner eligibility preserves its configured timer duration'
);
-- 38
select is(
  (
    select venue_payload -> 'offer' ->> 'kind'
    from jsonb_array_elements(
      public.get_consumer_bootstrap(
        '90000000-0000-4000-8000-000000000002',
        clock_timestamp()
      ) -> 'venues'
    ) as venue_payload
    where venue_payload ->> 'id' = '93000000-0000-4000-8000-000000000001'
  ),
  'partner',
  'consumer bootstrap includes premium partner discovery metadata'
);
-- 39
select ok(
  (
    select not ((venue_payload -> 'offer') ? 'destination_url')
    from jsonb_array_elements(
      public.get_consumer_bootstrap(
        '90000000-0000-4000-8000-000000000002',
        clock_timestamp()
      ) -> 'venues'
    ) as venue_payload
    where venue_payload ->> 'id' = '93000000-0000-4000-8000-000000000001'
  ),
  'bootstrap withholds the ride redemption URL until verified check-in'
);
-- 40
select ok(
  (
    select not ((venue_payload -> 'offer') ?| array['staff_display_title', 'staff_instruction'])
    from jsonb_array_elements(
      public.get_consumer_bootstrap(
        '90000000-0000-4000-8000-000000000002',
        clock_timestamp()
      ) -> 'venues'
    ) as venue_payload
    where venue_payload ->> 'id' = '93000000-0000-4000-8000-000000000001'
  ),
  'bootstrap withholds staff proof until an offer is claimed'
);
-- 41
select is(
  (
    select venue_payload -> 'offer' ->> 'sponsor_display_name'
    from jsonb_array_elements(
      public.get_consumer_bootstrap(
        '90000000-0000-4000-8000-000000000002',
        clock_timestamp()
      ) -> 'venues'
    ) as venue_payload
    where venue_payload ->> 'id' = '93000000-0000-4000-8000-000000000001'
  ),
  'Northline',
  'bootstrap retains safe sponsor branding for discovery'
);

-- All time windows are normalized to the 4:00 AM nightlife boundary.
-- 42
select is(
  private.time_is_in_window(time '21:59', null::time, time '22:00'),
  true,
  '9:59 PM is eligible for a 10 PM cutoff'
);
-- 43
select is(
  private.time_is_in_window(time '22:01', null::time, time '22:00'),
  false,
  '10:01 PM is ineligible for a 10 PM cutoff'
);
-- 44
select is(
  private.time_is_in_window(time '01:00', null::time, time '22:00'),
  false,
  '1:00 AM cannot slip through the previous 10 PM cutoff'
);
-- 45
select is(
  private.time_is_in_window(time '00:59', null::time, time '01:00'),
  true,
  'a genuine post-midnight cutoff remains supported'
);

-- Account deletion first anonymizes durable attendance and claims, removes
-- detailed events/tokens, and only then permits the Auth identity to disappear.
insert into public.night_plans (
  id, user_id, venue_id, nightlife_date, plan_status,
  request_idempotency_key
)
values (
  '9a000000-0000-4000-8000-000000000001',
  '90000000-0000-4000-8000-000000000002',
  (select venue_id from public.venue_accounts where auth_user_id = '90000000-0000-4000-8000-000000000004'),
  ((clock_timestamp() at time zone 'America/Toronto') - interval '4 hours')::date,
  'planned',
  '9a000000-0000-4000-8000-000000000002'
);

insert into public.check_ins (
  id, user_id, venue_id, plan_id, nightlife_date,
  request_idempotency_key, client_location_captured_at,
  server_requested_at, server_verified_at,
  horizontal_accuracy_metres, location_age_seconds,
  accuracy_authorization, location_authorization,
  distance_from_venue_metres, configured_radius_metres,
  maximum_sample_age_seconds, maximum_horizontal_accuracy_metres,
  nearest_venue_tie_tolerance_metres, outcome, verifier_version
)
values (
  '9b000000-0000-4000-8000-000000000001',
  '90000000-0000-4000-8000-000000000002',
  (select venue_id from public.venue_accounts where auth_user_id = '90000000-0000-4000-8000-000000000004'),
  '9a000000-0000-4000-8000-000000000001',
  ((clock_timestamp() at time zone 'America/Toronto') - interval '4 hours')::date,
  '9b000000-0000-4000-8000-000000000002',
  clock_timestamp() - interval '1 second',
  clock_timestamp() - interval '1 second',
  clock_timestamp(),
  10,
  1,
  'full',
  'when_in_use',
  5,
  75,
  30,
  75,
  1,
  'verified',
  'deletion-test'
);

insert into public.offer_claims (
  id, user_id, venue_id, offer_id, offer_version_id,
  schedule_id, check_in_id, nightlife_date,
  request_idempotency_key, unlocked_at, expires_at,
  status, staff_reference
)
select
  '9c000000-0000-4000-8000-000000000001',
  '90000000-0000-4000-8000-000000000002',
  offer_record.venue_id,
  offer_record.id,
  version_record.id,
  schedule_record.id,
  '9b000000-0000-4000-8000-000000000001',
  ((clock_timestamp() at time zone 'America/Toronto') - interval '4 hours')::date,
  '9c000000-0000-4000-8000-000000000002',
  clock_timestamp(),
  clock_timestamp() + interval '45 minutes',
  'active',
  'DELTEST1'
from public.offers as offer_record
join public.offer_versions as version_record
  on version_record.id = offer_record.current_approved_version_id
join public.offer_schedules as schedule_record
  on schedule_record.offer_version_id = version_record.id
where offer_record.submission_idempotency_key = 'aa000000-0000-4000-8000-000000000001';

insert into private.device_push_tokens (
  user_id, token, environment, bundle_id
)
values (
  '90000000-0000-4000-8000-000000000002',
  '0123456789abcdef0123456789abcdef',
  'sandbox',
  'app.getoutly.test'
);

-- 46
select lives_ok(
  $$
    select * from public.prepare_account_deletion(
      '90000000-0000-4000-8000-000000000002',
      'consumer',
      '9d000000-0000-4000-8000-000000000001'
    )
  $$,
  'consumer deletion prepares and anonymizes dependent records'
);
-- 47
select lives_ok(
  $$
    select * from public.prepare_account_deletion(
      '90000000-0000-4000-8000-000000000002',
      'consumer',
      '9d000000-0000-4000-8000-000000000001'
    )
  $$,
  'consumer deletion preparation is idempotent'
);
-- 48
select is(
  (
    select count(*)::integer
    from private.account_deletion_requests
    where request_idempotency_key = '9d000000-0000-4000-8000-000000000001'
  ),
  1,
  'an idempotent deletion retry keeps one durable request'
);
select lives_ok(
  $$
    select * from public.prepare_account_deletion(
      '90000000-0000-4000-8000-000000000002',
      'consumer',
      '9d000000-0000-4000-8000-000000000099'
    )
  $$,
  'a deletion retry with a replacement idempotency key resumes safely'
);
select is(
  (
    select count(*)::integer
    from private.account_deletion_requests
    where requester_user_id = '90000000-0000-4000-8000-000000000002'
  ),
  1,
  'a replacement idempotency key does not create a second deletion request'
);
-- 49
select is(
  (select account_status from public.consumer_profiles where user_id = '90000000-0000-4000-8000-000000000002'),
  'deletion_pending',
  'deletion preparation immediately blocks the consumer account'
);
-- 50
select ok(
  (
    select user_id is null
      and anonymized_at is not null
      and plan_status = 'cancelled'
      and cancelled_at is not null
    from public.night_plans
    where id = '9a000000-0000-4000-8000-000000000001'
  ),
  'night plan history is anonymized and the active plan is cancelled'
);
-- 51
select ok(
  (
    select user_id is null and anonymized_at is not null
    from public.check_ins
    where id = '9b000000-0000-4000-8000-000000000001'
  ),
  'verified check-in history is anonymized before Auth deletion'
);
-- 52
select ok(
  (
    select user_id is null
      and anonymized_at is not null
      and status = 'voided'
      and void_reason = 'account_deleted'
    from public.offer_claims
    where id = '9c000000-0000-4000-8000-000000000001'
  ),
  'an active offer claim is anonymized and voided during deletion'
);
-- 53
select is(
  (select count(*)::integer from private.analytics_events where user_id = '90000000-0000-4000-8000-000000000002'),
  0,
  'detailed analytics events are removed during deletion'
);
-- 54
select is(
  (select count(*)::integer from private.device_push_tokens where user_id = '90000000-0000-4000-8000-000000000002'),
  0,
  'push tokens are removed during deletion'
);

set local role postgres;

-- 55
select lives_ok(
  $$delete from auth.users where id = '90000000-0000-4000-8000-000000000002'$$,
  'the prepared Auth user can be permanently deleted without FK failure'
);

set local role service_role;

-- 56
select is(
  (
    select state
    from private.account_deletion_requests
    where request_idempotency_key = '9d000000-0000-4000-8000-000000000001'
  ),
  'completed',
  'Auth deletion durably completes the prepared application deletion audit'
);

-- 57
select lives_ok(
  $$
    select * from public.complete_account_deletion(
      (
        select id
        from private.account_deletion_requests
        where request_idempotency_key = '9d000000-0000-4000-8000-000000000001'
      )
    )
  $$,
  'completion remains idempotent after the Auth identity is gone'
);
-- 58
select ok(
  (
    select state = 'completed'
      and auth_user_id is null
      and requester_user_id is null
      and subject_reference is null
      and completed_at is not null
    from private.account_deletion_requests
    where request_idempotency_key = '9d000000-0000-4000-8000-000000000001'
  ),
  'completed consumer deletion clears identifying request references'
);

select * from finish();
rollback;
