import { authenticated, readJsonObject } from "../_shared/http.ts";
import { callRpc } from "../_shared/rpc.ts";
import {
  assertOnlyKeys,
  optionalString,
  requiredEnum,
  requiredUuid,
} from "../_shared/validation.ts";

export default {
  fetch: authenticated(["POST"], async (request, context) => {
    const body = await readJsonObject(request);
    assertOnlyKeys(body, [
      "offer_version_id",
      "decision",
      "public_response",
      "private_note",
    ]);

    const offer = await callRpc<Record<string, unknown>>(
      context.supabaseAdmin,
      "review_offer_version",
      {
        p_user_id: context.userId,
        p_offer_version_id: requiredUuid(body, "offer_version_id"),
        p_decision: requiredEnum(body, "decision", [
          "approved",
          "changes_requested",
          "rejected",
        ]),
        p_public_response: optionalString(body, "public_response", 1, 1000),
        p_private_note: optionalString(body, "private_note", 1, 4000),
      },
      context.requestId,
    );
    return context.respond({ offer });
  }),
};
