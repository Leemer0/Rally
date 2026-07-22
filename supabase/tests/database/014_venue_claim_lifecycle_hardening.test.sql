begin;

set local role postgres;
set local search_path = public, extensions, pgtap;

create extension if not exists pgtap with schema extensions;

select plan(53);

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
    ('e1000000-0000-4000-8000-000000000001'::uuid, 'lifecycle-founder@example.test'),
    ('e1000000-0000-4000-8000-000000000002'::uuid, 'lifecycle-founder-two@example.test'),
    ('e1000000-0000-4000-8000-000000000003'::uuid, 'stale-claim@example.test'),
    ('e1000000-0000-4000-8000-000000000004'::uuid, 'direct-delete@example.test'),
    ('e1000000-0000-4000-8000-000000000005'::uuid, 'replacement-claim@example.test'),
    ('e1000000-0000-4000-8000-000000000006'::uuid, 'reinstate-claim@example.test'),
    ('e1000000-0000-4000-8000-000000000007'::uuid, 'withdrawn-claim@example.test'),
    ('e1000000-0000-4000-8000-000000000008'::uuid, 'next-claim@example.test')
) as user_record(id, email);

insert into private.internal_admins (user_id)
values
  ('e1000000-0000-4000-8000-000000000001'),
  ('e1000000-0000-4000-8000-000000000002');

set local role service_role;

-- A rejected historical claim must not reroute deletion away from the user's
-- newer, self-registered listing.
select lives_ok(
  $$select public.founder_create_venue(
    'e1000000-0000-4000-8000-000000000001',
    'Lifecycle Founder Listing A',
    '101 King St W',
    'King West',
    'M5X 1A9',
    43.6487::double precision,
    -79.3817::double precision,
    75::smallint
  )$$,
  'founder listing A is created'
);

select lives_ok(
  $$select * from public.register_venue_account(
    'e1000000-0000-4000-8000-000000000003',
    'Lifecycle Founder Listing A',
    '101 King St W',
    'Stale Claim Hospitality Inc.',
    '101 King St W, Toronto, ON',
    'Stale Claimant',
    'Owner',
    'stale-claim@example.test',
    '+1 416 555 0203',
    'venue-terms-2026-07',
    (select id from public.venues where display_name = 'Lifecycle Founder Listing A')
  )$$,
  'the first listing claim is registered'
);

select lives_ok(
  $$select public.review_venue_registration(
    'e1000000-0000-4000-8000-000000000001',
    (select id from public.venues where display_name = 'Lifecycle Founder Listing A'),
    'rejected',
    'The business relationship could not be verified.',
    'Lifecycle rejection'
  )$$,
  'the historical claim is rejected'
);

select throws_ok(
  $$select * from public.complete_consumer_onboarding(
    'e1000000-0000-4000-8000-000000000003',
    'Stale',
    '1995-01-01'::date,
    'other',
    'terms-2026-07',
    'privacy-2026-07'
  )$$,
  'P0001',
  'account_type_conflict',
  'a rejected business identity cannot silently become a consumer identity'
);

select lives_ok(
  $$select * from public.register_venue_account(
    'e1000000-0000-4000-8000-000000000003',
    'Lifecycle Fresh Listing B',
    '202 College St',
    'Fresh Listing Hospitality Inc.',
    '202 College St, Toronto, ON',
    'Stale Claimant',
    'Owner',
    'stale-claim@example.test',
    '+1 416 555 0203',
    'venue-terms-2026-07',
    null
  )$$,
  'the same venue identity can submit a distinct new listing after rejection'
);

select lives_ok(
  $$select * from public.prepare_account_deletion(
    'e1000000-0000-4000-8000-000000000003',
    'venue',
    'e1000000-0000-4000-8000-000000000103'
  )$$,
  'deleting the newer account routes through the fresh-listing workflow'
);

