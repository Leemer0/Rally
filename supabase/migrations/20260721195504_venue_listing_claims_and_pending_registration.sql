-- Founder-created discovery listings can be claimed without replacing or
-- unpublishing their public venue row. Registration data is held privately
-- until Supabase Auth confirms the business email, and every claim decision is
-- retained in a dedicated audit trail.

create table private.pending_venue_registrations (
  auth_user_id uuid primary key references auth.users (id) on delete cascade,
  existing_venue_id uuid references public.venues (id) on delete restrict,
  display_name text not null,
  venue_address text not null,
  legal_business_name text not null,
  legal_address text not null,
  primary_contact_name text not null,
  primary_contact_title text,
  business_email text not null,
  business_phone text not null,
  venue_agreement_version text not null,
  pending_state text not null default 'pending_email_confirmation',
  stored_at timestamptz not null default now(),
  consumed_at timestamptz,
  updated_at timestamptz not null default now(),

  constraint pending_venue_registrations_state_valid check (
    pending_state in ('pending_email_confirmation', 'consumed')
  ),
  constraint pending_venue_registrations_state_consistent check (
    (pending_state = 'pending_email_confirmation' and consumed_at is null)
    or (pending_state = 'consumed' and consumed_at is not null)
  ),
  constraint pending_venue_registrations_required_text_valid check (
    display_name = btrim(display_name)
    and char_length(display_name) between 1 and 100
    and venue_address = btrim(venue_address)
    and char_length(venue_address) between 1 and 160
    and legal_business_name = btrim(legal_business_name)
    and char_length(legal_business_name) between 1 and 160
    and legal_address = btrim(legal_address)
    and char_length(legal_address) between 5 and 300
    and primary_contact_name = btrim(primary_contact_name)
    and char_length(primary_contact_name) between 1 and 120
    and business_email = lower(btrim(business_email))
    and char_length(business_email) between 3 and 254
    and position('@' in business_email) > 1
    and business_phone = btrim(business_phone)
    and char_length(business_phone) between 7 and 32
    and venue_agreement_version = btrim(venue_agreement_version)
    and char_length(venue_agreement_version) between 1 and 80
  ),
  constraint pending_venue_registrations_title_valid check (
    primary_contact_title is null
    or (
      primary_contact_title = btrim(primary_contact_title)
      and char_length(primary_contact_title) between 1 and 100
    )
  )
);

comment on table private.pending_venue_registrations is
  'Server-only registration payload held until the matching Supabase Auth email is confirmed.';

create index pending_venue_registrations_existing_venue_id_idx
  on private.pending_venue_registrations (existing_venue_id)
  where existing_venue_id is not null;

create table private.venue_account_claims (
  id bigint generated always as identity primary key,
  venue_id uuid not null references public.venues (id) on delete restrict,
  auth_user_id uuid references auth.users (id) on delete set null,
  claim_status text not null default 'pending_review',
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users (id) on delete set null,
  reviewed_by_snapshot uuid,
  withdrawn_at timestamptz,
  withdrawal_reason text,
  public_response text,
  private_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint venue_account_claims_status_valid check (
    claim_status in (
      'pending_review', 'changes_requested', 'superseded', 'approved', 'rejected',
      'withdrawn'
    )
  ),
  constraint venue_account_claims_review_consistent check (
    (
      claim_status = 'pending_review'
      and reviewed_at is null
      and reviewed_by is null
      and reviewed_by_snapshot is null
      and withdrawn_at is null
      and withdrawal_reason is null
    )
    or (
      claim_status = 'withdrawn'
      and withdrawn_at is not null
      and withdrawal_reason is not null
      and (
        (
          reviewed_at is null
          and reviewed_by is null
          and reviewed_by_snapshot is null
        )
        or (
          reviewed_at is not null
          and reviewed_by_snapshot is not null
        )
      )
    )
    or (
      claim_status not in ('pending_review', 'withdrawn')
      and reviewed_at is not null
      and reviewed_by_snapshot is not null
      and withdrawn_at is null
      and withdrawal_reason is null
    )
  ),
  constraint venue_account_claims_withdrawal_reason_valid check (
    withdrawal_reason is null
    or withdrawal_reason in ('account_deleted', 'auth_identity_deleted')
  ),
  constraint venue_account_claims_public_response_valid check (
    public_response is null
    or (
      public_response = btrim(public_response)
      and char_length(public_response) between 1 and 1000
    )
  ),
  constraint venue_account_claims_changes_response_required check (
    claim_status <> 'changes_requested' or public_response is not null
  ),
  constraint venue_account_claims_private_note_valid check (
    private_note is null
    or (
      private_note = btrim(private_note)
      and char_length(private_note) between 1 and 4000
    )
  )
);

comment on table private.venue_account_claims is
  'Founder-reviewed audit trail for linking a business Auth account to an existing approved public venue listing.';

create unique index venue_account_claims_one_open_per_venue_idx
  on private.venue_account_claims (venue_id)
  where claim_status in ('pending_review', 'changes_requested');
create unique index venue_account_claims_one_open_per_user_idx
  on private.venue_account_claims (auth_user_id)
  where auth_user_id is not null
    and claim_status in ('pending_review', 'changes_requested');
create index venue_account_claims_review_queue_idx
  on private.venue_account_claims (claim_status, submitted_at)
  where claim_status in ('pending_review', 'changes_requested');
create index venue_account_claims_venue_id_idx
  on private.venue_account_claims (venue_id);
create index venue_account_claims_auth_user_id_idx
  on private.venue_account_claims (auth_user_id)
  where auth_user_id is not null;
create index venue_account_claims_reviewed_by_idx
  on private.venue_account_claims (reviewed_by)
  where reviewed_by is not null;
create index venue_account_claims_reviewer_snapshot_idx
  on private.venue_account_claims (reviewed_by_snapshot)
  where reviewed_by_snapshot is not null;

