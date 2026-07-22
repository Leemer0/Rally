import { ApiError } from "./http.ts";

interface RpcErrorLike {
  code?: string;
  message?: string;
}

interface RpcClientLike {
  rpc: (
    functionName: string,
    arguments_: Record<string, unknown>,
  ) => PromiseLike<{ data: unknown; error: RpcErrorLike | null }>;
}

interface MappedRpcError {
  status: number;
  message: string;
}

const RPC_ERRORS: Record<string, MappedRpcError> = {
  active_partner_with_logo_required: { status: 409, message: "The partner must be active and have an approved logo." },
  account_deletion_in_progress: { status: 409, message: "This account is already being deleted." },
  account_inactive: { status: 403, message: "This account is not active." },
  account_ineligible: { status: 403, message: "This account is not eligible for this action." },
  account_type_conflict: { status: 409, message: "This login is already assigned to another account type." },
  active_offer_claim_required: { status: 409, message: "An active offer claim is required." },
  active_offer_limit_reached: { status: 403, message: "The venue's active offer limit has been reached." },
  active_subscription_cancellation_required: { status: 409, message: "Cancel the active subscription before deleting this venue account." },
  age_requirement_not_met: { status: 403, message: "Outly accounts require the user to be at least 19 years old." },
  analytics_event_not_allowed: { status: 400, message: "This analytics event is not allowed." },
  analytics_event_time_invalid: { status: 400, message: "The analytics event timestamp is outside the accepted window." },
  analytics_offer_venue_mismatch: { status: 400, message: "The offer does not belong to the selected venue." },
  approved_offer_schedule_is_immutable: { status: 409, message: "An approved offer schedule cannot be changed." },
  approved_offer_version_is_immutable: { status: 409, message: "An approved offer version cannot be changed." },
  auth_user_not_found: { status: 404, message: "The authenticated account no longer exists." },
  business_email_mismatch: { status: 409, message: "The business email must match the signed-in email." },
  check_in_already_verified: { status: 409, message: "A venue check-in is already verified for this nightlife date." },
  check_in_claim_user_mismatch: { status: 403, message: "The offer claim does not belong to this account." },
  check_in_not_found: { status: 404, message: "The check-in was not found." },
  check_in_not_verified: { status: 409, message: "The check-in has not been verified." },
  check_in_offer_already_unlocked: { status: 409, message: "A different offer was already unlocked for this check-in." },
  check_in_timestamp_invalid: { status: 409, message: "The check-in timestamp could not be verified." },
  check_in_too_old_to_unlock_offer: { status: 409, message: "This check-in is too old to unlock an offer." },
  check_in_user_mismatch: { status: 403, message: "The check-in does not belong to this account." },
  claim_changes_response_required: { status: 400, message: "Explain the changes the venue must make before resubmitting." },
  consumer_account_not_found: { status: 404, message: "The consumer account was not found." },
  deletion_request_not_found: { status: 404, message: "The deletion request was not found." },
  deletion_request_not_processing: { status: 409, message: "The deletion request is not ready to complete." },
  deletion_subject_type_mismatch: { status: 409, message: "This deletion request belongs to a different account type." },
  email_confirmation_required: { status: 409, message: "Confirm the business email before completing venue registration." },
  idempotency_key_conflict: { status: 409, message: "This idempotency key was already used for different request data." },
  invalid_analytics_period: { status: 400, message: "The analytics period is invalid." },
  invalid_date_of_birth: { status: 400, message: "The date of birth is invalid." },
  invalid_deletion_subject_type: { status: 400, message: "The deletion account type is invalid." },
  invalid_first_name: { status: 400, message: "The first name is invalid." },
  invalid_gender: { status: 400, message: "The gender selection is invalid." },
  invalid_venue_name: { status: 400, message: "The venue name is invalid." },
  invalid_offer_review_decision: { status: 400, message: "The offer review decision is invalid." },
  invalid_partner_campaign_dates: { status: 400, message: "The partner campaign dates are invalid." },
  invalid_partner_campaign_parameter: { status: 400, message: "The partner campaign request is invalid." },
  invalid_subscription_state: { status: 400, message: "The requested manual venue plan state is invalid." },
  invalid_trial_end: { status: 400, message: "A trial must have a future end date, and non-trial plans cannot include one." },
  invalid_venue_coordinates: { status: 400, message: "The venue coordinates are invalid." },
  invalid_venue_parameter: { status: 400, message: "The venue request is invalid." },
  invalid_venue_review_decision: { status: 400, message: "The venue review decision is invalid." },
  founder_access_required: { status: 403, message: "Founder administrator access is required." },
  missing_partner_parameter: { status: 400, message: "Required partner information is missing." },
  offer_claim_config_missing: { status: 503, message: "Offer claiming is temporarily unavailable." },
  offer_no_longer_available: { status: 409, message: "This offer is no longer available." },
  offer_not_eligible: { status: 409, message: "This offer is not eligible for the verified check-in." },
  offer_not_pending_review: { status: 409, message: "Only the latest submitted offer version can be reviewed." },
  offer_revision_conflict: { status: 409, message: "This offer changed after the page was loaded. Reload it before editing." },
  offer_not_ready_for_approval: { status: 409, message: "The offer is not ready for approval." },
  offer_version_not_found: { status: 404, message: "The offer version was not found." },
  onboarding_required: { status: 409, message: "Complete consumer onboarding before loading Outly." },
  onboarding_already_complete: { status: 409, message: "Onboarding has already been completed." },
  partner_offer_requires_pro_venue: { status: 403, message: "Partner offers require an active Pro venue subscription." },
  partner_campaign_requires_pro_venues: { status: 403, message: "Every selected campaign venue must have active Pro partner access." },
  partner_not_found: { status: 404, message: "The partner was not found." },
  pending_venue_registration_not_found: { status: 404, message: "No pending venue registration was found for this account." },
  plan_not_cancellable: { status: 409, message: "This plan can no longer be cancelled." },
  plan_not_found: { status: 404, message: "The plan was not found." },
  protected_profile_is_immutable: { status: 409, message: "Date of birth and gender cannot be changed after onboarding." },
  unapproved_venue_cannot_be_suspended: { status: 409, message: "A venue must be approved before it can be suspended." },
  venue_account_ineligible: { status: 403, message: "The venue account cannot submit offers in its current state." },
  venue_account_not_found: { status: 404, message: "The venue account was not found." },
  venue_claim_account_unavailable: { status: 409, message: "The venue claim no longer has a reviewable account." },
  venue_claim_listing_unavailable: { status: 409, message: "The public venue listing is no longer available to claim." },
  venue_claim_not_reviewable: { status: 409, message: "This venue claim has already reached a final state." },
  venue_claim_transition_conflict: { status: 409, message: "This venue claim changed during the request. Reload and try again." },
  venue_claim_unavailable: { status: 409, message: "This venue listing is not currently available to claim." },
  venue_entitlement_missing: { status: 503, message: "The venue subscription configuration is unavailable." },
  venue_offer_already_archived: { status: 409, message: "An archived offer cannot be reopened." },
  venue_offer_must_be_ended_before_archive: { status: 409, message: "End the offer before archiving it." },
  venue_offer_not_editable: { status: 409, message: "This offer cannot be edited in its current state." },
  venue_offer_not_found: { status: 404, message: "The offer was not found for this venue account." },
  venue_offer_revision_unavailable: { status: 409, message: "This offer does not have an editable revision." },
  venue_not_found: { status: 404, message: "The venue was not found." },
  venue_registration_conflict: { status: 409, message: "This login is already linked to a different venue registration." },
  venue_unavailable: { status: 409, message: "The venue is not currently available." },
};

