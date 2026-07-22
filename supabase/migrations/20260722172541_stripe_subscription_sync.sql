-- Stripe remains the billing source of truth. These service-role-only RPCs
-- give the Vercel server a narrow contract for Checkout, Customer Portal, and
-- signed webhook synchronization without exposing the private billing tables.

alter table private.venue_subscriptions
  add column last_stripe_event_created_at timestamptz;

create function public.get_venue_billing_context(p_user_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_result jsonb;
begin
  if p_user_id is null then
    raise exception using errcode = '22023', message = 'missing_user_id';
  end if;

  select jsonb_build_object(
    'venue_id', venue_record.id,
    'venue_name', venue_record.display_name,
    'business_email', coalesce(business_record.business_email, auth_user.email),
    'plan_code', subscription_record.plan_code,
    'stripe_status', subscription_record.stripe_status,
    'stripe_customer_id', subscription_record.stripe_customer_id,
    'stripe_subscription_id', subscription_record.stripe_subscription_id,
    'stripe_price_id', subscription_record.stripe_price_id,
    'current_period_ends_at', subscription_record.current_period_ends_at,
    'cancel_at_period_end', subscription_record.cancel_at_period_end
  )
  into v_result
  from public.venue_accounts as account_record
  join public.venues as venue_record on venue_record.id = account_record.venue_id
  join auth.users as auth_user on auth_user.id = account_record.auth_user_id
  left join private.venue_business_details as business_record
    on business_record.venue_id = venue_record.id
  join private.venue_subscriptions as subscription_record
    on subscription_record.venue_id = venue_record.id
  where account_record.auth_user_id = p_user_id
    and account_record.account_status = 'active'
    and venue_record.registration_status = 'approved';

  if v_result is null then
    raise exception using errcode = 'P0001', message = 'active_venue_account_required';
  end if;

  return v_result;
end;
$$;

revoke execute on function public.get_venue_billing_context(uuid)
from public, anon, authenticated, service_role;
grant execute on function public.get_venue_billing_context(uuid) to service_role;

create function public.attach_venue_stripe_customer(
  p_user_id uuid,
  p_stripe_customer_id text
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_venue_id uuid;
begin
  if p_user_id is null
     or p_stripe_customer_id is null
     or p_stripe_customer_id !~ '^cus_[A-Za-z0-9]+$'
     or char_length(p_stripe_customer_id) > 255 then
    raise exception using errcode = '22023', message = 'invalid_stripe_customer';
  end if;

  select account_record.venue_id
  into v_venue_id
  from public.venue_accounts as account_record
  join public.venues as venue_record on venue_record.id = account_record.venue_id
  where account_record.auth_user_id = p_user_id
    and account_record.account_status = 'active'
    and venue_record.registration_status = 'approved'
  for update of account_record;

  if v_venue_id is null then
    raise exception using errcode = 'P0001', message = 'active_venue_account_required';
  end if;

  update private.venue_subscriptions as subscription_record
  set
    stripe_customer_id = p_stripe_customer_id,
    updated_at = current_timestamp
  where subscription_record.venue_id = v_venue_id
    and (
      subscription_record.stripe_customer_id is null
      or subscription_record.stripe_customer_id = p_stripe_customer_id
    );

  if not found then
    raise exception using errcode = 'P0001', message = 'stripe_customer_conflict';
  end if;
end;
$$;

revoke execute on function public.attach_venue_stripe_customer(uuid, text)
from public, anon, authenticated, service_role;
grant execute on function public.attach_venue_stripe_customer(uuid, text) to service_role;

create function public.claim_stripe_webhook_event(
  p_event_id text,
  p_event_type text
)
returns boolean
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_claimed boolean;
begin
  if p_event_id is null
     or p_event_type is null
     or char_length(btrim(p_event_id)) not between 4 and 255
     or char_length(btrim(p_event_type)) not between 3 and 255 then
    raise exception using errcode = '22023', message = 'invalid_stripe_event';
  end if;

  insert into private.stripe_webhook_events as event_record (
    stripe_event_id,
    event_type,
    processing_status
  )
  values (btrim(p_event_id), btrim(p_event_type), 'processing')
  on conflict on constraint stripe_webhook_events_pkey do update
  set
    event_type = excluded.event_type,
    processing_status = 'processing',
    failure_code = null,
    received_at = current_timestamp,
    processed_at = null
  where event_record.processing_status = 'failed'
     or (
       event_record.processing_status = 'processing'
       and event_record.received_at < current_timestamp - interval '5 minutes'
     )
  returning true into v_claimed;

  return coalesce(v_claimed, false);
end;
$$;

revoke execute on function public.claim_stripe_webhook_event(text, text)
from public, anon, authenticated, service_role;
grant execute on function public.claim_stripe_webhook_event(text, text) to service_role;

create function public.finish_stripe_webhook_event(
  p_event_id text,
  p_status text,
  p_failure_code text default null
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  if p_status not in ('processed', 'ignored', 'failed') then
    raise exception using errcode = '22023', message = 'invalid_webhook_completion_status';
  end if;

  update private.stripe_webhook_events
  set
    processing_status = p_status,
    failure_code = case
      when p_status = 'failed' then left(coalesce(nullif(btrim(p_failure_code), ''), 'processing_failed'), 120)
      else null
    end,
    processed_at = case
      when p_status in ('processed', 'ignored') then current_timestamp
      else null
    end
  where stripe_event_id = p_event_id
    and processing_status = 'processing';
end;
$$;

revoke execute on function public.finish_stripe_webhook_event(text, text, text)
from public, anon, authenticated, service_role;
grant execute on function public.finish_stripe_webhook_event(text, text, text) to service_role;

create function public.sync_venue_stripe_subscription(
  p_event_id text,
  p_event_created_at timestamptz,
  p_venue_id uuid,
  p_stripe_customer_id text,
  p_stripe_subscription_id text,
  p_stripe_price_id text,
  p_stripe_status text,
  p_current_period_ends_at timestamptz,
  p_cancel_at_period_end boolean,
  p_cancelled_at timestamptz
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_venue_id uuid;
  v_last_event_at timestamptz;
  v_terminal boolean;
begin
  if p_event_id is null
     or p_event_created_at is null
     or p_stripe_customer_id is null
     or p_stripe_customer_id !~ '^cus_[A-Za-z0-9]+$'
     or p_stripe_subscription_id is null
     or p_stripe_subscription_id !~ '^sub_[A-Za-z0-9]+$'
     or p_stripe_price_id is null
     or p_stripe_price_id !~ '^price_[A-Za-z0-9]+$'
     or p_stripe_status not in (
       'trialing', 'active', 'past_due', 'unpaid', 'paused',
       'cancelled', 'incomplete', 'incomplete_expired'
     ) then
    raise exception using errcode = '22023', message = 'invalid_stripe_subscription_payload';
  end if;

  if not exists (
    select 1 from private.stripe_webhook_events
    where stripe_event_id = p_event_id
      and processing_status = 'processing'
  ) then
    raise exception using errcode = 'P0001', message = 'stripe_event_not_claimed';
  end if;

  select subscription_record.venue_id, subscription_record.last_stripe_event_created_at
  into v_venue_id, v_last_event_at
  from private.venue_subscriptions as subscription_record
  where (
      p_venue_id is not null
      and subscription_record.venue_id = p_venue_id
      and (
        subscription_record.stripe_customer_id is null
        or subscription_record.stripe_customer_id = p_stripe_customer_id
      )
    )
    or subscription_record.stripe_customer_id = p_stripe_customer_id
  order by (subscription_record.venue_id = p_venue_id) desc
  limit 1
  for update;

  if v_venue_id is null then
    raise exception using errcode = 'P0001', message = 'stripe_venue_mapping_not_found';
  end if;

  if v_last_event_at is not null and p_event_created_at < v_last_event_at then
    perform public.finish_stripe_webhook_event(p_event_id, 'ignored', null);
    return;
  end if;

  v_terminal := p_stripe_status in ('cancelled', 'incomplete_expired');

  update private.venue_subscriptions
  set
    plan_code = case when v_terminal then 'free' else 'pro' end,
    stripe_customer_id = p_stripe_customer_id,
    stripe_subscription_id = case when v_terminal then null else p_stripe_subscription_id end,
    stripe_price_id = case when v_terminal then null else p_stripe_price_id end,
    stripe_status = case when v_terminal then 'free' else p_stripe_status end,
    trial_ends_at = case when p_stripe_status = 'trialing' then p_current_period_ends_at else null end,
    current_period_ends_at = case when v_terminal then null else p_current_period_ends_at end,
    cancel_at_period_end = case when v_terminal then false else coalesce(p_cancel_at_period_end, false) end,
    cancelled_at = case when v_terminal then coalesce(p_cancelled_at, current_timestamp) else p_cancelled_at end,
    last_webhook_at = current_timestamp,
    last_stripe_event_created_at = p_event_created_at,
    updated_at = current_timestamp
  where venue_id = v_venue_id;

  perform public.finish_stripe_webhook_event(p_event_id, 'processed', null);
end;
$$;

revoke execute on function public.sync_venue_stripe_subscription(
  text, timestamptz, uuid, text, text, text, text, timestamptz, boolean, timestamptz
)
from public, anon, authenticated, service_role;
grant execute on function public.sync_venue_stripe_subscription(
  text, timestamptz, uuid, text, text, text, text, timestamptz, boolean, timestamptz
) to service_role;