-- The live reviewer FK may be nulled when a founder Auth identity is removed.
-- Keep the reviewer UUID snapshot so the moderation decision remains
-- attributable without making founder account deletion fail a CHECK constraint.
create function private.sync_venue_claim_reviewer_snapshot()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.reviewed_by is not null then
    new.reviewed_by_snapshot := new.reviewed_by;
  elsif tg_op = 'UPDATE'
        and old.reviewed_by is not null
        and new.reviewed_by is null then
    new.reviewed_by_snapshot := coalesce(
      old.reviewed_by_snapshot,
      old.reviewed_by
    );
  end if;

  return new;
end;
$$;

revoke execute on function private.sync_venue_claim_reviewer_snapshot()
from public, anon, authenticated, service_role;

create trigger venue_account_claims_sync_reviewer_snapshot
before insert or update of reviewed_by on private.venue_account_claims
for each row execute function private.sync_venue_claim_reviewer_snapshot();

-- Supabase Auth can also be removed administratively. The FK's SET NULL must
-- close an unfinished claim in the same statement or the partial unique index
-- would permanently reserve the public listing for a nonexistent claimant.
create function private.close_venue_claim_on_auth_unlink()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.auth_user_id is not null
     and new.auth_user_id is null
     and old.claim_status in ('pending_review', 'changes_requested') then
    new.claim_status := 'withdrawn';
    new.withdrawn_at := clock_timestamp();
    new.withdrawal_reason := 'auth_identity_deleted';
  end if;

  return new;
end;
$$;

revoke execute on function private.close_venue_claim_on_auth_unlink()
from public, anon, authenticated, service_role;

create trigger venue_account_claims_close_on_auth_unlink
before update of auth_user_id on private.venue_account_claims
for each row execute function private.close_venue_claim_on_auth_unlink();

create trigger pending_venue_registrations_set_updated_at
before update on private.pending_venue_registrations
for each row execute function private.set_updated_at();

create trigger venue_account_claims_set_updated_at
before update on private.venue_account_claims
for each row execute function private.set_updated_at();

alter table private.pending_venue_registrations enable row level security;
alter table private.venue_account_claims enable row level security;

revoke all on table
  private.pending_venue_registrations,
  private.venue_account_claims
from public, anon, authenticated, service_role;
grant select, insert, update, delete on table
  private.pending_venue_registrations,
  private.venue_account_claims
to service_role;
grant usage, select on sequence private.venue_account_claims_id_seq to service_role;

