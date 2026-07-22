begin;

set local role postgres;
set local search_path = public, extensions, pgtap;

create extension if not exists pgtap with schema extensions;

select plan(37);

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
    ('a1000000-0000-4000-8000-000000000001'::uuid, 'founder@example.test'),
    ('a2000000-0000-4000-8000-000000000002'::uuid, 'partner-consumer@example.test'),
    ('a3000000-0000-4000-8000-000000000003'::uuid, 'standard-consumer@example.test'),
    ('a4000000-0000-4000-8000-000000000004'::uuid, 'stale-consumer@example.test'),
    ('a5000000-0000-4000-8000-000000000005'::uuid, 'venue@example.test')
) as user_record(id, email);

insert into private.internal_admins (user_id)
values ('a1000000-0000-4000-8000-000000000001');

insert into public.consumer_profiles (
  user_id, first_name, onboarding_status, onboarding_completed_at
)
values
  ('a2000000-0000-4000-8000-000000000002', 'Partner', 'complete', now()),
  ('a3000000-0000-4000-8000-000000000003', 'Standard', 'complete', now()),
  ('a4000000-0000-4000-8000-000000000004', 'Stale', 'complete', now());

insert into private.consumer_eligibility (
  user_id, date_of_birth, gender, is_19_plus, age_eligibility_checked_at
)
values
  ('a2000000-0000-4000-8000-000000000002', (current_date - interval '21 years')::date, 'other', true, now()),
  ('a3000000-0000-4000-8000-000000000003', (current_date - interval '30 years')::date, 'woman', true, now()),
  ('a4000000-0000-4000-8000-000000000004', (current_date - interval '30 years')::date, 'man', true, now());

insert into public.venues (
  id, slug, display_name, registration_status, publication_status,
  address_line_1, market_code, neighbourhood, city, province_code,
  postal_code, country_code, location, approved_at
)
values
  (
    'b1000000-0000-4000-8000-000000000001',
    'vesper-row-offers',
    'Vesper Row',
    'approved',
    'published',
    '100 Ossington Ave',
    'toronto',
    'Ossington',
    'Toronto',
    'ON',
    'M6J 2Z4',
    'CA',
    extensions.st_setsrid(extensions.st_makepoint(-79.4207, 43.6466), 4326)::extensions.geography,
    now()
  ),
  (
    'b2000000-0000-4000-8000-000000000002',
    'halide-house-offers',
    'Halide House',
    'approved',
    'published',
    '200 King St W',
    'toronto',
    'King West',
    'Toronto',
    'ON',
    'M5V 1J2',
    'CA',
    extensions.st_setsrid(extensions.st_makepoint(-79.3890, 43.6468), 4326)::extensions.geography,
    now()
  );

insert into public.venue_accounts (auth_user_id, venue_id, account_status)
values (
  'a5000000-0000-4000-8000-000000000005',
  'b1000000-0000-4000-8000-000000000001',
  'active'
);

update private.venue_subscriptions
set plan_code = 'pro', stripe_status = 'active'
where venue_id = 'b1000000-0000-4000-8000-000000000001';

insert into private.partners (
  id, brand_name, legal_name, status, website_url,
  approved_logo_storage_path, approved_logo_alt_text
)
values (
  'c1000000-0000-4000-8000-000000000001',
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
  'c2000000-0000-4000-8000-000000000002',
  'c1000000-0000-4000-8000-000000000001',
  'Northline new rider credit',
  'live',
  'approved',
  clock_timestamp() - interval '1 day',
  clock_timestamp() + interval '1 day',
  'toronto',
  array['Ossington'],
  25,
  100,
  'Northline',
  '50% off your ride home',
  'Outly partner · New Northline riders only',
  'a1000000-0000-4000-8000-000000000001',
  'a1000000-0000-4000-8000-000000000001',
  now()
);

insert into private.campaign_venues (
  campaign_id, venue_id, claim_limit_override
)
values (
  'c2000000-0000-4000-8000-000000000002',
  'b1000000-0000-4000-8000-000000000001',
  1
);

