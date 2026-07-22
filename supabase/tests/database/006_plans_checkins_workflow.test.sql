begin;

set local role postgres;
set local search_path = public, extensions, pgtap;

create extension if not exists pgtap with schema extensions;

select plan(41);

insert into auth.users (
  id,
  instance_id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
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
    ('11111111-aaaa-4111-8111-111111111111'::uuid, 'primary@example.test'),
    ('22222222-aaaa-4222-8222-222222222222'::uuid, 'quality@example.test'),
    ('33333333-aaaa-4333-8333-333333333333'::uuid, 'ineligible@example.test'),
    ('44444444-aaaa-4444-8444-444444444444'::uuid, 'rate@example.test'),
    ('55555555-aaaa-4555-8555-555555555555'::uuid, 'ambiguous@example.test')
) as user_record(id, email);

insert into public.consumer_profiles (
  user_id,
  first_name,
  onboarding_status,
  onboarding_completed_at
)
values
  ('11111111-aaaa-4111-8111-111111111111', 'Primary', 'complete', now()),
  ('22222222-aaaa-4222-8222-222222222222', 'Quality', 'complete', now()),
  ('33333333-aaaa-4333-8333-333333333333', 'Ineligible', 'complete', now()),
  ('44444444-aaaa-4444-8444-444444444444', 'Rate', 'complete', now()),
  ('55555555-aaaa-4555-8555-555555555555', 'Ambiguous', 'complete', now());

insert into private.consumer_eligibility (
  user_id,
  date_of_birth,
  gender,
  is_19_plus,
  age_eligibility_checked_at
)
values
  ('11111111-aaaa-4111-8111-111111111111', '2000-01-01', 'other', true, now()),
  ('22222222-aaaa-4222-8222-222222222222', '2000-01-01', 'woman', true, now()),
  ('44444444-aaaa-4444-8444-444444444444', '2000-01-01', 'man', true, now()),
  ('55555555-aaaa-4555-8555-555555555555', '2000-01-01', 'other', true, now());

insert into public.venues (
  id,
  slug,
  display_name,
  registration_status,
  publication_status,
  address_line_1,
  market_code,
  neighbourhood,
  city,
  province_code,
  postal_code,
  country_code,
  location,
  approved_at
)
values
  (
    '10000000-aaaa-4000-8000-000000000001',
    'track-and-field-workflow',
    'Track & Field',
    'approved',
    'published',
    '860 College St',
    'toronto',
    'Ossington',
    'Toronto',
    'ON',
    'M6H 1A2',
    'CA',
    extensions.st_setsrid(extensions.st_makepoint(-79.4236, 43.6547), 4326)::extensions.geography,
    now()
  ),
  (
    '20000000-aaaa-4000-8000-000000000002',
    'king-west-workflow',
    'King West Room',
    'approved',
    'published',
    '100 King St W',
    'toronto',
    'King West',
    'Toronto',
    'ON',
    'M5X 1A9',
    'CA',
    extensions.st_setsrid(extensions.st_makepoint(-79.3900, 43.6480), 4326)::extensions.geography,
    now()
  );

select is(
  private.nightlife_date_for('2026-07-19 03:59:59-04', 'America/Toronto'),
  '2026-07-18'::date,
  '3:59 AM belongs to the prior nightlife date'
);
select is(
  private.nightlife_date_for('2026-07-19 04:00:00-04', 'America/Toronto'),
  '2026-07-19'::date,
  '4:00 AM starts the next nightlife date'
);

set local role service_role;

