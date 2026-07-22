"use server";

import { redirect } from "next/navigation";
import { requireVenueSession } from "@/lib/auth/venue";
import { loadVenueBillingContext } from "@/lib/data/venue-billing";
import { createAdminClient } from "@/lib/supabase/admin";
import { getSiteUrl } from "@/lib/supabase/config";
import { getStripeClient, getStripeProPriceId } from "@/lib/stripe/server";

function billingError(code: string): never {
  redirect(`/dashboard/billing?error=${encodeURIComponent(code)}`);
}

function integrationIdentifier(attemptId: string) {
  const letters = "abcdefghijklmnopqrstuvwxyz";
  const suffix = attemptId
    .replaceAll("-", "")
    .slice(0, 8)
    .split("")
    .map((character) => letters[Number.parseInt(character, 16) % letters.length])
    .join("");
  return `outly_web_${suffix}`;
}

export async function startProCheckout(formData: FormData) {
  const attempt = formData.get("checkoutAttemptId");
  const attemptId = typeof attempt === "string" ? attempt : "";
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(attemptId)) {
    billingError("billing_unavailable");
  }

  const session = await requireVenueSession();
  const context = await loadVenueBillingContext(session.userId);
  if (!context) billingError("billing_unavailable");

  if (
    context.stripeSubscriptionId &&
    ["active", "trialing", "past_due", "unpaid", "paused", "incomplete"].includes(
      context.stripeStatus,
    )
  ) {
    return openBillingPortal();
  }

  try {
    const stripe = getStripeClient();
    const priceId = getStripeProPriceId();
    const price = await stripe.prices.retrieve(priceId);
    if (!price.active || !price.recurring) billingError("plan_unavailable");

    let customerId = context.stripeCustomerId;
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: context.businessEmail || session.email || undefined,
        name: context.venueName,
        metadata: {
          outly_venue_id: context.venueId,
          outly_auth_user_id: session.userId,
        },
      });
      customerId = customer.id;

      const admin = createAdminClient();
      const { error } = await admin.rpc("attach_venue_stripe_customer", {
        p_user_id: session.userId,
        p_stripe_customer_id: customerId,
      });
      if (error) billingError("billing_unavailable");
    }

    const siteUrl = getSiteUrl();
    const checkout = await stripe.checkout.sessions.create(
      {
        mode: "subscription",
        customer: customerId,
        client_reference_id: context.venueId,
        line_items: [{ price: priceId, quantity: 1 }],
        integration_identifier: integrationIdentifier(attemptId),
        metadata: {
          outly_venue_id: context.venueId,
          outly_auth_user_id: session.userId,
        },
        subscription_data: {
          metadata: {
            outly_venue_id: context.venueId,
            outly_auth_user_id: session.userId,
          },
        },
        success_url: `${siteUrl}/dashboard/billing?checkout=success`,
        cancel_url: `${siteUrl}/dashboard/billing?checkout=cancelled`,
      },
      {
        idempotencyKey: `outly-checkout-${context.venueId}-${attemptId}`,
      },
    );

    if (!checkout.url) billingError("billing_unavailable");
    redirect(checkout.url);
  } catch (error) {
    if (error && typeof error === "object" && "digest" in error) throw error;
    billingError("billing_unavailable");
  }
}

export async function openBillingPortal() {
  const session = await requireVenueSession();
  const context = await loadVenueBillingContext(session.userId);
  if (!context?.stripeCustomerId) billingError("portal_unavailable");

  try {
    const portal = await getStripeClient().billingPortal.sessions.create({
      customer: context.stripeCustomerId,
      return_url: `${getSiteUrl()}/dashboard/billing`,
    });
    redirect(portal.url);
  } catch (error) {
    if (error && typeof error === "object" && "digest" in error) throw error;
    billingError("portal_unavailable");
  }
}
