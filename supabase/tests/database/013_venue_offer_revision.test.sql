begin;

set local role postgres;
set local search_path = public, extensions, pgtap;

create extension if not exists pgtap with schema extensions;

select plan(32);

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
    ('d1000000-0000-4000-8000-000000000001'::uuid, 'founder-revision@example.test'),
    ('d1000000-0000-4000-8000-000000000002'::uuid, 'venue-revision@example.test'),
    ('d1000000-0000-4000-8000-000000000003'::uuid, 'other-venue@example.test')
) as user_record(id, email);

insert into private.internal_admins (user_id)
values ('d1000000-0000-4000-8000-000000000001');

insert into public.venues (
  id, slug, display_name, registration_status, publication_status,
  address_line_1, market_code, neighbourhood, city, province_code,
  postal_code, country_code, location, approved_at
)
values (
  'd2000000-0000-4000-8000-000000000001',
  'revision-room',
  'Revision Room',
  'approved',
  'published',
  '18 Ossington Ave',
  'toronto',
  'Ossington',
  'Toronto',
  'ON',
  'M6J 2Y7',
  'CA',
  extensions.st_setsrid(
    extensions.st_makepoint(-79.4201, 43.6461),
    4326
  )::extensions.geography,
  now()
);

insert into public.venue_accounts (auth_user_id, venue_id, account_status)
values (
  'd1000000-0000-4000-8000-000000000002',
  'd2000000-0000-4000-8000-000000000001',
  'active'
);

insert into private.venue_subscriptions (venue_id, plan_code, stripe_status)
values ('d2000000-0000-4000-8000-000000000001', 'free', 'free')
on conflict (venue_id) do update
set plan_code = excluded.plan_code, stripe_status = excluded.stripe_status;

set local role service_role;

-- 01-04: the mutation ledger and every RPC stay behind the trusted adapter.
select has_table(
  'private',
  'venue_offer_mutations',
  'venue offer mutation idempotency records exist privately'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'private.venue_offer_mutations'::regclass),
  'venue offer mutation records have RLS enabled'
);
select ok(
  not has_function_privilege(
    'authenticated',
    'public.revise_venue_offer(uuid,uuid,uuid,uuid,text,text,text,text,integer,date,date,smallint[],time without time zone,time without time zone,time without time zone,time without time zone,time without time zone,integer,boolean)',
    'execute'
  )
  and not has_function_privilege(
    'authenticated',
    'public.set_venue_offer_status(uuid,uuid,uuid,text)',
    'execute'
  )
  and not has_function_privilege(
    'authenticated',
    'public.get_venue_offer_editor(uuid,uuid)',
    'execute'
  ),
  'authenticated clients cannot execute venue offer management RPCs directly'
);
select ok(
  has_function_privilege(
    'service_role',
    'public.revise_venue_offer(uuid,uuid,uuid,uuid,text,text,text,text,integer,date,date,smallint[],time without time zone,time without time zone,time without time zone,time without time zone,time without time zone,integer,boolean)',
    'execute'
  )
  and has_function_privilege(
    'service_role',
    'public.set_venue_offer_status(uuid,uuid,uuid,text)',
    'execute'
  ),
  'the trusted service role can execute venue offer mutations'
);

-- 05-10: a free venue's changes-requested offer keeps its one active slot,
-- and public founder feedback is visible without exposing private notes.
select lives_ok(
  $$
    select * from public.submit_venue_offer(
      'd1000000-0000-4000-8000-000000000002',
      'd3000000-0000-4000-8000-000000000001',
      'Free cover before 10 PM',
      'Arrive early and check in.',
      'Outly guest — free cover',
      'Confirm the offer is valid now.',
      600,
      current_date,
      current_date + 30,
      array[5, 6]::smallint[],
      time '20:00',
      time '22:00',
      null,
      time '22:00',
      null,
      100,
      true
    )
  $$,
  'a free venue submits its first offer for review'
);
select is(
  (
    select lifecycle_status from public.offers
    where submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001'
  ),
  'pending_review',
  'the submitted offer enters the founder review queue'
);
select lives_ok(
  $$
    select public.review_offer_version(
      'd1000000-0000-4000-8000-000000000001',
      (
        select version_record.id
        from public.offer_versions as version_record
        join public.offers as offer_record on offer_record.id = version_record.offer_id
        where offer_record.submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001'
      ),
      'changes_requested',
      'Clarify that the offer applies only before 10 PM.',
      'Operational wording needs one pass.'
    )
  $$,
  'a founder requests changes with separate public and private feedback'
);
select is(
  (
    select lifecycle_status from public.offers
    where submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001'
  ),
  'changes_requested',
  'the offer waits for a venue revision'
);
select is(
  (
    select jsonb_path_query_first(
      public.get_venue_offer_management('d1000000-0000-4000-8000-000000000002'),
      '$[0].latest_feedback.public_response'
    ) #>> '{}'
  ),
  'Clarify that the offer applies only before 10 PM.',
  'the venue management snapshot includes founder public feedback'
);
select throws_ok(
  $$
    select * from public.submit_venue_offer(
      'd1000000-0000-4000-8000-000000000002',
      'd3000000-0000-4000-8000-000000000002',
      'Second active offer', null,
      'Second active offer', 'Confirm valid now.', null,
      current_date, null, array[5]::smallint[],
      null, null, null, null, null, null, false
    )
  $$,
  'P0001',
  'active_offer_limit_reached',
  'changes requested still consumes the free plan active-offer slot'
);