const INVALID_PARAMETER_MESSAGES = new Set([
  "missing_analytics_parameter",
  "missing_check_in_parameter",
  "missing_deletion_parameter",
  "missing_offer_claim_parameter",
  "missing_offer_parameter",
  "invalid_offer_revision_parameter",
  "invalid_offer_status_parameter",
  "missing_onboarding_parameter",
  "missing_plan_parameter",
  "missing_user_id",
  "missing_venue_registration_parameter",
]);

function normalizedDatabaseMessage(error: RpcErrorLike): string {
  return (error.message ?? "").trim().split("\n", 1)[0];
}

export function apiErrorFromRpc(
  error: RpcErrorLike,
  requestId: string,
  operation: string,
): ApiError {
  const databaseMessage = normalizedDatabaseMessage(error);
  const mapped = RPC_ERRORS[databaseMessage];
  if (mapped) {
    return new ApiError(databaseMessage.toUpperCase(), mapped.message, mapped.status);
  }
  if (INVALID_PARAMETER_MESSAGES.has(databaseMessage) || error.code === "22023") {
    return new ApiError(
      "INVALID_REQUEST",
      "The request does not satisfy the backend contract.",
      400,
    );
  }

  console.error(JSON.stringify({
    request_id: requestId,
    operation,
    database_code: error.code ?? "unknown",
    database_message: databaseMessage || "unknown",
  }));
  return new ApiError(
    "BACKEND_REQUEST_FAILED",
    "The backend could not complete this request.",
    500,
  );
}

export async function callRpc<T>(
  client: unknown,
  functionName: string,
  arguments_: Record<string, unknown>,
  requestId: string,
): Promise<T> {
  const { data, error } = await (client as RpcClientLike).rpc(
    functionName,
    arguments_,
  );
  if (error) throw apiErrorFromRpc(error, requestId, functionName);
  return data as T;
}

export function firstRow<T>(data: T | T[] | null, operation: string): T {
  const row = Array.isArray(data) ? data[0] : data;
  if (!row) {
    throw new ApiError(
      "BACKEND_CONTRACT_ERROR",
      `The ${operation} response was empty.`,
      500,
    );
  }
  return row;
}