insert into public.offers (
  id, venue_id, creator_type, offer_kind, lifecycle_status, display_priority
)
values
  ('d1000000-0000-4000-8000-000000000001', 'b1000000-0000-4000-8000-000000000001', 'outly', 'partner', 'live', 20),
  ('d2000000-0000-4000-8000-000000000002', 'b1000000-0000-4000-8000-000000000001', 'outly', 'partner', 'live', 10),
  ('d3000000-0000-4000-8000-000000000003', 'b2000000-0000-4000-8000-000000000002', 'venue', 'standard', 'live', 0);

insert into public.offer_versions (
  id, offer_id, version_number, public_title, short_explanation,
  cta_label, redemption_mode, destination_url, minimum_age,
  claim_duration_seconds, per_user_limit, presentation_kind,
  sponsor_display_name, sponsor_logo_storage_path, sponsor_logo_alt_text,
  sponsor_disclosure, discovery_treatment, discovery_badge_label,
  discovery_icon_key, approval_state, submitted_by, approved_by,
  submitted_at, approved_at
)
values
  (
    'e1000000-0000-4000-8000-000000000001',
    'd1000000-0000-4000-8000-000000000001',
    1,
    '50% off your ride home',
    'For new Northline riders.',
    'Sign up with Northline',
    'external_link',
    'https://getoutly.app/partners/northline',
    19,
    1800,
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
    'a1000000-0000-4000-8000-000000000001',
    null,
    now(),
    null
  ),
  (
    'e2000000-0000-4000-8000-000000000002',
    'd2000000-0000-4000-8000-000000000002',
    1,
    'Northline late-night credit',
    'For new Northline riders.',
    'Sign up with Northline',
    'external_link',
    'https://getoutly.app/partners/northline',
    19,
    1800,
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
    'a1000000-0000-4000-8000-000000000001',
    null,
    now(),
    null
  );

insert into public.offer_versions (
  id, offer_id, version_number, public_title, short_explanation,
  staff_display_title, staff_instruction, cta_label, redemption_mode,
  minimum_age, claim_duration_seconds, per_user_limit,
  presentation_kind, discovery_treatment, discovery_badge_label,
  discovery_icon_key, approval_state, submitted_by, approved_by,
  submitted_at, approved_at
)
values (
  'e3000000-0000-4000-8000-000000000003',
  'd3000000-0000-4000-8000-000000000003',
  1,
  'Complimentary coat check',
  'Available after verified check-in.',
  'Complimentary coat check',
  'Show this active offer to your server.',
  'Show offer',
  'staff_display',
  19,
  null,
  1,
  'standard',
  'outly_exclusive',
  'Outly exclusive',
  'outly-winged-o',
  'pending_review',
  'a1000000-0000-4000-8000-000000000001',
  null,
  now(),
  null
);

insert into public.offer_schedules (
  id, offer_version_id, nightlife_start_date, nightlife_end_date
)
values
  (
    'f1000000-0000-4000-8000-000000000001',
    'e1000000-0000-4000-8000-000000000001',
    ((clock_timestamp() at time zone 'America/Toronto') - interval '4 hours')::date - 1,
    ((clock_timestamp() at time zone 'America/Toronto') - interval '4 hours')::date + 1
  ),
  (
    'f2000000-0000-4000-8000-000000000002',
    'e2000000-0000-4000-8000-000000000002',
    ((clock_timestamp() at time zone 'America/Toronto') - interval '4 hours')::date - 1,
    ((clock_timestamp() at time zone 'America/Toronto') - interval '4 hours')::date + 1
  ),
  (
    'f3000000-0000-4000-8000-000000000003',
    'e3000000-0000-4000-8000-000000000003',
    ((clock_timestamp() at time zone 'America/Toronto') - interval '4 hours')::date - 1,
    ((clock_timestamp() at time zone 'America/Toronto') - interval '4 hours')::date + 1
  );

update public.offer_versions
set
  approval_state = 'approved',
  approved_by = 'a1000000-0000-4000-8000-000000000001',
  approved_at = now()
where id in (
  'e1000000-0000-4000-8000-000000000001',
  'e2000000-0000-4000-8000-000000000002',
  'e3000000-0000-4000-8000-000000000003'
);

