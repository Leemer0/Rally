begin;

set local role postgres;
set local search_path = public, extensions, pgtap;

create extension if not exists pgtap with schema extensions;

select plan(38);

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
    ('a1000000-0000-4000-8000-000000000001'::uuid, 'founder-ops@example.test'),
    ('a1000000-0000-4000-8000-000000000002'::uuid, 'non-founder-ops@example.test'),
    ('a1000000-0000-4000-8000-000000000003'::uuid, 'consumer-ops@example.test'),
    ('a1000000-0000-4000-8000-000000000004'::uuid, 'venue-ops@example.test')
) as user_record(id, email);

insert into private.internal_admins (user_id)
values ('a1000000-0000-4000-8000-000000000001');

set local role service_role;

do $$
begin
  perform * from public.complete_consumer_onboarding(
    'a1000000-0000-4000-8000-000000000003',
    'Avery',
    '2000-01-01',
    'other',
    'terms-2026-07',
    'privacy-2026-07'
  );
end;
$$;

-- Founder authorization is explicit and none of the administrative RPCs can
-- be called directly by an authenticated browser or mobile client.
-- 01
select ok(
  not has_function_privilege('authenticated', 'public.has_founder_access(uuid)', 'execute')
  and not has_function_privilege(
    'authenticated',
    'public.founder_create_venue(uuid,text,text,text,text,double precision,double precision,smallint)',
    'execute'
  )
  and not has_function_privilege(
    'authenticated',
    'public.review_venue_registration(uuid,uuid,text,text,text,text,text,double precision,double precision,smallint)',
    'execute'
  )
  and not has_function_privilege(
    'authenticated',
    'public.create_partner_campaign_offer(uuid,uuid,uuid[],text,text,text,text,text,text,text,integer,timestamptz,timestamptz,integer,smallint,text,text)',
    'execute'
  ),
  'authenticated clients cannot execute founder administration RPCs'
);
-- 02
select ok(
  has_function_privilege('service_role', 'public.has_founder_access(uuid)', 'execute')
  and has_function_privilege(
    'service_role',
    'public.founder_create_venue(uuid,text,text,text,text,double precision,double precision,smallint)',
    'execute'
  )
  and has_function_privilege(
    'service_role',
    'public.review_venue_registration(uuid,uuid,text,text,text,text,text,double precision,double precision,smallint)',
    'execute'
  )
  and has_function_privilege(
    'service_role',
    'public.create_partner_campaign_offer(uuid,uuid,uuid[],text,text,text,text,text,text,text,integer,timestamptz,timestamptz,integer,smallint,text,text)',
    'execute'
  ),
  'the trusted service role can execute founder administration RPCs'
);
-- 03
select ok(
  public.has_founder_access('a1000000-0000-4000-8000-000000000001'),
  'an active founder administrator is recognized'
);
-- 04
select ok(
  not public.has_founder_access('a1000000-0000-4000-8000-000000000002'),
  'an ordinary authenticated account has no founder access'
);

-- Founder-created listings are immediately usable, but still leave an audit
-- record. The same operation is rejected when the supplied user is not a
-- founder administrator.
-- 05
select lives_ok(
  $$
    select public.founder_create_venue(
      'a1000000-0000-4000-8000-000000000001',
      'Juniper Room',
      '88 King St W',
      'King West',
      'M5V 1M5',
      43.6455::double precision,
      -79.3940::double precision,
      90::smallint
    )
  $$,
  'a founder can create an approved venue listing'
);
-- 06
select ok(
  (
    select registration_status = 'approved'
      and publication_status = 'published'
      and neighbourhood = 'King West'
      and geofence_radius_metres = 90
      and location is not null
    from public.venues
    where display_name = 'Juniper Room'
  ),
  'a founder-created venue stores its approved publication and geofence state'
);
-- 07
select is(
  (
    select count(*)::integer
    from private.venue_reviews as review_record
    join public.venues as venue_record on venue_record.id = review_record.venue_id
    where venue_record.display_name = 'Juniper Room'
      and review_record.reviewer_id = 'a1000000-0000-4000-8000-000000000001'
      and review_record.decision = 'approved'
  ),
  1,
  'founder-created venue approval is recorded in the review history'
);
-- 08
select throws_ok(
  $$
    select public.founder_create_venue(
      'a1000000-0000-4000-8000-000000000002',
      'Unauthorized Room',
      '1 Front St W',
      'King West',
      'M5J 1E6',
      43.6440::double precision,
      -79.3810::double precision,
      75::smallint
    )
  $$,
  '42501',
  'founder_access_required',
  'a non-founder cannot create a venue through the privileged RPC'
);

