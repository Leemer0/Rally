import "server-only";

import { createClient } from "@/lib/supabase/server";

export type FounderMetrics = {
  activeConsumers: number;
  pendingVenues: number;
  pendingVenueClaims: number;
  publishedVenues: number;
  liveOffers: number;
  verifiedCheckIns: number;
  offerClaims: number;
};

export type FounderVenue = {
  id: string;
  slug: string;
  name: string;
  neighbourhood: string | null;
  registrationStatus: string;
  publicationStatus: string;
  placementState: string;
  accountStatus: string | null;
  businessEmail: string | null;
  claimStatus: string | null;
  planCode: string | null;
  subscriptionStatus: string | null;
  partnerCampaignAccess: boolean;
  createdAt: string;
};

export type FounderConsumer = {
  userId: string;
  email: string | null;
  firstName: string | null;
  onboardingStatus: string;
  accountStatus: string;
  createdAt: string;
};

export type FounderOfferReview = {
  offerId: string;
  offerVersionId: string;
  venueId: string;
  venueName: string;
  kind: string;
  title: string;
  submittedAt: string | null;
  approvalState: string;
};

export type FounderPartner = {
  id: string;
  brandName: string;
  legalName: string;
  status: string;
  websiteUrl: string | null;
  campaignCount: number;
};

export type FounderDashboardSnapshot = {
  serverTime: string;
  metrics: FounderMetrics;
  venues: FounderVenue[];
  consumers: FounderConsumer[];
  offerReviewQueue: FounderOfferReview[];
  partners: FounderPartner[];
};

type JsonRecord = Record<string, unknown>;

function record(value: unknown, path: string): JsonRecord {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error(`Founder dashboard returned an invalid ${path}.`);
  }
  return value as JsonRecord;
}

function list(value: unknown, path: string): unknown[] {
  if (!Array.isArray(value)) {
    throw new Error(`Founder dashboard returned an invalid ${path}.`);
  }
  return value;
}

function text(value: unknown, path: string): string {
  if (typeof value !== "string" || !value) {
    throw new Error(`Founder dashboard returned an invalid ${path}.`);
  }
  return value;
}

function nullableText(value: unknown, path: string): string | null {
  if (value === null || value === undefined) return null;
  return text(value, path);
}

function count(value: unknown, path: string): number {
  if (typeof value !== "number" || !Number.isSafeInteger(value) || value < 0) {
    throw new Error(`Founder dashboard returned an invalid ${path}.`);
  }
  return value;
}

function boolean(value: unknown, path: string): boolean {
  if (typeof value !== "boolean") {
    throw new Error(`Founder dashboard returned an invalid ${path}.`);
  }
  return value;
}