select ok(
  (
    select registration_status = 'approved'
      and publication_status = 'published'
    from public.venues
    where display_name = 'Lifecycle Founder Listing A'
  ),
  'historical founder listing A remains published'
);

select ok(
  (
    select registration_status = 'archived'
      and publication_status = 'unpublished'
    from public.venues
    where display_name = 'Lifecycle Fresh Listing B'
  ),
  'current fresh listing B is archived by deletion'
);

select is(
  (
    select account_status
    from public.venue_accounts
    where auth_user_id = 'e1000000-0000-4000-8000-000000000003'
  ),
  'deletion_pending',
  'fresh-listing access follows the base resumable deletion state'
);

select is(
  (
    select count(*)::integer
    from private.venue_business_details as business_record
    join public.venues as venue_record on venue_record.id = business_record.venue_id
    where venue_record.display_name = 'Lifecycle Fresh Listing B'
  ),
  0,
  'fresh-listing private business details are removed'
);

select is(
  (
    select claim_status
    from private.venue_account_claims
    where auth_user_id = 'e1000000-0000-4000-8000-000000000003'
      and venue_id = (select id from public.venues where display_name = 'Lifecycle Founder Listing A')
  ),
  'rejected',
  'the unrelated rejected claim remains immutable history'
);

-- Direct Auth deletion must withdraw an open claim and perform the same private
-- cleanup as the app deletion endpoint.
select lives_ok(
  $$select public.founder_create_venue(
    'e1000000-0000-4000-8000-000000000001',
    'Lifecycle Founder Listing C',
    '303 Ossington Ave',
    'Ossington',
    'M6J 2Z8',
    43.6488::double precision,
    -79.4207::double precision,
    75::smallint
  )$$,
  'founder listing C is created'
);

select lives_ok(
  $$select * from public.register_venue_account(
    'e1000000-0000-4000-8000-000000000004',
    'Lifecycle Founder Listing C',
    '303 Ossington Ave',
    'Direct Delete Hospitality Inc.',
    '303 Ossington Ave, Toronto, ON',
    'Direct Delete Claimant',
    'Operator',
    'direct-delete@example.test',
    '+1 416 555 0204',
    'venue-terms-2026-07',
    (select id from public.venues where display_name = 'Lifecycle Founder Listing C')
  )$$,
  'the direct-delete claim is pending'
);

set local role postgres;

select lives_ok(
  $$delete from auth.users
    where id = 'e1000000-0000-4000-8000-000000000004'$$,
  'direct Auth deletion succeeds for an open claimant'
);

set local role service_role;

select is(
  (
    select claim_status
    from private.venue_account_claims
    where venue_id = (select id from public.venues where display_name = 'Lifecycle Founder Listing C')
    order by id desc
    limit 1
  ),
  'withdrawn',
  'the orphan-prone open claim is closed atomically'
);

select ok(
  (
    select auth_user_id is null
    from private.venue_account_claims
    where venue_id = (select id from public.venues where display_name = 'Lifecycle Founder Listing C')
    order by id desc
    limit 1
  ),
  'the deleted claimant reference is anonymized'
);

select is(
  (
    select withdrawal_reason
    from private.venue_account_claims
    where venue_id = (select id from public.venues where display_name = 'Lifecycle Founder Listing C')
    order by id desc
    limit 1
  ),
  'auth_identity_deleted',
  'the direct Auth deletion reason is retained'
);

select is(
  (
    select count(*)::integer
    from public.venue_accounts
    where venue_id = (select id from public.venues where display_name = 'Lifecycle Founder Listing C')
  ),
  0,
  'direct Auth deletion removes dashboard access'
);

select is(
  (
    select count(*)::integer
    from private.venue_business_details
    where venue_id = (select id from public.venues where display_name = 'Lifecycle Founder Listing C')
  ),
  0,
  'direct Auth deletion removes private business details'
);

select ok(
  (
    select registration_status = 'approved'
      and publication_status = 'published'
    from public.venues
    where display_name = 'Lifecycle Founder Listing C'
  ),
  'direct claimant deletion preserves the public founder listing'
);

