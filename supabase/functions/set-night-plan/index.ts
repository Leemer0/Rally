import { authenticated, readJsonObject } from "../_shared/http.ts";
import { presentPlan } from "../_shared/presenters.ts";
import { callRpc } from "../_shared/rpc.ts";
import {
  assertOnlyKeys,
  requiredUuid,
} from "../_shared/validation.ts";

export default {
  fetch: authenticated(["POST"], async (request, context) => {
    const body = await readJsonObject(request);
    assertOnlyKeys(body, ["venue_id", "idempotency_key"]);

    const plan = await callRpc<unknown>(
      context.supabaseAdmin,
      "set_night_plan",
      {
        p_user_id: context.userId,
        p_venue_id: requiredUuid(body, "venue_id"),
        p_idempotency_key: requiredUuid(body, "idempotency_key"),
      },
      context.requestId,
    );

    return context.respond({ plan: presentPlan(plan) });
  }),
};
