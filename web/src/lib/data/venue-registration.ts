import "server-only";

import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";

export type ClaimableVenue = {
  id: string;
  name: string;
  neighbourhood: string | null;
  address: string;
};

export type VenueRegistrationStatus = {
  workflowType: "new_listing" | "existing_listing_claim";
  venueId: string;
  venueName: string;
  registrationStatus: string;
  publicationStatus: string;
  accountStatus: string | null;
  claimStatus: string | null;
  publicResponse: string | null;
  reviewedAt: string | null;
  canResubmit: boolean;
};

type JsonRecord = Record<string, unknown>;

function record(value: unknown): JsonRecord {
  return value && typeof value === "object" && !Array.isArray(value)
    ? (value as JsonRecord)
    : {};
}

function string(value: unknown) {
  return typeof value === "string" ? value : "";
}

function nullableString(value: unknown) {
  return value === null || value === undefined ? null : string(value);
}

export async function loadClaimableVenues(selectedVenueId?: string | null) {
  const admin = createAdminClient();
  const { data, error } = await admin
    .from("venues")
    .select(
      "id, display_name, neighbourhood, address_line_1, venue_accounts(auth_user_id)",
    )
    .eq("registration_status", "approved")
    .eq("publication_status", "published")
    .order("display_name");

  if (error) {
    throw new Error("Claimable venues could not be loaded.", { cause: error });
  }

  const venues = (data ?? []).flatMap((entry) => {
    const item = record(entry);
    const venueId = string(item.id);
    const accounts = Array.isArray(item.venue_accounts)
      ? item.venue_accounts
      : item.venue_accounts
        ? [item.venue_accounts]
        : [];
    const selected = selectedVenueId === venueId;

    if (!selected && accounts.length > 0) return [];

    return [{
      id: venueId,
      name: string(item.display_name),
      neighbourhood: nullableString(item.neighbourhood),
      address: string(item.address_line_1),
    } satisfies ClaimableVenue];
  });

  return venues;
}

export async function loadVenueRegistrationStatus(): Promise<
  VenueRegistrationStatus | null
> {
  const supabase = await createClient();
  const { data, error } = await supabase.functions.invoke(
    "venue-registration-status",
    { method: "GET" },
  );

  if (error || !data) return null;

  const root = record(data);
  const registration = record(root.registration);
  const workflowType = string(registration.workflow_type);

  if (
    workflowType !== "new_listing" &&
    workflowType !== "existing_listing_claim"
  ) {
    return null;
  }

  return {
    workflowType,
    venueId: string(registration.venue_id),
    venueName: string(registration.venue_name),
    registrationStatus: string(registration.registration_status),
    publicationStatus: string(registration.publication_status),
    accountStatus: nullableString(registration.account_status),
    claimStatus: nullableString(registration.claim_status),
    publicResponse: nullableString(registration.public_response),
    reviewedAt: nullableString(registration.reviewed_at),
    canResubmit: registration.can_resubmit === true,
  };
}
