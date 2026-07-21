begin;

create extension if not exists pgtap with schema extensions;

select plan(29);

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
values
  (
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'consumer@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  ),
  (
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'published-venue@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  ),
  (
    'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'pending-venue@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  );

insert into public.consumer_profiles (
  user_id,
  first_name,
  onboarding_status,
  onboarding_completed_at
)
values (
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'Avery',
  'complete',
  now()
);

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
    '10000000-0000-4000-8000-000000000001',
    'track-and-field',
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
    '20000000-0000-4000-8000-000000000002',
    'pending-room',
    'Pending Room',
    'pending_review',
    'unpublished',
    '100 Test St',
    'toronto',
    'King West',
    'Toronto',
    'ON',
    'M5V 1A1',
    'CA',
    extensions.st_setsrid(extensions.st_makepoint(-79.3970, 43.6440), 4326)::extensions.geography,
    null
  );

insert into public.venue_accounts (auth_user_id, venue_id, account_status)
values
  (
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    '10000000-0000-4000-8000-000000000001',
    'active'
  ),
  (
    'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    '20000000-0000-4000-8000-000000000002',
    'draft'
  );

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
  '20000000-0000-4000-8000-000000000002',
  'Pending Room Incorporated',
  '100 Test St, Toronto, ON M5V 1A1',
  'Morgan Test',
  'Owner',
  'morgan@example.test',
  '+1 416 555 0100',
  true,
  'venue-terms-v1',
  now()
);

insert into public.venue_hours (
  venue_id,
  weekday,
  opens_at,
  closes_at
)
values
  ('10000000-0000-4000-8000-000000000001', 5, '17:00', '02:00'),
  ('20000000-0000-4000-8000-000000000002', 5, '18:00', '02:00');

insert into public.venue_hour_exceptions (
  venue_id,
  local_date,
  is_closed,
  public_note
)
values
  ('10000000-0000-4000-8000-000000000001', '2026-12-25', true, 'Closed Christmas Day'),
  ('20000000-0000-4000-8000-000000000002', '2026-12-25', true, 'Closed Christmas Day');

insert into public.venue_assets (
  id,
  venue_id,
  asset_kind,
  storage_bucket,
  storage_path,
  alt_text,
  moderation_status,
  uploaded_by,
  requires_paid_entitlement,
  pixel_width,
  pixel_height,
  mime_type,
  reviewed_at
)
values
  (
    '30000000-0000-4000-8000-000000000003',
    '10000000-0000-4000-8000-000000000001',
    'hero',
    'venue-media',
    '10000000-0000-4000-8000-000000000001/hero/main.webp',
    'Track & Field interior',
    'approved',
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    false,
    1600,
    1000,
    'image/webp',
    now()
  ),
  (
    '40000000-0000-4000-8000-000000000004',
    '20000000-0000-4000-8000-000000000002',
    'marker',
    'venue-media-submissions',
    '20000000-0000-4000-8000-000000000002/marker/draft.png',
    'Pending Room map marker',
    'pending_review',
    'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    true,
    256,
    256,
    'image/png',
    null
  );

update public.venues
set current_hero_asset_id = '30000000-0000-4000-8000-000000000003'
where id = '10000000-0000-4000-8000-000000000001';

insert into public.venue_profile_revisions (
  id,
  venue_id,
  submitted_by,
  requested_marker_asset_id,
  revision_status
)
values (
  '50000000-0000-4000-8000-000000000005',
  '20000000-0000-4000-8000-000000000002',
  'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  '40000000-0000-4000-8000-000000000004',
  'draft'
);

insert into public.venue_events (
  id,
  venue_id,
  title,
  starts_at,
  ends_at,
  image_asset_id,
  event_status,
  created_by
)
values
  (
    '60000000-0000-4000-8000-000000000006',
    '10000000-0000-4000-8000-000000000001',
    'Friday Social',
    '2026-07-24 20:00:00-04',
    '2026-07-25 02:00:00-04',
    '30000000-0000-4000-8000-000000000003',
    'published',
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'
  ),
  (
    '70000000-0000-4000-8000-000000000007',
    '10000000-0000-4000-8000-000000000001',
    'Private Draft',
    '2026-07-25 20:00:00-04',
    '2026-07-26 02:00:00-04',
    null,
    'draft',
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'
  ),
  (
    '80000000-0000-4000-8000-000000000008',
    '20000000-0000-4000-8000-000000000002',
    'Pending Venue Event',
    '2026-07-24 20:00:00-04',
    '2026-07-25 02:00:00-04',
    null,
    'published',
    'cccccccc-cccc-4ccc-8ccc-cccccccccccc'
  );

select set_config(
  'request.jwt.claims',
  '{"sub":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa","role":"authenticated"}',
  true
);
select set_config(
  'request.jwt.claim.sub',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  true
);
set local role authenticated;

