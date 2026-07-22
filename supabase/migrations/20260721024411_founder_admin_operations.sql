-- Founder-only operations for the Outly MVP. The browser never receives
-- service credentials; authenticated Edge Functions derive the caller from
-- the JWT and invoke these RPCs with the service role.

create table private.offer_reviews (
  id bigint generated always as identity primary key,
  offer_version_id uuid not null references public.offer_versions (id) on delete cascade,
  reviewer_id uuid references auth.users (id) on delete set null,
  decision text not null,
  public_response text,
  private_note text,
  created_at timestamptz not null default now(),

  constraint offer_reviews_decision_valid check (
    decision in ('approved', 'changes_requested', 'rejected')
  ),
  constraint offer_reviews_public_response_valid check (
    public_response is null
    or (
      public_response = btrim(public_response)
      and char_length(public_response) between 1 and 1000
    )
  ),
  constraint offer_reviews_private_note_valid check (
    private_note is null
    or (
      private_note = btrim(private_note)
      and char_length(private_note) between 1 and 4000
    )
  )
);

create index offer_reviews_version_created_idx
  on private.offer_reviews (offer_version_id, created_at desc);
create index offer_reviews_reviewer_idx
  on private.offer_reviews (reviewer_id)
  where reviewer_id is not null;

alter table private.offer_reviews enable row level security;
revoke all on table private.offer_reviews from public, anon, authenticated, service_role;
grant select, insert, update, delete on table private.offer_reviews to service_role;
grant usage, select on sequence private.offer_reviews_id_seq to service_role;

-- Partner artwork is founder-managed and becomes public only after approval.
-- Clients receive a storage path, never credentials that permit uploads.
alter table private.partners
  add constraint partners_logo_storage_path_valid check (
    approved_logo_storage_path is null
    or (
      approved_logo_storage_path ~ '^partner-media/[A-Za-z0-9][A-Za-z0-9._/-]*$'
      and char_length(approved_logo_storage_path) <= 512
      and approved_logo_storage_path !~ '(^|/)\.{1,2}(/|$)'
      and approved_logo_storage_path !~ '//'
      and right(approved_logo_storage_path, 1) <> '/'
    )
  );

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'partner-media',
  'partner-media',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']::text[]
)
on conflict (id) do update
set
  name = excluded.name,
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- No storage.objects write policy is intentionally created. Only founder
-- server operations may upload approved partner artwork for the MVP.

create function private.require_founder_admin(p_user_id uuid)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if p_user_id is null or not exists (
    select 1
    from private.internal_admins as admin_record
    where admin_record.user_id = p_user_id
      and admin_record.role = 'founder_admin'
      and admin_record.active
  ) then
    raise exception using errcode = '42501', message = 'founder_access_required';
  end if;
end;
$$;

revoke execute on function private.require_founder_admin(uuid)
from public, anon, authenticated, service_role;
grant execute on function private.require_founder_admin(uuid) to service_role;

