begin;

set local role postgres;
set local search_path = public, extensions, pgtap;

create extension if not exists pgtap with schema extensions;

select plan(16);

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
    ('b1100000-0000-4000-8000-000000000001'::uuid, 'bootstrap-new@example.test'),
    ('b1100000-0000-4000-8000-000000000002'::uuid, 'bootstrap-incomplete@example.test'),
    ('b1100000-0000-4000-8000-000000000003'::uuid, 'bootstrap-suspended@example.test'),
    ('b1100000-0000-4000-8000-000000000004'::uuid, 'bootstrap-active@example.test'),
    ('b1100000-0000-4000-8000-000000000005'::uuid, 'bootstrap-rejected@example.test')
) as user_record(id, email);

insert into public.consumer_profiles (
  user_id, first_name, onboarding_status, account_status, onboarding_completed_at
)
values
  ('b1100000-0000-4000-8000-000000000002', null, 'incomplete', 'active', null),
  ('b1100000-0000-4000-8000-000000000003', 'Suspended', 'complete', 'suspended', now()),
  ('b1100000-0000-4000-8000-000000000004', 'Active', 'complete', 'active', now()),
  ('b1100000-0000-4000-8000-000000000005', 'Rejected', 'complete', 'active', now());

insert into private.consumer_eligibility (
  user_id, date_of_birth, gender, is_19_plus, age_eligibility_checked_at
)
values
  ('b1100000-0000-4000-8000-000000000003', '2000-01-01', 'other', true, now()),
  ('b1100000-0000-4000-8000-000000000004', '2000-01-01', 'woman', true, now()),
  ('b1100000-0000-4000-8000-000000000005', '2000-01-01', 'man', true, now());

insert into public.venues (
  id, slug, display_name, registration_status, publication_status,
  address_line_1, market_code, neighbourhood, city, province_code,
  postal_code, country_code, location, approved_at
)
values (
  'b1200000-0000-4000-8000-000000000001',
  'bootstrap-session-venue',
  'Session House',
  'approved',
  'published',
  '100 King St W',
  'toronto',
  'King West',
  'Toronto',
  'ON',
  'M5X 1A9',
  'CA',
  extensions.st_setsrid(
    extensions.st_makepoint(-79.3900, 43.6480),
    4326
  )::extensions.geography,
  now()
);

set local role service_role;

select throws_ok(
  $$select public.get_consumer_bootstrap(
    'b1100000-0000-4000-8000-000000000001', clock_timestamp()
  )$$,
  'P0001',
  'onboarding_required',
  'a signed-in user without a consumer profile is routed to onboarding'
);

select throws_ok(
  $$select public.get_consumer_bootstrap(
    'b1100000-0000-4000-8000-000000000002', clock_timestamp()
  )$$,
  'P0001',
  'onboarding_required',
  'an incomplete active consumer is routed to onboarding'
);

select throws_ok(
  $$select public.get_consumer_bootstrap(
    'b1100000-0000-4000-8000-000000000003', clock_timestamp()
  )$$,
  'P0001',
  'account_ineligible',
  'a suspended completed account is ineligible rather than onboarding-required'
);

select is(
  public.get_consumer_bootstrap(
    'b1100000-0000-4000-8000-000000000004', clock_timestamp()
  ) -> 'current_check_in',
  'null'::jsonb,
  'bootstrap returns a nullable current_check_in before any attempt'
);

select lives_ok(
  $$select public.verify_venue_check_in(
    'b1100000-0000-4000-8000-000000000004',
    'b1200000-0000-4000-8000-000000000001',
    'b1300000-0000-4000-8000-000000000001',
    43.6480,
    -79.3900,
    10,
    clock_timestamp() - interval '1 second',
    'full',
    'when_in_use',
    null
  )$$,
  'location verification succeeds without requiring an offer claim'
);

select is(
  public.get_consumer_bootstrap(
    'b1100000-0000-4000-8000-000000000004', clock_timestamp()
  ) -> 'active_claim',
  'null'::jsonb,
  'a verified check-in remains independent from active_claim'
);

select is(
  public.get_consumer_bootstrap(
    'b1100000-0000-4000-8000-000000000004', clock_timestamp()
  ) #>> '{current_check_in,outcome}',
  'verified',
  'current_check_in reports the durable verified outcome'
);

select is(
  public.get_consumer_bootstrap(
    'b1100000-0000-4000-8000-000000000004', clock_timestamp()
  ) #>> '{current_check_in,id}',
  (
    select check_in_record.id::text
    from public.check_ins as check_in_record
    where check_in_record.request_idempotency_key = 'b1300000-0000-4000-8000-000000000001'
  ),
  'current_check_in returns the durable check-in identifier'
);

select is(
  public.get_consumer_bootstrap(
    'b1100000-0000-4000-8000-000000000004', clock_timestamp()
  ) #>> '{current_check_in,venue_id}',
  'b1200000-0000-4000-8000-000000000001',
  'current_check_in returns the verified venue identifier'
);

select ok(
  (
    public.get_consumer_bootstrap(
      'b1100000-0000-4000-8000-000000000004', clock_timestamp()
    ) #>> '{current_check_in,server_verified_at}'
  )::timestamptz = (
    select check_in_record.server_verified_at
    from public.check_ins as check_in_record
    where check_in_record.request_idempotency_key = 'b1300000-0000-4000-8000-000000000001'
  ),
  'current_check_in returns the authoritative server decision time'
);

select is(
  (
    select count(*)::integer
    from jsonb_object_keys(
      public.get_consumer_bootstrap(
        'b1100000-0000-4000-8000-000000000004', clock_timestamp()
      ) -> 'current_check_in'
    )
  ),
  4,
  'the compact current_check_in payload exposes only the documented fields'
);

select lives_ok(
  $$select public.verify_venue_check_in(
    'b1100000-0000-4000-8000-000000000004',
    'b1200000-0000-4000-8000-000000000001',
    'b1300000-0000-4000-8000-000000000003',
    43.6480,
    -79.3900,
    10,
    clock_timestamp() - interval '1 second',
    'full',
    'when_in_use',
    null
  )$$,
  'a new-key retry after verification is recorded as rejected'
);

select is(
  public.get_consumer_bootstrap(
    'b1100000-0000-4000-8000-000000000004', clock_timestamp()
  ) #>> '{current_check_in,id}',
  (
    select check_in_record.id::text
    from public.check_ins as check_in_record
    where check_in_record.request_idempotency_key = 'b1300000-0000-4000-8000-000000000001'
  ),
  'a verified session remains authoritative over a later rejected attempt'
);

select is(
  public.get_consumer_bootstrap(
    'b1100000-0000-4000-8000-000000000004',
    clock_timestamp() + interval '1 day'
  ) -> 'current_check_in',
  'null'::jsonb,
  'a prior-night check-in is not returned as the current session'
);

select lives_ok(
  $$select public.verify_venue_check_in(
    'b1100000-0000-4000-8000-000000000005',
    'b1200000-0000-4000-8000-000000000001',
    'b1300000-0000-4000-8000-000000000002',
    43.6480,
    -79.3900,
    10,
    clock_timestamp() - interval '1 second',
    'reduced',
    'when_in_use',
    null
  )$$,
  'a rejected location attempt is durably recorded'
);

select is(
  public.get_consumer_bootstrap(
    'b1100000-0000-4000-8000-000000000005', clock_timestamp()
  ) #>> '{current_check_in,outcome}',
  'rejected',
  'current_check_in also reports the latest rejected outcome'
);

select * from finish();

rollback;
