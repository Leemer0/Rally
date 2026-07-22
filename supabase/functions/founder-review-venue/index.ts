import { ApiError, authenticated, readJsonObject } from "../_shared/http.ts";
import { callRpc } from "../_shared/rpc.ts";
import {
  assertOnlyKeys,
  optionalInteger,
  optionalNumber,
  optionalString,
  requiredString,
  requiredEnum,
  requiredUuid,
} from "../_shared/validation.ts";

export default {
  fetch: authenticated(["POST"], async (request, context) => {
    const body = await readJsonObject(request);
    assertOnlyKeys(body, [
      "venue_id",
      "decision",
      "public_response",
      "private_note",
      "neighbourhood",
      "postal_code",
      "latitude",
      "longitude",
      "geofence_radius_metres",
    ]);

    const latitude = optionalNumber(body, "latitude", -90, 90);
    const longitude = optionalNumber(body, "longitude", -180, 180);
    if ((latitude === null) !== (longitude === null)) {
      throw new ApiError(
        "INVALID_REQUEST",
        "latitude and longitude must be provided together.",
        400,
        { fields: ["latitude", "longitude"] },
      );
    }

    const decision = requiredEnum(body, "decision", [
      "approved",
      "changes_requested",
      "rejected",
      "suspended",
      "reinstated",
      "archived",
    ]);
    const publicResponse = decision === "changes_requested"
      ? requiredString(body, "public_response", 1, 1000)
      : optionalString(body, "public_response", 1, 1000);

    const venue = await callRpc<Record<string, unknown>>(
      context.supabaseAdmin,
      "review_venue_registration",
      {
        p_user_id: context.userId,
        p_venue_id: requiredUuid(body, "venue_id"),
        p_decision: decision,
        p_public_response: publicResponse,
        p_private_note: optionalString(body, "private_note", 1, 4000),
        p_neighbourhood: optionalString(body, "neighbourhood", 1, 80),
        p_postal_code: optionalString(body, "postal_code", 2, 16),
        p_latitude: latitude,
        p_longitude: longitude,
        p_geofence_radius_metres: optionalInteger(
          body,
          "geofence_radius_metres",
          25,
          200,
        ),
      },
      context.requestId,
    );
    return context.respond({ venue });
  }),
};
