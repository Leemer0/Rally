"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { requireFounderSession } from "@/lib/auth/founder";
import { createClient } from "@/lib/supabase/server";

function value(formData: FormData, key: string) {
  const entry = formData.get(key);
  return typeof entry === "string" ? entry.trim() : "";
}

function optionalValue(formData: FormData, key: string) {
  const entry = value(formData, key);
  return entry || null;
}

function numberValue(formData: FormData, key: string) {
  const raw = value(formData, key);
  if (!raw) return null;
  const parsed = Number(raw);
  return Number.isFinite(parsed) ? parsed : null;
}

function integerValue(formData: FormData, key: string) {
  const parsed = numberValue(formData, key);
  return parsed !== null && Number.isSafeInteger(parsed) ? parsed : null;
}

function zonedLocalDateTimeToIso(localValue: string, timeZone: string) {
  if (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(localValue)) return null;

  const [date, time] = localValue.split("T");
  const [year, month, day] = date.split("-").map(Number);
  const [hour, minute] = time.split(":").map(Number);
  const requestedAsUtc = Date.UTC(year, month - 1, day, hour, minute);
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  });

  let candidate = requestedAsUtc;
  for (let attempt = 0; attempt < 2; attempt += 1) {
    const parts = Object.fromEntries(
      formatter
        .formatToParts(new Date(candidate))
        .filter((part) => part.type !== "literal")
        .map((part) => [part.type, Number(part.value)]),
    );
    const representedAsUtc = Date.UTC(
      parts.year,
      parts.month - 1,
      parts.day,
      parts.hour,
      parts.minute,
    );
    candidate += requestedAsUtc - representedAsUtc;
  }

  return new Date(candidate).toISOString();
}

async function invokeFounder(functionName: string, body: Record<string, unknown>) {
  await requireFounderSession();
  const supabase = await createClient();
  const { error } = await supabase.functions.invoke(functionName, { body });
  if (error) throw error;
}

export async function createFounderVenue(formData: FormData) {
  try {
    await invokeFounder("founder-create-venue", {
      display_name: value(formData, "displayName"),
      address_line_1: value(formData, "addressLine1"),
      neighbourhood: value(formData, "neighbourhood"),
      postal_code: value(formData, "postalCode"),
      latitude: numberValue(formData, "latitude"),
      longitude: numberValue(formData, "longitude"),
      geofence_radius_metres: integerValue(formData, "geofenceRadiusMetres"),
    });
  } catch {
    redirect("/admin/venues/new?error=create_failed");
  }

  revalidatePath("/admin");
  revalidatePath("/admin/venues");
  redirect("/admin/venues?created=1");
}

export async function reviewFounderVenue(formData: FormData) {
  const venueId = value(formData, "venueId");
  const decision = value(formData, "decision");

  try {
    await invokeFounder("founder-review-venue", {
      venue_id: venueId,
      decision,
      public_response: optionalValue(formData, "publicResponse"),
      private_note: optionalValue(formData, "privateNote"),
      neighbourhood: optionalValue(formData, "neighbourhood"),
      postal_code: optionalValue(formData, "postalCode"),
      latitude: numberValue(formData, "latitude"),
      longitude: numberValue(formData, "longitude"),
      geofence_radius_metres: integerValue(
        formData,
        "geofenceRadiusMetres",
      ),
    });
  } catch {
    redirect(`/admin/venues/${encodeURIComponent(venueId)}?error=review_failed`);
  }

  revalidatePath("/admin");
  revalidatePath("/admin/venues");
  revalidatePath(`/admin/venues/${venueId}`);
  redirect(`/admin/venues/${venueId}?updated=1`);
}

export async function reviewFounderOffer(formData: FormData) {
  try {
    await invokeFounder("founder-review-offer", {
      offer_version_id: value(formData, "offerVersionId"),
      decision: value(formData, "decision"),
      public_response: optionalValue(formData, "publicResponse"),
      private_note: optionalValue(formData, "privateNote"),
    });
  } catch {
    redirect("/admin/assignments?error=review_failed");
  }

  revalidatePath("/admin");
  revalidatePath("/admin/assignments");
  redirect("/admin/assignments?reviewed=1");
}

export async function setFounderVenuePlan(formData: FormData) {
  const venueId = value(formData, "venueId");
  const planCode = value(formData, "planCode");
  const status = value(formData, "status");
  const trialLocal = optionalValue(formData, "trialEndsAt");

  try {
    await invokeFounder("founder-set-venue-plan", {
      venue_id: venueId,
      plan_code: planCode,
      status,
      trial_ends_at: trialLocal
        ? zonedLocalDateTimeToIso(trialLocal, "America/Toronto")
        : null,
    });
  } catch {
    redirect(`/admin/venues/${encodeURIComponent(venueId)}?error=plan_failed`);
  }

  revalidatePath("/admin");
  revalidatePath("/admin/venues");
  revalidatePath(`/admin/venues/${venueId}`);
  redirect(`/admin/venues/${venueId}?planUpdated=1`);
}

export async function upsertFounderPartner(formData: FormData) {
  try {
    await invokeFounder("founder-upsert-partner", {
      brand_name: value(formData, "brandName"),
      legal_name: value(formData, "legalName"),
      website_url: optionalValue(formData, "websiteUrl"),
      industry: optionalValue(formData, "industry"),
      logo_storage_path: value(formData, "logoStoragePath"),
      logo_alt_text: value(formData, "logoAltText"),
      contact_name: value(formData, "contactName"),
      contact_email: value(formData, "contactEmail"),
      contact_phone: optionalValue(formData, "contactPhone"),
    });
  } catch {
    redirect("/admin/partners/new?mode=partner&error=create_failed");
  }

  revalidatePath("/admin");
  revalidatePath("/admin/partners");
  redirect("/admin/partners?created=partner");
}

export async function createFounderPartnerCampaign(formData: FormData) {
  const startsAt = zonedLocalDateTimeToIso(
    value(formData, "startsAt"),
    "America/Toronto",
  );
  const endsLocal = optionalValue(formData, "endsAt");
  const endsAt = endsLocal
    ? zonedLocalDateTimeToIso(endsLocal, "America/Toronto")
    : null;
  const venueIds = formData
    .getAll("venueIds")
    .filter((entry): entry is string => typeof entry === "string");

  try {
    await invokeFounder("founder-create-partner-campaign", {
      partner_id: value(formData, "partnerId"),
      venue_ids: venueIds,
      internal_name: value(formData, "internalName"),
      public_title: value(formData, "publicTitle"),
      short_explanation: optionalValue(formData, "shortExplanation"),
      cta_label: value(formData, "ctaLabel"),
      destination_url: value(formData, "destinationUrl"),
      fine_print: optionalValue(formData, "finePrint"),
      sponsor_disclosure: value(formData, "sponsorDisclosure"),
      claim_duration_seconds: integerValue(formData, "claimDurationSeconds"),
      starts_at: startsAt,
      ends_at: endsAt,
      total_claim_limit: integerValue(formData, "totalClaimLimit"),
      per_user_limit: integerValue(formData, "perUserLimit") ?? 1,
      discovery_badge_label:
        optionalValue(formData, "discoveryBadgeLabel") || "Outly exclusive",
      discovery_icon_key:
        optionalValue(formData, "discoveryIconKey") || "outly-winged-o",
    });
  } catch {
    redirect("/admin/partners/new?mode=offer&error=create_failed");
  }

  revalidatePath("/admin");
  revalidatePath("/admin/partners");
  revalidatePath("/admin/assignments");
  redirect("/admin/partners?created=offer");
}