-- A venue can self-register, but only a founder can complete its moderation
-- and supply the public location/geofence information.
-- 09
select lives_ok(
  $$
    select * from public.register_venue_account(
      'a1000000-0000-4000-8000-000000000004',
      'Harbour Assembly',
      '240 Richmond St W',
      'Harbour Assembly Hospitality Inc.',
      '240 Richmond St W, Toronto, ON',
      'Taylor Chen',
      'General Manager',
      'venue-ops@example.test',
      '+1 416 555 0148',
      'venue-terms-2026-07'
    )
  $$,
  'a venue business can create a pending registration'
);
-- 10
select ok(
  (
    select venue_record.registration_status = 'pending_review'
      and venue_record.publication_status = 'unpublished'
      and account_record.account_status = 'draft'
    from public.venue_accounts as account_record
    join public.venues as venue_record on venue_record.id = account_record.venue_id
    where account_record.auth_user_id = 'a1000000-0000-4000-8000-000000000004'
  ),
  'a self-registered venue remains unavailable until founder review'
);
-- 11
select lives_ok(
  $$
    select public.review_venue_registration(
      'a1000000-0000-4000-8000-000000000001',
      (select venue_id from public.venue_accounts
       where auth_user_id = 'a1000000-0000-4000-8000-000000000004'),
      'approved',
      'Approved for Toronto launch.',
      'Business registration reviewed.',
      'Queen West',
      'M5V 1Z6',
      43.6490::double precision,
      -79.3900::double precision,
      85::smallint
    )
  $$,
  'a founder can approve a self-registered venue'
);
-- 12
select ok(
  (
    select venue_record.registration_status = 'approved'
      and venue_record.publication_status = 'published'
      and venue_record.neighbourhood = 'Queen West'
      and venue_record.postal_code = 'M5V 1Z6'
      and venue_record.geofence_radius_metres = 85
      and venue_record.location is not null
      and account_record.account_status = 'active'
    from public.venue_accounts as account_record
    join public.venues as venue_record on venue_record.id = account_record.venue_id
    where account_record.auth_user_id = 'a1000000-0000-4000-8000-000000000004'
  ),
  'venue review atomically publishes the listing and activates its login'
);
-- 13
select is(
  (
    select count(*)::integer
    from private.venue_reviews as review_record
    join public.venue_accounts as account_record on account_record.venue_id = review_record.venue_id
    where account_record.auth_user_id = 'a1000000-0000-4000-8000-000000000004'
      and review_record.reviewer_id = 'a1000000-0000-4000-8000-000000000001'
      and review_record.decision = 'approved'
  ),
  1,
  'venue moderation stores the founder decision in its private audit trail'
);
-- 14
select throws_ok(
  $$
    select public.review_venue_registration(
      'a1000000-0000-4000-8000-000000000002',
      (select venue_id from public.venue_accounts
       where auth_user_id = 'a1000000-0000-4000-8000-000000000004'),
      'suspended', null, null, null, null, null, null, null
    )
  $$,
  '42501',
  'founder_access_required',
  'a non-founder cannot review or suspend a venue'
);

