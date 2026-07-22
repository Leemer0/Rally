begin;

set local role postgres;
set local search_path = public, extensions, pgtap;

create extension if not exists pgtap with schema extensions;

select plan(45);

select has_table('public', 'night_plans', 'night plans table exists');
select has_table('private', 'check_in_verification_config', 'private verification config exists');
select has_table('public', 'check_ins', 'check-ins table exists');
select hasnt_table('private', 'check_in_location_evidence', 'raw location evidence is not retained');

select col_is_pk('public', 'night_plans', 'id', 'night plan ID is the primary key');
select col_is_pk('public', 'check_ins', 'id', 'check-in ID is the primary key');
select fk_ok(
  'public', 'night_plans', 'user_id',
  'auth', 'users', 'id',
  'night plans reference consumer Auth users'
);
select fk_ok(
  'public', 'night_plans', 'venue_id',
  'public', 'venues', 'id',
  'night plans reference venues'
);
select fk_ok(
  'public', 'check_ins', 'user_id',
  'auth', 'users', 'id',
  'check-ins reference consumer Auth users'
);
select fk_ok(
  'public', 'check_ins', 'venue_id',
  'public', 'venues', 'id',
  'check-ins reference venues'
);

select hasnt_column('public', 'check_ins', 'latitude', 'durable check-ins do not store latitude');
select hasnt_column('public', 'check_ins', 'longitude', 'durable check-ins do not store longitude');
select has_column('public', 'check_ins', 'distance_from_venue_metres', 'derived venue distance is retained');
select has_column('public', 'check_ins', 'horizontal_accuracy_metres', 'horizontal accuracy is retained');
select has_column('public', 'check_ins', 'location_age_seconds', 'location sample age is retained');

select ok((select relrowsecurity from pg_class where oid = 'public.night_plans'::regclass), 'RLS is enabled on plans');
select ok((select relrowsecurity from pg_class where oid = 'private.check_in_verification_config'::regclass), 'RLS is enabled on verification config');
select ok((select relrowsecurity from pg_class where oid = 'public.check_ins'::regclass), 'RLS is enabled on check-ins');

select policies_are(
  'public',
  'night_plans',
  array['night_plans_select_own'],
  'plans expose only the own-row read policy'
);
select policies_are(
  'public',
  'check_ins',
  array['check_ins_select_own'],
  'check-ins expose only the own-row read policy'
);

select ok(has_table_privilege('authenticated', 'public.night_plans', 'select'), 'consumer clients can read own plans through RLS');
select ok(not has_table_privilege('authenticated', 'public.night_plans', 'insert'), 'consumer clients cannot insert plans directly');
select ok(has_table_privilege('authenticated', 'public.check_ins', 'select'), 'consumer clients can read own check-ins through RLS');
select ok(not has_table_privilege('authenticated', 'public.check_ins', 'insert'), 'consumer clients cannot forge check-ins');
select ok(not has_table_privilege('authenticated', 'private.check_in_verification_config', 'select'), 'verification rules are not client-readable');
select ok(has_table_privilege('service_role', 'private.check_in_verification_config', 'select'), 'trusted server code can read verification rules');
select ok(not has_table_privilege('anon', 'public.night_plans', 'select'), 'anonymous clients cannot read plans');
select ok(not has_table_privilege('anon', 'public.check_ins', 'select'), 'anonymous clients cannot read check-ins');