function parseSnapshot(raw: unknown): FounderDashboardSnapshot {
  const response = record(raw, "response");
  const payload = "data" in response ? record(response.data, "response data") : response;
  const metrics = record(payload.metrics, "metrics");

  return {
    serverTime: text(payload.server_time, "server_time"),
    metrics: {
      activeConsumers: count(metrics.active_consumers, "metrics.active_consumers"),
      pendingVenues: count(metrics.pending_venues, "metrics.pending_venues"),
      pendingVenueClaims: count(
        metrics.pending_venue_claims,
        "metrics.pending_venue_claims",
      ),
      publishedVenues: count(metrics.published_venues, "metrics.published_venues"),
      liveOffers: count(metrics.live_offers, "metrics.live_offers"),
      verifiedCheckIns: count(metrics.verified_check_ins, "metrics.verified_check_ins"),
      offerClaims: count(metrics.offer_claims, "metrics.offer_claims"),
    },
    venues: list(payload.venues, "venues").map((value, index) => {
      const venue = record(value, `venues[${index}]`);
      return {
        id: text(venue.id, `venues[${index}].id`),
        slug: text(venue.slug, `venues[${index}].slug`),
        name: text(venue.name, `venues[${index}].name`),
        neighbourhood: nullableText(
          venue.neighbourhood,
          `venues[${index}].neighbourhood`,
        ),
        registrationStatus: text(
          venue.registration_status,
          `venues[${index}].registration_status`,
        ),
        publicationStatus: text(
          venue.publication_status,
          `venues[${index}].publication_status`,
        ),
        placementState: text(
          venue.placement_state,
          `venues[${index}].placement_state`,
        ),
        accountStatus: nullableText(
          venue.account_status,
          `venues[${index}].account_status`,
        ),
        businessEmail: nullableText(
          venue.business_email,
          `venues[${index}].business_email`,
        ),
        claimStatus: nullableText(
          venue.claim_status,
          `venues[${index}].claim_status`,
        ),
        planCode: nullableText(
          venue.plan_code,
          `venues[${index}].plan_code`,
        ),
        subscriptionStatus: nullableText(
          venue.subscription_status,
          `venues[${index}].subscription_status`,
        ),
        partnerCampaignAccess: boolean(
          venue.partner_campaign_access,
          `venues[${index}].partner_campaign_access`,
        ),
        createdAt: text(venue.created_at, `venues[${index}].created_at`),
      };
    }),
    consumers: list(payload.consumers, "consumers").map((value, index) => {
      const consumer = record(value, `consumers[${index}]`);
      return {
        userId: text(consumer.user_id, `consumers[${index}].user_id`),
        email: nullableText(consumer.email, `consumers[${index}].email`),
        firstName: nullableText(
          consumer.first_name,
          `consumers[${index}].first_name`,
        ),
        onboardingStatus: text(
          consumer.onboarding_status,
          `consumers[${index}].onboarding_status`,
        ),
        accountStatus: text(
          consumer.account_status,
          `consumers[${index}].account_status`,
        ),
        createdAt: text(consumer.created_at, `consumers[${index}].created_at`),
      };
    }),
    offerReviewQueue: list(payload.offer_review_queue, "offer_review_queue").map(
      (value, index) => {
        const offer = record(value, `offer_review_queue[${index}]`);
        return {
          offerId: text(offer.offer_id, `offer_review_queue[${index}].offer_id`),
          offerVersionId: text(
            offer.offer_version_id,
            `offer_review_queue[${index}].offer_version_id`,
          ),
          venueId: text(offer.venue_id, `offer_review_queue[${index}].venue_id`),
          venueName: text(
            offer.venue_name,
            `offer_review_queue[${index}].venue_name`,
          ),
          kind: text(offer.kind, `offer_review_queue[${index}].kind`),
          title: text(offer.title, `offer_review_queue[${index}].title`),
          submittedAt: nullableText(
            offer.submitted_at,
            `offer_review_queue[${index}].submitted_at`,
          ),
          approvalState: text(
            offer.approval_state,
            `offer_review_queue[${index}].approval_state`,
          ),
        };
      },
    ),
    partners: list(payload.partners, "partners").map((value, index) => {
      const partner = record(value, `partners[${index}]`);
      return {
        id: text(partner.id, `partners[${index}].id`),
        brandName: text(partner.brand_name, `partners[${index}].brand_name`),
        legalName: text(partner.legal_name, `partners[${index}].legal_name`),
        status: text(partner.status, `partners[${index}].status`),
        websiteUrl: nullableText(
          partner.website_url,
          `partners[${index}].website_url`,
        ),
        campaignCount: count(
          partner.campaign_count,
          `partners[${index}].campaign_count`,
        ),
      };
    }),
  };
}

export async function getFounderDashboardSnapshot() {
  const supabase = await createClient();
  const functionName =
    process.env.SUPABASE_FOUNDER_DASHBOARD_FUNCTION?.trim() ||
    "founder-dashboard";
  const { data, error } = await supabase.functions.invoke(functionName, {
    method: "GET",
  });

  if (error) {
    throw new Error("The live founder dashboard could not be loaded.", {
      cause: error,
    });
  }

  return parseSnapshot(data);
}

export function presentStatus(value: string) {
  return value
    .split("_")
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

export function maskEmail(value: string | null) {
  if (!value) return "No email";
  const [local, domain] = value.split("@");
  if (!domain) return "Hidden";
  return `${local.slice(0, 2)}${local.length > 2 ? "••" : ""}@${domain}`;
}

export function formatAdminDate(value: string) {
  const parsed = new Date(value);
  if (Number.isNaN(parsed.valueOf())) return "Unknown";
  return new Intl.DateTimeFormat("en-CA", {
    month: "short",
    day: "numeric",
    year: parsed.getFullYear() === new Date().getFullYear() ? undefined : "numeric",
  }).format(parsed);
}
