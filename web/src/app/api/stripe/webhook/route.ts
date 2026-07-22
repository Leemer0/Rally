import { NextResponse } from "next/server";
import type Stripe from "stripe";
import { createAdminClient } from "@/lib/supabase/admin";
import { getStripeClient, getStripeWebhookSecret } from "@/lib/stripe/server";

export const runtime = "nodejs";

function id(value: string | { id: string } | null) {
  return typeof value === "string" ? value : value?.id ?? null;
}

function timestamp(value: number | null | undefined) {
  return typeof value === "number" ? new Date(value * 1000).toISOString() : null;
}

function periodEnd(subscription: Stripe.Subscription) {
  const ends = subscription.items.data.map((item) => item.current_period_end);
  return ends.length > 0 ? timestamp(Math.max(...ends)) : null;
}

async function syncSubscription(event: Stripe.Event, subscription: Stripe.Subscription) {
  const item = subscription.items.data[0];
  const priceId = item?.price.id;
  const customerId = id(subscription.customer);
  if (!priceId || !customerId) throw new Error("incomplete_subscription_payload");

  const venueId = subscription.metadata.outly_venue_id || null;
  const status = subscription.status === "canceled" ? "cancelled" : subscription.status;
  const admin = createAdminClient();
  const { error } = await admin.rpc("sync_venue_stripe_subscription", {
    p_event_id: event.id,
    p_event_created_at: timestamp(event.created),
    p_venue_id: venueId,
    p_stripe_customer_id: customerId,
    p_stripe_subscription_id: subscription.id,
    p_stripe_price_id: priceId,
    p_stripe_status: status,
    p_current_period_ends_at: periodEnd(subscription),
    p_cancel_at_period_end: subscription.cancel_at_period_end,
    p_cancelled_at: timestamp(subscription.canceled_at),
  });
  if (error) throw new Error("subscription_sync_failed");
}

export async function POST(request: Request) {
  const signature = request.headers.get("stripe-signature");
  if (!signature) {
    return NextResponse.json({ error: "Missing signature." }, { status: 400 });
  }

  let event: Stripe.Event;
  try {
    const payload = await request.text();
    event = getStripeClient().webhooks.constructEvent(
      payload,
      signature,
      getStripeWebhookSecret(),
    );
  } catch {
    return NextResponse.json({ error: "Invalid signature." }, { status: 400 });
  }

  const admin = createAdminClient();
  const { data: claimed, error: claimError } = await admin.rpc(
    "claim_stripe_webhook_event",
    { p_event_id: event.id, p_event_type: event.type },
  );
  if (claimError) {
    return NextResponse.json({ error: "Webhook unavailable." }, { status: 503 });
  }
  if (!claimed) return NextResponse.json({ received: true, duplicate: true });

  try {
    switch (event.type) {
      case "customer.subscription.created":
      case "customer.subscription.updated":
      case "customer.subscription.deleted":
        await syncSubscription(event, event.data.object as Stripe.Subscription);
        break;
      default: {
        const { error } = await admin.rpc("finish_stripe_webhook_event", {
          p_event_id: event.id,
          p_status: "ignored",
          p_failure_code: null,
        });
        if (error) throw new Error("webhook_completion_failed");
      }
    }
  } catch (error) {
    await admin.rpc("finish_stripe_webhook_event", {
      p_event_id: event.id,
      p_status: "failed",
      p_failure_code:
        error instanceof Error ? error.message : "processing_failed",
    });
    return NextResponse.json({ error: "Webhook processing failed." }, { status: 500 });
  }

  return NextResponse.json({ received: true });
}