-- 11-20: resubmission creates a new auditable version and retries safely.
select lives_ok(
  $$
    select * from public.revise_venue_offer(
      'd1000000-0000-4000-8000-000000000002',
      (
        select id from public.offers
        where submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001'
      ),
      (
        select version_record.id
        from public.offer_versions as version_record
        join public.offers as offer_record on offer_record.id = version_record.offer_id
        where offer_record.submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001'
        order by version_record.version_number desc limit 1
      ),
      'd4000000-0000-4000-8000-000000000001',
      'Free cover with Outly before 10 PM',
      'Check in before 10 PM to unlock it.',
      'Outly guest — free cover before 10 PM',
      'Confirm Valid now and the venue name before admitting one guest.',
      900,
      current_date,
      current_date + 30,
      array[5, 6]::smallint[],
      time '20:00', time '22:00', null, time '22:00', null, 100, true
    )
  $$,
  'the venue repairs and resubmits the requested revision'
);
select is(
  (
    select count(*)::integer
    from public.offer_versions as version_record
    join public.offers as offer_record on offer_record.id = version_record.offer_id
    where offer_record.submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001'
  ),
  2,
  'a changes-requested repair creates exactly one new version'
);
select is(
  (
    select approval_state
    from public.offer_versions as version_record
    join public.offers as offer_record on offer_record.id = version_record.offer_id
    where offer_record.submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001'
      and version_record.version_number = 1
  ),
  'changes_requested',
  'the founder-reviewed version remains unchanged for audit'
);
select is(
  (
    select public_title
    from public.offer_versions as version_record
    join public.offers as offer_record on offer_record.id = version_record.offer_id
    where offer_record.submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001'
      and version_record.version_number = 2
  ),
  'Free cover with Outly before 10 PM',
  'the new version contains the repaired public copy'
);
select is(
  (
    select lifecycle_status from public.offers
    where submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001'
  ),
  'pending_review',
  'the repaired version returns to pending review'
);
select is(
  (
    select count(*)::integer
    from private.offer_reviews as review_record
    join public.offer_versions as version_record on version_record.id = review_record.offer_version_id
    join public.offers as offer_record on offer_record.id = version_record.offer_id
    where offer_record.submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001'
      and version_record.version_number = 1
      and review_record.private_note = 'Operational wording needs one pass.'
  ),
  1,
  'the original founder review and private audit note remain on version one'
);
select lives_ok(
  $$
    select * from public.revise_venue_offer(
      'd1000000-0000-4000-8000-000000000002',
      (select id from public.offers where submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001'),
      (select id from public.offer_versions where offer_id = (select id from public.offers where submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001') and version_number = 1),
      'd4000000-0000-4000-8000-000000000001',
      'Free cover with Outly before 10 PM', 'Check in before 10 PM to unlock it.',
      'Outly guest — free cover before 10 PM',
      'Confirm Valid now and the venue name before admitting one guest.',
      900, current_date, current_date + 30, array[5, 6]::smallint[],
      time '20:00', time '22:00', null, time '22:00', null, 100, true
    )
  $$,
  'an identical revision retry returns its original result'
);
select is(
  (
    select count(*)::integer
    from public.offer_versions as version_record
    join public.offers as offer_record on offer_record.id = version_record.offer_id
    where offer_record.submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001'
  ),
  2,
  'the retry does not create another version'
);
select throws_ok(
  $$
    select * from public.revise_venue_offer(
      'd1000000-0000-4000-8000-000000000002',
      (select id from public.offers where submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001'),
      (select id from public.offer_versions where offer_id = (select id from public.offers where submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001') and version_number = 1),
      'd4000000-0000-4000-8000-000000000001',
      'Changed request with reused key', null, 'Staff title', 'Staff instruction',
      null, current_date, null, array[5]::smallint[],
      null, null, null, null, null, null, false
    )
  $$,
  'P0001',
  'idempotency_key_conflict',
  'reusing a revision key for different request data is rejected'
);
select throws_ok(
  $$
    select * from public.revise_venue_offer(
      'd1000000-0000-4000-8000-000000000002',
      (select id from public.offers where submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001'),
      (select id from public.offer_versions where offer_id = (select id from public.offers where submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001') and version_number = 1),
      'd4000000-0000-4000-8000-000000000002',
      'Stale revision', null, 'Staff title', 'Staff instruction',
      null, current_date, null, array[5]::smallint[],
      null, null, null, null, null, null, false
    )
  $$,
  'P0001',
  'offer_revision_conflict',
  'an independently retried stale editor cannot overwrite the latest revision'
);

-- 21-25: only the replacement can be reviewed; approved records stay immutable.
select throws_ok(
  $$
    select public.review_offer_version(
      'd1000000-0000-4000-8000-000000000001',
      (select id from public.offer_versions where offer_id = (select id from public.offers where submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001') and version_number = 1),
      'approved', null, null
    )
  $$,
  'P0001',
  'offer_not_pending_review',
  'a founder cannot approve the superseded changes-requested version'
);
select lives_ok(
  $$
    select public.review_offer_version(
      'd1000000-0000-4000-8000-000000000001',
      (select id from public.offer_versions where offer_id = (select id from public.offers where submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001') and version_number = 2),
      'approved', 'Approved.', null
    )
  $$,
  'the founder approves the latest submitted revision'
);
select ok(
  (
    select lifecycle_status = 'live'
      and current_approved_version_id = (
        select id from public.offer_versions
        where offer_id = offer_record.id and version_number = 2
      )
    from public.offers as offer_record
    where submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001'
  ),
  'the approved revision becomes the live immutable snapshot'
);
select throws_ok(
  $$
    select * from public.revise_venue_offer(
      'd1000000-0000-4000-8000-000000000002',
      (select id from public.offers where submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001'),
      (select id from public.offer_versions where offer_id = (select id from public.offers where submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001') and version_number = 2),
      'd4000000-0000-4000-8000-000000000003',
      'Attempted live edit', null, 'Staff title', 'Staff instruction',
      null, current_date, null, array[5]::smallint[],
      null, null, null, null, null, null, false
    )
  $$,
  'P0001',
  'venue_offer_not_editable',
  'the venue cannot mutate an approved offer version'
);
select is(
  (
    select public_title from public.offer_versions
    where offer_id = (select id from public.offers where submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001')
      and version_number = 2
  ),
  'Free cover with Outly before 10 PM',
  'the rejected live edit leaves approved copy unchanged'
);

-- 26-32: end/archive is idempotent, frees the plan slot, and is owner-scoped.
select lives_ok(
  $$
    select * from public.set_venue_offer_status(
      'd1000000-0000-4000-8000-000000000002',
      (select id from public.offers where submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001'),
      'd5000000-0000-4000-8000-000000000001',
      'ended'
    )
  $$,
  'the owning venue ends its live offer'
);
select lives_ok(
  $$
    select * from public.set_venue_offer_status(
      'd1000000-0000-4000-8000-000000000002',
      (select id from public.offers where submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001'),
      'd5000000-0000-4000-8000-000000000001',
      'ended'
    )
  $$,
  'an identical end retry returns the stored result'
);
select lives_ok(
  $$
    select * from public.submit_venue_offer(
      'd1000000-0000-4000-8000-000000000002',
      'd3000000-0000-4000-8000-000000000003',
      'New free-plan offer', null,
      'New free-plan offer', 'Confirm valid now.', null,
      current_date, null, array[5]::smallint[],
      null, null, null, null, null, null, false
    )
  $$,
  'ending the prior offer releases the free-plan slot'
);
select lives_ok(
  $$
    select * from public.set_venue_offer_status(
      'd1000000-0000-4000-8000-000000000002',
      (select id from public.offers where submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001'),
      'd5000000-0000-4000-8000-000000000002',
      'archived'
    )
  $$,
  'the venue archives its ended offer'
);
select ok(
  (
    select lifecycle_status = 'archived' and archived_at is not null
    from public.offers
    where submission_idempotency_key = 'd3000000-0000-4000-8000-000000000001'
  ),
  'archiving sets both the lifecycle and audit timestamp'
);
select throws_ok(
  $$
    select * from public.set_venue_offer_status(
      'd1000000-0000-4000-8000-000000000003',
      (select id from public.offers where submission_idempotency_key = 'd3000000-0000-4000-8000-000000000003'),
      'd5000000-0000-4000-8000-000000000003',
      'ended'
    )
  $$,
  'P0001',
  'venue_offer_not_found',
  'another authenticated user cannot end the venue offer'
);
select throws_ok(
  $$
    select public.get_venue_offer_editor(
      'd1000000-0000-4000-8000-000000000003',
      (select id from public.offers where submission_idempotency_key = 'd3000000-0000-4000-8000-000000000003')
    )
  $$,
  'P0001',
  'venue_offer_not_found',
  'another authenticated user cannot read the venue offer editor payload'
);

select * from finish();

rollback;