-- Account access and billing identity belong to one business login tenure, not
-- permanently to a public discovery listing. This routine is deliberately
-- idempotent so the explicit deletion workflow and an Auth cascade can share it.
create function private.require_venue_subscription_detached(
  p_venue_id uuid
)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if exists (
    select 1
    from private.venue_subscriptions as subscription_record
    where subscription_record.venue_id = p_venue_id
      and subscription_record.stripe_subscription_id is not null
      and subscription_record.stripe_status not in (
        'cancelled', 'incomplete_expired'
      )
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'active_subscription_cancellation_required';
  end if;
end;
$$;

revoke execute on function private.require_venue_subscription_detached(uuid)
from public, anon, authenticated, service_role;

create function private.retire_venue_access(
  p_auth_user_id uuid,
  p_venue_id uuid,
  p_preserve_public_listing boolean,
  p_at timestamptz
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  delete from private.pending_venue_registrations
  where auth_user_id = p_auth_user_id;

  delete from private.venue_business_details
  where venue_id = p_venue_id;

  update public.offers
  set lifecycle_status = 'archived',
      archived_at = p_at,
      paused_reason = null
  where venue_id = p_venue_id
    and creator_type = 'venue'
    and lifecycle_status <> 'archived';

  update private.venue_subscriptions
  set plan_code = 'free',
      stripe_customer_id = null,
      stripe_subscription_id = null,
      stripe_price_id = null,
      stripe_status = 'free',
      trial_ends_at = null,
      current_period_ends_at = null,
      cancel_at_period_end = false,
      cancelled_at = null,
      last_webhook_at = null
  where venue_id = p_venue_id;

  update public.venues
  set placement_state = 'standard',
      current_marker_asset_id = null
  where id = p_venue_id;

  if not p_preserve_public_listing then
    update public.venues
    set registration_status = 'archived',
        publication_status = 'unpublished',
        public_phone = null,
        public_email = null,
        website_url = null,
        instagram_handle = null,
        suspended_at = null,
        archived_at = p_at
    where id = p_venue_id;
  end if;
end;
$$;

revoke execute on function private.retire_venue_access(
  uuid, uuid, boolean, timestamptz
) from public, anon, authenticated, service_role;

-- A dashboard/admin Auth deletion cascades through venue_accounts. Mirror the
-- application deletion cleanup and distinguish founder-created listings by the
-- presence of claim history on that venue.
create function private.retire_deleted_venue_account()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_preserve_public_listing boolean;
begin
  perform private.require_venue_subscription_detached(old.venue_id);

  select exists (
    select 1
    from private.venue_account_claims as claim_record
    where claim_record.venue_id = old.venue_id
  ) into v_preserve_public_listing;

  perform private.retire_venue_access(
    old.auth_user_id,
    old.venue_id,
    v_preserve_public_listing,
    clock_timestamp()
  );

  return old;
end;
$$;

revoke execute on function private.retire_deleted_venue_account()
from public, anon, authenticated, service_role;

create trigger venue_accounts_retire_after_delete
after delete on public.venue_accounts
for each row execute function private.retire_deleted_venue_account();

create function public.store_pending_venue_registration(
  p_auth_user_id uuid,
  p_display_name text,
  p_venue_address text,
  p_legal_business_name text,
  p_legal_address text,
  p_primary_contact_name text,
  p_primary_contact_title text,
  p_business_email text,
  p_business_phone text,
  p_venue_agreement_version text,
  p_existing_venue_id uuid default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_auth_email text;
  v_existing_account public.venue_accounts%rowtype;
  v_existing_claim private.venue_account_claims%rowtype;
  v_pending private.pending_venue_registrations%rowtype;
begin
  if p_auth_user_id is null
     or p_display_name is null
     or p_venue_address is null
     or p_legal_business_name is null
     or p_legal_address is null
     or p_primary_contact_name is null
     or p_business_email is null
     or p_business_phone is null
     or p_venue_agreement_version is null then
    raise exception using errcode = '22023', message = 'missing_venue_registration_parameter';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'account-deletion:' || p_auth_user_id::text,
      0
    )
  );

  if exists (
    select 1
    from private.account_deletion_requests as deletion_record
    where deletion_record.requester_user_id = p_auth_user_id
      and deletion_record.state in ('requested', 'confirmed', 'processing')
  ) then
    raise exception using errcode = 'P0001', message = 'account_deletion_in_progress';
  end if;

  select lower(auth_user.email) into v_auth_email
  from auth.users as auth_user
  where auth_user.id = p_auth_user_id;

  if v_auth_email is null then
    raise exception using errcode = 'P0001', message = 'auth_user_not_found';
  end if;
  if v_auth_email <> lower(btrim(p_business_email)) then
    raise exception using errcode = 'P0001', message = 'business_email_mismatch';
  end if;
  if exists (
    select 1
    from public.consumer_profiles as consumer_profile
    where consumer_profile.user_id = p_auth_user_id
      and consumer_profile.account_status <> 'deleted'
  ) then
    raise exception using errcode = 'P0001', message = 'account_type_conflict';
  end if;

  select * into v_existing_account
  from public.venue_accounts as account_record
  where account_record.auth_user_id = p_auth_user_id
  for update;

  if v_existing_account.auth_user_id is not null then
    select * into v_existing_claim
    from private.venue_account_claims as claim_record
    where claim_record.auth_user_id = p_auth_user_id
      and claim_record.venue_id = v_existing_account.venue_id
    order by claim_record.id desc
    limit 1
    for update;

    if p_existing_venue_id is distinct from v_existing_claim.venue_id then
      raise exception using errcode = 'P0001', message = 'venue_registration_conflict';
    end if;

    -- A founder's changes request is the only state in which an existing
    -- provisional account may replace its private registration payload.
    -- Pending/approved retries remain idempotent and cannot mutate a review.
    if v_existing_claim.claim_status is distinct from 'changes_requested' then
      return jsonb_build_object(
        'state', 'consumed',
        'existing_venue_id', v_existing_account.venue_id
      );
    end if;
  end if;

  if p_existing_venue_id is not null
     and v_existing_claim.claim_status is distinct from 'changes_requested'
     and not exists (
    select 1
    from public.venues as venue_record
    where venue_record.id = p_existing_venue_id
      and venue_record.registration_status = 'approved'
      and venue_record.publication_status = 'published'
      and not exists (
        select 1 from public.venue_accounts as account_record
        where account_record.venue_id = venue_record.id
      )
      and not exists (
        select 1 from private.venue_account_claims as claim_record
        where claim_record.venue_id = venue_record.id
          and claim_record.claim_status in ('pending_review', 'changes_requested')
      )
  ) then
    raise exception using errcode = 'P0001', message = 'venue_claim_unavailable';
  end if;

  insert into private.pending_venue_registrations (
    auth_user_id,
    existing_venue_id,
    display_name,
    venue_address,
    legal_business_name,
    legal_address,
    primary_contact_name,
    primary_contact_title,
    business_email,
    business_phone,
    venue_agreement_version,
    pending_state,
    stored_at,
    consumed_at
  )
  values (
    p_auth_user_id,
    p_existing_venue_id,
    btrim(p_display_name),
    btrim(p_venue_address),
    btrim(p_legal_business_name),
    btrim(p_legal_address),
    btrim(p_primary_contact_name),
    nullif(btrim(p_primary_contact_title), ''),
    lower(btrim(p_business_email)),
    btrim(p_business_phone),
    btrim(p_venue_agreement_version),
    'pending_email_confirmation',
    clock_timestamp(),
    null
  )
  on conflict on constraint pending_venue_registrations_pkey do update
  set
    existing_venue_id = excluded.existing_venue_id,
    display_name = excluded.display_name,
    venue_address = excluded.venue_address,
    legal_business_name = excluded.legal_business_name,
    legal_address = excluded.legal_address,
    primary_contact_name = excluded.primary_contact_name,
    primary_contact_title = excluded.primary_contact_title,
    business_email = excluded.business_email,
    business_phone = excluded.business_phone,
    venue_agreement_version = excluded.venue_agreement_version,
    pending_state = 'pending_email_confirmation',
    stored_at = clock_timestamp(),
    consumed_at = null
  returning * into v_pending;

  return jsonb_build_object(
    'state', v_pending.pending_state,
    'existing_venue_id', v_pending.existing_venue_id,
    'stored_at', v_pending.stored_at
  );
end;
$$;

revoke execute on function public.store_pending_venue_registration(
  uuid, text, text, text, text, text, text, text, text, text, uuid
) from public, anon, authenticated, service_role;
grant execute on function public.store_pending_venue_registration(
  uuid, text, text, text, text, text, text, text, text, text, uuid
) to service_role;

drop function public.register_venue_account(
  uuid, text, text, text, text, text, text, text, text, text
);

create function public.register_venue_account(
  p_auth_user_id uuid,
  p_display_name text,
  p_venue_address text,
  p_legal_business_name text,
  p_legal_address text,
  p_primary_contact_name text,
  p_primary_contact_title text,
  p_business_email text,
  p_business_phone text,
  p_venue_agreement_version text,
  p_existing_venue_id uuid default null
)
returns table (
  venue_id uuid,
  venue_slug text,
  registration_status text,
  account_status text
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := clock_timestamp();
  v_auth_email text;
  v_email_confirmed_at timestamptz;
  v_display_name text := btrim(p_display_name);
  v_slug_base text;
  v_slug text;
  v_venue_id uuid := coalesce(p_existing_venue_id, gen_random_uuid());
  v_existing_account public.venue_accounts%rowtype;
  v_existing_claim private.venue_account_claims%rowtype;
  v_existing_venue public.venues%rowtype;
begin
  if p_auth_user_id is null
     or v_display_name is null
     or p_venue_address is null
     or p_legal_business_name is null
     or p_legal_address is null
     or p_primary_contact_name is null
     or p_business_email is null
     or p_business_phone is null
     or p_venue_agreement_version is null then
    raise exception using errcode = '22023', message = 'missing_venue_registration_parameter';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'account-deletion:' || p_auth_user_id::text,
      0
    )
  );

  if exists (
    select 1
    from private.account_deletion_requests as deletion_record
    where deletion_record.requester_user_id = p_auth_user_id
      and deletion_record.state in ('requested', 'confirmed', 'processing')
  ) then
    raise exception using errcode = 'P0001', message = 'account_deletion_in_progress';
  end if;

  select lower(auth_user.email), auth_user.email_confirmed_at
  into v_auth_email, v_email_confirmed_at
  from auth.users as auth_user
  where auth_user.id = p_auth_user_id;

  if v_auth_email is null then
    raise exception using errcode = 'P0001', message = 'auth_user_not_found';
  end if;
  if v_auth_email <> lower(btrim(p_business_email)) then
    raise exception using errcode = 'P0001', message = 'business_email_mismatch';
  end if;
  if v_email_confirmed_at is null then
    raise exception using errcode = 'P0001', message = 'email_confirmation_required';
  end if;
  if exists (
    select 1
    from public.consumer_profiles as consumer_profile
    where consumer_profile.user_id = p_auth_user_id
      and consumer_profile.account_status <> 'deleted'
  ) then
    raise exception using errcode = 'P0001', message = 'account_type_conflict';
  end if;

  select * into v_existing_account
  from public.venue_accounts as account_record
  where account_record.auth_user_id = p_auth_user_id
  for update;

  if v_existing_account.auth_user_id is not null then
    select * into v_existing_claim
    from private.venue_account_claims as claim_record
    where claim_record.auth_user_id = p_auth_user_id
      and claim_record.venue_id = v_existing_account.venue_id
    order by claim_record.id desc
    limit 1
    for update;

    if p_existing_venue_id is distinct from v_existing_claim.venue_id then
      raise exception using errcode = 'P0001', message = 'venue_registration_conflict';
    end if;

    if v_existing_claim.claim_status = 'changes_requested' then
      select * into v_existing_venue
      from public.venues as venue_record
      where venue_record.id = v_existing_account.venue_id
      for update;

      if v_existing_venue.id is null
         or v_existing_venue.registration_status <> 'approved'
         or v_existing_venue.publication_status <> 'published'
         or v_existing_account.account_status <> 'draft' then
        raise exception using errcode = 'P0001', message = 'venue_claim_listing_unavailable';
      end if;

      update private.venue_business_details as business_record
      set
        legal_business_name = btrim(p_legal_business_name),
        legal_address = btrim(p_legal_address),
        primary_contact_name = btrim(p_primary_contact_name),
        primary_contact_title = nullif(btrim(p_primary_contact_title), ''),
        business_email = lower(btrim(p_business_email)),
        business_phone = btrim(p_business_phone),
        authority_to_represent_affirmed = true,
        venue_agreement_version = btrim(p_venue_agreement_version),
        registration_submitted_at = v_now
      where business_record.venue_id = v_existing_account.venue_id;

      if not found then
        raise exception using errcode = 'P0001', message = 'venue_registration_conflict';
      end if;

      -- Preserve the reviewed row as immutable history, then create a new
      -- pending review attempt. This retains the founder's response.
      update private.venue_account_claims
      set claim_status = 'superseded'
      where id = v_existing_claim.id;

      insert into private.venue_account_claims (
        venue_id,
        auth_user_id,
        claim_status,
        submitted_at
      )
      values (
        v_existing_account.venue_id,
        p_auth_user_id,
        'pending_review',
        v_now
      );

      insert into private.legal_acceptances (
        subject_user_id,
        subject_type,
        document_type,
        document_version,
        source
      )
      values (
        p_auth_user_id,
        'venue',
        'venue_agreement',
        btrim(p_venue_agreement_version),
        'web'
      )
      on conflict on constraint legal_acceptances_once_per_version do nothing;

      return query
      select
        v_existing_venue.id,
        v_existing_venue.slug,
        v_existing_venue.registration_status,
        v_existing_account.account_status;
      return;
    end if;

    return query
    select
      existing_venue.id,
      existing_venue.slug,
      existing_venue.registration_status,
      v_existing_account.account_status
    from public.venues as existing_venue
    where existing_venue.id = v_existing_account.venue_id;
    return;
  end if;

  if char_length(v_display_name) not between 1 and 100 then
    raise exception using errcode = '22023', message = 'invalid_venue_name';
  end if;

  if p_existing_venue_id is not null then
    select * into v_existing_venue
    from public.venues as venue_record
    where venue_record.id = p_existing_venue_id
    for update;

    if v_existing_venue.id is null
       or v_existing_venue.registration_status <> 'approved'
       or v_existing_venue.publication_status <> 'published'
       or exists (
         select 1 from public.venue_accounts as account_record
         where account_record.venue_id = p_existing_venue_id
       )
       or exists (
         select 1 from private.venue_account_claims as claim_record
         where claim_record.venue_id = p_existing_venue_id
           and claim_record.claim_status in ('pending_review', 'changes_requested')
       ) then
      raise exception using errcode = 'P0001', message = 'venue_claim_unavailable';
    end if;
  else
    v_slug_base := trim(both '-' from lower(
      regexp_replace(v_display_name, '[^A-Za-z0-9]+', '-', 'g')
    ));
    if char_length(v_slug_base) < 2 then
      v_slug_base := 'venue';
    end if;
    v_slug := left(v_slug_base, 67) || '-' || substr(replace(v_venue_id::text, '-', ''), 1, 8);

    insert into public.venues (
      id,
      slug,
      display_name,
      registration_status,
      publication_status,
      address_line_1,
      market_code,
      city,
      province_code,
      country_code
    )
    values (
      v_venue_id,
      v_slug,
      v_display_name,
      'pending_review',
      'unpublished',
      btrim(p_venue_address),
      'toronto',
      'Toronto',
      'ON',
      'CA'
    )
    returning * into v_existing_venue;
  end if;

  insert into public.venue_accounts (
    auth_user_id,
    venue_id,
    account_status
  )
  values (p_auth_user_id, v_venue_id, 'draft');

  insert into private.venue_business_details (
    venue_id,
    legal_business_name,
    legal_address,
    primary_contact_name,
    primary_contact_title,
    business_email,
    business_phone,
    authority_to_represent_affirmed,
    venue_agreement_version,
    registration_submitted_at
  )
  values (
    v_venue_id,
    btrim(p_legal_business_name),
    btrim(p_legal_address),
    btrim(p_primary_contact_name),
    nullif(btrim(p_primary_contact_title), ''),
    lower(btrim(p_business_email)),
    btrim(p_business_phone),
    true,
    btrim(p_venue_agreement_version),
    v_now
  );

  insert into private.venue_subscriptions (venue_id, plan_code, stripe_status)
  values (v_venue_id, 'free', 'free')
  on conflict on constraint venue_subscriptions_pkey do nothing;

  if p_existing_venue_id is not null then
    insert into private.venue_account_claims (
      venue_id,
      auth_user_id,
      claim_status,
      submitted_at
    )
    values (
      v_venue_id,
      p_auth_user_id,
      'pending_review',
      v_now
    );
  end if;

  insert into private.legal_acceptances (
    subject_user_id,
    subject_type,
    document_type,
    document_version,
    source
  )
  values (
    p_auth_user_id,
    'venue',
    'venue_agreement',
    btrim(p_venue_agreement_version),
    'web'
  )
  on conflict on constraint legal_acceptances_once_per_version do nothing;

  return query
  select
    v_venue_id,
    v_existing_venue.slug,
    v_existing_venue.registration_status,
    'draft'::text;
