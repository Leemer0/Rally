begin;

set local role postgres;
set local search_path = public, extensions, pgtap;

create extension if not exists pgtap with schema extensions;

select plan(48);

select has_table(
  'private',
  'pending_venue_registrations',
  'unconfirmed venue registration payloads have a private table'
);
select has_table(
  'private',
  'venue_account_claims',
  'existing-listing claims have a private audit table'
);
select ok(
  not has_table_privilege('authenticated', 'private.pending_venue_registrations', 'select'),
  'authenticated clients cannot read pending business registration data'
);
select ok(
  not has_function_privilege(
    'authenticated',
    'public.store_pending_venue_registration(uuid,text,text,text,text,text,text,text,text,text,uuid)',
    'execute'
  ),
  'authenticated Data API callers cannot invoke the pending registration RPC directly'
);

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
  user_record.email_confirmed_at,
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{}'::jsonb,
  now(),
  now()
from (
  values
    ('c1000000-0000-4000-8000-000000000001'::uuid, 'claim-founder@example.test', now()),
    ('c1000000-0000-4000-8000-000000000002'::uuid, 'first-claim@example.test', null::timestamptz),
    ('c1000000-0000-4000-8000-000000000003'::uuid, 'legitimate-claim@example.test', now()),
    ('c1000000-0000-4000-8000-000000000004'::uuid, 'fresh-venue@example.test', now()),
    ('c1000000-0000-4000-8000-000000000005'::uuid, 'competing-claim@example.test', now())
) as user_record(id, email, email_confirmed_at);

insert into private.internal_admins (user_id)
values ('c1000000-0000-4000-8000-000000000001');

set local role service_role;

select lives_ok(
  $$select public.founder_create_venue(
    'c1000000-0000-4000-8000-000000000001',
    'Foundry Hall Claim Test',
    '88 King St W',
    'King West',
    'M5H 1J9',
    43.6490::double precision,
    -79.3810::double precision,
    75::smallint
  )$$,
  'a founder can create the public listing before a business account exists'
);

select is(
  (
    select subscription_record.plan_code
    from private.venue_subscriptions as subscription_record
    join public.venues as venue_record on venue_record.id = subscription_record.venue_id
    where venue_record.display_name = 'Foundry Hall Claim Test'
  ),
  'free',
  'a founder-created listing receives the default subscription record'
);

select lives_ok(
  $$select public.store_pending_venue_registration(
    'c1000000-0000-4000-8000-000000000002',
    'Foundry Hall Claim Test',
    '88 King St W',
    'Foundry Hall Hospitality Inc.',
    '88 King St W, Toronto, ON',
    'First Claimant',
    'General Manager',
    'first-claim@example.test',
    '+1 416 555 0101',
    'venue-terms-2026-07',
    (select id from public.venues where display_name = 'Foundry Hall Claim Test')
  )$$,
  'an unconfirmed signup can store its registration privately'
);

select is(
  (
    select pending_state
    from private.pending_venue_registrations
    where auth_user_id = 'c1000000-0000-4000-8000-000000000002'
  ),
  'pending_email_confirmation',
  'the registration remains pending until Auth confirms the email'
);

select throws_ok(
  $$select * from public.register_venue_account(
    'c1000000-0000-4000-8000-000000000002',
    'Foundry Hall Claim Test',
    '88 King St W',
    'Foundry Hall Hospitality Inc.',
    '88 King St W, Toronto, ON',
    'First Claimant',
    'General Manager',
    'first-claim@example.test',
    '+1 416 555 0101',
    'venue-terms-2026-07',
    (select id from public.venues where display_name = 'Foundry Hall Claim Test')
  )$$,
  'P0001',
  'email_confirmation_required',
  'direct registration cannot bypass email confirmation'
);

select throws_ok(
  $$select * from public.consume_pending_venue_registration(
    'c1000000-0000-4000-8000-000000000002'
  )$$,
  'P0001',
  'email_confirmation_required',
  'the stored registration cannot be consumed before confirmation'
);

