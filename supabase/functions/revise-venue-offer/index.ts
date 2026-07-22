import { ApiError, authenticated, readJsonObject } from "../_shared/http.ts";
import { callRpc, firstRow } from "../_shared/rpc.ts";
import {
  assertOnlyKeys,
  optionalBoolean,
  optionalDate,
  optionalInteger,
  optionalString,
  optionalTime,
  requiredDate,
  requiredIntegerArray,
  requiredString,
  requiredUuid,
} from "../_shared/validation.ts";

export default {
  fetch: authenticated(["POST"], async (request, context) => {
    const body = await readJsonObject(request);
    assertOnlyKeys(body, [
      "offer_id",
      "offer_version_id",
      "idempotency_key",
      "public_title",
      "short_explanation",
      "staff_display_title",
      "staff_instruction",
      "claim_duration_seconds",
      "nightlife_start_date",
      "nightlife_end_date",
      "eligible_weekdays",
      "daily_starts_at",
      "daily_ends_at",
      "check_in_starts_at",
      "check_in_cutoff_at",
      "plan_cutoff_at",
      "occurrence_claim_limit",
      "submit_for_review",
    ]);

    const startDate = requiredDate(body, "nightlife_start_date");
    const endDate = optionalDate(body, "nightlife_end_date");
    if (endDate && endDate < startDate) {
      throw new ApiError(
        "INVALID_REQUEST",
        "nightlife_end_date cannot be before nightlife_start_date.",
        400,
        { fields: ["nightlife_start_date", "nightlife_end_date"] },
      );
    }

    const dailyStartsAt = optionalTime(body, "daily_starts_at");
    const dailyEndsAt = optionalTime(body, "daily_ends_at");
    if ((dailyStartsAt === null) !== (dailyEndsAt === null)) {
      throw new ApiError(
        "INVALID_REQUEST",
        "daily_starts_at and daily_ends_at must be provided together.",
        400,
        { fields: ["daily_starts_at", "daily_ends_at"] },
      );
    }

    const checkInStartsAt = optionalTime(body, "check_in_starts_at");
    const checkInCutoffAt = optionalTime(body, "check_in_cutoff_at");
    if (checkInStartsAt !== null && checkInCutoffAt === null) {
      throw new ApiError(
        "INVALID_REQUEST",
        "check_in_cutoff_at is required when check_in_starts_at is set.",
        400,
        { fields: ["check_in_starts_at", "check_in_cutoff_at"] },
      );
    }

    const revision = await callRpc<unknown>(
      context.supabaseAdmin,
      "revise_venue_offer",
      {
        p_user_id: context.userId,
        p_offer_id: requiredUuid(body, "offer_id"),
        p_offer_version_id: requiredUuid(body, "offer_version_id"),
        p_idempotency_key: requiredUuid(body, "idempotency_key"),
        p_public_title: requiredString(body, "public_title", 1, 140),
        p_short_explanation: optionalString(body, "short_explanation", 1, 240),
        p_staff_display_title: requiredString(
          body,
          "staff_display_title",
          1,
          140,
        ),
        p_staff_instruction: requiredString(
          body,
          "staff_instruction",
          1,
          240,
        ),
        p_claim_duration_seconds: optionalInteger(
          body,
          "claim_duration_seconds",
          1,
          86_400,
        ),
        p_nightlife_start_date: startDate,
        p_nightlife_end_date: endDate,
        p_eligible_weekdays: requiredIntegerArray(
          body,
          "eligible_weekdays",
          0,
          6,
        ),
        p_daily_starts_at: dailyStartsAt,
        p_daily_ends_at: dailyEndsAt,
        p_check_in_starts_at: checkInStartsAt,
        p_check_in_cutoff_at: checkInCutoffAt,
        p_plan_cutoff_at: optionalTime(body, "plan_cutoff_at"),
        p_occurrence_claim_limit: optionalInteger(
          body,
          "occurrence_claim_limit",
          1,
          2_147_483_647,
        ),
        p_submit_for_review: optionalBoolean(body, "submit_for_review", false),
      },
      context.requestId,
    );

    return context.respond({
      offer: firstRow(
        revision as Record<string, unknown>[],
        "offer revision",
      ),
    });
  }),
};
