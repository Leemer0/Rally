import { authenticated } from "../_shared/http.ts";
import { callRpc } from "../_shared/rpc.ts";

export default {
  fetch: authenticated(["POST"], async (_request, context) => {
    const authorized = await callRpc<boolean>(
      context.supabaseAdmin,
      "has_founder_access",
      { p_user_id: context.userId },
      context.requestId,
    );

    return context.respond({ authorized });
  }),
};
