"use server";

import { redirect } from "next/navigation";
import { requireVenueSession } from "@/lib/auth/venue";
import { createClient } from "@/lib/supabase/server";

function value(formData: FormData, key: string) {
  const entry = formData.get(key);
  return typeof entry === "string" ? entry.trim() : "";
}

export async function deleteVenueAccount(formData: FormData) {
  const session = await requireVenueSession();
  const passwordEntry = formData.get("password");
  const password = typeof passwordEntry === "string" ? passwordEntry : "";

  if (value(formData, "venueName") !== session.venue.name) {
    redirect("/dashboard/venue?error=delete_confirmation");
  }
  if (!session.email || !password) {
    redirect("/dashboard/venue?error=delete_reauthentication");
  }

  let supabase;
  try {
    supabase = await createClient();
  } catch {
    redirect("/dashboard/venue?error=delete_failed");
  }

  const { error: reauthenticationError } =
    await supabase.auth.signInWithPassword({
      email: session.email,
      password,
    });

  if (reauthenticationError) {
    redirect("/dashboard/venue?error=delete_reauthentication");
  }

  try {
    const { error } = await supabase.functions.invoke(
      "request-account-deletion",
      {
        body: {
          subject_type: "venue",
          idempotency_key: crypto.randomUUID(),
        },
      },
    );

    if (error) throw error;
  } catch {
    redirect("/dashboard/venue?error=delete_failed");
  }

  // The Edge Function removes the Auth identity. Clear any remaining browser
  // session cookie as a best-effort local cleanup before leaving the portal.
  try {
    await supabase.auth.signOut({ scope: "local" });
  } catch {
    // The identity has already been deleted, so an Auth 404 is expected here.
  }

  redirect("/venue/login?message=account_deleted");
}
