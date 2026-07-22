import { ApiError, isJsonObject, type JsonObject } from "./http.ts";

function databaseRecord(value: unknown, operation: string): JsonObject {
  if (!isJsonObject(value)) {
    throw new ApiError(
      "BACKEND_CONTRACT_ERROR",
      `The ${operation} response was malformed.`,
      500,
    );
  }
  return value;
}

export function presentPlan(value: unknown): JsonObject {
  const row = databaseRecord(value, "night plan");
  return {
    id: row.id,
    venue_id: row.venue_id,
    nightlife_date: row.nightlife_date,
    status: row.plan_status,
    replaces_plan_id: row.replaces_plan_id,
    created_at: row.created_at,
    updated_at: row.updated_at,
    cancelled_at: row.cancelled_at,
    replaced_at: row.replaced_at,
    checked_in_at: row.checked_in_at,
    expired_at: row.expired_at,
  };
}

export function presentCheckIn(value: unknown): JsonObject {
  const row = databaseRecord(value, "check-in");
  return {
    id: row.id,
    venue_id: row.venue_id,
    plan_id: row.plan_id,
    nightlife_date: row.nightlife_date,
    outcome: row.outcome,
    rejection_reason: row.rejection_reason,
    client_location_captured_at: row.client_location_captured_at,
    server_requested_at: row.server_requested_at,
    server_verified_at: row.server_verified_at,
    horizontal_accuracy_metres: row.horizontal_accuracy_metres,
    location_age_seconds: row.location_age_seconds,
    distance_from_venue_metres: row.distance_from_venue_metres,
    configured_radius_metres: row.configured_radius_metres,
    verifier_version: row.verifier_version,
  };
}

export function presentClaim(value: unknown): JsonObject {
  const row = databaseRecord(value, "offer claim");
  const duration = typeof row.claim_duration_seconds === "number"
    ? row.claim_duration_seconds
    : null;

  return {
    claim_id: row.claim_id,
    venue_id: row.venue_id,
    unlocked_at: row.unlocked_at,
    countdown_ends_at: duration === null ? null : row.expires_at,
    entitlement_expires_at: row.expires_at,
    status: row.effective_status,
    staff_reference: row.staff_reference,
    offer: {
      offer_id: row.offer_id,
      offer_version_id: row.offer_version_id,
      kind: row.kind,
      title: row.title,
      explanation: row.explanation,
      cta_label: row.cta_label,
      redemption_mode: row.redemption_mode,
      destination_url: row.destination_url,
      staff_display_title: row.staff_display_title,
      staff_instruction: row.staff_instruction,
      fine_print: row.fine_print,
      claim_duration_seconds: row.claim_duration_seconds,
      presentation_kind: row.presentation_kind,
      sponsor_display_name: row.sponsor_display_name,
      sponsor_logo_storage_path: row.sponsor_logo_storage_path,
      sponsor_logo_alt_text: row.sponsor_logo_alt_text,
      sponsor_disclosure: row.sponsor_disclosure,
      discovery_treatment: row.discovery_treatment,
      discovery_badge_label: row.discovery_badge_label,
      discovery_icon_key: row.discovery_icon_key,
    },
  };
}
