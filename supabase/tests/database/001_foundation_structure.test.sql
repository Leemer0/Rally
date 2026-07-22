begin;

set local role postgres;
set local search_path = public, extensions, pgtap;

create extension if not exists pgtap with schema extensions;

select plan(32);

select has_schema('private', 'private schema exists');
select ok(
  exists (select 1 from pg_extension where extname = 'postgis'),
  'PostGIS is enabled'
);

select has_table('public', 'consumer_profiles', 'consumer profiles table exists');
select has_table('private', 'consumer_eligibility', 'consumer eligibility table exists');
select has_table('private', 'internal_admins', 'internal admins table exists');
select has_table('private', 'legal_acceptances', 'legal acceptances table exists');
select has_table('private', 'device_push_tokens', 'device push tokens table exists');
select has_table('private', 'account_deletion_requests', 'deletion request table exists');

select col_is_pk('public', 'consumer_profiles', 'user_id', 'consumer user ID is the primary key');
select col_is_pk('private', 'consumer_eligibility', 'user_id', 'eligibility user ID is the primary key');
select fk_ok(
  'public', 'consumer_profiles', 'user_id',
  'auth', 'users', 'id',
  'consumer profiles reference Supabase Auth users'
);
select fk_ok(
  'private', 'consumer_eligibility', 'user_id',
  'auth', 'users', 'id',
  'consumer eligibility references Supabase Auth users'
);

select has_column('private', 'consumer_eligibility', 'date_of_birth', 'DOB is stored privately');
select has_column('private', 'consumer_eligibility', 'gender', 'gender is stored privately');
select has_column('private', 'consumer_eligibility', 'is_19_plus', '19+ result is stored privately');

select policies_are(
  'public',
  'consumer_profiles',
  array['consumer_profiles_select_own'],
  'consumer profiles expose only the own-row read policy'
);

select ok(
  (select relrowsecurity from pg_class where oid = 'public.consumer_profiles'::regclass),
  'RLS is enabled on consumer profiles'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'private.consumer_eligibility'::regclass),
  'RLS is enabled on private eligibility'
);

select ok(
  has_table_privilege('authenticated', 'public.consumer_profiles', 'select'),
  'authenticated users may select consumer profiles through RLS'
);
select ok(
  not has_table_privilege('authenticated', 'public.consumer_profiles', 'insert'),
  'authenticated users cannot insert consumer profiles directly'
);
select ok(
  not has_table_privilege('authenticated', 'public.consumer_profiles', 'update'),
  'authenticated users cannot update consumer profiles directly'
);
select ok(
  not has_table_privilege('anon', 'public.consumer_profiles', 'select'),
  'anonymous clients cannot select consumer profiles'
);
select ok(
  not has_schema_privilege('authenticated', 'private', 'usage'),
  'authenticated users cannot access the private schema'
);
select ok(
  has_schema_privilege('service_role', 'private', 'usage'),
  'trusted server role can use the private schema'
);
select ok(
  has_table_privilege('service_role', 'private.consumer_eligibility', 'select'),
  'trusted server role can read protected eligibility'
);
select ok(
  not has_table_privilege('authenticated', 'private.consumer_eligibility', 'select'),
  'authenticated users have no direct eligibility table grant'
);

select ok(
  not (
    select prosecdef
    from pg_proc
    where oid = 'private.set_updated_at()'::regprocedure
  ),
  'updated-at trigger runs as security invoker'
);
select ok(
  exists (
    select 1
    from pg_constraint
    where conrelid = 'public.consumer_profiles'::regclass
      and conname = 'consumer_profiles_first_name_valid'
  ),
  'consumer first-name validation is database-enforced'
);
select ok(
  exists (
    select 1
    from pg_constraint
    where conrelid = 'private.consumer_eligibility'::regclass
      and conname = 'consumer_eligibility_result_consistent'
  ),
  '19+ result consistency is database-enforced'
);
select ok(
  exists (
    select 1
    from pg_indexes
    where schemaname = 'private'
      and tablename = 'device_push_tokens'
      and indexname = 'device_push_tokens_user_id_idx'
  ),
  'device-token user foreign key is indexed'
);
select ok(
  exists (
    select 1
    from pg_indexes
    where schemaname = 'private'
      and tablename = 'account_deletion_requests'
      and indexname = 'account_deletion_requests_auth_user_id_idx'
  ),
  'deletion-request Auth foreign key is indexed'
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
  'every foundation foreign-key column is indexed'
);

select * from finish();
rollback;