create function public.has_founder_access(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_user_id is not null and exists (
    select 1
    from private.internal_admins as admin_record
    where admin_record.user_id = p_user_id
      and admin_record.role = 'founder_admin'
      and admin_record.active
  );
$$;

revoke execute on function public.has_founder_access(uuid)
from public, anon, authenticated, service_role;
grant execute on function public.has_founder_access(uuid) to service_role;

create function public.get_founder_admin_snapshot(p_user_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_result jsonb;
begin
  perform private.require_founder_admin(p_user_id);

  select jsonb_build_object(
    'server_time', current_timestamp,
    'metrics', jsonb_build_object(
      'active_consumers', (
        select count(*) from public.consumer_profiles
        where account_status = 'active'
      ),
      'pending_venues', (
        select count(*) from public.venues
        where registration_status in ('pending_review', 'changes_requested')
      ),
      'published_venues', (
        select count(*) from public.venues
        where registration_status = 'approved' and publication_status = 'published'
      ),
      'live_offers', (
        select count(*) from public.offers where lifecycle_status = 'live'
      ),
      'verified_check_ins', (
        select count(*) from public.check_ins where outcome = 'verified'
      ),
      'offer_claims', (
        select count(*) from public.offer_claims where status <> 'voided'
      )
    ),
    'venues', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', venue_record.id,
        'slug', venue_record.slug,
        'name', venue_record.display_name,
        'neighbourhood', venue_record.neighbourhood,
        'registration_status', venue_record.registration_status,
        'publication_status', venue_record.publication_status,
        'placement_state', venue_record.placement_state,
        'account_status', account_record.account_status,
        'business_email', business_record.business_email,
        'created_at', venue_record.created_at
      ) order by venue_record.created_at desc)
      from public.venues as venue_record
      left join public.venue_accounts as account_record
        on account_record.venue_id = venue_record.id
      left join private.venue_business_details as business_record
        on business_record.venue_id = venue_record.id
    ), '[]'::jsonb),
    'consumers', coalesce((
      select jsonb_agg(jsonb_build_object(
        'user_id', profile_record.user_id,
        'email', auth_user.email,
        'first_name', profile_record.first_name,
        'onboarding_status', profile_record.onboarding_status,
        'account_status', profile_record.account_status,
        'created_at', profile_record.created_at
      ) order by profile_record.created_at desc)
      from (
        select * from public.consumer_profiles
        order by created_at desc
        limit 250
      ) as profile_record
      join auth.users as auth_user on auth_user.id = profile_record.user_id
    ), '[]'::jsonb),
    'offer_review_queue', coalesce((
      select jsonb_agg(jsonb_build_object(
        'offer_id', offer_record.id,
        'offer_version_id', version_record.id,
        'venue_id', offer_record.venue_id,
        'venue_name', venue_record.display_name,
        'kind', offer_record.offer_kind,
        'title', version_record.public_title,
        'submitted_at', version_record.submitted_at,
        'approval_state', version_record.approval_state
      ) order by version_record.submitted_at nulls last)
      from public.offer_versions as version_record
      join public.offers as offer_record on offer_record.id = version_record.offer_id
      join public.venues as venue_record on venue_record.id = offer_record.venue_id
      where version_record.approval_state in ('pending_review', 'changes_requested')
    ), '[]'::jsonb),
    'partners', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', partner_record.id,
        'brand_name', partner_record.brand_name,
        'legal_name', partner_record.legal_name,
        'status', partner_record.status,
        'website_url', partner_record.website_url,
        'campaign_count', (
          select count(*) from private.partner_campaigns as campaign_record
          where campaign_record.partner_id = partner_record.id
        )
      ) order by partner_record.brand_name)
      from private.partners as partner_record
      where partner_record.status <> 'archived'
    ), '[]'::jsonb)
  ) into v_result;

  return v_result;
end;
$$;

revoke execute on function public.get_founder_admin_snapshot(uuid)
from public, anon, authenticated, service_role;
grant execute on function public.get_founder_admin_snapshot(uuid) to service_role;

