import { ApiError, authenticated, readJsonObject } from "../_shared/http.ts";
import { callRpc } from "../_shared/rpc.ts";
import {
  assertOnlyKeys,
  optionalDateTime,
  optionalInteger,
  optionalString,
  requiredDateTime,
  requiredHttpsUrl,
  requiredString,
  requiredUuid,
  requiredUuidArray,
} from "../_shared/validation.ts";

export default {
  fetch: authenticated(["POST"], async (request, context) => {
    const body = await readJsonObject(request);
    assertOnlyKeys(body, [
      "partner_id",
      "venue_ids",
      "internal_name",
      "public_title",
      "short_explanation",
      "cta_label",
      "destination_url",
      "fine_print",
      "sponsor_disclosure",
      "claim_duration_seconds",
      "starts_at",
      "ends_at",
      "total_claim_limit",
      "per_user_limit",
      "discovery_badge_label",
      "discovery_icon_key",
    ]);

    const startsAt = requiredDateTime(body, "starts_at");
    const endsAt = optionalDateTime(body, "ends_at");
    if (endsAt && Date.parse(endsAt) <= Date.parse(startsAt)) {
      throw new ApiError(
        "INVALID_REQUEST",
        "ends_at must be after starts_at.",
        400,
        { fields: ["starts_at", "ends_at"] },
      );
    }

    const campaign = await callRpc<Record<string, unknown>>(
      context.supabaseAdmin,
      "create_partner_campaign_offer",
      {
        p_user_id: context.userId,
        p_partner_id: requiredUuid(body, "partner_id"),
        p_venue_ids: requiredUuidArray(body, "venue_ids", 100),
        p_internal_name: requiredString(body, "internal_name", 1, 160),
        p_public_title: requiredString(body, "public_title", 1, 140),
        p_short_explanation: optionalString(
          body,
          "short_explanation",
          1,
          240,
        ),
        p_cta_label: requiredString(body, "cta_label", 1, 60),
        p_destination_url: requiredHttpsUrl(body, "destination_url"),
        p_fine_print: optionalString(body, "fine_print", 1, 1000),
        p_sponsor_disclosure: requiredString(
          body,
          "sponsor_disclosure",
          1,
          240,
        ),
        p_claim_duration_seconds: optionalInteger(
          body,
          "claim_duration_seconds",
          1,
          86_400,
        ),
        p_starts_at: startsAt,
        p_ends_at: endsAt,
        p_total_claim_limit: optionalInteger(
          body,
          "total_claim_limit",
          1,
          2_147_483_647,
        ),
        p_per_user_limit:
          optionalInteger(body, "per_user_limit", 1, 100) ?? 1,
        p_discovery_badge_label:
          optionalString(body, "discovery_badge_label", 1, 60) ??
          "Outly exclusive",
        p_discovery_icon_key:
          optionalString(body, "discovery_icon_key", 1, 80) ??
          "outly-winged-o",
      },
      context.requestId,
    );

    // The RPC deliberately returns only identifiers/counts. The external
    // destination remains absent from discovery and pre-claim responses.
    return context.respond({ campaign }, 201);
  }),
};
