import { ApiError, authenticated, readJsonObject } from "../_shared/http.ts";
import { callRpc, firstRow } from "../_shared/rpc.ts";
import {
  assertOnlyKeys,
  requiredEnum,
  requiredUuid,
} from "../_shared/validation.ts";

interface DeletionRow {
  deletion_request_id: number;
  deletion_state: string;
  subject_type: string;
}

export default {
  fetch: authenticated(["POST"], async (request, context) => {
    const body = await readJsonObject(request);
    assertOnlyKeys(body, ["subject_type", "idempotency_key"]);

    const subjectType = requiredEnum(body, "subject_type", [
      "consumer",
      "venue",
    ]);
    const preparedRows = await callRpc<unknown>(
      context.supabaseAdmin,
      "prepare_account_deletion",
      {
        p_user_id: context.userId,
        p_subject_type: subjectType,
        p_idempotency_key: requiredUuid(body, "idempotency_key"),
      },
      context.requestId,
    );
    const prepared = firstRow(
      preparedRows as DeletionRow[],
      "account deletion preparation",
    );

    const { error: deleteUserError } =
      await context.supabaseAdmin.auth.admin.deleteUser(context.userId, false);
    if (
      deleteUserError &&
      deleteUserError.status !== 404 &&
      deleteUserError.code !== "user_not_found"
    ) {
      console.error(JSON.stringify({
        request_id: context.requestId,
        operation: "delete_auth_user",
        auth_error_code: deleteUserError.code ?? "unknown",
      }));
      throw new ApiError(
        "ACCOUNT_DELETION_INCOMPLETE",
        "The deletion request was recorded, but authentication cleanup did not finish. Retry with the same idempotency key.",
        503,
        { deletion_request_id: prepared.deletion_request_id },
      );
    }

    const completedRows = await callRpc<unknown>(
      context.supabaseAdmin,
      "complete_account_deletion",
      { p_deletion_request_id: prepared.deletion_request_id },
      context.requestId,
    );
    const completed = firstRow(
      completedRows as DeletionRow[],
      "account deletion completion",
    );

    return context.respond({ deletion: completed });
  }),
};
