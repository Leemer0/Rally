import { authenticated, readJsonObject } from "../_shared/http.ts";
import { callRpc } from "../_shared/rpc.ts";
import {
  assertOnlyKeys,
  optionalInteger,
  requiredNumber,
  requiredString,
} from "../_shared/validation.ts";

export default {
  fetch: authenticated(["POST"], async (request, context) => {
    const body = await readJsonObject(request);
    assertOnlyKeys(body, [
      "display_name",
      "address_line_1",
      "neighbourhood",
      "postal_code",
      "latitude",
      "longitude",
      "geofence_radius_metres",
    ]);

    const venue = await callRpc<Record<string, unknown>>(
      context.supabaseAdmin,
      "founder_create_venue",
      {
        p_user_id: context.userId,
        p_display_name: requiredString(body, "display_name", 1, 100),
        p_address_line_1: requiredString(body, "address_line_1", 1, 160),
        p_neighbourhood: requiredString(body, "neighbourhood", 1, 80),
        p_postal_code: requiredString(body, "postal_code", 2, 16),
        p_latitude: requiredNumber(body, "latitude", -90, 90),
        p_longitude: requiredNumber(body, "longitude", -180, 180),
        p_geofence_radius_metres:
          optionalInteger(body, "geofence_radius_metres", 25, 200) ?? 75,
      },
      context.requestId,
    );
    return context.respond({ venue }, 201);
  }),
};
