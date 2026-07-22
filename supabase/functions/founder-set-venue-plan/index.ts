import { ApiError, authenticated, readJsonObject } from "../_shared/http.ts";
import { callRpc } from "../_shared/rpc.ts";
import {
  assertOnlyKeys,
  optionalDateTime,
  requiredEnum,
  requiredUuid,
} from "../_shared/validation.ts";

export default {
  fetch: authenticated(["POST"], async (request, context) => {
    const body = await readJsonObject(request);
    assertOnlyKeys(body, ["venue_id", "plan_code", "status", "trial_ends_at"]);

    const planCode = requiredEnum(body, "plan_code", ["free", "pro"]);
    const status = requiredEnum(body, "status", ["free", "trialing", "active"]);
    const trialEndsAt = optionalDateTime(body, "trial_ends_at");
    if (
      (planCode === "free" && status !== "free") ||
      (planCode === "pro" && status === "free") ||
      (status === "trialing" && trialEndsAt === null) ||
      (status !== "trialing" && trialEndsAt !== null)
    ) {
      throw new ApiError(
        "INVALID_REQUEST",
        "The manual plan, status, and trial end do not form a valid MVP subscription state.",
        400,
        { fields: ["plan_code", "status", "trial_ends_at"] },
      );
    }

    const subscription = await callRpc<Record<string, unknown>>(
      context.supabaseAdmin,
      "set_venue_subscription_plan",
      {
        p_user_id: context.userId,
        p_venue_id: requiredUuid(body, "venue_id"),
        p_plan_code: planCode,
        p_status: status,
        p_trial_ends_at: trialEndsAt,
      },
      context.requestId,
    );
    return context.respond({ subscription });
  }),
};