update public.offers
set current_approved_version_id = case id
  when 'd1000000-0000-4000-8000-000000000001' then 'e1000000-0000-4000-8000-000000000001'::uuid
  when 'd2000000-0000-4000-8000-000000000002' then 'e2000000-0000-4000-8000-000000000002'::uuid
  when 'd3000000-0000-4000-8000-000000000003' then 'e3000000-0000-4000-8000-000000000003'::uuid
end;

insert into private.offer_campaign_links (offer_id, campaign_id)
values
  ('d1000000-0000-4000-8000-000000000001', 'c2000000-0000-4000-8000-000000000002'),
  ('d2000000-0000-4000-8000-000000000002', 'c2000000-0000-4000-8000-000000000002');

insert into public.check_ins (
  id, user_id, venue_id, nightlife_date, request_idempotency_key,
  client_location_captured_at, server_requested_at, server_verified_at,
  horizontal_accuracy_metres, location_age_seconds,
  accuracy_authorization, location_authorization,
  distance_from_venue_metres, configured_radius_metres,
  maximum_sample_age_seconds, maximum_horizontal_accuracy_metres,
  nearest_venue_tie_tolerance_metres, outcome, verifier_version
)
values
  (
    '91000000-0000-4000-8000-000000000001',
    'a2000000-0000-4000-8000-000000000002',
    'b1000000-0000-4000-8000-000000000001',
    ((clock_timestamp() at time zone 'America/Toronto') - interval '4 hours')::date,
    '92000000-0000-4000-8000-000000000001',
    clock_timestamp() - interval '61 seconds',
    clock_timestamp() - interval '60 seconds',
    clock_timestamp() - interval '60 seconds',
    10, 1, 'full', 'when_in_use', 5, 75, 30, 75, 1,
    'verified', 'offer-test'
  ),
  (
    '91000000-0000-4000-8000-000000000002',
    'a3000000-0000-4000-8000-000000000003',
    'b2000000-0000-4000-8000-000000000002',
    ((clock_timestamp() at time zone 'America/Toronto') - interval '4 hours')::date,
    '92000000-0000-4000-8000-000000000002',
    clock_timestamp() - interval '61 seconds',
    clock_timestamp() - interval '60 seconds',
    clock_timestamp() - interval '60 seconds',
    10, 1, 'full', 'when_in_use', 5, 75, 30, 75, 1,
    'verified', 'offer-test'
  ),
  (
    '91000000-0000-4000-8000-000000000003',
    'a4000000-0000-4000-8000-000000000004',
    'b2000000-0000-4000-8000-000000000002',
    (((clock_timestamp() - interval '20 minutes') at time zone 'America/Toronto') - interval '4 hours')::date,
    '92000000-0000-4000-8000-000000000003',
    clock_timestamp() - interval '20 minutes 1 second',
    clock_timestamp() - interval '20 minutes',
    clock_timestamp() - interval '20 minutes',
    10, 1, 'full', 'when_in_use', 5, 75, 30, 75, 1,
    'verified', 'offer-test'
  );

set local role service_role;

select is(
  (
    select count(*)::integer
    from public.list_eligible_offers(
      'a2000000-0000-4000-8000-000000000002',
      array['b1000000-0000-4000-8000-000000000001'::uuid],
      clock_timestamp()
    )
  ),
  0,
  'campaign minimum age is enforced independently of the offer snapshot'
);
select lives_ok(
  $$update private.partner_campaigns set minimum_age = 19 where id = 'c2000000-0000-4000-8000-000000000002'$$,
  'founder workflow can approve a lower campaign age threshold'
);
select is(
  (
    select count(*)::integer
    from public.list_eligible_offers(
      'a2000000-0000-4000-8000-000000000002',
      array['b1000000-0000-4000-8000-000000000001'::uuid],
      clock_timestamp()
    )
  ),
  1,
  'one highest-priority eligible offer is returned per venue'
);
select is((select kind from public.list_eligible_offers('a2000000-0000-4000-8000-000000000002', array['b1000000-0000-4000-8000-000000000001'::uuid], clock_timestamp())), 'partner', 'partner offers use the shared eligibility result');
select is((select sponsor_display_name from public.list_eligible_offers('a2000000-0000-4000-8000-000000000002', array['b1000000-0000-4000-8000-000000000001'::uuid], clock_timestamp())), 'Northline', 'approved sponsor display metadata is returned');
select is((select destination_url from public.list_eligible_offers('a2000000-0000-4000-8000-000000000002', array['b1000000-0000-4000-8000-000000000001'::uuid], clock_timestamp())), 'https://getoutly.app/partners/northline', 'approved HTTPS partner CTA is returned');
select is((select claim_duration_seconds from public.list_eligible_offers('a2000000-0000-4000-8000-000000000002', array['b1000000-0000-4000-8000-000000000001'::uuid], clock_timestamp())), 1800, 'partner timer duration is not fixed at ten minutes');
select is((select discovery_treatment from public.list_eligible_offers('a2000000-0000-4000-8000-000000000002', array['b1000000-0000-4000-8000-000000000001'::uuid], clock_timestamp())), 'partner_featured', 'partner discovery treatment is returned through the same contract');