select lives_ok(
  $$
    select public.set_night_plan(
      '11111111-aaaa-4111-8111-111111111111',
      '10000000-aaaa-4000-8000-000000000001',
      'a0000000-0000-4000-8000-000000000001'
    )
  $$,
  'trusted server creates a first plan'
);
select lives_ok(
  $$
    select public.set_night_plan(
      '11111111-aaaa-4111-8111-111111111111',
      '20000000-aaaa-4000-8000-000000000002',
      'a0000000-0000-4000-8000-000000000001'
    )
  $$,
  'repeating an idempotency key returns the original plan'
);
select is(
  (
    select count(*)::integer from public.night_plans
    where user_id = '11111111-aaaa-4111-8111-111111111111'
      and request_idempotency_key = 'a0000000-0000-4000-8000-000000000001'
  ),
  1,
  'plan idempotency does not create a duplicate row'
);
select lives_ok(
  $$
    select public.set_night_plan(
      '11111111-aaaa-4111-8111-111111111111',
      '20000000-aaaa-4000-8000-000000000002',
      'a0000000-0000-4000-8000-000000000002'
    )
  $$,
  'a new venue plan atomically replaces the first plan'
);
select is(
  (
    select count(*)::integer from public.night_plans
    where user_id = '11111111-aaaa-4111-8111-111111111111'
      and plan_status in ('planned', 'checked_in')
  ),
  1,
  'only one active plan remains'
);
select is(
  (
    select count(*)::integer from public.night_plans
    where user_id = '11111111-aaaa-4111-8111-111111111111'
      and plan_status = 'replaced'
  ),
  1,
  'the prior plan is retained as replaced history'
);
select ok(
  (
    select replaces_plan_id is not null from public.night_plans
    where request_idempotency_key = 'a0000000-0000-4000-8000-000000000002'
  ),
  'the replacement points to the prior same-user, same-night plan'
);
select lives_ok(
  $$
    select public.cancel_night_plan(
      '11111111-aaaa-4111-8111-111111111111',
      (select id from public.night_plans where request_idempotency_key = 'a0000000-0000-4000-8000-000000000002')
    )
  $$,
  'trusted server cancels an active plan'
);
select is(
  (
    select count(*)::integer from public.night_plans
    where user_id = '11111111-aaaa-4111-8111-111111111111'
      and plan_status in ('planned', 'checked_in')
  ),
  0,
  'cancellation clears the active plan slot'
);
select ok(
  (
    select cancelled_at is not null from public.night_plans
    where request_idempotency_key = 'a0000000-0000-4000-8000-000000000002'
  ),
  'cancelled plans retain their server timestamp'
);
select lives_ok(
  $$
    select public.set_night_plan(
      '11111111-aaaa-4111-8111-111111111111',
      '10000000-aaaa-4000-8000-000000000001',
      'a0000000-0000-4000-8000-000000000003'
    )
  $$,
  'consumer can make a new plan after cancellation'
);
select lives_ok(
  $$
    select public.verify_venue_check_in(
      '11111111-aaaa-4111-8111-111111111111',
      '10000000-aaaa-4000-8000-000000000001',
      'b0000000-0000-4000-8000-000000000001',
      43.6547,
      -79.4236,
      10,
      clock_timestamp() - interval '1 second',
      'full',
      'when_in_use',
      (select id from public.night_plans where request_idempotency_key = 'a0000000-0000-4000-8000-000000000003')
    )
  $$,
  'exact, fresh, precise venue location verifies'
);
select is(
  (
    select count(*)::integer from public.check_ins
    where user_id = '11111111-aaaa-4111-8111-111111111111'
      and outcome = 'verified'
  ),
  1,
  'one verified check-in is recorded'
);
select ok(
  (
    select distance_from_venue_metres < 1 from public.check_ins
    where request_idempotency_key = 'b0000000-0000-4000-8000-000000000001'
  ),
  'the server-derived venue distance is accurate'
);
select is(
  (
    select plan_status from public.night_plans
    where request_idempotency_key = 'a0000000-0000-4000-8000-000000000003'
  ),
  'checked_in',
  'a matching plan becomes checked in'
);
select lives_ok(
  $$
    select public.verify_venue_check_in(
      '11111111-aaaa-4111-8111-111111111111',
      '10000000-aaaa-4000-8000-000000000001',
      'b0000000-0000-4000-8000-000000000001',
      0,
      0,
      999,
      clock_timestamp() - interval '1 hour',
      'reduced',
      'denied',
      null
    )
  $$,
  'an idempotent check-in retry returns the original decision'
);
select is(
  (
    select count(*)::integer from public.check_ins
    where user_id = '11111111-aaaa-4111-8111-111111111111'
      and request_idempotency_key = 'b0000000-0000-4000-8000-000000000001'
  ),
  1,
  'check-in idempotency does not create a duplicate row'
);
select lives_ok(
  $$
    select public.verify_venue_check_in(
      '11111111-aaaa-4111-8111-111111111111',
      '10000000-aaaa-4000-8000-000000000001',
      'b0000000-0000-4000-8000-000000000002',
      43.6547,
      -79.4236,
      10,
      clock_timestamp() - interval '1 second',
      'full',
      'when_in_use',
      null
    )
  $$,
  'a second same-night attempt is safely recorded as rejected'
);
select is(
  (
    select rejection_reason from public.check_ins
    where request_idempotency_key = 'b0000000-0000-4000-8000-000000000002'
  ),
  'already_checked_in',
  'MVP permits only one verified check-in per night'
);
select throws_ok(
  $$
    select public.set_night_plan(
      '11111111-aaaa-4111-8111-111111111111',
      '20000000-aaaa-4000-8000-000000000002',
      'a0000000-0000-4000-8000-000000000004'
    )
  $$,
  'P0001',
  'check_in_already_verified',
  'a verified check-in closes the consumer plan slot for that night'
);

