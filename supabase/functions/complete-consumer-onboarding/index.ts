import { authenticated, readJsonObject } from "../_shared/http.ts";
import { sendConsumerWelcomeEmail } from "../_shared/email.ts";
import { callRpc, firstRow } from "../_shared/rpc.ts";
import {
  assertOnlyKeys,
  requiredDate,
  requiredEnum,
  requiredString,
} from "../_shared/validation.ts";

export default {
  fetch: authenticated(["POST"], async (request, context) => {
    const body = await readJsonObject(request);
    assertOnlyKeys(body, [
      "first_name",
      "date_of_birth",
      "gender",
      "terms_version",
      "privacy_version",
    ]);

    const firstName = requiredString(body, "first_name", 1, 50);
    const result = await callRpc<unknown>(
      context.supabaseAdmin,
      "complete_consumer_onboarding",
      {
        p_user_id: context.userId,
        p_first_name: firstName,
        p_date_of_birth: requiredDate(body, "date_of_birth"),
        p_gender: requiredEnum(body, "gender", ["man", "woman", "other"]),
        p_terms_version: requiredString(body, "terms_version", 1, 80),
        p_privacy_version: requiredString(body, "privacy_version", 1, 80),
      },
      context.requestId,
    );

    try {
      const { data } = await context.supabaseAdmin.auth.admin.getUserById(
        context.userId,
      );
      if (data.user?.email) {
        await sendConsumerWelcomeEmail({
          userId: context.userId,
          email: data.user.email,
          firstName,
        });
      }
    } catch {
      // Onboarding is already committed. Email delivery is deliberately
      // best-effort so a provider outage never turns success into an error.
    }

    return context.respond({
      profile: firstRow(result as Record<string, unknown>[], "consumer onboarding"),
    });
  }),
};