create function public.founder_create_venue(
  p_user_id uuid,
  p_display_name text,
  p_address_line_1 text,
  p_neighbourhood text,
  p_postal_code text,
  p_latitude double precision,
  p_longitude double precision,
  p_geofence_radius_metres smallint default 75
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_id uuid := gen_random_uuid();
  v_slug_base text;
  v_slug text;
  v_venue public.venues%rowtype;
begin
  perform private.require_founder_admin(p_user_id);

  if p_display_name is null
     or p_address_line_1 is null
     or p_neighbourhood is null
     or p_postal_code is null
     or p_latitude is null
     or p_longitude is null
     or p_latitude not between -90 and 90
     or p_longitude not between -180 and 180 then
    raise exception using errcode = '22023', message = 'invalid_venue_parameter';
  end if;

  v_slug_base := trim(both '-' from lower(
    regexp_replace(btrim(p_display_name), '[^A-Za-z0-9]+', '-', 'g')
  ));
  if char_length(v_slug_base) < 2 then
    v_slug_base := 'venue';
  end if;
  v_slug := left(v_slug_base, 67) || '-' || substr(replace(v_id::text, '-', ''), 1, 8);

  insert into public.venues (
    id, slug, display_name, registration_status, publication_status,
    address_line_1, market_code, neighbourhood, city, province_code,
    postal_code, country_code, location, geofence_radius_metres,
    timezone, approved_at
  )
  values (
    v_id, v_slug, btrim(p_display_name), 'approved', 'published',
    btrim(p_address_line_1), 'toronto', btrim(p_neighbourhood), 'Toronto', 'ON',
    upper(btrim(p_postal_code)), 'CA',
    extensions.st_setsrid(extensions.st_makepoint(p_longitude, p_latitude), 4326)::extensions.geography,
    p_geofence_radius_metres, 'America/Toronto', clock_timestamp()
  )
  returning * into v_venue;

  insert into private.venue_reviews (venue_id, reviewer_id, decision, private_note)
  values (v_venue.id, p_user_id, 'approved', 'Founder-created listing');

  return jsonb_build_object(
    'id', v_venue.id,
    'slug', v_venue.slug,
    'name', v_venue.display_name,
    'registration_status', v_venue.registration_status,
    'publication_status', v_venue.publication_status
  );
end;
$$;

revoke execute on function public.founder_create_venue(
  uuid, text, text, text, text, double precision, double precision, smallint
) from public, anon, authenticated, service_role;
grant execute on function public.founder_create_venue(
  uuid, text, text, text, text, double precision, double precision, smallint
) to service_role;

create function public.review_venue_registration(
  p_user_id uuid,
  p_venue_id uuid,
  p_decision text,
  p_public_response text default null,
  p_private_note text default null,
  p_neighbourhood text default null,
  p_postal_code text default null,
  p_latitude double precision default null,
  p_longitude double precision default null,
  p_geofence_radius_metres smallint default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := clock_timestamp();
  v_venue public.venues%rowtype;
begin
  perform private.require_founder_admin(p_user_id);

  if p_decision not in (
    'approved', 'changes_requested', 'rejected', 'suspended', 'reinstated', 'archived'
  ) then
    raise exception using errcode = '22023', message = 'invalid_venue_review_decision';
  end if;
  if (p_latitude is null) <> (p_longitude is null)
     or (p_latitude is not null and p_latitude not between -90 and 90)
     or (p_longitude is not null and p_longitude not between -180 and 180) then
    raise exception using errcode = '22023', message = 'invalid_venue_coordinates';
  end if;

  select * into v_venue
  from public.venues as venue_record
  where venue_record.id = p_venue_id
  for update;

  if v_venue.id is null then
    raise exception using errcode = 'P0001', message = 'venue_not_found';
  end if;

  if p_decision in ('approved', 'reinstated') then
    update public.venues as venue_record
    set
      registration_status = 'approved',
      publication_status = 'published',
      neighbourhood = coalesce(nullif(btrim(p_neighbourhood), ''), venue_record.neighbourhood),
      postal_code = coalesce(nullif(upper(btrim(p_postal_code)), ''), venue_record.postal_code),
      location = case
        when p_latitude is null then venue_record.location
        else extensions.st_setsrid(
          extensions.st_makepoint(p_longitude, p_latitude), 4326
        )::extensions.geography
      end,
      geofence_radius_metres = coalesce(p_geofence_radius_metres, venue_record.geofence_radius_metres),
      approved_at = coalesce(venue_record.approved_at, v_now),
      suspended_at = null,
      archived_at = null
    where venue_record.id = p_venue_id
    returning * into v_venue;

    update public.venue_accounts
    set account_status = 'active'
    where venue_id = p_venue_id;
  elsif p_decision = 'changes_requested' then
    update public.venues
    set registration_status = 'changes_requested', publication_status = 'unpublished',
        suspended_at = null, archived_at = null
    where id = p_venue_id
    returning * into v_venue;

    update public.venue_accounts set account_status = 'draft' where venue_id = p_venue_id;
  elsif p_decision = 'rejected' then
    update public.venues
    set registration_status = 'rejected', publication_status = 'unpublished',
        suspended_at = null, archived_at = null
    where id = p_venue_id
    returning * into v_venue;

    update public.venue_accounts set account_status = 'draft' where venue_id = p_venue_id;
  elsif p_decision = 'suspended' then
    if v_venue.approved_at is null then
      raise exception using errcode = 'P0001', message = 'unapproved_venue_cannot_be_suspended';
    end if;
    update public.venues
    set registration_status = 'suspended', publication_status = 'unpublished',
        suspended_at = v_now, archived_at = null
    where id = p_venue_id
    returning * into v_venue;

    update public.venue_accounts set account_status = 'suspended' where venue_id = p_venue_id;
  else
    update public.venues
    set registration_status = 'archived', publication_status = 'unpublished',
        suspended_at = null, archived_at = v_now
    where id = p_venue_id
    returning * into v_venue;

    update public.venue_accounts set account_status = 'suspended' where venue_id = p_venue_id;
  end if;

  insert into private.venue_reviews (
    venue_id, reviewer_id, decision, public_response, private_note
  )
  values (
    p_venue_id,
    p_user_id,
    p_decision,
    nullif(btrim(p_public_response), ''),
    nullif(btrim(p_private_note), '')
  );

  return jsonb_build_object(
    'id', v_venue.id,
    'registration_status', v_venue.registration_status,
    'publication_status', v_venue.publication_status
  );
end;
$$;

revoke execute on function public.review_venue_registration(
  uuid, uuid, text, text, text, text, text, double precision, double precision, smallint
) from public, anon, authenticated, service_role;
grant execute on function public.review_venue_registration(
  uuid, uuid, text, text, text, text, text, double precision, double precision, smallint
) to service_role;

create function public.review_offer_version(
  p_user_id uuid,
  p_offer_version_id uuid,
  p_decision text,
  p_public_response text default null,
  p_private_note text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := clock_timestamp();
  v_version public.offer_versions%rowtype;
  v_offer public.offers%rowtype;
begin
  perform private.require_founder_admin(p_user_id);

  if p_decision not in ('approved', 'changes_requested', 'rejected') then
    raise exception using errcode = '22023', message = 'invalid_offer_review_decision';
  end if;

  select * into v_version
  from public.offer_versions as version_record
  where version_record.id = p_offer_version_id
  for update;

  if v_version.id is null then
    raise exception using errcode = 'P0001', message = 'offer_version_not_found';
  end if;
  if v_version.approval_state = 'approved' then
    raise exception using errcode = 'P0001', message = 'approved_offer_version_is_immutable';
  end if;

  select * into v_offer
  from public.offers as offer_record
  where offer_record.id = v_version.offer_id
  for update;

  if p_decision = 'approved' then
    if v_version.submitted_at is null or not exists (
      select 1 from public.offer_schedules as schedule_record
      where schedule_record.offer_version_id = v_version.id
    ) then
      raise exception using errcode = 'P0001', message = 'offer_not_ready_for_approval';
    end if;

    update public.offer_versions
    set approval_state = 'approved', approved_by = p_user_id, approved_at = v_now
    where id = v_version.id
    returning * into v_version;

    update public.offers
    set current_approved_version_id = v_version.id, lifecycle_status = 'live'
    where id = v_offer.id
    returning * into v_offer;
  else
    update public.offer_versions
    set approval_state = p_decision, approved_by = null, approved_at = null
    where id = v_version.id
    returning * into v_version;

    update public.offers
    set lifecycle_status = p_decision
    where id = v_offer.id
    returning * into v_offer;
  end if;

  insert into private.offer_reviews (
    offer_version_id, reviewer_id, decision, public_response, private_note
  )
  values (
    v_version.id,
    p_user_id,
    p_decision,
    nullif(btrim(p_public_response), ''),
    nullif(btrim(p_private_note), '')
  );

  return jsonb_build_object(
    'offer_id', v_offer.id,
    'offer_version_id', v_version.id,
    'lifecycle_status', v_offer.lifecycle_status,
    'approval_state', v_version.approval_state
  );
end;
$$;

revoke execute on function public.review_offer_version(uuid, uuid, text, text, text)
from public, anon, authenticated, service_role;
grant execute on function public.review_offer_version(uuid, uuid, text, text, text)
to service_role;

-- MVP subscription control is founder-managed until Stripe Checkout and its
-- signed webhook are configured. This gives trials and negotiated Pro venues
-- the same entitlement path without pretending a payment has occurred.
create function public.set_venue_subscription_plan(
  p_user_id uuid,
  p_venue_id uuid,
  p_plan_code text,
  p_status text,
  p_trial_ends_at timestamptz default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_subscription private.venue_subscriptions%rowtype;
begin
  perform private.require_founder_admin(p_user_id);

  if p_plan_code not in ('free', 'pro')
     or (p_plan_code = 'free' and p_status <> 'free')
     or (p_plan_code = 'pro' and p_status not in ('trialing', 'active')) then
    raise exception using errcode = '22023', message = 'invalid_subscription_state';
  end if;

  if (p_status = 'trialing' and (
        p_trial_ends_at is null or p_trial_ends_at <= current_timestamp
      ))
     or (p_status <> 'trialing' and p_trial_ends_at is not null) then
    raise exception using errcode = '22023', message = 'invalid_trial_end';
  end if;

  if not exists (select 1 from public.venues where id = p_venue_id) then
    raise exception using errcode = 'P0001', message = 'venue_not_found';
  end if;

  insert into private.venue_subscriptions as current_subscription (
    venue_id, plan_code, stripe_status, trial_ends_at,
    stripe_subscription_id, stripe_price_id
  )
  values (
    p_venue_id, p_plan_code, p_status,
    case when p_status = 'trialing' then p_trial_ends_at else null end,
    null, null
  )
  on conflict on constraint venue_subscriptions_pkey do update
  set
    plan_code = excluded.plan_code,
    stripe_status = excluded.stripe_status,
    trial_ends_at = excluded.trial_ends_at,
    stripe_customer_id = case
      when excluded.plan_code = 'free' then null
      else current_subscription.stripe_customer_id
    end,
    stripe_subscription_id = case
      when excluded.plan_code = 'free' then null
      else current_subscription.stripe_subscription_id
    end,
    stripe_price_id = case
      when excluded.plan_code = 'free' then null
      else current_subscription.stripe_price_id
    end,
    cancel_at_period_end = false,
    cancelled_at = null
  returning * into v_subscription;

  return jsonb_build_object(
    'venue_id', v_subscription.venue_id,
    'plan_code', v_subscription.plan_code,
    'status', v_subscription.stripe_status,
    'trial_ends_at', v_subscription.trial_ends_at
  );
end;
$$;

revoke execute on function public.set_venue_subscription_plan(
  uuid, uuid, text, text, timestamptz
) from public, anon, authenticated, service_role;
grant execute on function public.set_venue_subscription_plan(
  uuid, uuid, text, text, timestamptz
) to service_role;

create function public.upsert_partner(
  p_user_id uuid,
  p_partner_id uuid,
  p_brand_name text,
  p_legal_name text,
  p_website_url text,
  p_industry text,
  p_logo_storage_path text,
  p_logo_alt_text text,
  p_contact_name text,
  p_contact_email text,
  p_contact_phone text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_partner private.partners%rowtype;
begin
  perform private.require_founder_admin(p_user_id);

  if p_brand_name is null
     or p_legal_name is null
     or p_logo_storage_path is null
     or p_logo_alt_text is null
     or p_contact_name is null
     or p_contact_email is null then
    raise exception using errcode = '22023', message = 'missing_partner_parameter';
  end if;

  if p_partner_id is null then
    insert into private.partners (
      brand_name, legal_name, status, website_url, industry,
      approved_logo_storage_path, approved_logo_alt_text
    )
    values (
      btrim(p_brand_name), btrim(p_legal_name), 'active',
      nullif(btrim(p_website_url), ''), nullif(btrim(p_industry), ''),
      btrim(p_logo_storage_path), btrim(p_logo_alt_text)
    )
    returning * into v_partner;
  else
    update private.partners as partner_record
    set
      brand_name = btrim(p_brand_name),
      legal_name = btrim(p_legal_name),
      website_url = nullif(btrim(p_website_url), ''),
      industry = nullif(btrim(p_industry), ''),
      approved_logo_storage_path = btrim(p_logo_storage_path),
      approved_logo_alt_text = btrim(p_logo_alt_text)
    where partner_record.id = p_partner_id
      and partner_record.status <> 'archived'
    returning * into v_partner;

    if v_partner.id is null then
      raise exception using errcode = 'P0001', message = 'partner_not_found';
    end if;

    delete from private.partner_contacts
    where partner_id = v_partner.id and is_primary;
  end if;

  insert into private.partner_contacts (
    partner_id, contact_name, email, phone, is_primary
  )
  values (
    v_partner.id, btrim(p_contact_name), btrim(p_contact_email),
    nullif(btrim(p_contact_phone), ''), true
  );

  return jsonb_build_object(
    'id', v_partner.id,
    'brand_name', v_partner.brand_name,
    'status', v_partner.status
  );
end;
$$;

revoke execute on function public.upsert_partner(
  uuid, uuid, text, text, text, text, text, text, text, text, text
) from public, anon, authenticated, service_role;
grant execute on function public.upsert_partner(
  uuid, uuid, text, text, text, text, text, text, text, text, text
) to service_role;

create function public.create_partner_campaign_offer(
  p_user_id uuid,
  p_partner_id uuid,
  p_venue_ids uuid[],
  p_internal_name text,
  p_public_title text,
  p_short_explanation text,
  p_cta_label text,
  p_destination_url text,
  p_fine_print text,
  p_sponsor_disclosure text,
  p_claim_duration_seconds integer,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_total_claim_limit integer,
  p_per_user_limit smallint default 1,
  p_discovery_badge_label text default 'Outly exclusive',
  p_discovery_icon_key text default 'outly-winged-o'
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := clock_timestamp();
  v_partner private.partners%rowtype;
  v_campaign_id uuid;
  v_venue public.venues%rowtype;
  v_offer_id uuid;
  v_version_id uuid;
  v_offer_ids uuid[] := array[]::uuid[];
begin
  perform private.require_founder_admin(p_user_id);

  if p_partner_id is null
     or coalesce(array_length(p_venue_ids, 1), 0) = 0
     or p_internal_name is null
     or p_public_title is null
     or p_cta_label is null
     or p_destination_url is null
     or p_sponsor_disclosure is null
     or p_starts_at is null
     or p_destination_url !~ '^https://' then
    raise exception using errcode = '22023', message = 'invalid_partner_campaign_parameter';
  end if;
  if p_ends_at is not null and p_ends_at <= p_starts_at then
    raise exception using errcode = '22023', message = 'invalid_partner_campaign_dates';
  end if;

  select * into v_partner
  from private.partners as partner_record
  where partner_record.id = p_partner_id and partner_record.status = 'active';

  if v_partner.id is null or v_partner.approved_logo_storage_path is null then
    raise exception using errcode = 'P0001', message = 'active_partner_with_logo_required';
  end if;

  if (
    select count(distinct venue_record.id)
    from public.venues as venue_record
    join private.venue_subscriptions as subscription_record
      on subscription_record.venue_id = venue_record.id
    join private.plan_entitlements as entitlement_record
      on entitlement_record.plan_code = subscription_record.plan_code
     and entitlement_record.entitlement_key = 'partner_campaign_access'
     and entitlement_record.entitlement_value = 'true'::jsonb
    where venue_record.id = any(p_venue_ids)
      and venue_record.registration_status = 'approved'
      and venue_record.publication_status = 'published'
      and (
        subscription_record.stripe_status = 'active'
        or (
          subscription_record.stripe_status = 'trialing'
          and subscription_record.trial_ends_at > v_now
        )
      )
  ) <> (select count(distinct requested_id) from unnest(p_venue_ids) as requested_id) then
    raise exception using errcode = 'P0001', message = 'partner_campaign_requires_pro_venues';
  end if;

  insert into private.partner_campaigns (
    partner_id, internal_name, campaign_status, approval_status,
    starts_at, ends_at, market_code, minimum_age, total_claim_limit,
    per_user_limit, public_sponsor_wording, public_reward,
    approved_disclosure, public_terms, created_by, approved_by, approved_at
  )
  values (
    v_partner.id, btrim(p_internal_name), 'live', 'approved',
    p_starts_at, p_ends_at, 'toronto', 19, p_total_claim_limit,
    p_per_user_limit, v_partner.brand_name, btrim(p_public_title),
    btrim(p_sponsor_disclosure), nullif(btrim(p_fine_print), ''),
    p_user_id, p_user_id, v_now
  )
  returning id into v_campaign_id;

  for v_venue in
    select venue_record.*
    from public.venues as venue_record
    where venue_record.id = any(p_venue_ids)
    order by venue_record.id
  loop
    insert into private.campaign_venues (
      campaign_id, venue_id, starts_at, ends_at
    ) values (v_campaign_id, v_venue.id, p_starts_at, p_ends_at);

    insert into public.offers (
      venue_id, creator_type, offer_kind, lifecycle_status,
      display_priority, created_by
    )
    values (v_venue.id, 'outly', 'partner', 'live', 100, p_user_id)
    returning id into v_offer_id;

    insert into public.offer_versions (
      offer_id, version_number, public_title, short_explanation,
      fine_print, cta_label, redemption_mode, destination_url,
      minimum_age, eligibility_mode, claim_duration_seconds,
      per_user_limit, total_claim_limit, presentation_kind,
      sponsor_display_name, sponsor_logo_storage_path,
      sponsor_logo_alt_text, sponsor_disclosure,
      discovery_treatment, discovery_badge_label, discovery_icon_key,
      approval_state, submitted_by, submitted_at
    )
    values (
      v_offer_id, 1, btrim(p_public_title), nullif(btrim(p_short_explanation), ''),
      nullif(btrim(p_fine_print), ''), btrim(p_cta_label), 'external_link', btrim(p_destination_url),
      19, 'verified_check_in', p_claim_duration_seconds,
      p_per_user_limit, p_total_claim_limit, 'partner',
      v_partner.brand_name, v_partner.approved_logo_storage_path,
      v_partner.approved_logo_alt_text, btrim(p_sponsor_disclosure),
      'partner_featured', btrim(p_discovery_badge_label), btrim(p_discovery_icon_key),
      'pending_review', p_user_id, v_now
    )
    returning id into v_version_id;

    insert into public.offer_schedules (
      offer_version_id, nightlife_start_date, nightlife_end_date
    )
    values (
      v_version_id,
      private.nightlife_date_for(p_starts_at, v_venue.timezone),
      case when p_ends_at is null then null
        else private.nightlife_date_for(p_ends_at, v_venue.timezone) end
    );

    update public.offer_versions
    set approval_state = 'approved', approved_by = p_user_id, approved_at = v_now
    where id = v_version_id;

    update public.offers
    set current_approved_version_id = v_version_id
    where id = v_offer_id;

    insert into private.offer_campaign_links (offer_id, campaign_id)
    values (v_offer_id, v_campaign_id);

    insert into private.offer_reviews (
      offer_version_id, reviewer_id, decision, private_note
    ) values (
      v_version_id, p_user_id, 'approved', 'Founder-created partner campaign'
    );

    v_offer_ids := array_append(v_offer_ids, v_offer_id);
  end loop;

  return jsonb_build_object(
    'campaign_id', v_campaign_id,
    'offer_ids', to_jsonb(v_offer_ids),
    'venue_count', cardinality(v_offer_ids)
  );
end;
$$;

revoke execute on function public.create_partner_campaign_offer(
  uuid, uuid, uuid[], text, text, text, text, text, text, text,
  integer, timestamptz, timestamptz, integer, smallint, text, text
) from public, anon, authenticated, service_role;
grant execute on function public.create_partner_campaign_offer(
  uuid, uuid, uuid[], text, text, text, text, text, text, text,
  integer, timestamptz, timestamptz, integer, smallint, text, text
) to service_role;
