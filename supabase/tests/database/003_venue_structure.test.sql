begin;

set local role postgres;
set local search_path = public, extensions, pgtap;

create extension if not exists pgtap with schema extensions;

select plan(47);

select has_table('public', 'venues', 'venues table exists');
select has_table('public', 'venue_accounts', 'venue accounts table exists');
select has_table('private', 'venue_business_details', 'private venue business details exist');
select has_table('public', 'venue_hours', 'venue hours table exists');
select has_table('public', 'venue_hour_exceptions', 'venue hour exceptions table exists');
select has_table('public', 'venue_assets', 'venue assets table exists');
select has_table('public', 'venue_profile_revisions', 'venue profile revisions table exists');
select has_table('public', 'venue_events', 'venue events table exists');
select has_table('private', 'venue_reviews', 'private venue reviews exist');

select col_is_pk('public', 'venues', 'id', 'venue ID is the primary key');
select col_is_pk('public', 'venue_accounts', 'auth_user_id', 'venue Auth user is the account primary key');
select fk_ok(
  'public', 'venue_accounts', 'auth_user_id',
  'auth', 'users', 'id',
  'venue accounts reference Supabase Auth users'
);
select fk_ok(
  'public', 'venue_accounts', 'venue_id',
  'public', 'venues', 'id',
  'venue accounts reference venues'
);

select ok(
  exists (
    select 1
    from pg_attribute as column_record
    where column_record.attrelid = 'public.venues'::regclass
      and column_record.attname = 'location'
      and column_record.atttypid = 'extensions.geography'::regtype
      and extensions.postgis_typmod_type(column_record.atttypmod) = 'Point'
      and extensions.postgis_typmod_srid(column_record.atttypmod) = 4326
  ),
  'venue location is a WGS84 PostGIS geography point'
);
select ok(
  exists (
    select 1
    from pg_index as index_record
    join pg_class as index_class on index_class.oid = index_record.indexrelid
    join pg_am as access_method on access_method.oid = index_class.relam
    where index_record.indrelid = 'public.venues'::regclass
      and index_class.relname = 'venues_location_gix'
      and access_method.amname = 'gist'
  ),
  'venue geography has a GiST index'
);
select ok(
  exists (
    select 1
    from pg_attrdef as default_record
    join pg_attribute as column_record
      on column_record.attrelid = default_record.adrelid
      and column_record.attnum = default_record.adnum
    where default_record.adrelid = 'public.venues'::regclass
      and column_record.attname = 'geofence_radius_metres'
      and pg_get_expr(default_record.adbin, default_record.adrelid) = '75'
  ),
  'venue geofence defaults to 75 metres'
);
select ok(
  exists (
    select 1
    from pg_constraint
    where conrelid = 'public.venue_accounts'::regclass
      and conname = 'venue_accounts_venue_id_key'
      and contype = 'u'
  ),
  'the MVP permits only one login per venue'
);

select ok((select relrowsecurity from pg_class where oid = 'public.venues'::regclass), 'RLS is enabled on venues');
select ok((select relrowsecurity from pg_class where oid = 'public.venue_accounts'::regclass), 'RLS is enabled on venue accounts');
select ok((select relrowsecurity from pg_class where oid = 'private.venue_business_details'::regclass), 'RLS is enabled on business details');
select ok((select relrowsecurity from pg_class where oid = 'public.venue_hours'::regclass), 'RLS is enabled on venue hours');
select ok((select relrowsecurity from pg_class where oid = 'public.venue_hour_exceptions'::regclass), 'RLS is enabled on hour exceptions');
select ok((select relrowsecurity from pg_class where oid = 'public.venue_assets'::regclass), 'RLS is enabled on venue assets');
select ok((select relrowsecurity from pg_class where oid = 'public.venue_profile_revisions'::regclass), 'RLS is enabled on profile revisions');
select ok((select relrowsecurity from pg_class where oid = 'public.venue_events'::regclass), 'RLS is enabled on venue events');
select ok((select relrowsecurity from pg_class where oid = 'private.venue_reviews'::regclass), 'RLS is enabled on private venue reviews');