-- Partner media accepts only canonical paths inside the founder-managed
-- public bucket. In particular, a valid prefix cannot hide path traversal.
-- 15
select ok(
  (
    select bucket_record.public
      and bucket_record.file_size_limit = 5242880
      and bucket_record.allowed_mime_types @> array['image/jpeg', 'image/png', 'image/webp']::text[]
    from storage.buckets as bucket_record
    where bucket_record.id = 'partner-media'
  ),
  'partner media uses the public five-megabyte image-only bucket'
);
-- 16
select throws_ok(
  $$
    select public.upsert_partner(
      'a1000000-0000-4000-8000-000000000001',
      null::uuid,
      'Outside Bucket Ride',
      'Outside Bucket Ride Inc.',
      'https://example.test/outside',
      'Mobility',
      'other-bucket/outside/logo.webp',
      'Outside Bucket Ride logo',
      'Alex Park',
      'alex@example.test',
      null::text
    )
  $$,
  '23514',
  null,
  'a partner logo path outside partner-media is rejected by the database'
);
-- 17
select throws_ok(
  $$
    select public.upsert_partner(
      'a1000000-0000-4000-8000-000000000001',
      null::uuid,
      'Traversal Ride',
      'Traversal Ride Inc.',
      'https://example.test/traversal',
      'Mobility',
      'partner-media/traversal/../logo.webp',
      'Traversal Ride logo',
      'Alex Park',
      'alex@example.test',
      null::text
    )
  $$,
  '23514',
  null,
  'a partner-media path containing traversal segments is rejected'
);
-- 18
select lives_ok(
  $$
    select public.upsert_partner(
      'a1000000-0000-4000-8000-000000000001',
      null::uuid,
      'Skyway',
      'Skyway Mobility Inc.',
      'https://example.test/skyway',
      'Mobility',
      'partner-media/skyway/logo.webp',
      'Skyway logo',
      'Robin Patel',
      'partners@example.test',
      '+1 416 555 0177'
    )
  $$,
  'a founder can create a partner with a canonical approved media path'
);
-- 19
select ok(
  (
    select partner_record.status = 'active'
      and partner_record.approved_logo_storage_path = 'partner-media/skyway/logo.webp'
      and exists (
        select 1
        from private.partner_contacts as contact_record
        where contact_record.partner_id = partner_record.id
          and contact_record.is_primary
          and contact_record.email = 'partners@example.test'
      )
    from private.partners as partner_record
    where partner_record.brand_name = 'Skyway'
  ),
  'partner creation stores only the approved artwork snapshot and primary contact'
);

-- Manual trials must end in the future. Trial metadata is removed for active
-- subscriptions so entitlement checks have one unambiguous state.
-- 20
select lives_ok(
  $$
    select public.set_venue_subscription_plan(
      'a1000000-0000-4000-8000-000000000001',
      (select venue_id from public.venue_accounts
       where auth_user_id = 'a1000000-0000-4000-8000-000000000004'),
      'pro',
      'trialing',
      clock_timestamp() + interval '14 days'
    )
  $$,
  'a founder can grant a Pro trial with a future deadline'
);
-- 21
select ok(
  (
    select subscription_record.plan_code = 'pro'
      and subscription_record.stripe_status = 'trialing'
      and subscription_record.trial_ends_at > clock_timestamp()
    from private.venue_subscriptions as subscription_record
    join public.venue_accounts as account_record
      on account_record.venue_id = subscription_record.venue_id
    where account_record.auth_user_id = 'a1000000-0000-4000-8000-000000000004'
  ),
  'the future manual trial is stored as an effective Pro entitlement'
);
-- 22
select throws_ok(
  $$
    select public.set_venue_subscription_plan(
      'a1000000-0000-4000-8000-000000000001',
      (select venue_id from public.venue_accounts
       where auth_user_id = 'a1000000-0000-4000-8000-000000000004'),
      'pro',
      'trialing',
      clock_timestamp() - interval '1 minute'
    )
  $$,
  '22023',
  'invalid_trial_end',
  'a founder cannot create a trial that is already expired'
);
-- 23
select throws_ok(
  $$
    select public.set_venue_subscription_plan(
      'a1000000-0000-4000-8000-000000000001',
      (select venue_id from public.venue_accounts
       where auth_user_id = 'a1000000-0000-4000-8000-000000000004'),
      'pro',
      'active',
      clock_timestamp() + interval '14 days'
    )
  $$,
  '22023',
  'invalid_trial_end',
  'an active subscription cannot retain manual trial metadata'
);

