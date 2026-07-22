import { authenticated, readJsonObject } from "../_shared/http.ts";
import { callRpc } from "../_shared/rpc.ts";
import {
  assertOnlyKeys,
  optionalHttpsUrl,
  optionalString,
  optionalUuid,
  requiredEmail,
  requiredPartnerMediaPath,
  requiredString,
} from "../_shared/validation.ts";

export default {
  fetch: authenticated(["POST"], async (request, context) => {
    const body = await readJsonObject(request);
    assertOnlyKeys(body, [
      "partner_id",
      "brand_name",
      "legal_name",
      "website_url",
      "industry",
      "logo_storage_path",
      "logo_alt_text",
      "contact_name",
      "contact_email",
      "contact_phone",
    ]);

    const partner = await callRpc<Record<string, unknown>>(
      context.supabaseAdmin,
      "upsert_partner",
      {
        p_user_id: context.userId,
        p_partner_id: optionalUuid(body, "partner_id"),
        p_brand_name: requiredString(body, "brand_name", 1, 120),
        p_legal_name: requiredString(body, "legal_name", 1, 180),
        p_website_url: optionalHttpsUrl(body, "website_url"),
        p_industry: optionalString(body, "industry", 1, 120),
        p_logo_storage_path: requiredPartnerMediaPath(body, "logo_storage_path"),
        p_logo_alt_text: requiredString(body, "logo_alt_text", 1, 180),
        p_contact_name: requiredString(body, "contact_name", 1, 120),
        p_contact_email: requiredEmail(body, "contact_email"),
        p_contact_phone: optionalString(body, "contact_phone", 7, 32),
      },
      context.requestId,
    );
    return context.respond({ partner }, body.partner_id ? 200 : 201);
  }),
};
