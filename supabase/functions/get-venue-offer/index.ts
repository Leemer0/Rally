import { authenticated, readJsonObject } from "../_shared/http.ts";
import { callRpc } from "../_shared/rpc.ts";
import { assertOnlyKeys, requiredUuid } from "../_shared/validation.ts";

export default {
  fetch: authenticated(["POST"], async (request, context) => {
    const body = await readJsonObject(request);
    assertOnlyKeys(body, ["offer_id"]);

    const offer = await callRpc<Record<string, unknown>>(
      context.supabaseAdmin,
      "get_venue_offer_editor",
      {
        p_user_id: context.userId,
        p_offer_id: requiredUuid(body, "offer_id"),
      },
      context.requestId,
    );

    return context.respond({ offer });
  }),
};