select is((select auth.uid()), 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'::uuid, 'consumer test identity is active');
select is((select count(*)::integer from public.venues), 1, 'consumer sees exactly one published venue');
select is((select display_name from public.venues), 'Track & Field', 'consumer sees the approved published venue');
select is((select count(*)::integer from public.venue_accounts), 0, 'consumer sees no venue account records');
select is((select count(*)::integer from public.venue_hours), 1, 'consumer sees hours only for a published venue');
select is((select count(*)::integer from public.venue_hour_exceptions), 1, 'consumer sees exceptions only for a published venue');
select is((select count(*)::integer from public.venue_events), 1, 'consumer sees only published events at published venues');
select is((select count(*)::integer from public.venue_assets), 1, 'consumer sees only approved public media at published venues');
select is((select count(*)::integer from public.venue_profile_revisions), 0, 'consumer sees no venue review queue');
select throws_ok(
  $$insert into public.venues (slug, display_name) values ('client-write', 'Client Write')$$,
  '42501',
  null,
  'consumer cannot register a venue by writing tables directly'
);
select throws_ok(
  $$update public.venues set placement_state = 'featured' where slug = 'track-and-field'$$,
  '42501',
  null,
  'consumer cannot change paid placement state'
);
select throws_ok(
  $$select * from private.venue_business_details$$,
  '42501',
  null,
  'consumer cannot read legal or business registration data'
);

reset role;
select set_config(
  'request.jwt.claims',
  '{"sub":"cccccccc-cccc-4ccc-8ccc-cccccccccccc","role":"authenticated"}',
  true
);
select set_config(
  'request.jwt.claim.sub',
  'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  true
);
set local role authenticated;

select is((select count(*)::integer from public.venues), 2, 'venue owner sees public discovery plus their own pending venue');
select is((select count(*)::integer from public.venue_accounts), 1, 'venue owner sees only their own account');
select is(
  (select venue_id from public.venue_accounts),
  '20000000-0000-4000-8000-000000000002'::uuid,
  'venue account cannot cross the tenant boundary'
);
select is((select count(*)::integer from public.venue_hours), 2, 'venue owner sees public hours and their own pending hours');
select is((select count(*)::integer from public.venue_events), 2, 'venue owner sees the public event and their own venue event');
select is((select count(*)::integer from public.venue_assets), 2, 'venue owner sees approved public media and their own pending media');
select is((select count(*)::integer from public.venue_profile_revisions), 1, 'venue owner sees their own critical revision');
select is(
  (
    select count(*)::integer
    from public.venue_accounts
    where auth_user_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'
  ),
  0,
  'venue owner cannot see another venue account'
);
select throws_ok(
  $$update public.venue_accounts set account_status = 'active'$$,
  '42501',
  null,
  'venue owner cannot activate their own account directly'
);

reset role;

select throws_ok(
  $$insert into public.venues (slug, display_name, geofence_radius_metres) values ('unsafe-radius', 'Unsafe Radius', 201)$$,
  '23514',
  null,
  'unsafe geofence radii are rejected'
);
select throws_ok(
  $$insert into public.venues (slug, display_name, registration_status, publication_status, approved_at) values ('incomplete-published', 'Incomplete Published', 'approved', 'published', now())$$,
  '23514',
  null,
  'an incomplete venue cannot be published'
);
select throws_ok(
  $$update public.venues set current_hero_asset_id = '30000000-0000-4000-8000-000000000003' where id = '20000000-0000-4000-8000-000000000002'$$,
  '23503',
  null,
  'a venue cannot select another venue asset as its hero'
);
select throws_ok(
  $$
    insert into public.venue_assets (
      venue_id, asset_kind, storage_bucket, storage_path, alt_text,
      moderation_status, requires_paid_entitlement, mime_type
    ) values (
      '20000000-0000-4000-8000-000000000002', 'marker',
      'venue-media-submissions',
      '20000000-0000-4000-8000-000000000002/marker/unpaid.png',
      'Unpaid marker', 'pending_review', false, 'image/png'
    )
  $$,
  '23514',
  null,
  'custom markers are marked as paid-entitlement assets'
);
select throws_ok(
  $$
    insert into public.venue_assets (
      venue_id, asset_kind, storage_bucket, storage_path, alt_text,
      moderation_status, requires_paid_entitlement, mime_type, reviewed_at
    ) values (
      '20000000-0000-4000-8000-000000000002', 'hero',
      'venue-media-submissions',
      '20000000-0000-4000-8000-000000000002/hero/not-promoted.webp',
      'Not promoted', 'approved', false, 'image/webp', now()
    )
  $$,
  '23514',
  null,
  'approved asset metadata cannot point at the private submission bucket'
);
select is(
  (select public from storage.buckets where id = 'venue-media'),
  true,
  'approved venue-media bucket is public'
);
select is(
  (select public from storage.buckets where id = 'venue-media-submissions'),
  false,
  'venue-media-submissions bucket remains private'
);
select throws_ok(
  $$
    insert into public.venue_events (
      venue_id, title, starts_at, ends_at, image_asset_id
    ) values (
      '20000000-0000-4000-8000-000000000002', 'Wrong Venue Image',
      now(), now() + interval '2 hours',
      '30000000-0000-4000-8000-000000000003'
    )
  $$,
  '23503',
  null,
  'an event cannot use another venue image'
);

select * from finish();
rollback;