end;
$$;

revoke execute on function public.register_venue_account(
  uuid, text, text, text, text, text, text, text, text, text, uuid
) from public, anon, authenticated, service_role;
grant execute on function public.register_venue_account(
  uuid, text, text, text, text, text, text, text, text, text, uuid
) to service_role;

create function public.consume_pending_venue_registration(p_auth_user_id uuid)
returns table (
  venue_id uuid,
  venue_slug text,
  registration_status text,
  account_status text
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_pending private.pending_venue_registrations%rowtype;
  v_email_confirmed_at timestamptz;
  v_venue_id uuid;
  v_venue_slug text;
  v_registration_status text;
  v_account_status text;
begin
  if p_auth_user_id is null then
    raise exception using errcode = '22023', message = 'missing_venue_registration_parameter';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'account-deletion:' || p_auth_user_id::text,
      0
    )
  );

  if exists (
    select 1
    from private.account_deletion_requests as deletion_record
    where deletion_record.requester_user_id = p_auth_user_id
      and deletion_record.state in ('requested', 'confirmed', 'processing')
  ) then
    raise exception using errcode = 'P0001', message = 'account_deletion_in_progress';
  end if;

  select auth_user.email_confirmed_at into v_email_confirmed_at
  from auth.users as auth_user
  where auth_user.id = p_auth_user_id;

  if not found then
    raise exception using errcode = 'P0001', message = 'auth_user_not_found';
  end if;
  if v_email_confirmed_at is null then
    raise exception using errcode = 'P0001', message = 'email_confirmation_required';
  end if;

  select * into v_pending
  from private.pending_venue_registrations as pending_record
  where pending_record.auth_user_id = p_auth_user_id
  for update;

  if v_pending.auth_user_id is null then
    return query
    select
      venue_record.id,
      venue_record.slug,
      venue_record.registration_status,
      account_record.account_status
    from public.venue_accounts as account_record
    join public.venues as venue_record on venue_record.id = account_record.venue_id
    where account_record.auth_user_id = p_auth_user_id;

    if not found then
      raise exception using errcode = 'P0001', message = 'pending_venue_registration_not_found';
    end if;
    return;
  end if;

  select registration.venue_id,
         registration.venue_slug,
         registration.registration_status,
         registration.account_status
  into v_venue_id, v_venue_slug, v_registration_status, v_account_status
  from public.register_venue_account(
    v_pending.auth_user_id,
    v_pending.display_name,
    v_pending.venue_address,
    v_pending.legal_business_name,
    v_pending.legal_address,
    v_pending.primary_contact_name,
    v_pending.primary_contact_title,
    v_pending.business_email,
    v_pending.business_phone,
    v_pending.venue_agreement_version,
    v_pending.existing_venue_id
  ) as registration;

  update private.pending_venue_registrations
  set pending_state = 'consumed', consumed_at = clock_timestamp()
  where auth_user_id = p_auth_user_id;

  return query
  select v_venue_id, v_venue_slug, v_registration_status, v_account_status;
