import "server-only";

import { cache } from "react";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export type VenueSession = {
  userId: string;
  email: string | null;
  accountStatus: string;
  venue: {
    id: string;
    slug: string;
    name: string;
    registrationStatus: string;
    publicationStatus: string;
    neighbourhood: string | null;
    city: string | null;
    timezone: string;
  };
};

export const requireVenueSession = cache(async (
  requireActive = true,
): Promise<VenueSession> => {
  let supabase;

  try {
    supabase = await createClient();
  } catch {
    redirect("/venue/login?error=configuration");
  }

  const { data: claimsData, error: claimsError } =
    await supabase.auth.getClaims();
  const claims = claimsData?.claims;
  const userId = claims?.sub;

  if (claimsError || typeof userId !== "string") {
    redirect("/venue/login?next=/dashboard");
  }

  const { data: account, error: accountError } = await supabase
    .from("venue_accounts")
    .select("auth_user_id, venue_id, account_status")
    .eq("auth_user_id", userId)
    .maybeSingle();

  if (accountError || !account) {
    redirect("/venue/login?error=not_venue");
  }

  const { data: venue, error: venueError } = await supabase
    .from("venues")
    .select(
      "id, slug, display_name, registration_status, publication_status, neighbourhood, city, timezone",
    )
    .eq("id", account.venue_id)
    .maybeSingle();

  if (venueError || !venue) {
    redirect("/venue/login?error=not_venue");
  }

  const ready =
    account.account_status === "active" &&
    venue.registration_status === "approved";

  if (requireActive && !ready) {
    redirect("/venue/status");
  }

  const email = claims?.email;

  return {
    userId,
    email: typeof email === "string" ? email : null,
    accountStatus: account.account_status,
    venue: {
      id: venue.id,
      slug: venue.slug,
      name: venue.display_name,
      registrationStatus: venue.registration_status,
      publicationStatus: venue.publication_status,
      neighbourhood: venue.neighbourhood,
      city: venue.city,
      timezone: venue.timezone,
    },
  } satisfies VenueSession;
});
