import "server-only";

import { createAdminClient } from "@/lib/supabase/admin";

export type VenueDashboardSnapshot = {
  serverTime: string;
  period: {
    start: string;
    end: string;
    maximumHistoryDays: number;
  };
  subscription: {
    planCode: string;
    billingPlanCode: string;
    status: string;
    entitlements: {
      activeOfferLimit: number;
      analyticsHistoryDays: number;
      advancedDemographics: boolean;
      customMapMarker: boolean;
      featuredPlacement: boolean;
      campaignCustomization: boolean;
      neighbourhoodBenchmarks: boolean;
      repeatVisitorInsights: boolean;
      detailedAttribution: boolean;
      partnerCampaignAccess: boolean;
    };
  };
  venue: {
    id: string;
    slug: string;
    name: string;
    registrationStatus: string;
    publicationStatus: string;
    accountStatus: string;
    neighbourhood: string | null;
    address: string;
  };
  metrics: {
    impressions: number;
    detailViewers: number;
    plans: number;
    checkInAttempts: number;
    verifiedCheckIns: number;
    offersUnlocked: number;
    returningVisitors: number | null;
  };
  dailyActivity: Array<{
    date: string;
    impressions: number;
    detailViewers: number;
    plans: number;
    verifiedCheckIns: number;
    offersUnlocked: number;
  }>;
  checkInsByHour: Array<{ hour: number; count: number }>;
  demographics: {
    cohortSize: number;
    averageAge: number;
    gender: {
      man: number;
      woman: number;
      other: number;
    };
  } | null;
  demographicsSuppressed: boolean;
  offers: Array<{
    id: string;
    title: string;
    status: string;
    approvalState: string | null;
    claimDurationSeconds: number | null;
    unlockedCount: number;
  }>;
};

export type VenueOfferFeedback = {
  decision: string;
  publicResponse: string | null;
  createdAt: string;
};

export type VenueOfferManagementItem = {
  offerId: string;
  offerVersionId: string;
  versionNumber: number;
  title: string;
  lifecycleStatus: string;
  approvalState: string;
  claimDurationSeconds: number | null;
  canEdit: boolean;
  canEnd: boolean;
  canArchive: boolean;
  latestFeedback: VenueOfferFeedback | null;
};

export type VenueOfferEditor = {
  offerId: string;
  offerVersionId: string;
  versionNumber: number;
  lifecycleStatus: string;
  approvalState: string;
  canEdit: boolean;
  publicTitle: string;
  shortExplanation: string | null;
  staffDisplayTitle: string;
  staffInstruction: string;
  claimDurationSeconds: number | null;
  schedule: {
    nightlifeStartDate: string;
    nightlifeEndDate: string | null;
    eligibleWeekdays: number[];
    dailyStartsAt: string | null;
    dailyEndsAt: string | null;
    checkInStartsAt: string | null;
    checkInCutoffAt: string | null;
    planCutoffAt: string | null;
    occurrenceClaimLimit: number | null;
  };
  latestFeedback: VenueOfferFeedback | null;
};

type DashboardResult =
  | { data: VenueDashboardSnapshot; error: null }
  | { data: null; error: "configuration" | "unavailable" };

function record(value: unknown): Record<string, unknown> {
  return typeof value === "object" && value !== null
    ? (value as Record<string, unknown>)
    : {};
}

function number(value: unknown) {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}

function nullableNumber(value: unknown) {
  return value === null ? null : number(value);
}

function boolean(value: unknown) {
  return value === true;
}

function string(value: unknown) {
  return typeof value === "string" ? value : "";
}

function nullableString(value: unknown) {
  return value === null || value === undefined ? null : string(value);
}

function parseFeedback(value: unknown): VenueOfferFeedback | null {
  if (value === null || value === undefined) return null;
  const feedback = record(value);
  return {
    decision: string(feedback.decision),
    publicResponse: nullableString(feedback.public_response),
    createdAt: string(feedback.created_at),
  };
}

