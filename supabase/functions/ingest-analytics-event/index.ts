import { authenticated, readJsonObject } from "../_shared/http.ts";
import { callRpc } from "../_shared/rpc.ts";
import {
  assertOnlyKeys,
  optionalString,
  optionalUuid,
  requiredDateTime,
  requiredEnum,
  requiredUuid,
} from "../_shared/validation.ts";

export default {
  fetch: authenticated(["POST"], async (request, context) => {
    const body = await readJsonObject(request);
    assertOnlyKeys(body, [
      "event_name",
      "venue_id",
      "offer_id",
      "client_occurred_at",
      "source",
      "app_version",
      "idempotency_key",
    ]);

    const eventId = await callRpc<number>(
      context.supabaseAdmin,
      "ingest_analytics_event",
      {
        p_user_id: context.userId,
        p_event_name: requiredEnum(body, "event_name", [
          "venue_impression",
          "venue_detail_view",
          "offer_cta_opened",
        ]),
        p_venue_id: requiredUuid(body, "venue_id"),
        p_offer_id: optionalUuid(body, "offer_id"),
        p_client_occurred_at: requiredDateTime(body, "client_occurred_at"),
        p_source: requiredEnum(body, "source", ["ios", "web"]),
        p_app_version: optionalString(body, "app_version", 1, 80),
        p_idempotency_key: requiredUuid(body, "idempotency_key"),
      },
      context.requestId,
    );

    return context.respond({ event_id: eventId }, 201);
  }),
};