select policies_are(
  'public',
  'venues',
  array['venues_select_published_or_owned'],
  'venues expose one deliberate read policy'
);
select policies_are(
  'public',
  'venue_accounts',
  array['venue_accounts_select_own'],
  'venue accounts expose only the own-account policy'
);
select policies_are(
  'public',
  'venue_hours',
  array['venue_hours_select_visible_venue'],
  'venue hours follow parent venue visibility'
);
select policies_are(
  'public',
  'venue_hour_exceptions',
  array['venue_hour_exceptions_select_visible_venue'],
  'venue hour exceptions follow parent venue visibility'
);
select policies_are(
  'public',
  'venue_assets',
  array['venue_assets_select_approved_or_owned'],
  'venue assets separate approved media from owner submissions'
);
select policies_are(
  'public',
  'venue_profile_revisions',
  array['venue_profile_revisions_select_owned'],
  'critical profile revisions are venue-private'
);
select policies_are(
  'public',
  'venue_events',
  array['venue_events_select_published_or_owned'],
  'venue events separate published discovery from owner drafts'
);

select ok(
  has_table_privilege('authenticated', 'public.venues', 'select'),
  'authenticated clients can select venues through RLS'
);
select ok(
  not has_table_privilege('authenticated', 'public.venues', 'insert'),
  'authenticated clients cannot insert venues directly'
);
select ok(
  not has_table_privilege('authenticated', 'public.venues', 'update'),
  'authenticated clients cannot change venue publication state directly'
);
select ok(
  not has_table_privilege('anon', 'public.venues', 'select'),
  'anonymous clients cannot query venues'
);
select ok(
  not has_table_privilege('authenticated', 'private.venue_business_details', 'select'),
  'venue business details have no authenticated-client grant'
);
select ok(
  has_table_privilege('service_role', 'private.venue_business_details', 'select'),
  'trusted server code can read venue business details'
);

select ok(
  exists (
    select 1 from storage.buckets
    where id = 'venue-media-submissions' and not public
  ),
  'venue media submissions use a private bucket'
);
select ok(
  exists (
    select 1 from storage.buckets
    where id = 'venue-media' and public
  ),
  'approved venue media use a public bucket'
);
select ok(
  not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and (
        coalesce(qual, '') like '%venue-media%'
        or coalesce(with_check, '') like '%venue-media%'
      )
  ),
  'no client storage policy bypasses the trusted media-review workflow'
);

select is(
  (
    select count(*)::integer
    from pg_constraint
    where conname in (
      'venues_current_hero_asset_same_venue_fk',
      'venues_current_marker_asset_same_venue_fk',
      'venue_profile_revisions_marker_same_venue_fk',
      'venue_events_image_same_venue_fk'
    )
      and contype = 'f'
  ),
  4,
  'all asset references enforce same-venue ownership'
);
select ok(
  exists (
    select 1 from pg_constraint
    where conrelid = 'public.venues'::regclass
      and conname = 'venues_publication_consistent'
  ),
  'venue publication completeness is database-enforced'
);
select ok(
  exists (
    select 1 from pg_constraint
    where conrelid = 'public.venue_assets'::regclass
      and conname = 'venue_assets_bucket_matches_moderation'
  ),
  'asset moderation controls its delivery bucket'
);
select ok(
  exists (
    select 1
    from pg_indexes
    where schemaname = 'public'
      and tablename = 'venues'
      and indexname = 'venues_discovery_idx'
      and indexdef like '%WHERE ((registration_status =%'
  ),
  'venue discovery uses a partial approved-and-published index'
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
  'every public/private foreign-key column is indexed'
);

select * from finish();
rollback;