function parseSnapshot(value: unknown): VenueDashboardSnapshot {
  const root = record(value);
  const period = record(root.period);
  const venue = record(root.venue);
  const subscription = record(root.subscription);
  const entitlements = record(subscription.entitlements);
  const metrics = record(root.metrics);
  const demographics =
    typeof root.demographics === "object" && root.demographics !== null
      ? record(root.demographics)
      : null;
  const dailyActivity = Array.isArray(root.daily_activity)
    ? root.daily_activity
    : [];
  const checkInsByHour = Array.isArray(root.check_ins_by_hour)
    ? root.check_ins_by_hour
    : [];
  const offers = Array.isArray(root.offers) ? root.offers : [];

  return {
    serverTime: string(root.server_time),
    period: {
      start: string(period.start),
      end: string(period.end),
      maximumHistoryDays: number(period.maximum_history_days),
    },
    subscription: {
      planCode: string(subscription.plan_code) || "free",
      billingPlanCode:
        string(subscription.billing_plan_code) ||
        string(subscription.plan_code) ||
        "free",
      status: string(subscription.status) || "free",
      entitlements: {
        activeOfferLimit: number(entitlements.active_offer_limit),
        analyticsHistoryDays: number(entitlements.analytics_history_days),
        advancedDemographics: boolean(entitlements.advanced_demographics),
        customMapMarker: boolean(entitlements.custom_map_marker),
        featuredPlacement: boolean(entitlements.featured_placement),
        campaignCustomization: boolean(entitlements.campaign_customization),
        neighbourhoodBenchmarks: boolean(entitlements.neighbourhood_benchmarks),
        repeatVisitorInsights: boolean(entitlements.repeat_visitor_insights),
        detailedAttribution: boolean(entitlements.detailed_attribution),
        partnerCampaignAccess: boolean(entitlements.partner_campaign_access),
      },
    },
    venue: {
      id: string(venue.id),
      slug: string(venue.slug),
      name: string(venue.name),
      registrationStatus: string(venue.registration_status),
      publicationStatus: string(venue.publication_status),
      accountStatus: string(venue.account_status),
      neighbourhood:
        venue.neighbourhood === null ? null : string(venue.neighbourhood),
      address: string(venue.address),
    },
    metrics: {
      impressions: number(metrics.impressions),
      detailViewers: number(metrics.detail_viewers),
      plans: number(metrics.plans),
      checkInAttempts: number(metrics.check_in_attempts),
      verifiedCheckIns: number(metrics.verified_check_ins),
      offersUnlocked: number(metrics.offers_unlocked),
      returningVisitors: nullableNumber(metrics.returning_visitors),
    },
    dailyActivity: dailyActivity.map((entry) => {
      const item = record(entry);
      return {
        date: string(item.date),
        impressions: number(item.impressions),
        detailViewers: number(item.detail_viewers),
        plans: number(item.plans),
        verifiedCheckIns: number(item.verified_check_ins),
        offersUnlocked: number(item.offers_unlocked),
      };
    }),
    checkInsByHour: checkInsByHour.map((entry) => {
      const item = record(entry);
      return { hour: number(item.hour), count: number(item.count) };
    }),
    demographics: demographics
      ? {
          cohortSize: number(demographics.cohort_size),
          averageAge: number(demographics.average_age),
          gender: {
            man: number(record(demographics.gender).man),
            woman: number(record(demographics.gender).woman),
            other: number(record(demographics.gender).other),
          },
        }
      : null,
    demographicsSuppressed: boolean(root.demographics_suppressed),
    offers: offers.map((entry) => {
      const item = record(entry);
      return {
        id: string(item.offer_id),
        title: string(item.title) || "Untitled offer",
        status: string(item.status),
        approvalState:
          item.approval_state === null ? null : string(item.approval_state),
        claimDurationSeconds:
          item.claim_duration_seconds === null
            ? null
            : number(item.claim_duration_seconds),
        unlockedCount: number(item.unlocked_count),
      };
    }),
  };
}

