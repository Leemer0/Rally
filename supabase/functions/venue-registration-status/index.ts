import { authenticated } from "../_shared/http.ts";
import { callRpc } from "../_shared/rpc.ts";

export default {
  fetch: authenticated(["GET"], async (_request, context) => {
    const registration = await callRpc<Record<string, unknown>>(
      context.supabaseAdmin,
      "get_venue_registration_status",
      { p_user_id: context.userId },
      context.requestId,
    );

    return context.respond({ registration });
  }),
};
