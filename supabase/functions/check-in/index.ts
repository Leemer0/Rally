import {
  ApiError,
  authenticated,
  isJsonObject,
  readJsonObject,
} from "../_shared/http.ts";
import { presentCheckIn, presentClaim } from "../_shared/presenters.ts";
import { callRpc, firstRow } from "../_shared/rpc.ts";
import {
  assertOnlyKeys,
  optionalUuid,
  requiredDateTime,
  requiredEnum,
  requiredNumber,
  requiredUuid,
} from "../_shared/validation.ts";

const REJECTION_MESSAGES: Record<string, string> = {
  permission_denied: "Location access is required to verify this check-in.",
  reduced_accuracy: "Turn on Precise Location to verify this check-in.",
  insufficient_accuracy: "The location reading is not accurate enough yet.",
  stale_sample: "The location reading is too old. Try checking in again.",
  future_sample: "The location timestamp is invalid. Try checking in again.",
  outside_geofence: "You do not appear to be at this venue yet.",
  ambiguous_nearest_venue: "Your location is too close to another venue to verify safely.",
  venue_unavailable: "This venue is not currently accepting check-ins.",
  account_ineligible: "This account is not eligible to check in.",
  rate_limited: "Too many check-in attempts were made. Wait before trying again.",
  already_checked_in: "A venue check-in is already verified for tonight.",
  invalid_request: "The location evidence could not be verified.",
};

function rejectedCheckIn(reason: string, checkIn: Record<string, unknown>): ApiError {
  const status = reason === "rate_limited"
    ? 429
    : reason === "account_ineligible"
    ? 403
    : reason === "venue_unavailable" || reason === "already_checked_in"
    ? 409
    : 422;

  return new ApiError(
    reason.toUpperCase(),
    REJECTION_MESSAGES[reason] ?? "The check-in could not be verified.",
    status,
    { check_in: checkIn },
  );
}

export default {
  fetch: authenticated(["POST"], async (request, context) => {
    const body = await readJsonObject(request);
    assertOnlyKeys(body, [
      "venue_id",
      "plan_id",
      "offer_id",
      "check_in_idempotency_key",
      "claim_idempotency_key",
      "location",
    ]);

    if (!isJsonObject(body.location)) {
      throw new ApiError(
        "INVALID_REQUEST",
        "location must be a JSON object.",
        400,
        { field: "location" },
      );
    }
    const location = body.location;
    assertOnlyKeys(location, [
      "latitude",
      "longitude",
      "horizontal_accuracy_metres",
      "captured_at",
      "accuracy_authorization",
      "location_authorization",
    ]);

    const offerId = optionalUuid(body, "offer_id");
    const claimIdempotencyKey = optionalUuid(body, "claim_idempotency_key");
    if ((offerId === null) !== (claimIdempotencyKey === null)) {
      throw new ApiError(
        "INVALID_REQUEST",
        "offer_id and claim_idempotency_key must be provided together.",
        400,
        { fields: ["offer_id", "claim_idempotency_key"] },
      );
    }

    const rawCheckIn = await callRpc<unknown>(
      context.supabaseAdmin,
      "verify_venue_check_in",
      {
        p_user_id: context.userId,
        p_venue_id: requiredUuid(body, "venue_id"),
        p_idempotency_key: requiredUuid(body, "check_in_idempotency_key"),
        p_latitude: requiredNumber(location, "latitude", -90, 90),
        p_longitude: requiredNumber(location, "longitude", -180, 180),
        p_horizontal_accuracy_metres: requiredNumber(
          location,
          "horizontal_accuracy_metres",
          -1,
          100_000,
        ),
        p_location_captured_at: requiredDateTime(location, "captured_at"),
        p_accuracy_authorization: requiredEnum(
          location,
          "accuracy_authorization",
          ["full", "reduced", "unknown"],
        ),
        p_location_authorization: requiredEnum(
          location,
          "location_authorization",
          [
            "when_in_use",
            "always",
            "denied",
            "restricted",
            "not_determined",
            "unknown",
          ],
        ),
        p_plan_id: optionalUuid(body, "plan_id"),
      },
      context.requestId,
    );

    const checkIn = presentCheckIn(rawCheckIn);
    if (checkIn.outcome !== "verified") {
      throw rejectedCheckIn(
        typeof checkIn.rejection_reason === "string"
          ? checkIn.rejection_reason
          : "invalid_request",
        checkIn,
      );
    }

    if (!offerId || !claimIdempotencyKey) {
      return context.respond({ check_in: checkIn, claim: null });
    }

    try {
      const claimRows = await callRpc<unknown>(
        context.supabaseAdmin,
        "unlock_offer_for_check_in",
        {
          p_user_id: context.userId,
          p_check_in_id: checkIn.id,
          p_offer_id: offerId,
          p_idempotency_key: claimIdempotencyKey,
        },
        context.requestId,
      );
      const claim = presentClaim(
        firstRow(claimRows as Record<string, unknown>[], "offer claim"),
      );
      return context.respond({ check_in: checkIn, claim });
    } catch (error) {
      if (error instanceof ApiError) {
        throw new ApiError(error.code, error.message, error.status, {
          check_in: checkIn,
          ...(error.details === undefined ? {} : { cause: error.details }),
        });
      }
      throw error;
    }
  }),
};