select ok(
  not has_function_privilege('authenticated', 'public.set_night_plan(uuid,uuid,uuid)', 'execute'),
  'authenticated clients cannot execute the plan mutation RPC'
);
select ok(
  has_function_privilege('service_role', 'public.set_night_plan(uuid,uuid,uuid)', 'execute'),
  'trusted server code can execute the plan mutation RPC'
);
select ok(
  not has_function_privilege('authenticated', 'public.cancel_night_plan(uuid,uuid)', 'execute'),
  'authenticated clients cannot execute the plan cancellation RPC'
);
select ok(
  has_function_privilege('service_role', 'public.cancel_night_plan(uuid,uuid)', 'execute'),
  'trusted server code can execute the plan cancellation RPC'
);
select ok(
  not has_function_privilege(
    'authenticated',
    'public.verify_venue_check_in(uuid,uuid,uuid,double precision,double precision,double precision,timestamp with time zone,text,text,uuid)',
    'execute'
  ),
  'authenticated clients cannot execute the privileged verification RPC'
);
select ok(
  has_function_privilege(
    'service_role',
    'public.verify_venue_check_in(uuid,uuid,uuid,double precision,double precision,double precision,timestamp with time zone,text,text,uuid)',
    'execute'
  ),
  'trusted server code can execute the verification RPC'
);

select ok(
  (select prosecdef from pg_proc where oid = 'public.set_night_plan(uuid,uuid,uuid)'::regprocedure),
  'plan mutation is an explicitly privileged security-definer operation'
);
select ok(
  (select prosecdef from pg_proc where oid = 'public.cancel_night_plan(uuid,uuid)'::regprocedure),
  'plan cancellation is an explicitly privileged security-definer operation'
);
select ok(
  (
    select prosecdef
    from pg_proc
    where oid = 'public.verify_venue_check_in(uuid,uuid,uuid,double precision,double precision,double precision,timestamptz,text,text,uuid)'::regprocedure
  ),
  'verification is an explicitly privileged security-definer operation'
);
select ok(
  not (
    select prosecdef
    from pg_proc
    where oid = 'private.nightlife_date_for(timestamptz,text)'::regprocedure
  ),
  'nightlife date helper runs as security invoker'
);
select ok(
  not has_function_privilege(
    'authenticated',
    'private.nightlife_date_for(timestamp with time zone,text)',
    'execute'
  ),
  'nightlife date helper is not directly callable by clients'
);

select ok(
  exists (
    select 1
    from pg_indexes
    where schemaname = 'public'
      and tablename = 'night_plans'
      and indexname = 'night_plans_one_active_per_user_night_idx'
      and indexdef like '%WHERE ((user_id IS NOT NULL)%'
  ),
  'a partial unique index enforces one active plan per consumer night'
);
select ok(
  exists (
    select 1
    from pg_indexes
    where schemaname = 'public'
      and tablename = 'check_ins'
      and indexname = 'check_ins_one_verified_per_user_night_idx'
      and indexdef like '%WHERE ((user_id IS NOT NULL)%'
  ),
  'a partial unique index enforces one verified check-in per consumer night'
);
select ok(
  exists (
    select 1
    from private.check_in_verification_config
    where singleton
      and maximum_sample_age_seconds = 30
      and maximum_horizontal_accuracy_metres = 75
      and nearest_venue_tie_tolerance_metres = 1
  ),
  'verification defaults match the approved iOS prototype thresholds'
);
select ok(
  exists (
    select 1 from pg_constraint
    where conrelid = 'public.night_plans'::regclass
      and conname = 'night_plans_transition_timestamp_consistent'
  ),
  'plan status timestamps are database-enforced'
);
select ok(
  exists (
    select 1 from pg_constraint
    where conrelid = 'public.check_ins'::regclass
      and conname = 'check_ins_decision_consistent'
  ),
  'verified check-in evidence is database-enforced'
);
select ok(
  not exists (
    select 1
    from pg_constraint as constraint_record
    join pg_class as table_record
      on table_record.oid = constraint_record.conrelid
    join pg_namespace as schema_record
      on schema_record.oid = table_record.relnamespace
    join pg_attribute as column_record
      on column_record.attrelid = constraint_record.conrelid
      and column_record.attnum = any (constraint_record.conkey)
    where constraint_record.contype = 'f'
      and schema_record.nspname in ('public', 'private')
      and not exists (
        select 1
        from pg_index as index_record
        where index_record.indrelid = constraint_record.conrelid
          and column_record.attnum = any (index_record.indkey)
      )
  ),
  'every public/private foreign-key column remains indexed'
);

select * from finish();
rollback;