-- Seed a normal venue offer so the same venue can prove the premium ranking
-- and the safe fallback after its Pro entitlement expires.
-- 24
select lives_ok(
  $$
    select * from public.submit_venue_offer(
      'a1000000-0000-4000-8000-000000000004',
      'a2000000-0000-4000-8000-000000000001',
      'Complimentary coat check',
      'Available after you check in.',
      'Complimentary coat check',
      'Confirm the active offer on this screen.',
      1800,
      ((clock_timestamp() at time zone 'America/Toronto') - interval '4 hours')::date - 1,
      ((clock_timestamp() at time zone 'America/Toronto') - interval '4 hours')::date + 1,
      array[0, 1, 2, 3, 4, 5, 6]::smallint[],
      null, null, null, null, null, null,
      true
    )
  $$,
  'an approved venue can submit its standard offer for founder review'
);
-- 25
select lives_ok(
  $$
    select public.review_offer_version(
      'a1000000-0000-4000-8000-000000000001',
      (
        select version_record.id
        from public.offer_versions as version_record
        join public.offers as offer_record on offer_record.id = version_record.offer_id
        where offer_record.submission_idempotency_key = 'a2000000-0000-4000-8000-000000000001'
      ),
      'approved',
      null,
      'Approved standard fallback offer.'
    )
  $$,
  'a founder can approve the venue-submitted offer'
);
-- 26
select ok(
  (
    select offer_record.lifecycle_status = 'live'
      and offer_record.offer_kind = 'standard'
      and version_record.approval_state = 'approved'
    from public.offers as offer_record
    join public.offer_versions as version_record
      on version_record.id = offer_record.current_approved_version_id
    where offer_record.submission_idempotency_key = 'a2000000-0000-4000-8000-000000000001'
  ),
  'the reviewed standard offer becomes the current live version'
);

-- Active Pro allows a founder-created partner campaign. Its offer ranks above
-- the venue offer while entitlement remains active.
-- 27
select lives_ok(
  $$
    select public.set_venue_subscription_plan(
      'a1000000-0000-4000-8000-000000000001',
      (select venue_id from public.venue_accounts
       where auth_user_id = 'a1000000-0000-4000-8000-000000000004'),
      'pro',
      'active',
      null
    )
  $$,
  'a founder can activate the venue Pro subscription'
);
-- 28
select ok(
  (
    select subscription_record.plan_code = 'pro'
      and subscription_record.stripe_status = 'active'
      and subscription_record.trial_ends_at is null
    from private.venue_subscriptions as subscription_record
    join public.venue_accounts as account_record
      on account_record.venue_id = subscription_record.venue_id
    where account_record.auth_user_id = 'a1000000-0000-4000-8000-000000000004'
  ),
  'active Pro replaces the manual trial state cleanly'
);
-- 29
select lives_ok(
  $$
    select public.create_partner_campaign_offer(
      'a1000000-0000-4000-8000-000000000001',
      (select id from private.partners where brand_name = 'Skyway'),
      array[(
        select venue_id from public.venue_accounts
        where auth_user_id = 'a1000000-0000-4000-8000-000000000004'
      )]::uuid[],
      'Skyway launch ride',
      '50% off your ride home',
      'For new Skyway riders.',
      'Get the Skyway app',
      'https://example.test/skyway/signup',
      'New riders only. Maximum discount applies.',
      'Outly partner offer',
      1800,
      clock_timestamp() - interval '1 hour',
      clock_timestamp() + interval '1 day',
      500,
      1::smallint,
      'Ride home offer',
      'skyway-mark'
    )
  $$,
  'an active Pro venue can receive a founder-created partner campaign'
);
-- 30
select ok(
  (
    select campaign_record.campaign_status = 'live'
      and campaign_record.approval_status = 'approved'
      and offer_record.lifecycle_status = 'live'
      and offer_record.display_priority = 100
      and version_record.presentation_kind = 'partner'
      and version_record.sponsor_logo_storage_path = 'partner-media/skyway/logo.webp'
    from private.partner_campaigns as campaign_record
    join private.offer_campaign_links as campaign_link
      on campaign_link.campaign_id = campaign_record.id
    join public.offers as offer_record on offer_record.id = campaign_link.offer_id
    join public.offer_versions as version_record
      on version_record.id = offer_record.current_approved_version_id
    where campaign_record.internal_name = 'Skyway launch ride'
  ),
  'campaign creation publishes one approved premium offer with immutable sponsor artwork'
);
-- 31
select is(
  (
    select count(*)::integer
    from public.list_eligible_offers(
      'a1000000-0000-4000-8000-000000000003',
      array[(
        select venue_id from public.venue_accounts
        where auth_user_id = 'a1000000-0000-4000-8000-000000000004'
      )]::uuid[],
      clock_timestamp()
    )
  ),
  1,
  'one highest-ranked offer is selected for an active Pro venue'
);
-- 32
select is(
  (
    select kind
    from public.list_eligible_offers(
      'a1000000-0000-4000-8000-000000000003',
      array[(
        select venue_id from public.venue_accounts
        where auth_user_id = 'a1000000-0000-4000-8000-000000000004'
      )]::uuid[],
      clock_timestamp()
    )
  ),
  'partner',
  'the eligible partner offer outranks the venue standard offer on active Pro'
);

