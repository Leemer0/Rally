import "server-only";

import { createAdminClient } from "@/lib/supabase/admin";
import { getStripeClient, getStripeProPriceId } from "@/lib/stripe/server";

export type VenueBillingContext = {
  venueId: string;
  venueName: string;
  businessEmail: string;
  planCode: string;
  stripeStatus: string;
  stripeCustomerId: string | null;
  stripeSubscriptionId: string | null;
  stripePriceId: string | null;
  currentPeriodEndsAt: string | null;
  cancelAtPeriodEnd: boolean;
};

type ProPriceSummary = {
  displayPrice: string;
  interval: string;
};

function record(value: unknown): Record<string, unknown> {
  return typeof value === "object" && value !== null
    ? (value as Record<string, unknown>)
    : {};
}

function string(value: unknown) {
  return typeof value === "string" ? value : "";
}

function nullableString(value: unknown) {
  return value === null || value === undefined ? null : string(value);
}

export async function loadVenueBillingContext(userId: string) {
  try {
    const admin = createAdminClient();
    const { data, error } = await admin.rpc("get_venue_billing_context", {
      p_user_id: userId,
    });
    if (error || !data) return null;

    const context = record(data);
    return {
      venueId: string(context.venue_id),
      venueName: string(context.venue_name),
      businessEmail: string(context.business_email),
      planCode: string(context.plan_code) || "free",
      stripeStatus: string(context.stripe_status) || "free",
      stripeCustomerId: nullableString(context.stripe_customer_id),
      stripeSubscriptionId: nullableString(context.stripe_subscription_id),
      stripePriceId: nullableString(context.stripe_price_id),
      currentPeriodEndsAt: nullableString(context.current_period_ends_at),
      cancelAtPeriodEnd: context.cancel_at_period_end === true,
    } satisfies VenueBillingContext;
  } catch {
    return null;
  }
}

export async function loadProPriceSummary(): Promise<ProPriceSummary | null> {
  try {
    const stripe = getStripeClient();
    const price = await stripe.prices.retrieve(getStripeProPriceId());
    if (!price.active || !price.recurring || price.unit_amount === null) {
      return null;
    }

    return {
      displayPrice: new Intl.NumberFormat("en-CA", {
        style: "currency",
        currency: price.currency.toUpperCase(),
        maximumFractionDigits: price.unit_amount % 100 === 0 ? 0 : 2,
      }).format(price.unit_amount / 100),
      interval: price.recurring.interval,
    };
  } catch {
    return null;
  }
}