export async function loadVenueDashboardSnapshot(
  userId: string,
): Promise<DashboardResult> {
  let admin;

  try {
    admin = createAdminClient();
  } catch {
    return { data: null, error: "configuration" };
  }

  const { data, error } = await admin.rpc("get_venue_dashboard_snapshot", {
    p_user_id: userId,
  });

  if (error || !data) {
    return { data: null, error: "unavailable" };
  }

  return { data: parseSnapshot(data), error: null };
}

export async function loadVenueOfferManagement(
  userId: string,
): Promise<
  | { data: VenueOfferManagementItem[]; error: null }
  | { data: null; error: "configuration" | "unavailable" }
> {
  let admin;

  try {
    admin = createAdminClient();
  } catch {
    return { data: null, error: "configuration" };
  }

  const { data, error } = await admin.rpc("get_venue_offer_management", {
    p_user_id: userId,
  });
  if (error || !Array.isArray(data)) {
    return { data: null, error: "unavailable" };
  }

  return {
    data: data.map((entry) => {
      const item = record(entry);
      return {
        offerId: string(item.offer_id),
        offerVersionId: string(item.offer_version_id),
        versionNumber: number(item.version_number),
        title: string(item.title) || "Untitled offer",
        lifecycleStatus: string(item.lifecycle_status),
        approvalState: string(item.approval_state),
        claimDurationSeconds:
          item.claim_duration_seconds === null
            ? null
            : number(item.claim_duration_seconds),
        canEdit: boolean(item.can_edit),
        canEnd: boolean(item.can_end),
        canArchive: boolean(item.can_archive),
        latestFeedback: parseFeedback(item.latest_feedback),
      };
    }),
    error: null,
  };
}

export async function loadVenueOfferEditor(
  userId: string,
  offerId: string,
): Promise<
  | { data: VenueOfferEditor; error: null }
  | { data: null; error: "configuration" | "unavailable" }
> {
  let admin;

  try {
    admin = createAdminClient();
  } catch {
    return { data: null, error: "configuration" };
  }

  const { data, error } = await admin.rpc("get_venue_offer_editor", {
    p_user_id: userId,
    p_offer_id: offerId,
  });
  if (error || !data) {
    return { data: null, error: "unavailable" };
  }

  const item = record(data);
  const schedule = record(item.schedule);
  const eligibleWeekdays = Array.isArray(schedule.eligible_weekdays)
    ? schedule.eligible_weekdays.map(number)
    : [];

  return {
    data: {
      offerId: string(item.offer_id),
      offerVersionId: string(item.offer_version_id),
      versionNumber: number(item.version_number),
      lifecycleStatus: string(item.lifecycle_status),
      approvalState: string(item.approval_state),
      canEdit: boolean(item.can_edit),
      publicTitle: string(item.public_title),
      shortExplanation: nullableString(item.short_explanation),
      staffDisplayTitle: string(item.staff_display_title),
      staffInstruction: string(item.staff_instruction),
      claimDurationSeconds:
        item.claim_duration_seconds === null
          ? null
          : number(item.claim_duration_seconds),
      schedule: {
        nightlifeStartDate: string(schedule.nightlife_start_date),
        nightlifeEndDate: nullableString(schedule.nightlife_end_date),
        eligibleWeekdays,
        dailyStartsAt: nullableString(schedule.daily_starts_at),
        dailyEndsAt: nullableString(schedule.daily_ends_at),
        checkInStartsAt: nullableString(schedule.check_in_starts_at),
        checkInCutoffAt: nullableString(schedule.check_in_cutoff_at),
        planCutoffAt: nullableString(schedule.plan_cutoff_at),
        occurrenceClaimLimit:
          schedule.occurrence_claim_limit === null
            ? null
            : number(schedule.occurrence_claim_limit),
      },
      latestFeedback: parseFeedback(item.latest_feedback),
    },
    error: null,
  };
}
