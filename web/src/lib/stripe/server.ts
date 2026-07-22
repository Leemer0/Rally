import "server-only";

import Stripe from "stripe";

const STRIPE_API_VERSION = "2026-06-24.dahlia" as const;

export function getStripeClient() {
  const apiKey =
    process.env.STRIPE_RESTRICTED_KEY?.trim() ||
    process.env.STRIPE_SECRET_KEY?.trim();

  if (!apiKey) {
    throw new Error("Stripe is not configured.");
  }

  return new Stripe(apiKey, {
    apiVersion: STRIPE_API_VERSION,
    typescript: true,
    appInfo: {
      name: "Outly Venue Billing",
      version: "1.0.0",
      url: "https://www.getoutly.app",
    },
  });
}

export function getStripeProPriceId() {
  const priceId = process.env.STRIPE_PRO_PRICE_ID?.trim();
  if (!priceId?.startsWith("price_")) {
    throw new Error("STRIPE_PRO_PRICE_ID is not configured.");
  }
  return priceId;
}

export function getStripeWebhookSecret() {
  const secret = process.env.STRIPE_WEBHOOK_SECRET?.trim();
  if (!secret?.startsWith("whsec_")) {
    throw new Error("STRIPE_WEBHOOK_SECRET is not configured.");
  }
  return secret;
}

