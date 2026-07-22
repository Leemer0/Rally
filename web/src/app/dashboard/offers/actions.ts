"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { requireVenueSession } from "@/lib/auth/venue";
import { createClient } from "@/lib/supabase/server";

function value(formData: FormData, key: string) {
  const entry = formData.get(key);
  return typeof entry === "string" ? entry.trim() : "";
}

function optionalValue(formData: FormData, key: string) {
  return value(formData, key) || null;
}

function optionalPositiveInteger(formData: FormData, key: string) {
  const raw = value(formData, key);
  if (!raw) return null;

  const parsed = Number(raw);
  return Number.isSafeInteger(parsed) && parsed > 0 ? parsed : Number.NaN;
}

function offerPayload(formData: FormData) {
  const publicTitle = value(formData, "publicTitle");
  const staffDisplayTitle = value(formData, "staffDisplayTitle");
  const staffInstruction = value(formData, "staffInstruction");
  const nightlifeStartDate = value(formData, "nightlifeStartDate");
  const eligibleWeekdays = formData
    .getAll("eligibleWeekdays")
    .map((entry) => (typeof entry === "string" ? Number(entry) : Number.NaN))
    .filter(
      (weekday) =>
        Number.isSafeInteger(weekday) && weekday >= 0 && weekday <= 6,
    );
  const durationMinutes = optionalPositiveInteger(
    formData,
    "claimDurationMinutes",
  );
  const occurrenceClaimLimit = optionalPositiveInteger(
    formData,
    "occurrenceClaimLimit",
  );
  const dailyStartsAt = optionalValue(formData, "dailyStartsAt");
  const dailyEndsAt = optionalValue(formData, "dailyEndsAt");
  const checkInStartsAt = optionalValue(formData, "checkInStartsAt");
  const checkInCutoffAt = optionalValue(formData, "checkInCutoffAt");

  const invalid =
    !publicTitle ||
    !staffDisplayTitle ||
    !staffInstruction ||
    !nightlifeStartDate ||
    eligibleWeekdays.length === 0 ||
    Number.isNaN(durationMinutes) ||
    (durationMinutes !== null && durationMinutes > 1_440) ||
    Number.isNaN(occurrenceClaimLimit) ||
    Boolean(dailyStartsAt) !== Boolean(dailyEndsAt) ||
    (Boolean(checkInStartsAt) && !checkInCutoffAt);

  if (invalid) return null;

  return {
    public_title: publicTitle,
    short_explanation: optionalValue(formData, "shortExplanation"),
    staff_display_title: staffDisplayTitle,
    staff_instruction: staffInstruction,
    claim_duration_seconds:
      durationMinutes === null ? null : durationMinutes * 60,
    nightlife_start_date: nightlifeStartDate,
    nightlife_end_date: optionalValue(formData, "nightlifeEndDate"),
    eligible_weekdays: eligibleWeekdays,
    daily_starts_at: dailyStartsAt,
    daily_ends_at: dailyEndsAt,
    check_in_starts_at: checkInStartsAt,
    check_in_cutoff_at: checkInCutoffAt,
    plan_cutoff_at: optionalValue(formData, "planCutoffAt"),
    occurrence_claim_limit: occurrenceClaimLimit,
  };
}

export async function submitVenueOffer(formData: FormData) {
  await requireVenueSession();
  const payload = offerPayload(formData);
  const intent = value(formData, "intent");

  if (!payload) {
    redirect("/dashboard/offers/new?error=invalid_form");
  }

  try {
    const supabase = await createClient();
    const { error } = await supabase.functions.invoke("submit-venue-offer", {
      body: {
        idempotency_key: crypto.randomUUID(),
        ...payload,
        submit_for_review: intent === "review",
      },
    });

    if (error) throw error;
  } catch {
    redirect("/dashboard/offers/new?error=submit_failed");
  }

  revalidatePath("/dashboard");
  revalidatePath("/dashboard/offers");
  redirect(
    `/dashboard/offers?created=${intent === "review" ? "review" : "draft"}`,
  );
}

export async function reviseVenueOffer(formData: FormData) {
  await requireVenueSession();
  const offerId = value(formData, "offerId");
  const offerVersionId = value(formData, "offerVersionId");
  const idempotencyKey = value(formData, "idempotencyKey");
  const intent = value(formData, "intent");
  const payload = offerPayload(formData);

  if (!offerId || !offerVersionId || !idempotencyKey || !payload) {
    redirect(
      `/dashboard/offers/${encodeURIComponent(offerId)}?error=invalid_form`,
    );
  }

  try {
    const supabase = await createClient();
    const { error } = await supabase.functions.invoke("revise-venue-offer", {
      body: {
        offer_id: offerId,
        offer_version_id: offerVersionId,
        idempotency_key: idempotencyKey,
        ...payload,
        submit_for_review: intent === "review",
      },
    });
    if (error) throw error;
  } catch {
    redirect(
      `/dashboard/offers/${encodeURIComponent(offerId)}?error=revision_failed`,
    );
  }

  revalidatePath("/dashboard");
  revalidatePath("/dashboard/offers");
  revalidatePath(`/dashboard/offers/${offerId}`);
  redirect(
    `/dashboard/offers?updated=${intent === "review" ? "review" : "draft"}`,
  );
}

export async function setVenueOfferStatus(formData: FormData) {
  await requireVenueSession();
  const offerId = value(formData, "offerId");
  const idempotencyKey = value(formData, "idempotencyKey");
  const targetStatus = value(formData, "targetStatus");

  if (
    !offerId ||
    !idempotencyKey ||
    !["ended", "archived"].includes(targetStatus)
  ) {
    redirect("/dashboard/offers?error=invalid_status");
  }

  try {
    const supabase = await createClient();
    const { error } = await supabase.functions.invoke(
      "set-venue-offer-status",
      {
        body: {
          offer_id: offerId,
          idempotency_key: idempotencyKey,
          target_status: targetStatus,
        },
      },
    );
    if (error) throw error;
  } catch {
    redirect("/dashboard/offers?error=status_failed");
  }

  revalidatePath("/dashboard");
  revalidatePath("/dashboard/offers");
  revalidatePath(`/dashboard/offers/${offerId}`);
  redirect(`/dashboard/offers?updated=${targetStatus}`);
}
