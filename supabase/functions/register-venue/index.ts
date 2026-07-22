import { authenticated, readJsonObject } from "../_shared/http.ts";
import { callRpc, firstRow } from "../_shared/rpc.ts";
import {
  assertOnlyKeys,
  optionalString,
  optionalUuid,
  requiredEmail,
  requiredString,
} from "../_shared/validation.ts";

export default {
  fetch: authenticated(["POST"], async (request, context) => {
    const body = await readJsonObject(request);

    if (body.finalize_pending === true) {
      assertOnlyKeys(body, ["finalize_pending"]);
      const registration = await callRpc<unknown>(
        context.supabaseAdmin,
        "consume_pending_venue_registration",
        { p_auth_user_id: context.userId },
        context.requestId,
      );

      return context.respond(
        { registration: firstRow(registration as Record<string, unknown>[], "venue registration") },
        201,
      );
    }

    assertOnlyKeys(body, [
      "existing_venue_id",
      "display_name",
      "venue_address",
      "legal_business_name",
      "legal_address",
      "primary_contact_name",
      "primary_contact_title",
      "business_email",
      "business_phone",
      "venue_agreement_version",
    ]);

    const registrationArguments = {
      p_auth_user_id: context.userId,
      p_display_name: requiredString(body, "display_name", 1, 100),
      p_venue_address: requiredString(body, "venue_address", 1, 160),
      p_legal_business_name: requiredString(
        body,
        "legal_business_name",
        1,
        160,
      ),
      p_legal_address: requiredString(body, "legal_address", 5, 300),
      p_primary_contact_name: requiredString(
        body,
        "primary_contact_name",
        1,
        120,
      ),
      p_primary_contact_title: optionalString(
        body,
        "primary_contact_title",
        1,
        100,
      ),
      p_business_email: requiredEmail(body, "business_email"),
      p_business_phone: requiredString(body, "business_phone", 7, 32),
      p_venue_agreement_version: requiredString(
        body,
        "venue_agreement_version",
        1,
        80,
      ),
      p_existing_venue_id: optionalUuid(body, "existing_venue_id"),
    };

    // This first transaction persists the form even when email confirmation
    // is still outstanding. The second transaction consumes it only after
    // Auth reports email_confirmed_at.
    await callRpc<unknown>(
      context.supabaseAdmin,
      "store_pending_venue_registration",
      registrationArguments,
      context.requestId,
    );

    const registration = await callRpc<unknown>(
      context.supabaseAdmin,
      "consume_pending_venue_registration",
      { p_auth_user_id: context.userId },
      context.requestId,
    );

    return context.respond(
      { registration: firstRow(registration as Record<string, unknown>[], "venue registration") },
      201,
    );
  }),
};
