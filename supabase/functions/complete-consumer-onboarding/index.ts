import { authenticated, readJsonObject } from "../_shared/http.ts";
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

    const result = await callRpc<unknown>(
      context.supabaseAdmin,
      "complete_consumer_onboarding",
      {
        p_user_id: context.userId,
        p_first_name: requiredString(body, "first_name", 1, 50),
        p_date_of_birth: requiredDate(body, "date_of_birth"),
        p_gender: requiredEnum(body, "gender", ["man", "woman", "other"]),
        p_terms_version: requiredString(body, "terms_version", 1, 80),
        p_privacy_version: requiredString(body, "privacy_version", 1, 80),
      },
      context.requestId,
    );

    return context.respond({
      profile: firstRow(result as Record<string, unknown>[], "consumer onboarding"),
    });
  }),
};
