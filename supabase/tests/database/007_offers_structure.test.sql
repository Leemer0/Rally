begin;

set local role postgres;
set local search_path = public, extensions, pgtap;

create extension if not exists pgtap with schema extensions;

select plan(60);

select has_table('public', 'offers', 'stable offer identities exist');
select has_table('public', 'offer_versions', 'versioned offer copy and rules exist');
select has_table('public', 'offer_schedules', 'venue-local offer schedules exist');
select has_table('public', 'offer_claims', 'location-verified offer claims exist');
select has_table('private', 'partners', 'partner records remain private');
select has_table('private', 'partner_contacts', 'partner contacts remain private');
select has_table('private', 'partner_campaigns', 'partner campaign terms remain private');
select has_table('private', 'campaign_venues', 'campaign venue assignments remain private');
select has_table('private', 'offer_campaign_links', 'partner offer links remain private');
select has_table('private', 'offer_claim_config', 'claim safeguards are server-configured');
select hasnt_table('public', 'partner_campaigns', 'campaign terms are not in the exposed schema');

select has_column('public', 'offers', 'offer_kind', 'standard and partner offers share one catalogue');
select has_column('public', 'offer_versions', 'claim_duration_seconds', 'claim duration is data-driven');
select has_column('public', 'offer_claims', 'expires_at', 'claim expiry can be represented');
select has_column('public', 'offer_versions', 'destination_url', 'approved external redemption links can be represented');
select has_column('public', 'offer_versions', 'discovery_treatment', 'map/list discovery treatment can be represented');

select ok((select relrowsecurity from pg_class where oid = 'public.offers'::regclass), 'RLS is enabled on offers');
select ok((select relrowsecurity from pg_class where oid = 'public.offer_versions'::regclass), 'RLS is enabled on offer versions');
select ok((select relrowsecurity from pg_class where oid = 'public.offer_schedules'::regclass), 'RLS is enabled on offer schedules');
select ok((select relrowsecurity from pg_class where oid = 'public.offer_claims'::regclass), 'RLS is enabled on offer claims');
select ok((select relrowsecurity from pg_class where oid = 'private.partners'::regclass), 'RLS is enabled on partners');
select ok((select relrowsecurity from pg_class where oid = 'private.partner_contacts'::regclass), 'RLS is enabled on partner contacts');
select ok((select relrowsecurity from pg_class where oid = 'private.partner_campaigns'::regclass), 'RLS is enabled on partner campaigns');
select ok((select relrowsecurity from pg_class where oid = 'private.campaign_venues'::regclass), 'RLS is enabled on campaign venues');
select ok((select relrowsecurity from pg_class where oid = 'private.offer_campaign_links'::regclass), 'RLS is enabled on campaign links');
select ok((select relrowsecurity from pg_class where oid = 'private.offer_claim_config'::regclass), 'RLS is enabled on claim configuration');

select policies_are('public', 'offers', array['offers_select_own_venue'], 'offers expose only an own-venue read policy');
select policies_are('public', 'offer_versions', array['offer_versions_select_own_venue'], 'versions expose only an own-venue read policy');
select policies_are('public', 'offer_schedules', array['offer_schedules_select_own_venue'], 'schedules expose only an own-venue read policy');
select policies_are('public', 'offer_claims', array['offer_claims_select_own'], 'claims expose only the consumer own-row read policy');

select ok(has_table_privilege('authenticated', 'public.offers', 'select'), 'venue clients may read their own offers through RLS');
select ok(not has_table_privilege('authenticated', 'public.offers', 'insert'), 'clients cannot create offers directly');
select ok(has_table_privilege('authenticated', 'public.offer_versions', 'select'), 'venue clients may read their own offer versions through RLS');
select ok(not has_table_privilege('authenticated', 'public.offer_versions', 'update'), 'clients cannot approve or mutate offer versions directly');
select ok(has_table_privilege('authenticated', 'public.offer_claims', 'select'), 'consumers may read their own claims through RLS');
select ok(not has_table_privilege('authenticated', 'public.offer_claims', 'insert'), 'clients cannot forge offer claims');
select ok(not has_table_privilege('anon', 'public.offers', 'select'), 'anonymous clients cannot read offers directly');
select ok(not has_table_privilege('anon', 'public.offer_claims', 'select'), 'anonymous clients cannot read claims');
select ok(not has_table_privilege('authenticated', 'private.partners', 'select'), 'partner business data is not client-readable');
select ok(has_table_privilege('service_role', 'private.partners', 'select'), 'trusted server code can manage partners');
select ok(not has_table_privilege('authenticated', 'private.offer_claim_config', 'select'), 'claim safeguards are not client-readable');
select ok(has_table_privilege('service_role', 'private.offer_claim_config', 'select'), 'trusted server code can read claim safeguards');

