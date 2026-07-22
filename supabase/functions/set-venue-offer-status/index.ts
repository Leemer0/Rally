import { authenticated, readJsonObject } from "../_shared/http.ts";
import { callRpc, firstRow } from "../_shared/rpc.ts";
import {
  assertOnlyKeys,
  requiredEnum,
  requiredUuid,
} from "../_shared/validation.ts";

export default {
  fetch: authenticated(["POST"], async (request, context) => {
    const body = await readJsonObject(request);
    assertOnlyKeys(body, ["offer_id", "idempotency_key", "target_status"]);

    const result = await callRpc<unknown>(
      context.supabaseAdmin,
      "set_venue_offer_status",
      {
        p_user_id: context.userId,
        p_offer_id: requiredUuid(body, "offer_id"),
        p_idempotency_key: requiredUuid(body, "idempotency_key"),
        p_target_status: requiredEnum(body, "target_status", [
          "ended",
          "archived",
        ]),
      },
      context.requestId,
    );

    return context.respond({
      offer: firstRow(
        result as Record<string, unknown>[],
        "offer status update",
      ),
    });
  }),
};
