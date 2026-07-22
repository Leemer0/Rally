const messages: Record<string, string> = {
  account_deleted: "Your venue account has been permanently deleted.",
  account_exists: "An account already exists for that business email. Sign in instead.",
  business_email_mismatch: "Use the same business email as the signed-in venue account.",
  configuration: "Venue access is not configured yet. Please try again shortly.",
  email_not_confirmed: "Confirm your email before signing in.",
  founder_access_required: "That account does not have founder access.",
  invalid_credentials: "The email or password is incorrect.",
  invalid_registration: "Check the highlighted account details and try again.",
  not_venue: "That login is not connected to a venue account.",
  password_mismatch: "Use at least 10 characters and make sure both passwords match.",
  password_reset_sent: "If that business email is registered, a password reset link is on its way.",
  password_update_failed: "That password could not be saved. Request a new reset link and try again.",
  password_updated: "Your password was updated. Sign in to continue.",
  recovery_expired: "That password reset link is invalid or has expired. Request a new one.",
  registration_failed: "We could not submit this registration. No venue account was created.",
  registration_submitted: "Registration submitted. Confirm your email, then sign in to check its status.",
  registration_resubmitted: "Your updated venue access request is back in review.",
};

export function getAuthMessage(code?: string) {
  if (!code) {
    return null;
  }

  return messages[code] ?? null;
}
