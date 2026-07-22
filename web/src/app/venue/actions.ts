"use server";

import { redirect } from "next/navigation";
import { createAdminClient } from "@/lib/supabase/admin";
import { getSiteUrl } from "@/lib/supabase/config";
import { createClient } from "@/lib/supabase/server";
import { isFounderAuthorized } from "@/lib/auth/founder";
import { safeNextPath } from "@/lib/auth/paths";

function field(formData: FormData, name: string) {
  const value = formData.get(name);
  return typeof value === "string" ? value.trim() : "";
}

function rawField(formData: FormData, name: string) {
  const value = formData.get(name);
  return typeof value === "string" ? value : "";
}

function optionalUuidField(formData: FormData, name: string) {
  const value = field(formData, name);
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
    value,
  )
    ? value
    : null;
}

function loginError(code: string, next?: string | null): never {
  const params = new URLSearchParams({ error: code });

  if (next) {
    params.set("next", next);
  }

  redirect(`/venue/login?${params.toString()}`);
}

function registrationError(code: string): never {
  redirect(`/venue/register?error=${encodeURIComponent(code)}`);
}

export async function signInVenue(formData: FormData) {
  const email = field(formData, "email").toLowerCase();
  const password = rawField(formData, "password");
  const next = safeNextPath(formData.get("next"));

  if (!email || !password) {
    loginError("invalid_credentials", next);
  }

  let supabase;

  try {
    supabase = await createClient();
  } catch {
    loginError("configuration", next);
  }

  const { data: authData, error: authError } =
    await supabase.auth.signInWithPassword({ email, password });

  if (authError || !authData.user) {
    loginError(
      authError?.code === "email_not_confirmed"
        ? "email_not_confirmed"
        : "invalid_credentials",
      next,
    );
  }

  if (next?.startsWith("/admin")) {
    if (!(await isFounderAuthorized(supabase))) {
      await supabase.auth.signOut({ scope: "local" });
      loginError("founder_access_required", next);
    }

    redirect(next);
  }

  // A confirmed registration may still be waiting in the private staging
  // table if the email callback was interrupted. Finalization is idempotent,
  // so signing in safely completes that hand-off before the account lookup.
  try {
    const admin = createAdminClient();
    await admin.rpc("consume_pending_venue_registration", {
      p_auth_user_id: authData.user.id,
    });
  } catch {
    // The regular account lookup below remains the source of truth. Accounts
    // with no staged registration are expected to take this path.
  }

  const { data: account, error: accountError } = await supabase
    .from("venue_accounts")
    .select("venue_id, account_status")
    .eq("auth_user_id", authData.user.id)
    .maybeSingle();

  if (accountError || !account) {
    const { error: statusError } = await supabase.functions.invoke(
      "venue-registration-status",
      { method: "GET" },
    );
    if (!statusError) {
      redirect("/venue/status");
    }

    await supabase.auth.signOut({ scope: "local" });
    loginError("not_venue", next);
  }

  const { data: venue, error: venueError } = await supabase
    .from("venues")
    .select("registration_status")
    .eq("id", account.venue_id)
    .maybeSingle();

  if (venueError || !venue) {
    await supabase.auth.signOut({ scope: "local" });
    loginError("not_venue", next);
  }

  if (
    account.account_status !== "active" ||
    venue.registration_status !== "approved"
  ) {
    redirect("/venue/status");
  }

  redirect(next?.startsWith("/dashboard") ? next : "/dashboard");
}

