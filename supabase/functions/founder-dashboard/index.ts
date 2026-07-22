import { authenticated } from "../_shared/http.ts";
import { callRpc } from "../_shared/rpc.ts";

export default {
  fetch: authenticated(["GET"], async (_request, context) => {
    const snapshot = await callRpc<Record<string, unknown>>(
      context.supabaseAdmin,
      "get_founder_admin_snapshot",
      { p_user_id: context.userId },
      context.requestId,
    );
    if (Array.isArray(snapshot.offer_review_queue)) {
      snapshot.offer_review_queue = snapshot.offer_review_queue.filter(
        (entry) =>
          typeof entry === "object" &&
          entry !== null &&
          (entry as Record<string, unknown>).approval_state === "pending_review",
      );
    }
    return context.respond(snapshot);
  }),
};