end;
$$;

revoke execute on function public.consume_pending_venue_registration(uuid)
from public, anon, authenticated, service_role;
grant execute on function public.consume_pending_venue_registration(uuid)
to service_role;

-- A rejected or withdrawn business claim is still a venue identity until that
-- Auth account is deleted. Prevent one Auth UUID from silently becoming both a
-- venue operator and a consumer after its provisional venue_accounts row is
-- removed.
alter function public.complete_consumer_onboarding(
  uuid, text, date, text, text, text
) rename to complete_consumer_onboarding_without_venue_claim_guard;

alter function public.complete_consumer_onboarding_without_venue_claim_guard(
  uuid, text, date, text, text, text
) set schema private;

revoke execute on function private.complete_consumer_onboarding_without_venue_claim_guard(
  uuid, text, date, text, text, text
) from public, anon, authenticated, service_role;

create function public.complete_consumer_onboarding(
  p_user_id uuid,
  p_first_name text,
  p_date_of_birth date,
  p_gender text,
  p_terms_version text,
  p_privacy_version text
)
returns table (
  user_id uuid,
  first_name text,
  onboarding_status text,
  account_status text,
  onboarding_completed_at timestamptz,
  is_19_plus boolean
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  if p_user_id is null then
    raise exception using errcode = '22023', message = 'missing_onboarding_parameter';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'account-deletion:' || p_user_id::text,
      0
    )
  );

  if exists (
    select 1
    from private.account_deletion_requests as deletion_record
    where deletion_record.requester_user_id = p_user_id
      and deletion_record.state in ('requested', 'confirmed', 'processing')
  ) then
    raise exception using errcode = 'P0001', message = 'account_deletion_in_progress';
  end if;

  if exists (
       select 1
       from private.pending_venue_registrations as pending_record
       where pending_record.auth_user_id = p_user_id
     )
     or exists (
       select 1
       from private.venue_account_claims as claim_record
       where claim_record.auth_user_id = p_user_id
     ) then
    raise exception using errcode = 'P0001', message = 'account_type_conflict';
  end if;

  return query
  select onboarding.user_id,
         onboarding.first_name,
         onboarding.onboarding_status,
         onboarding.account_status,
         onboarding.onboarding_completed_at,
         onboarding.is_19_plus
  from private.complete_consumer_onboarding_without_venue_claim_guard(
    p_user_id,
    p_first_name,
    p_date_of_birth,
    p_gender,
    p_terms_version,
    p_privacy_version
  ) as onboarding;
