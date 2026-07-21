begin;

create extension if not exists pgtap with schema extensions;

select plan(10);

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
    '11111111-1111-4111-8111-111111111111',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'first@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  ),
  (
    '22222222-2222-4222-8222-222222222222',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'second@example.test',
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
values
  ('11111111-1111-4111-8111-111111111111', 'Avery', 'complete', now()),
  ('22222222-2222-4222-8222-222222222222', 'Jordan', 'complete', now());

select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}',
  true
);
select set_config(
  'request.jwt.claim.sub',
  '11111111-1111-4111-8111-111111111111',
  true
);
set local role authenticated;

select is(
  (select auth.uid()),
  '11111111-1111-4111-8111-111111111111'::uuid,
  'test request is authenticated as the first consumer'
);
select is(
  (select count(*)::integer from public.consumer_profiles),
  1,
  'RLS returns exactly one profile row'
);
select is(
  (select first_name from public.consumer_profiles),
  'Avery',
  'consumer can read their own profile'
);
select is(
  (
    select count(*)::integer
    from public.consumer_profiles
    where user_id = '22222222-2222-4222-8222-222222222222'
  ),
  0,
  'consumer cannot read another profile'
);
select throws_ok(
  $$
    insert into public.consumer_profiles (user_id)
    values ('33333333-3333-4333-8333-333333333333')
  $$,
  '42501',
  null,
  'consumer cannot insert a profile directly'
);
select throws_ok(
  $$
    update public.consumer_profiles
    set first_name = 'Changed'
    where user_id = '11111111-1111-4111-8111-111111111111'
  $$,
  '42501',
  null,
  'consumer cannot update protected profile state directly'
);
select throws_ok(
  $$select * from private.consumer_eligibility$$,
  '42501',
  null,
  'consumer cannot read protected eligibility'
);

reset role;

select throws_ok(
  $$
    insert into private.consumer_eligibility (
      user_id,
      date_of_birth,
      gender,
      is_19_plus,
      age_eligibility_checked_at
    )
    values (
      '22222222-2222-4222-8222-222222222222',
      '2007-07-20',
      'woman',
      true,
      '2026-07-19 12:00:00-04'
    )
  $$,
  '23514',
  null,
  'a consumer one day under 19 cannot be marked eligible'
);
select lives_ok(
  $$
    insert into private.consumer_eligibility (
      user_id,
      date_of_birth,
      gender,
      is_19_plus,
      age_eligibility_checked_at
    )
    values (
      '11111111-1111-4111-8111-111111111111',
      '2007-07-19',
      'other',
      true,
      '2026-07-19 12:00:00-04'
    )
  $$,
  'a consumer turning 19 today is eligible and Another gender is accepted'
);
select throws_ok(
  $$
    insert into private.consumer_eligibility (
      user_id,
      date_of_birth,
      gender,
      is_19_plus,
      age_eligibility_checked_at
    )
    values (
      '22222222-2222-4222-8222-222222222222',
      '2000-01-01',
      'prefer_not_to_say',
      true,
      '2026-07-19 12:00:00-04'
    )
  $$,
  '23514',
  null,
  'unsupported gender values are rejected'
);

select * from finish();
rollback;
