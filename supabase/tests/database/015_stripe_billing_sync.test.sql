begin;

set local role postgres;
set local search_path = public, extensions, pgtap;

create extension if not exists pgtap with schema extensions;

select plan(19);

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
    ('f1000000-0000-4000-8000-000000000001'::uuid, 'stripe-founder@example.test'),
    ('f1000000-0000-4000-8000-000000000002'::uuid, 'stripe-venue@example.test')
) as user_record(id, email);

insert into private.internal_admins (user_id)
values ('f1000000-0000-4000-8000-000000000001');

set local role service_role;

select public.founder_create_venue(
  'f1000000-0000-4000-8000-000000000001',
  'Billing Test Room',
  '100 King St W',
  'King West',
  'M5X 1A9',
  43.6487::double precision,
  -79.3817::double precision,
  75::smallint
);

select * from public.register_venue_account(
  'f1000000-0000-4000-8000-000000000002',
  'Billing Test Room',
  '100 King St W',
  'Billing Test Hospitality Inc.',
  '100 King St W, Toronto, ON',
  'Taylor Billing',
  'Owner',
  'stripe-venue@example.test',
  '+1 416 555 0199',
  'venue-terms-2026-07',
  (select id from public.venues where display_name = 'Billing Test Room')
);

select public.review_venue_registration(
  'f1000000-0000-4000-8000-000000000001',
  (select id from public.venues where display_name = 'Billing Test Room'),
  'approved',
  'Approved.',
  'Billing fixture approved.'
);

select ok(
  not has_function_privilege('authenticated', 'public.get_venue_billing_context(uuid)', 'execute')
  and not has_function_privilege('authenticated', 'public.attach_venue_stripe_customer(uuid,text)', 'execute')
  and not has_function_privilege('authenticated', 'public.claim_stripe_webhook_event(text,text)', 'execute'),
  'authenticated clients cannot execute billing RPCs'
);

select ok(
  has_function_privilege('service_role', 'public.get_venue_billing_context(uuid)', 'execute')
  and has_function_privilege('service_role', 'public.attach_venue_stripe_customer(uuid,text)', 'execute')
  and has_function_privilege('service_role', 'public.claim_stripe_webhook_event(text,text)', 'execute'),
  'the trusted service role can execute billing RPCs'
);

select is(
  public.get_venue_billing_context('f1000000-0000-4000-8000-000000000002')->>'plan_code',
  'free',
  'an approved venue begins on Free'
);

select lives_ok(
  $$select public.attach_venue_stripe_customer(
    'f1000000-0000-4000-8000-000000000002',
    'cus_outlybillingtest'
  )$$,
  'the server can attach a Stripe customer to its venue'
);

select is(
  public.get_venue_billing_context('f1000000-0000-4000-8000-000000000002')->>'stripe_customer_id',
  'cus_outlybillingtest',
  'billing context returns the attached Stripe customer'
);

select throws_ok(
  $$select public.attach_venue_stripe_customer(
    'f1000000-0000-4000-8000-000000000002',
    'cus_conflictingcustomer'
  )$$,
  'P0001',
  'stripe_customer_conflict',
  'an existing venue billing identity cannot be replaced'
);

select ok(
  public.claim_stripe_webhook_event('evt_outly_001', 'customer.subscription.created'),
  'a new Stripe webhook event is claimed once'
);

select ok(
  not public.claim_stripe_webhook_event('evt_outly_001', 'customer.subscription.created'),
  'an in-flight duplicate event is ignored'
);

select lives_ok(
  $$select public.sync_venue_stripe_subscription(
    'evt_outly_001',
    '2026-07-22 17:00:00+00',
    (select id from public.venues where display_name = 'Billing Test Room'),
    'cus_outlybillingtest',
    'sub_outlybillingtest',
    'price_outlypro',
    'active',
    '2026-08-22 17:00:00+00',
    false,
    null
  )$$,
  'an active Stripe subscription synchronizes successfully'
);

select ok(
  (
    select plan_code = 'pro'
      and stripe_status = 'active'
      and stripe_subscription_id = 'sub_outlybillingtest'
      and stripe_price_id = 'price_outlypro'
    from private.venue_subscriptions
    where venue_id = (select id from public.venues where display_name = 'Billing Test Room')
  ),
  'active Stripe state provisions Pro'
);

select is(
  (select processing_status from private.stripe_webhook_events where stripe_event_id = 'evt_outly_001'),
  'processed',
  'successful synchronization completes its webhook event'
);

select ok(
  public.claim_stripe_webhook_event('evt_outly_000', 'customer.subscription.updated'),
  'an older event can arrive later'
);

select lives_ok(
  $$select public.sync_venue_stripe_subscription(
    'evt_outly_000',
    '2026-07-22 16:59:00+00',
    (select id from public.venues where display_name = 'Billing Test Room'),
    'cus_outlybillingtest',
    'sub_outlybillingtest',
    'price_outlypro',
    'past_due',
    '2026-08-22 17:00:00+00',
    false,
    null
  )$$,
  'an out-of-order event is handled without overwriting current state'
);

select is(
  (select processing_status from private.stripe_webhook_events where stripe_event_id = 'evt_outly_000'),
  'ignored',
  'the out-of-order event is recorded as ignored'
);

select ok(
  public.claim_stripe_webhook_event('evt_outly_002', 'customer.subscription.updated'),
  'a cancellation schedule update is claimed'
);

select public.sync_venue_stripe_subscription(
  'evt_outly_002',
  '2026-07-22 17:01:00+00',
  (select id from public.venues where display_name = 'Billing Test Room'),
  'cus_outlybillingtest',
  'sub_outlybillingtest',
  'price_outlypro',
  'active',
  '2026-08-22 17:00:00+00',
  true,
  '2026-07-22 17:01:00+00'
);

select ok(
  (
    select cancel_at_period_end
      and current_period_ends_at = '2026-08-22 17:00:00+00'::timestamptz
    from private.venue_subscriptions
    where venue_id = (select id from public.venues where display_name = 'Billing Test Room')
  ),
  'scheduled cancellation keeps Pro through the paid period'
);

select ok(
  public.claim_stripe_webhook_event('evt_outly_003', 'customer.subscription.deleted'),
  'the terminal subscription event is claimed'
);

select public.sync_venue_stripe_subscription(
  'evt_outly_003',
  '2026-08-22 17:00:01+00',
  (select id from public.venues where display_name = 'Billing Test Room'),
  'cus_outlybillingtest',
  'sub_outlybillingtest',
  'price_outlypro',
  'cancelled',
  '2026-08-22 17:00:00+00',
  false,
  '2026-08-22 17:00:01+00'
);

select ok(
  (
    select plan_code = 'free'
      and stripe_status = 'free'
      and stripe_customer_id = 'cus_outlybillingtest'
      and stripe_subscription_id is null
      and stripe_price_id is null
    from private.venue_subscriptions
    where venue_id = (select id from public.venues where display_name = 'Billing Test Room')
  ),
  'terminal Stripe cancellation returns the venue to Free without losing its customer identity'
);

select is(
  (select processing_status from private.stripe_webhook_events where stripe_event_id = 'evt_outly_003'),
  'processed',
  'terminal cancellation completes its webhook event'
);

select * from finish();

rollback;