select is(
  (
    select count(*)::integer
    from public.venue_accounts
    where auth_user_id = 'c1000000-0000-4000-8000-000000000002'
  ),
  0,
  'no account link exists before email confirmation'
);

set local role postgres;
update auth.users
set email_confirmed_at = clock_timestamp(), updated_at = clock_timestamp()
where id = 'c1000000-0000-4000-8000-000000000002';
set local role service_role;

select lives_ok(
  $$select * from public.consume_pending_venue_registration(
    'c1000000-0000-4000-8000-000000000002'
  )$$,
  'a confirmed business email can consume the stored claim registration'
);

select is(
  (
    select account_status
    from public.venue_accounts
    where auth_user_id = 'c1000000-0000-4000-8000-000000000002'
  ),
  'draft',
  'a claimed listing remains unavailable to the venue dashboard actions before founder approval'
);

select ok(
  (
    select registration_status = 'approved'
      and publication_status = 'published'
    from public.venues
    where display_name = 'Foundry Hall Claim Test'
  ),
  'submitting a claim does not change the public listing state'
);

select is(
  (
    select claim_status
    from private.venue_account_claims
    where auth_user_id = 'c1000000-0000-4000-8000-000000000002'
  ),
  'pending_review',
  'the account link enters the founder claim-review queue'
);

select is(
  (
    public.get_founder_admin_snapshot('c1000000-0000-4000-8000-000000000001')
      #>> '{metrics,pending_venue_claims}'
  )::integer,
  1,
  'the founder snapshot counts pending listing claims'
);

select is(
  (
    select venue_payload ->> 'plan_code'
    from jsonb_array_elements(
      public.get_founder_admin_snapshot('c1000000-0000-4000-8000-000000000001') -> 'venues'
    ) as venue_payload
    where venue_payload ->> 'name' = 'Foundry Hall Claim Test'
  ),
  'free',
  'the founder venue snapshot exposes the subscription plan'
);

select is(
  (
    select (venue_payload ->> 'partner_campaign_access')::boolean
    from jsonb_array_elements(
      public.get_founder_admin_snapshot('c1000000-0000-4000-8000-000000000001') -> 'venues'
    ) as venue_payload
    where venue_payload ->> 'name' = 'Foundry Hall Claim Test'
  ),
  false,
  'a free venue is not eligible for partner campaign targeting'
);

select throws_ok(
  $$select public.store_pending_venue_registration(
    'c1000000-0000-4000-8000-000000000005',
    'Foundry Hall Claim Test',
    '88 King St W',
    'Competing Hospitality Inc.',
    '88 King St W, Toronto, ON',
    'Competing Claimant',
    'Owner',
    'competing-claim@example.test',
    '+1 416 555 0105',
    'venue-terms-2026-07',
    (select id from public.venues where display_name = 'Foundry Hall Claim Test')
  )$$,
  'P0001',
  'venue_claim_unavailable',
  'a listing with a pending account cannot be claimed concurrently'
);

select lives_ok(
  $$select public.review_venue_registration(
    'c1000000-0000-4000-8000-000000000001',
    (select id from public.venues where display_name = 'Foundry Hall Claim Test'),
    'rejected',
    'We could not verify this claim.',
    'Test rejection'
  )$$,
  'a founder can reject the account claim without moderating the venue'
);

select ok(
  (
    select registration_status = 'approved'
      and publication_status = 'published'
    from public.venues
    where display_name = 'Foundry Hall Claim Test'
  ),
  'claim rejection leaves the approved public listing online'
);

select is(
  (
    select count(*)::integer
    from public.venue_accounts
    where auth_user_id = 'c1000000-0000-4000-8000-000000000002'
  ),
  0,
  'claim rejection removes the provisional account link'
);

select is(
  (
    select count(*)::integer
    from private.venue_business_details as business_record
    join public.venues as venue_record on venue_record.id = business_record.venue_id
    where venue_record.display_name = 'Foundry Hall Claim Test'
  ),
  0,
  'claim rejection removes the rejected claimant business details'
);