select lives_ok(
  $$select * from public.register_venue_account(
    'e1000000-0000-4000-8000-000000000005',
    'Lifecycle Founder Listing C',
    '303 Ossington Ave',
    'Replacement Hospitality Inc.',
    '303 Ossington Ave, Toronto, ON',
    'Replacement Claimant',
    'Owner',
    'replacement-claim@example.test',
    '+1 416 555 0205',
    'venue-terms-2026-07',
    (select id from public.venues where display_name = 'Lifecycle Founder Listing C')
  )$$,
  'a replacement claimant can immediately claim the released listing'
);

select is(
  (
    select account_status
    from public.venue_accounts
    where auth_user_id = 'e1000000-0000-4000-8000-000000000005'
  ),
  'draft',
  'replacement access remains draft before review'
);

-- Reviewer identity deletion must not destroy or invalidate reviewed history.
select lives_ok(
  $$select public.review_venue_registration(
    'e1000000-0000-4000-8000-000000000001',
    (select id from public.venues where display_name = 'Lifecycle Founder Listing C'),
    'approved',
    'Replacement ownership verified.',
    'Lifecycle approval'
  )$$,
  'the replacement claim is approved'
);

select is(
  (
    select reviewed_by_snapshot
    from private.venue_account_claims
    where auth_user_id = 'e1000000-0000-4000-8000-000000000005'
    order by id desc
    limit 1
  ),
  'e1000000-0000-4000-8000-000000000001'::uuid,
  'the reviewer snapshot is recorded at decision time'
);

set local role postgres;

select lives_ok(
  $$delete from auth.users
    where id = 'e1000000-0000-4000-8000-000000000001'$$,
  'a founder Auth identity can be deleted after reviewing claims'
);

set local role service_role;

select ok(
  (
    select reviewed_by is null
    from private.venue_account_claims
    where auth_user_id = 'e1000000-0000-4000-8000-000000000005'
    order by id desc
    limit 1
  ),
  'the live reviewer FK is cleared'
);

select is(
  (
    select reviewed_by_snapshot
    from private.venue_account_claims
    where auth_user_id = 'e1000000-0000-4000-8000-000000000005'
    order by id desc
    limit 1
  ),
  'e1000000-0000-4000-8000-000000000001'::uuid,
  'review attribution survives founder Auth deletion'
);

select is(
  (
    select claim_status
    from private.venue_account_claims
    where auth_user_id = 'e1000000-0000-4000-8000-000000000005'
    order by id desc
    limit 1
  ),
  'approved',
  'reviewed claim history remains valid'
);

-- A departing claimant must not transfer founder-managed Pro access or paid
-- placement to the next operator.
select lives_ok(
  $$select public.set_venue_subscription_plan(
    'e1000000-0000-4000-8000-000000000002',
    (select id from public.venues where display_name = 'Lifecycle Founder Listing C'),
    'pro',
    'active',
    null
  )$$,
  'the approved claimant receives founder-managed Pro access'
);

update public.venues
set placement_state = 'featured'
where display_name = 'Lifecycle Founder Listing C';

select lives_ok(
  $$select * from public.prepare_account_deletion(
    'e1000000-0000-4000-8000-000000000005',
    'venue',
    'e1000000-0000-4000-8000-000000000105'
  )$$,
  'the approved claimant can delete after founder-managed Pro access'
);

select ok(
  (
    select plan_code = 'free'
      and stripe_status = 'free'
      and stripe_customer_id is null
      and stripe_subscription_id is null
    from private.venue_subscriptions
    where venue_id = (select id from public.venues where display_name = 'Lifecycle Founder Listing C')
  ),
  'billing and Pro entitlement state resets to Free'
);

select ok(
  (
    select placement_state = 'standard'
      and current_marker_asset_id is null
    from public.venues
    where display_name = 'Lifecycle Founder Listing C'
  ),
  'paid discovery presentation resets when access is retired'
);