select lives_ok(
  $$
    select public.verify_venue_check_in(
      '22222222-aaaa-4222-8222-222222222222',
      '10000000-aaaa-4000-8000-000000000001',
      'c0000000-0000-4000-8000-000000000001',
      43.6547, -79.4236, 10, clock_timestamp() - interval '1 second',
      'reduced', 'when_in_use', null
    )
  $$,
  'reduced-accuracy attempt is recorded'
);
select is(
  (select rejection_reason from public.check_ins where request_idempotency_key = 'c0000000-0000-4000-8000-000000000001'),
  'reduced_accuracy',
  'reduced accuracy cannot verify'
);
select lives_ok(
  $$
    select public.verify_venue_check_in(
      '22222222-aaaa-4222-8222-222222222222',
      '10000000-aaaa-4000-8000-000000000001',
      'c0000000-0000-4000-8000-000000000002',
      43.6547, -79.4236, 10, clock_timestamp() - interval '31 seconds',
      'full', 'when_in_use', null
    )
  $$,
  'stale attempt is recorded'
);
select is(
  (select rejection_reason from public.check_ins where request_idempotency_key = 'c0000000-0000-4000-8000-000000000002'),
  'stale_sample',
  'a sample older than 30 seconds cannot verify'
);
select lives_ok(
  $$
    select public.verify_venue_check_in(
      '22222222-aaaa-4222-8222-222222222222',
      '10000000-aaaa-4000-8000-000000000001',
      'c0000000-0000-4000-8000-000000000003',
      43.6500, -79.4300, 10, clock_timestamp() - interval '1 second',
      'full', 'when_in_use', null
    )
  $$,
  'outside-geofence attempt is recorded'
);
select is(
  (select rejection_reason from public.check_ins where request_idempotency_key = 'c0000000-0000-4000-8000-000000000003'),
  'outside_geofence',
  'a sample outside the venue radius cannot verify'
);
select lives_ok(
  $$
    select public.verify_venue_check_in(
      '33333333-aaaa-4333-8333-333333333333',
      '10000000-aaaa-4000-8000-000000000001',
      'd0000000-0000-4000-8000-000000000001',
      43.6547, -79.4236, 10, clock_timestamp() - interval '1 second',
      'full', 'when_in_use', null
    )
  $$,
  'ineligible account attempt is recorded without verifying'
);
select is(
  (select rejection_reason from public.check_ins where request_idempotency_key = 'd0000000-0000-4000-8000-000000000001'),
  'account_ineligible',
  'missing protected eligibility prevents verification'
);

select lives_ok(
  $$
    do $rate_limit$
    declare
      attempt_number integer;
    begin
      for attempt_number in 1..6 loop
        perform public.verify_venue_check_in(
          '44444444-aaaa-4444-8444-444444444444',
          '10000000-aaaa-4000-8000-000000000001',
          ('e0000000-0000-4000-8000-' || lpad(attempt_number::text, 12, '0'))::uuid,
          43.6500, -79.4300, 10, clock_timestamp() - interval '1 second',
          'full', 'when_in_use', null
        );
      end loop;
    end
    $rate_limit$
  $$,
  'rapid check-in attempts are handled without a race'
);
select is(
  (
    select rejection_reason from public.check_ins
    where user_id = '44444444-aaaa-4444-8444-444444444444'
    order by server_requested_at desc
    limit 1
  ),
  'rate_limited',
  'the sixth attempt inside five minutes is rate limited'
);

set local role postgres;