select is(
  (
    select claim_status
    from private.venue_account_claims
    where auth_user_id = 'c1000000-0000-4000-8000-000000000002'
  ),
  'rejected',
  'the rejected claim decision remains in the private audit trail'
);

select is(
  (
    select count(*)::integer
    from private.pending_venue_registrations
    where auth_user_id = 'c1000000-0000-4000-8000-000000000002'
  ),
  0,
  'a rejected claim does not leave stale pending registration data'
);

select lives_ok(
  $$select public.store_pending_venue_registration(
    'c1000000-0000-4000-8000-000000000003',
    'Foundry Hall Claim Test',
    '88 King St W',
    'Foundry Hall Operations Inc.',
    '88 King St W, Toronto, ON',
    'Legitimate Claimant',
    'Owner',
    'legitimate-claim@example.test',
    '+1 416 555 0103',
    'venue-terms-2026-07',
    (select id from public.venues where display_name = 'Foundry Hall Claim Test')
  )$$,
  'a later legitimate claimant can store a registration for the same listing'
);

select lives_ok(
  $$select * from public.consume_pending_venue_registration(
    'c1000000-0000-4000-8000-000000000003'
  )$$,
  'the later confirmed claimant can create a new provisional link'
);

select is(
  (
    select claim_status
    from private.venue_account_claims
    where auth_user_id = 'c1000000-0000-4000-8000-000000000003'
  ),
  'pending_review',
  'the later claim independently enters founder review'
);

select lives_ok(
  $$select public.review_venue_registration(
    'c1000000-0000-4000-8000-000000000001',
    (select id from public.venues where display_name = 'Foundry Hall Claim Test'),
    'approved',
    'Ownership verified.',
    'Test approval'
  )$$,
  'a founder can approve the legitimate account link'
);

select is(
  (
    select account_status
    from public.venue_accounts
    where auth_user_id = 'c1000000-0000-4000-8000-000000000003'
  ),
  'active',
  'founder approval activates the claimed venue account'
);

select ok(
  (
    select registration_status = 'approved'
      and publication_status = 'published'
    from public.venues
    where display_name = 'Foundry Hall Claim Test'
  ),
  'claim approval also leaves the existing public listing unchanged'
);

select lives_ok(
  $$select * from public.consume_pending_venue_registration(
    'c1000000-0000-4000-8000-000000000003'
  )$$,
  'the confirmation callback can replay safely after claim creation'
);

select is(
  (
    select count(*)::integer
    from public.venue_accounts
    where auth_user_id = 'c1000000-0000-4000-8000-000000000003'
  ),
  1,
  'a confirmation replay does not duplicate the account link'
);

select lives_ok(
  $$select public.set_venue_subscription_plan(
    'c1000000-0000-4000-8000-000000000001',
    (select id from public.venues where display_name = 'Foundry Hall Claim Test'),
    'pro',
    'active',
    null
  )$$,
  'a founder can activate Pro for the claimed venue'
);

select is(
  (
    select venue_payload ->> 'plan_code'
    from jsonb_array_elements(
      public.get_founder_admin_snapshot('c1000000-0000-4000-8000-000000000001') -> 'venues'
    ) as venue_payload
    where venue_payload ->> 'name' = 'Foundry Hall Claim Test'
  ),
  'pro',
  'the founder venue snapshot reflects the Pro plan'
);

select is(
  (
    select (venue_payload ->> 'partner_campaign_access')::boolean
    from jsonb_array_elements(
      public.get_founder_admin_snapshot('c1000000-0000-4000-8000-000000000001') -> 'venues'
    ) as venue_payload
    where venue_payload ->> 'name' = 'Foundry Hall Claim Test'
  ),
  true,
  'the founder snapshot marks an active Pro venue as a partner campaign target'
);