select ok(
  (
    select registration_status = 'approved'
      and publication_status = 'published'
    from public.venues
    where display_name = 'Lifecycle Founder Listing C'
  ),
  'billing reset does not remove the founder-created listing'
);

select lives_ok(
  $$select * from public.register_venue_account(
    'e1000000-0000-4000-8000-000000000008',
    'Lifecycle Founder Listing C',
    '303 Ossington Ave',
    'Next Claim Hospitality Inc.',
    '303 Ossington Ave, Toronto, ON',
    'Next Claimant',
    'Owner',
    'next-claim@example.test',
    '+1 416 555 0208',
    'venue-terms-2026-07',
    (select id from public.venues where display_name = 'Lifecycle Founder Listing C')
  )$$,
  'the next claimant can request access after the prior operator leaves'
);

select ok(
  (
    select account_record.account_status = 'draft'
      and subscription_record.plan_code = 'free'
      and subscription_record.stripe_status = 'free'
    from public.venue_accounts as account_record
    join private.venue_subscriptions as subscription_record
      on subscription_record.venue_id = account_record.venue_id
    where account_record.auth_user_id = 'e1000000-0000-4000-8000-000000000008'
  ),
  'a replacement claimant starts draft and Free'
);

-- Suspending and reinstating the public listing cannot bypass claim approval.
select lives_ok(
  $$select public.founder_create_venue(
    'e1000000-0000-4000-8000-000000000002',
    'Lifecycle Reinstate Listing D',
    '404 Dundas St W',
    'Chinatown',
    'M5T 1G7',
    43.6533::double precision,
    -79.3978::double precision,
    75::smallint
  )$$,
  'founder listing D is created'
);

select lives_ok(
  $$select * from public.register_venue_account(
    'e1000000-0000-4000-8000-000000000006',
    'Lifecycle Reinstate Listing D',
    '404 Dundas St W',
    'Reinstate Hospitality Inc.',
    '404 Dundas St W, Toronto, ON',
    'Reinstate Claimant',
    'Owner',
    'reinstate-claim@example.test',
    '+1 416 555 0206',
    'venue-terms-2026-07',
    (select id from public.venues where display_name = 'Lifecycle Reinstate Listing D')
  )$$,
  'listing D receives a pending claim'
);

select lives_ok(
  $$select public.review_venue_registration(
    'e1000000-0000-4000-8000-000000000002',
    (select id from public.venues where display_name = 'Lifecycle Reinstate Listing D'),
    'suspended'
  )$$,
  'the public listing can be suspended independently'
);

select lives_ok(
  $$select public.review_venue_registration(
    'e1000000-0000-4000-8000-000000000002',
    (select id from public.venues where display_name = 'Lifecycle Reinstate Listing D'),
    'reinstated'
  )$$,
  'the public listing can be reinstated'
);

select is(
  (
    select account_status
    from public.venue_accounts
    where auth_user_id = 'e1000000-0000-4000-8000-000000000006'
  ),
  'draft',
  'reinstatement does not activate the pending claimant'
);

select is(
  (
    select claim_status
    from private.venue_account_claims
    where auth_user_id = 'e1000000-0000-4000-8000-000000000006'
    order by id desc
    limit 1
  ),
  'pending_review',
  'reinstatement leaves claim review pending'
);

select lives_ok(
  $$select public.review_venue_registration(
    'e1000000-0000-4000-8000-000000000002',
    (select id from public.venues where display_name = 'Lifecycle Reinstate Listing D'),
    'approved',
    'Access verified.',
    'Approved after reinstatement'
  )$$,
  'explicit claim approval succeeds after reinstatement'
);

select is(
  (
    select account_status
    from public.venue_accounts
    where auth_user_id = 'e1000000-0000-4000-8000-000000000006'
  ),
  'active',
  'only explicit claim approval activates access'
);

