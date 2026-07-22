import { authenticated } from "../_shared/http.ts";
import { callRpc } from "../_shared/rpc.ts";

export default {
  fetch: authenticated(["GET"], async (_request, context) => {
    const bootstrap = await callRpc<Record<string, unknown>>(
      context.supabaseAdmin,
      "get_consumer_bootstrap",
      {
        p_user_id: context.userId,
        p_at: new Date().toISOString(),
      },
      context.requestId,
    );

    return context.respond(bootstrap);
  }),
};