select lives_ok(
  $$select public.set_venue_subscription_plan(
    'c1000000-0000-4000-8000-000000000001',
    (select id from public.venues where display_name = 'Foundry Hall Claim Test'),
    'free',
    'free',
    null
  )$$,
  'a claimed venue can return to Free before deleting its account'
);

select lives_ok(
  $$select * from public.prepare_account_deletion(
    'c1000000-0000-4000-8000-000000000003',
    'venue',
    'c1000000-0000-4000-8000-000000000103'
  )$$,
  'an approved listing claimant can prepare account deletion'
);

select ok(
  (
    select registration_status = 'approved'
      and publication_status = 'published'
    from public.venues
    where display_name = 'Foundry Hall Claim Test'
  ),
  'deleting a claimant account preserves the founder-created public listing'
);

select is(
  (
    select count(*)::integer
    from public.venue_accounts
    where auth_user_id = 'c1000000-0000-4000-8000-000000000003'
  ),
  0,
  'claimant account deletion removes venue dashboard access'
);

select is(
  (
    select claim_status
    from private.venue_account_claims
    where auth_user_id = 'c1000000-0000-4000-8000-000000000003'
  ),
  'approved',
  'approved claim history is retained until Auth deletion anonymizes its user reference'
);

select lives_ok(
  $$select * from public.register_venue_account(
    'c1000000-0000-4000-8000-000000000004',
    'Fresh Venue Claim Test',
    '50 College St',
    'Fresh Venue Hospitality Inc.',
    '50 College St, Toronto, ON',
    'Fresh Owner',
    'Owner',
    'fresh-venue@example.test',
    '+1 416 555 0104',
    'venue-terms-2026-07'
  )$$,
  'confirmed fresh-listing registration remains backward compatible'
);

select ok(
  (
    select venue_record.registration_status = 'pending_review'
      and venue_record.publication_status = 'unpublished'
      and account_record.account_status = 'draft'
    from public.venue_accounts as account_record
    join public.venues as venue_record on venue_record.id = account_record.venue_id
    where account_record.auth_user_id = 'c1000000-0000-4000-8000-000000000004'
  ),
  'fresh registration still creates a founder-reviewed unpublished listing'
);

select throws_ok(
  $$select public.store_pending_venue_registration(
    'c1000000-0000-4000-8000-000000000002',
    'Fresh Venue Claim Test',
    '50 College St',
    'Retry Hospitality Inc.',
    '50 College St, Toronto, ON',
    'Retry Claimant',
    'Owner',
    'first-claim@example.test',
    '+1 416 555 0102',
    'venue-terms-2026-07',
    (select venue_id from public.venue_accounts
     where auth_user_id = 'c1000000-0000-4000-8000-000000000004')
  )$$,
  'P0001',
  'venue_claim_unavailable',
  'an unapproved fresh registration cannot be claimed as an existing listing'
);

select throws_ok(
  $$select public.store_pending_venue_registration(
    'c1000000-0000-4000-8000-000000000002',
    'Another Venue',
    '1 Queen St W',
    'Another Hospitality Inc.',
    '1 Queen St W, Toronto, ON',
    'Retry Claimant',
    'Owner',
    'wrong-email@example.test',
    '+1 416 555 0102',
    'venue-terms-2026-07',
    null
  )$$,
  'P0001',
  'business_email_mismatch',
  'pending storage preserves the Auth-to-business email equality check'
);

select is(
  (
    select count(*)::integer
    from public.venues
    where display_name = 'Foundry Hall Claim Test'
  ),
  1,
  'claim retries never duplicate the founder-created public listing'
);

select lives_ok(
  $$select * from public.prepare_account_deletion(
    'c1000000-0000-4000-8000-000000000002',
    'venue',
    'c1000000-0000-4000-8000-000000000102'
  )$$,
  'a rejected claimant can still delete the remaining Auth account'
);

select ok(
  (
    select registration_status = 'approved'
      and publication_status = 'published'
    from public.venues
    where display_name = 'Foundry Hall Claim Test'
  ),
  'rejected claimant account deletion also preserves the public listing'
);

select * from finish();

rollback;