set local role postgres;

select throws_ok(
  $$insert into private.offer_campaign_links (offer_id, campaign_id) values ('d3000000-0000-4000-8000-000000000003', 'c2000000-0000-4000-8000-000000000002')$$,
  '23514',
  'campaign_links_require_outly_partner_offers',
  'a standard venue offer cannot be attached to a private partner campaign'
);
select throws_ok(
  $$update public.offers set offer_kind = 'standard' where id = 'd1000000-0000-4000-8000-000000000001'$$,
  '23514',
  'linked_campaign_offers_must_remain_outly_partner_offers',
  'a linked campaign offer cannot silently change contract type'
);

set local role service_role;

select lives_ok(
  $$select * from public.unlock_offer_for_check_in('a2000000-0000-4000-8000-000000000002', '91000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', '93000000-0000-4000-8000-000000000001')$$,
  'a fresh verified check-in unlocks the partner offer'
);
select is((select count(*)::integer from public.offer_claims where user_id = 'a2000000-0000-4000-8000-000000000002'), 1, 'unlock creates exactly one durable claim');
select is((select extract(epoch from (expires_at - unlocked_at))::integer from public.offer_claims where user_id = 'a2000000-0000-4000-8000-000000000002'), 1800, 'claim expiry uses the configured partner duration exactly');
select is((select kind from public.unlock_offer_for_check_in('a2000000-0000-4000-8000-000000000002', '91000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', '93000000-0000-4000-8000-000000000001')), 'partner', 'unlocked partner claim retains its presentation kind');
select is((select destination_url from public.unlock_offer_for_check_in('a2000000-0000-4000-8000-000000000002', '91000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', '93000000-0000-4000-8000-000000000001')), 'https://getoutly.app/partners/northline', 'unlocked claim returns the approved app link');
select is((select effective_status from public.unlock_offer_for_check_in('a2000000-0000-4000-8000-000000000002', '91000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', '93000000-0000-4000-8000-000000000001')), 'active', 'new timed partner claim is active');
select lives_ok(
  $$select * from public.unlock_offer_for_check_in('a2000000-0000-4000-8000-000000000002', '91000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', '93000000-0000-4000-8000-000000000001')$$,
  'an idempotent retry returns the existing claim'
);
select is((select count(*)::integer from public.offer_claims where check_in_id = '91000000-0000-4000-8000-000000000001'), 1, 'idempotent retry does not duplicate a claim');
select lives_ok(
  $$select * from public.unlock_offer_for_check_in('a2000000-0000-4000-8000-000000000002', '91000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', '93000000-0000-4000-8000-000000000002')$$,
  'the same check-in and offer return one existing entitlement even if a retry key changes'
);
select is((select count(*)::integer from public.offer_claims where check_in_id = '91000000-0000-4000-8000-000000000001'), 1, 'one check-in still maps to one entitlement');
select lives_ok(
  $$update public.offers set lifecycle_status = 'paused', paused_reason = 'capacity test' where id = 'd1000000-0000-4000-8000-000000000001'$$,
  'founder workflow can pause the claimed campaign offer'
);
select is(
  (
    select count(*)::integer
    from public.list_eligible_offers(
      'a2000000-0000-4000-8000-000000000002',
      array['b1000000-0000-4000-8000-000000000001'::uuid],
      clock_timestamp()
    )
  ),
  0,
  'campaign venue capacity counts claims across every offer linked to that campaign'
);
select is((select count(*)::integer from public.list_eligible_offers('a3000000-0000-4000-8000-000000000003', array['b2000000-0000-4000-8000-000000000002'::uuid], clock_timestamp())), 1, 'standard offers use the same eligibility function');
select is((select title from public.list_eligible_offers('a3000000-0000-4000-8000-000000000003', array['b2000000-0000-4000-8000-000000000002'::uuid], clock_timestamp())), 'Complimentary coat check', 'standard offer copy is returned unchanged');
select lives_ok(
  $$select * from public.unlock_offer_for_check_in('a3000000-0000-4000-8000-000000000003', '91000000-0000-4000-8000-000000000002', 'd3000000-0000-4000-8000-000000000003', '93000000-0000-4000-8000-000000000003')$$,
  'a fresh verified check-in unlocks a standard offer through the same RPC'
);
select is(
  (
    select extract(epoch from (expires_at - unlocked_at))::integer
    from public.offer_claims
    where user_id = 'a3000000-0000-4000-8000-000000000003'
  ),
  43200,
  'NULL duration hides the countdown while server validity remains capped at twelve hours'
);
select is((select claim_duration_seconds from public.unlock_offer_for_check_in('a3000000-0000-4000-8000-000000000003', '91000000-0000-4000-8000-000000000002', 'd3000000-0000-4000-8000-000000000003', '93000000-0000-4000-8000-000000000003')), null::integer, 'open-ended claim returns no countdown duration');
select is((select effective_status from public.unlock_offer_for_check_in('a3000000-0000-4000-8000-000000000003', '91000000-0000-4000-8000-000000000002', 'd3000000-0000-4000-8000-000000000003', '93000000-0000-4000-8000-000000000003')), 'active', 'no-countdown claim remains active within the server validity window');
select throws_ok(
  $$select * from public.unlock_offer_for_check_in('a4000000-0000-4000-8000-000000000004', '91000000-0000-4000-8000-000000000003', 'd3000000-0000-4000-8000-000000000003', '93000000-0000-4000-8000-000000000004')$$,
  'P0001',
  'check_in_too_old_to_unlock_offer',
  'an old verified check-in cannot be replayed to unlock a current offer'
);
select is((select count(*)::integer from public.offer_claims where user_id = 'a4000000-0000-4000-8000-000000000004'), 0, 'stale check-in replay creates no entitlement');
select lives_ok(
  $$
    insert into public.offer_versions (
      offer_id, version_number, public_title, staff_display_title,
      staff_instruction, cta_label, redemption_mode, claim_duration_seconds
    ) values (
      'd3000000-0000-4000-8000-000000000003', 2, '30-second staff offer',
      '30-second staff offer', 'Show this active offer to your server.',
      'Show offer', 'staff_display', 30
    )
  $$,
  'positive custom durations are accepted without a ten-minute assumption'
);
select throws_ok(
  $$
    insert into public.offer_versions (
      offer_id, version_number, public_title, staff_display_title,
      staff_instruction, cta_label, redemption_mode, claim_duration_seconds
    ) values (
      'd3000000-0000-4000-8000-000000000003', 3, 'Invalid zero timer',
      'Invalid zero timer', 'Show this active offer to your server.',
      'Show offer', 'staff_display', 0
    )
  $$,
  '23514',
  null,
  'zero is rejected so NULL alone represents no timer'
);

set local role postgres;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'a5000000-0000-4000-8000-000000000005', true);
select is((select count(*)::integer from public.offers), 2, 'venue account can read only offers attached to its venue');
select is((select count(*)::integer from public.offer_claims), 0, 'venue account cannot read consumer claim records');

select set_config('request.jwt.claim.sub', 'a2000000-0000-4000-8000-000000000002', true);
select is((select count(*)::integer from public.offer_claims), 1, 'consumer can read their own partner claim');
select is((select count(*)::integer from public.offer_claims where user_id = 'a3000000-0000-4000-8000-000000000003'), 0, 'consumer cannot read another consumer open-ended claim');
select throws_ok(
  $$insert into public.offer_claims (user_id) values ('a2000000-0000-4000-8000-000000000002')$$,
  '42501',
  null,
  'consumer cannot forge a claim despite owning the requested user ID'
);

select * from finish();
rollback;