select ok(
  not has_function_privilege('authenticated', 'public.list_eligible_offers(uuid,uuid[],timestamptz)', 'execute'),
  'clients cannot invoke the eligibility RPC with an arbitrary user ID'
);
select ok(
  has_function_privilege('service_role', 'public.list_eligible_offers(uuid,uuid[],timestamptz)', 'execute'),
  'trusted server code can list eligible offers'
);
select ok(
  not has_function_privilege('authenticated', 'public.unlock_offer_for_check_in(uuid,uuid,uuid,uuid)', 'execute'),
  'clients cannot mint claims directly'
);
select ok(
  has_function_privilege('service_role', 'public.unlock_offer_for_check_in(uuid,uuid,uuid,uuid)', 'execute'),
  'trusted server code can unlock a verified offer'
);
select ok((select prosecdef from pg_proc where oid = 'public.list_eligible_offers(uuid,uuid[],timestamptz)'::regprocedure), 'eligibility is an explicitly privileged operation');
select ok((select prosecdef from pg_proc where oid = 'public.unlock_offer_for_check_in(uuid,uuid,uuid,uuid)'::regprocedure), 'claim creation is an explicitly privileged operation');
select ok(not (select prosecdef from pg_proc where oid = 'private.time_is_in_window(time,time,time)'::regprocedure), 'time-window helper is security invoker');
select ok(not (select prosecdef from pg_proc where oid = 'private.enforce_partner_campaign_link()'::regprocedure), 'campaign-link trigger is security invoker');

select ok(exists (select 1 from pg_constraint where conrelid = 'public.offers'::regclass and conname = 'offers_partner_creator_consistent'), 'partner offers must be founder-created');
select ok(exists (select 1 from pg_constraint where conrelid = 'public.offer_versions'::regclass and conname = 'offer_versions_duration_valid'), 'offer duration is database-validated');
select ok(exists (select 1 from pg_constraint where conrelid = 'public.offer_claims'::regclass and conname = 'offer_claims_one_per_check_in'), 'one verified check-in unlocks at most one offer');
select ok(exists (select 1 from pg_constraint where conrelid = 'public.offer_versions'::regclass and conname = 'offer_versions_redemption_destination_consistent'), 'external redemption destinations are HTTPS and founder-approved');
select ok(
  not exists (
    select 1
    from pg_constraint as constraint_record
    join pg_class as table_record on table_record.oid = constraint_record.conrelid
    join pg_namespace as schema_record on schema_record.oid = table_record.relnamespace
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
select ok(exists (select 1 from private.offer_claim_config where singleton and maximum_unlock_delay_seconds = 900), 'claim unlock replay protection has a safe default');
select ok(not has_schema_privilege('authenticated', 'private', 'usage'), 'authenticated clients cannot resolve private schema objects');
select ok(has_schema_privilege('service_role', 'private', 'usage'), 'trusted server code can use private schema objects');
select ok((select proconfig @> array['search_path=""'] from pg_proc where oid = 'public.list_eligible_offers(uuid,uuid[],timestamptz)'::regprocedure), 'eligibility RPC pins an empty search path');
select ok((select proconfig @> array['search_path=""'] from pg_proc where oid = 'public.unlock_offer_for_check_in(uuid,uuid,uuid,uuid)'::regprocedure), 'unlock RPC pins an empty search path');

select * from finish();
rollback;