insert into public.venues (
  id, slug, display_name, registration_status, publication_status,
  address_line_1, market_code, neighbourhood, city, province_code,
  postal_code, country_code, location, approved_at
)
values (
  '30000000-aaaa-4000-8000-000000000003',
  'overlapping-workflow',
  'Overlapping Venue',
  'approved',
  'published',
  '862 College St',
  'toronto',
  'Ossington',
  'Toronto',
  'ON',
  'M6H 1A2',
  'CA',
  extensions.st_setsrid(extensions.st_makepoint(-79.4236, 43.6547), 4326)::extensions.geography,
  now()
);

set local role service_role;
select lives_ok(
  $$
    select public.verify_venue_check_in(
      '55555555-aaaa-4555-8555-555555555555',
      '10000000-aaaa-4000-8000-000000000001',
      'f0000000-0000-4000-8000-000000000001',
      43.6547, -79.4236, 10, clock_timestamp() - interval '1 second',
      'full', 'when_in_use', null
    )
  $$,
  'overlapping venue attempt is recorded'
);
select is(
  (select rejection_reason from public.check_ins where request_idempotency_key = 'f0000000-0000-4000-8000-000000000001'),
  'ambiguous_nearest_venue',
  'an effectively tied venue location cannot verify either venue'
);

set local role postgres;
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-aaaa-4111-8111-111111111111","role":"authenticated"}',
  true
);
select set_config(
  'request.jwt.claim.sub',
  '11111111-aaaa-4111-8111-111111111111',
  true
);
set local role authenticated;

select is((select count(*)::integer from public.night_plans), 3, 'consumer sees only their own plan history');
select is((select count(*)::integer from public.check_ins), 2, 'consumer sees only their own derived check-in decisions');
select is(
  (
    select count(*)::integer from public.check_ins
    where user_id = '22222222-aaaa-4222-8222-222222222222'
  ),
  0,
  'consumer cannot read another consumer check-in evidence'
);
select throws_ok(
  $$
    insert into public.night_plans (
      user_id, venue_id, nightlife_date, request_idempotency_key
    ) values (
      '11111111-aaaa-4111-8111-111111111111',
      '10000000-aaaa-4000-8000-000000000001',
      current_date,
      'a0000000-0000-4000-8000-000000000099'
    )
  $$,
  '42501',
  null,
  'consumer cannot forge a plan row'
);
select throws_ok(
  $$
    insert into public.check_ins (
      user_id, venue_id, nightlife_date, request_idempotency_key,
      server_requested_at, server_verified_at, accuracy_authorization,
      location_authorization, configured_radius_metres,
      maximum_sample_age_seconds, maximum_horizontal_accuracy_metres,
      nearest_venue_tie_tolerance_metres, outcome, rejection_reason,
      verifier_version
    ) values (
      '11111111-aaaa-4111-8111-111111111111',
      '10000000-aaaa-4000-8000-000000000001',
      current_date,
      'b0000000-0000-4000-8000-000000000099',
      now(), now(), 'full', 'when_in_use', 75, 30, 75, 1,
      'rejected', 'forged', 'test'
    )
  $$,
  '42501',
  null,
  'consumer cannot forge a check-in decision'
);
select throws_ok(
  $$select * from private.check_in_verification_config$$,
  '42501',
  null,
  'consumer cannot read fraud and verification thresholds'
);

set local role postgres;

select throws_ok(
  $$
    insert into public.check_ins (
      user_id, venue_id, nightlife_date, request_idempotency_key,
      client_location_captured_at, server_requested_at, server_verified_at,
      horizontal_accuracy_metres, location_age_seconds,
      accuracy_authorization, location_authorization,
      distance_from_venue_metres, configured_radius_metres,
      maximum_sample_age_seconds, maximum_horizontal_accuracy_metres,
      nearest_venue_tie_tolerance_metres, outcome, verifier_version
    ) values (
      '22222222-aaaa-4222-8222-222222222222',
      '10000000-aaaa-4000-8000-000000000001',
      current_date,
      'c0000000-0000-4000-8000-000000000099',
      now(), now(), now(), 10, 1, 'full', 'when_in_use',
      100, 75, 30, 75, 1, 'verified', 'test'
    )
  $$,
  '23514',
  null,
  'a forged verified result outside the snapshotted radius is rejected'
);

select * from finish();
rollback;
