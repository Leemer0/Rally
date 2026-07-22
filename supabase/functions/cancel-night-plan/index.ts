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
    assertOnlyKeys(body, ["plan_id"]);

    const plan = await callRpc<unknown>(
      context.supabaseAdmin,
      "cancel_night_plan",
      {
        p_user_id: context.userId,
        p_plan_id: requiredUuid(body, "plan_id"),
      },
      context.requestId,
    );

    return context.respond({ plan: presentPlan(plan) });
  }),
};