export async function registerVenue(formData: FormData) {
  const venueName = field(formData, "venue-name");
  const legalName = field(formData, "legal-name");
  const venueAddress = field(formData, "address");
  const legalAddress = field(formData, "legal-address");
  const contactName = field(formData, "contact-name");
  const contactTitle = field(formData, "contact-title");
  const phone = field(formData, "phone");
  const email = field(formData, "email").toLowerCase();
  const password = rawField(formData, "password");
  const authorityConfirmed = formData.get("authority") === "on";
  const existingVenueId = optionalUuidField(formData, "existingVenueId");
  const agreementVersion = process.env.VENUE_AGREEMENT_VERSION?.trim();

  if (
    !venueName ||
    !legalName ||
    !venueAddress ||
    !legalAddress ||
    !contactName ||
    !phone ||
    !email.includes("@") ||
    password.length < 10 ||
    !authorityConfirmed
  ) {
    registrationError("invalid_registration");
  }

  if (!agreementVersion) {
    registrationError("configuration");
  }

  let supabase;
  let admin;
  let siteUrl;

  try {
    supabase = await createClient();
    admin = createAdminClient();
    siteUrl = getSiteUrl();
  } catch {
    registrationError("configuration");
  }

  const registrationPayload = {
    existing_venue_id: existingVenueId,
    display_name: venueName,
    venue_address: venueAddress,
    legal_business_name: legalName,
    legal_address: legalAddress,
    primary_contact_name: contactName,
    primary_contact_title: contactTitle || null,
    business_email: email,
    business_phone: phone,
    venue_agreement_version: agreementVersion,
  };

  const { data: currentAuth } = await supabase.auth.getUser();
  if (currentAuth.user) {
    if (currentAuth.user.email?.toLowerCase() !== email) {
      registrationError("business_email_mismatch");
    }

    const { error } = await supabase.functions.invoke("register-venue", {
      body: registrationPayload,
    });
    if (error) {
      registrationError("registration_failed");
    }

    redirect("/venue/status?resubmitted=1");
  }

  const { data: signupData, error: signupError } = await supabase.auth.signUp({
    email,
    password,
    options: {
      emailRedirectTo: `${siteUrl}/auth/callback?next=/venue/status`,
    },
  });

  if (
    signupError ||
    !signupData.user ||
    signupData.user.identities?.length === 0
  ) {
    registrationError(signupError ? "registration_failed" : "account_exists");
  }

  const { error: registrationRpcError } = await admin.rpc(
    "store_pending_venue_registration",
    {
      p_auth_user_id: signupData.user.id,
      p_display_name: venueName,
      p_venue_address: venueAddress,
      p_legal_business_name: legalName,
      p_legal_address: legalAddress,
      p_primary_contact_name: contactName,
      p_primary_contact_title: contactTitle,
      p_business_email: email,
      p_business_phone: phone,
      p_venue_agreement_version: agreementVersion,
      p_existing_venue_id: existingVenueId,
    },
  );

  if (registrationRpcError) {
    await admin.auth.admin.deleteUser(signupData.user.id);
    registrationError("registration_failed");
  }

  if (signupData.session) {
    const { error: consumptionError } = await admin.rpc(
      "consume_pending_venue_registration",
      { p_auth_user_id: signupData.user.id },
    );
    if (consumptionError) {
      await admin.auth.admin.deleteUser(signupData.user.id);
      registrationError("registration_failed");
    }
    redirect("/venue/status");
  }

  redirect("/venue/login?message=registration_submitted");
}

export async function signOutVenue() {
  try {
    const supabase = await createClient();
    await supabase.auth.signOut({ scope: "local" });
  } catch {
    // A missing/expired cookie is already signed out from the browser's view.
  }

  redirect("/venue/login");
}

export async function deletePendingVenueAccount(formData: FormData) {
  const password = rawField(formData, "password");
  if (!password) {
    redirect("/venue/status?error=delete_reauthentication");
  }

  let supabase;
  try {
    supabase = await createClient();
  } catch {
    redirect("/venue/status?error=delete_failed");
  }

  const { data: userData, error: userError } = await supabase.auth.getUser();
  const email = userData.user?.email;
  if (userError || !email) {
    redirect("/venue/login?error=recovery_expired");
  }

  const { error: reauthenticationError } =
    await supabase.auth.signInWithPassword({ email, password });
  if (reauthenticationError) {
    redirect("/venue/status?error=delete_reauthentication");
  }

  const { error } = await supabase.functions.invoke(
    "request-account-deletion",
    {
      body: {
        subject_type: "venue",
        idempotency_key: crypto.randomUUID(),
      },
    },
  );
  if (error) {
    redirect("/venue/status?error=delete_failed");
  }

  try {
    await supabase.auth.signOut({ scope: "local" });
  } catch {
    // The Edge Function has already removed the Auth identity.
  }

  redirect("/venue/login?message=account_deleted");
}

export async function requestVenuePasswordReset(formData: FormData) {
  const email = field(formData, "email").toLowerCase();

  if (!email.includes("@")) {
    redirect("/venue/forgot-password?error=invalid_registration");
  }

  try {
    const supabase = await createClient();
    const siteUrl = getSiteUrl();
    await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${siteUrl}/auth/callback?next=/venue/reset-password`,
    });
  } catch {
    redirect("/venue/forgot-password?error=configuration");
  }

  // Deliberately return the same response whether the address exists or not.
  redirect("/venue/login?message=password_reset_sent");
}

export async function updateVenuePassword(formData: FormData) {
  const password = rawField(formData, "password");
  const confirmation = rawField(formData, "password-confirmation");

  if (password.length < 10 || password !== confirmation) {
    redirect("/venue/reset-password?error=password_mismatch");
  }

  let failure: "recovery_expired" | "password_update_failed" | null = null;
  let supabase: Awaited<ReturnType<typeof createClient>> | null = null;

  try {
    supabase = await createClient();
    const { data, error: userError } = await supabase.auth.getUser();

    if (userError || !data.user) {
      failure = "recovery_expired";
    } else {
      const { error } = await supabase.auth.updateUser({ password });
      if (error) {
        failure = "password_update_failed";
      }
    }
  } catch {
    failure = "password_update_failed";
  }

  if (failure === "recovery_expired") {
    redirect("/venue/login?error=recovery_expired");
  }
  if (failure) {
    redirect("/venue/reset-password?error=password_update_failed");
  }

  // The password is already changed at this point. A best-effort local sign-out
  // must not turn that success into a misleading password update failure.
  try {
    await supabase?.auth.signOut({ scope: "local" });
  } catch {
    // The login screen will establish a fresh session with the new password.
  }

  redirect("/venue/login?message=password_updated");
}