end;
$$;

revoke execute on function public.complete_consumer_onboarding(
  uuid, text, date, text, text, text
) from public, anon, authenticated, service_role;
grant execute on function public.complete_consumer_onboarding(
  uuid, text, date, text, text, text
) to service_role;

create function public.get_venue_registration_status(p_user_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_account public.venue_accounts%rowtype;
  v_claim private.venue_account_claims%rowtype;
  v_venue public.venues%rowtype;
  v_public_response text;
  v_reviewed_at timestamptz;
begin
  select * into v_account
  from public.venue_accounts as account_record
  where account_record.auth_user_id = p_user_id
    and account_record.account_status <> 'deleted';

  if v_account.auth_user_id is not null then
    select * into v_claim
    from private.venue_account_claims as claim_record
    where claim_record.auth_user_id = p_user_id
      and claim_record.venue_id = v_account.venue_id
    order by claim_record.id desc
    limit 1;
  else
    -- Rejected listing claims intentionally remove the provisional account
    -- link. The claimant may still read only their own final review result.
    select * into v_claim
    from private.venue_account_claims as claim_record
    where claim_record.auth_user_id = p_user_id
    order by claim_record.id desc
    limit 1;
  end if;

  select * into v_venue
  from public.venues as venue_record
  where venue_record.id = coalesce(v_account.venue_id, v_claim.venue_id);

  if v_venue.id is null then
    raise exception using errcode = 'P0001', message = 'venue_account_not_found';
  end if;

  if v_claim.id is not null then
    v_public_response := v_claim.public_response;
    v_reviewed_at := v_claim.reviewed_at;
  else
    select review_record.public_response, review_record.created_at
    into v_public_response, v_reviewed_at
    from private.venue_reviews as review_record
    where review_record.venue_id = v_venue.id
    order by review_record.created_at desc, review_record.id desc
    limit 1;
  end if;

  return jsonb_build_object(
    'workflow_type', case
      when v_claim.id is null then 'new_listing'
      else 'existing_listing_claim'
    end,
    'venue_id', v_venue.id,
    'venue_name', v_venue.display_name,
    'registration_status', v_venue.registration_status,
    'publication_status', v_venue.publication_status,
    'account_status', v_account.account_status,
    'claim_status', v_claim.claim_status,
    'public_response', v_public_response,
    'reviewed_at', v_reviewed_at,
    'can_resubmit', coalesce(v_claim.claim_status = 'changes_requested', false)
  );
end;
$$;

revoke execute on function public.get_venue_registration_status(uuid)
from public, anon, authenticated, service_role;
grant execute on function public.get_venue_registration_status(uuid)
to service_role;

-- Deleting a login that claimed an existing founder-created listing must
-- remove the claimant's access and private business data without deleting or
-- unpublishing the public venue facts. New-listing accounts continue through
-- the original deletion workflow.
alter function public.prepare_account_deletion(uuid, text, uuid)
  rename to prepare_account_deletion_without_listing_claim;

alter function public.prepare_account_deletion_without_listing_claim(
  uuid, text, uuid
) set schema private;

revoke execute on function private.prepare_account_deletion_without_listing_claim(
  uuid, text, uuid
) from public, anon, authenticated, service_role;

create function public.prepare_account_deletion(
  p_user_id uuid,
  p_subject_type text,
  p_idempotency_key uuid
)
returns table (
  deletion_request_id bigint,
  deletion_state text,
  subject_type text
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := clock_timestamp();
  v_request private.account_deletion_requests%rowtype;
  v_claim private.venue_account_claims%rowtype;
  v_current_venue_id uuid;
begin
  if p_user_id is null or p_idempotency_key is null then
    raise exception using errcode = '22023', message = 'missing_deletion_parameter';
  end if;
  if p_subject_type not in ('consumer', 'venue') then
    raise exception using errcode = '22023', message = 'invalid_deletion_subject_type';
  end if;

  if p_subject_type <> 'venue' then
    return query
    select prepared.deletion_request_id,
           prepared.deletion_state,
           prepared.subject_type
    from private.prepare_account_deletion_without_listing_claim(
      p_user_id,
      p_subject_type,
      p_idempotency_key
    ) as prepared;
    return;
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('account-deletion:' || p_user_id::text, 0)
  );

  select * into v_request
  from private.account_deletion_requests as request_record
  where request_record.requester_user_id = p_user_id
    and request_record.request_idempotency_key = p_idempotency_key;

  if v_request.id is not null then
    if v_request.subject_type <> p_subject_type then
      raise exception using errcode = '22023', message = 'deletion_subject_type_mismatch';
    end if;
    return query select v_request.id, v_request.state, v_request.subject_type;
    return;
  end if;

  select * into v_request
  from private.account_deletion_requests as request_record
  where request_record.requester_user_id = p_user_id
    and request_record.state in ('requested', 'confirmed', 'processing')
  order by request_record.requested_at desc
  limit 1;

  if v_request.id is not null then
    if v_request.subject_type <> p_subject_type then
      raise exception using errcode = '22023', message = 'deletion_subject_type_mismatch';
    end if;
    return query select v_request.id, v_request.state, v_request.subject_type;
    return;
  end if;

  if exists (
    select 1
    from public.consumer_profiles as consumer_record
    where consumer_record.user_id = p_user_id
      and consumer_record.account_status <> 'deleted'
  ) then
    raise exception using errcode = '22023', message = 'deletion_subject_type_mismatch';
  end if;

  -- Read the current account only to scope the claim. The claim itself is
  -- locked first so review and deletion always serialize claim -> venue ->
  -- account and cannot deadlock while transitioning the same request.
  select account_record.venue_id into v_current_venue_id
  from public.venue_accounts as account_record
  where account_record.auth_user_id = p_user_id
    and account_record.account_status <> 'deleted';

  if v_current_venue_id is not null then
    select * into v_claim
    from private.venue_account_claims as claim_record
    where claim_record.auth_user_id = p_user_id
      and claim_record.venue_id = v_current_venue_id
    order by claim_record.id desc
    limit 1
    for update;

    if v_claim.id is null then
      return query
      select prepared.deletion_request_id,
             prepared.deletion_state,
             prepared.subject_type
      from private.prepare_account_deletion_without_listing_claim(
        p_user_id,
        p_subject_type,
        p_idempotency_key
      ) as prepared;
      return;
    end if;
  else
    -- Rejected claims intentionally have no venue_accounts row. Retain that
    -- terminal audit while still allowing the business Auth identity to leave.
    select * into v_claim
    from private.venue_account_claims as claim_record
    where claim_record.auth_user_id = p_user_id
      and claim_record.claim_status not in ('superseded', 'withdrawn')
    order by claim_record.id desc
    limit 1
    for update;
  end if;

  if v_claim.id is null then
    return query
    select prepared.deletion_request_id,
           prepared.deletion_state,
           prepared.subject_type
    from private.prepare_account_deletion_without_listing_claim(
      p_user_id,
      p_subject_type,
      p_idempotency_key
    ) as prepared;
    return;
  end if;

  perform 1
  from public.venues as venue_record
  where venue_record.id = v_claim.venue_id
  for update;

  if not found then
    raise exception using errcode = 'P0001', message = 'venue_claim_listing_unavailable';
  end if;

  perform 1
  from public.venue_accounts as account_record
  where account_record.auth_user_id = p_user_id
    and account_record.venue_id = v_claim.venue_id
  for update;

  perform private.require_venue_subscription_detached(v_claim.venue_id);

  if v_claim.claim_status in ('pending_review', 'changes_requested') then
    update private.venue_account_claims
    set
      claim_status = 'withdrawn',
      withdrawn_at = v_now,
      withdrawal_reason = 'account_deleted'
    where id = v_claim.id
      and claim_status in ('pending_review', 'changes_requested');

    if not found then
      raise exception using errcode = '40001', message = 'venue_claim_transition_conflict';
    end if;
  end if;

  perform private.retire_venue_access(
    p_user_id,
    v_claim.venue_id,
    true,
    v_now
  );

  delete from public.venue_accounts
  where auth_user_id = p_user_id
    and venue_id = v_claim.venue_id;

  insert into private.account_deletion_requests (
    subject_type,
    auth_user_id,
    requester_user_id,
    subject_reference,
    state,
    request_idempotency_key,
    requested_at,
    confirmed_at,
    started_at
  )
  values (
    'venue',
    p_user_id,
    p_user_id,
    v_claim.venue_id,
    'processing',
    p_idempotency_key,
    v_now,
    v_now,
    v_now
  )
  returning * into v_request;

  return query select v_request.id, v_request.state, v_request.subject_type;
end;
$$;

revoke execute on function public.prepare_account_deletion(uuid, text, uuid)
from public, anon, authenticated, service_role;
grant execute on function public.prepare_account_deletion(uuid, text, uuid)
to service_role;

alter function public.review_venue_registration(
  uuid, uuid, text, text, text, text, text, double precision, double precision, smallint
) rename to review_venue_registration_without_claim;

alter function public.review_venue_registration_without_claim(
  uuid, uuid, text, text, text, text, text, double precision, double precision, smallint
) set schema private;

revoke execute on function private.review_venue_registration_without_claim(
  uuid, uuid, text, text, text, text, text, double precision, double precision, smallint
) from public, anon, authenticated, service_role;

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
  v_claim private.venue_account_claims%rowtype;
  v_venue public.venues%rowtype;
  v_account public.venue_accounts%rowtype;
  v_result jsonb;
begin
  perform private.require_founder_admin(p_user_id);

  select * into v_claim
  from private.venue_account_claims as claim_record
  where claim_record.venue_id = p_venue_id
  order by claim_record.id desc
  limit 1
  for update;

  if v_claim.id is not null
     and p_decision in ('approved', 'changes_requested', 'rejected') then
    if v_claim.claim_status not in ('pending_review', 'changes_requested') then
      raise exception using errcode = 'P0001', message = 'venue_claim_not_reviewable';
    end if;

    select * into v_venue
    from public.venues as venue_record
    where venue_record.id = p_venue_id
    for update;

    if v_venue.id is null
       or v_venue.registration_status <> 'approved'
       or v_venue.publication_status <> 'published' then
      raise exception using errcode = 'P0001', message = 'venue_claim_listing_unavailable';
    end if;

    select * into v_account
    from public.venue_accounts as account_record
    where account_record.auth_user_id = v_claim.auth_user_id
      and account_record.venue_id = v_claim.venue_id
    for update;

    if v_account.auth_user_id is null
       or v_account.account_status <> 'draft' then
      raise exception using errcode = 'P0001', message = 'venue_claim_account_unavailable';
    end if;

    if p_decision = 'changes_requested'
       and nullif(btrim(p_public_response), '') is null then
      raise exception using errcode = '22023', message = 'claim_changes_response_required';
    end if;

    if p_decision = 'approved' then
      update public.venue_accounts
      set account_status = 'active'
      where auth_user_id = v_claim.auth_user_id
        and venue_id = v_claim.venue_id
        and account_status = 'draft';

      if not found then
        raise exception using errcode = '40001', message = 'venue_claim_transition_conflict';
      end if;
    end if;

    update private.venue_account_claims
    set claim_status = p_decision,
        reviewed_at = v_now,
        reviewed_by = p_user_id,
        reviewed_by_snapshot = p_user_id,
        public_response = nullif(btrim(p_public_response), ''),
        private_note = nullif(btrim(p_private_note), '')
    where id = v_claim.id
      and claim_status in ('pending_review', 'changes_requested');

    if not found then
      raise exception using errcode = '40001', message = 'venue_claim_transition_conflict';
    end if;

    if p_decision = 'rejected' then
      delete from public.venue_accounts
      where auth_user_id = v_claim.auth_user_id
        and venue_id = v_claim.venue_id
        and account_status = 'draft';

      if not found then
        raise exception using errcode = '40001', message = 'venue_claim_transition_conflict';
      end if;
    end if;

    return jsonb_build_object(
      'id', v_venue.id,
      'registration_status', v_venue.registration_status,
      'publication_status', v_venue.publication_status,
      'claim_status', p_decision,
      'account_status', case
        when p_decision = 'approved' then 'active'
        when p_decision = 'changes_requested' then 'draft'
        else null
      end
    );
  end if;

  v_result := private.review_venue_registration_without_claim(
    p_user_id,
    p_venue_id,
    p_decision,
    p_public_response,
    p_private_note,
    p_neighbourhood,
    p_postal_code,
    p_latitude,
    p_longitude,
    p_geofence_radius_metres
  );

  -- A public listing can be suspended independently of a pending access
  -- claim. Reinstating the listing must not activate that draft claimant before
  -- the founder explicitly approves the claim.
  if v_claim.id is not null
     and v_claim.claim_status in ('pending_review', 'changes_requested')
     and p_decision = 'reinstated' then
    update public.venue_accounts
    set account_status = 'draft'
    where auth_user_id = v_claim.auth_user_id
      and venue_id = v_claim.venue_id
      and account_status = 'active';

    v_result := v_result || jsonb_build_object(
      'claim_status', v_claim.claim_status,
      'account_status', 'draft'
    );
  end if;

  return v_result;
end;
$$;

revoke execute on function public.review_venue_registration(
  uuid, uuid, text, text, text, text, text, double precision, double precision, smallint
) from public, anon, authenticated, service_role;
grant execute on function public.review_venue_registration(
  uuid, uuid, text, text, text, text, text, double precision, double precision, smallint
) to service_role;

alter function public.get_founder_admin_snapshot(uuid)
  rename to get_founder_admin_snapshot_without_claims;

alter function public.get_founder_admin_snapshot_without_claims(uuid)
  set schema private;

revoke execute on function private.get_founder_admin_snapshot_without_claims(uuid)
from public, anon, authenticated, service_role;

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
  v_result := private.get_founder_admin_snapshot_without_claims(p_user_id);

  v_result := jsonb_set(
    v_result,
    '{metrics,pending_venue_claims}',
    to_jsonb((
      select count(*)
      from private.venue_account_claims as claim_record
      where claim_record.claim_status in ('pending_review', 'changes_requested')
    )),
    true
  );

  v_result := jsonb_set(
    v_result,
    '{venues}',
    coalesce((
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
        'claim_status', claim_record.claim_status,
        'plan_code', subscription_record.plan_code,
        'subscription_status', subscription_record.stripe_status,
        'partner_campaign_access', coalesce(
          entitlement_record.entitlement_value = 'true'::jsonb
          and (
            subscription_record.stripe_status = 'active'
            or (
              subscription_record.stripe_status = 'trialing'
              and subscription_record.trial_ends_at > current_timestamp
            )
          ),
          false
        ),
        'created_at', venue_record.created_at
      ) order by venue_record.created_at desc)
      from public.venues as venue_record
      left join public.venue_accounts as account_record
        on account_record.venue_id = venue_record.id
      left join private.venue_business_details as business_record
        on business_record.venue_id = venue_record.id
      left join private.venue_subscriptions as subscription_record
        on subscription_record.venue_id = venue_record.id
      left join private.plan_entitlements as entitlement_record
        on entitlement_record.plan_code = subscription_record.plan_code
       and entitlement_record.entitlement_key = 'partner_campaign_access'
      left join lateral (
        select latest_claim.claim_status
        from private.venue_account_claims as latest_claim
        where latest_claim.venue_id = venue_record.id
        order by latest_claim.id desc
        limit 1
      ) as claim_record on true
    ), '[]'::jsonb),
    true
  );

  return v_result;
end;
$$;

revoke execute on function public.get_founder_admin_snapshot(uuid)
from public, anon, authenticated, service_role;
grant execute on function public.get_founder_admin_snapshot(uuid)
to service_role;