update private.venue_subscriptions
set plan_code = 'pro',
    stripe_customer_id = 'cus_lifecycle_d',
    stripe_subscription_id = 'sub_lifecycle_d',
    stripe_price_id = 'price_lifecycle_d',
    stripe_status = 'active'
where venue_id = (select id from public.venues where display_name = 'Lifecycle Reinstate Listing D');

select throws_ok(
  $$select * from public.prepare_account_deletion(
    'e1000000-0000-4000-8000-000000000006',
    'venue',
    'e1000000-0000-4000-8000-000000000106'
  )$$,
  'P0001',
  'active_subscription_cancellation_required',
  'a live Stripe subscription must be detached before access is deleted'
);

select is(
  (
    select account_status
    from public.venue_accounts
    where auth_user_id = 'e1000000-0000-4000-8000-000000000006'
  ),
  'active',
  'failed deletion leaves venue access intact'
);

select lives_ok(
  $$select public.set_venue_subscription_plan(
    'e1000000-0000-4000-8000-000000000002',
    (select id from public.venues where display_name = 'Lifecycle Reinstate Listing D'),
    'free',
    'free',
    null
  )$$,
  'the founder can detach the test subscription state'
);

select lives_ok(
  $$select * from public.prepare_account_deletion(
    'e1000000-0000-4000-8000-000000000006',
    'venue',
    'e1000000-0000-4000-8000-000000000106'
  )$$,
  'deletion proceeds after subscription detachment'
);

-- Once deletion wins the row lock, a late moderation request cannot approve
-- the withdrawn claim or recreate venue access.
select lives_ok(
  $$select public.founder_create_venue(
    'e1000000-0000-4000-8000-000000000002',
    'Lifecycle Withdrawn Listing E',
    '505 Queen St W',
    'Queen West',
    'M5V 2B4',
    43.6481::double precision,
    -79.3997::double precision,
    75::smallint
  )$$,
  'founder listing E is created'
);

select lives_ok(
  $$select * from public.register_venue_account(
    'e1000000-0000-4000-8000-000000000007',
    'Lifecycle Withdrawn Listing E',
    '505 Queen St W',
    'Withdrawn Hospitality Inc.',
    '505 Queen St W, Toronto, ON',
    'Withdrawn Claimant',
    'Owner',
    'withdrawn-claim@example.test',
    '+1 416 555 0207',
    'venue-terms-2026-07',
    (select id from public.venues where display_name = 'Lifecycle Withdrawn Listing E')
  )$$,
  'listing E receives a pending claim'
);

select lives_ok(
  $$select * from public.prepare_account_deletion(
    'e1000000-0000-4000-8000-000000000007',
    'venue',
    'e1000000-0000-4000-8000-000000000107'
  )$$,
  'deletion withdraws the pending claim'
);

select ok(
  (
    select claim_status = 'withdrawn'
      and withdrawal_reason = 'account_deleted'
    from private.venue_account_claims
    where auth_user_id = 'e1000000-0000-4000-8000-000000000007'
    order by id desc
    limit 1
  ),
  'application deletion records a terminal withdrawal reason'
);

select throws_ok(
  $$select public.review_venue_registration(
    'e1000000-0000-4000-8000-000000000002',
    (select id from public.venues where display_name = 'Lifecycle Withdrawn Listing E'),
    'approved',
    'Too late.',
    'Should not apply'
  )$$,
  'P0001',
  'venue_claim_not_reviewable',
  'a late founder approval cannot revive a withdrawn claim'
);

select ok(
  (
    select venue_record.registration_status = 'approved'
      and venue_record.publication_status = 'published'
      and not exists (
        select 1
        from public.venue_accounts as account_record
        where account_record.venue_id = venue_record.id
      )
    from public.venues as venue_record
    where venue_record.display_name = 'Lifecycle Withdrawn Listing E'
  ),
  'withdrawn claim leaves the public listing live with no dashboard access'
);

select * from finish();

rollback;