-- Advance the subscription into an expired-trial state without waiting for
-- the clock. New campaign assignment must fail, and discovery must fall back
-- to the otherwise eligible standard offer instead of returning no offer.
-- 33
select lives_ok(
  $$
    update private.venue_subscriptions as subscription_record
    set stripe_status = 'trialing',
        trial_ends_at = clock_timestamp() - interval '1 minute'
    from public.venue_accounts as account_record
    where account_record.venue_id = subscription_record.venue_id
      and account_record.auth_user_id = 'a1000000-0000-4000-8000-000000000004'
  $$,
  'the test clock is advanced by storing a past trial deadline'
);
-- 34
select ok(
  (
    select subscription_record.plan_code = 'pro'
      and subscription_record.stripe_status = 'trialing'
      and subscription_record.trial_ends_at < clock_timestamp()
    from private.venue_subscriptions as subscription_record
    join public.venue_accounts as account_record
      on account_record.venue_id = subscription_record.venue_id
    where account_record.auth_user_id = 'a1000000-0000-4000-8000-000000000004'
  ),
  'the expired Pro trial remains stored but no longer grants entitlement'
);
-- 35
select throws_ok(
  $$
    select public.create_partner_campaign_offer(
      'a1000000-0000-4000-8000-000000000001',
      (select id from private.partners where brand_name = 'Skyway'),
      array[(
        select venue_id from public.venue_accounts
        where auth_user_id = 'a1000000-0000-4000-8000-000000000004'
      )]::uuid[],
      'Expired trial ride',
      'Free ride home',
      'For new Skyway riders.',
      'Get the Skyway app',
      'https://example.test/skyway/expired',
      'New riders only.',
      'Outly partner offer',
      900,
      clock_timestamp() - interval '1 hour',
      clock_timestamp() + interval '1 day',
      100,
      1::smallint,
      'Ride home offer',
      'skyway-mark'
    )
  $$,
  'P0001',
  'partner_campaign_requires_pro_venues',
  'an expired Pro trial cannot receive a new partner campaign'
);
-- 36
select is(
  (
    select count(*)::integer
    from public.list_eligible_offers(
      'a1000000-0000-4000-8000-000000000003',
      array[(
        select venue_id from public.venue_accounts
        where auth_user_id = 'a1000000-0000-4000-8000-000000000004'
      )]::uuid[],
      clock_timestamp()
    )
  ),
  1,
  'an ineligible premium offer does not suppress the venue standard fallback'
);
-- 37
select is(
  (
    select kind
    from public.list_eligible_offers(
      'a1000000-0000-4000-8000-000000000003',
      array[(
        select venue_id from public.venue_accounts
        where auth_user_id = 'a1000000-0000-4000-8000-000000000004'
      )]::uuid[],
      clock_timestamp()
    )
  ),
  'standard',
  'an expired Pro venue falls back to its standard offer kind'
);
-- 38
select is(
  (
    select title
    from public.list_eligible_offers(
      'a1000000-0000-4000-8000-000000000003',
      array[(
        select venue_id from public.venue_accounts
        where auth_user_id = 'a1000000-0000-4000-8000-000000000004'
      )]::uuid[],
      clock_timestamp()
    )
  ),
  'Complimentary coat check',
  'standard fallback preserves the approved venue offer copy'
);

select * from finish();
rollback;
