import { NextResponse, type NextRequest } from "next/server";
import { safeNextPath } from "@/lib/auth/paths";
import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";

function privateRedirect(url: URL) {
  const response = NextResponse.redirect(url);
  response.headers.set(
    "Cache-Control",
    "private, no-cache, no-store, must-revalidate, max-age=0",
  );
  response.headers.set("Expires", "0");
  response.headers.set("Pragma", "no-cache");
  return response;
}

export async function GET(request: NextRequest) {
  const code = request.nextUrl.searchParams.get("code");
  const next = safeNextPath(request.nextUrl.searchParams.get("next"));
  const loginUrl = new URL("/venue/login", request.url);

  if (!code) {
    loginUrl.searchParams.set("error", "invalid_credentials");
    return privateRedirect(loginUrl);
  }

  try {
    const supabase = await createClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);

    if (error) {
      loginUrl.searchParams.set("error", "invalid_credentials");
      return privateRedirect(loginUrl);
    }

    if ((next ?? "/venue/status") === "/venue/status") {
      const { data: userData, error: userError } = await supabase.auth.getUser();
      if (userError || !userData.user) {
        loginUrl.searchParams.set("error", "invalid_credentials");
        return privateRedirect(loginUrl);
      }

      const admin = createAdminClient();
      const { error: registrationError } = await admin.rpc(
        "consume_pending_venue_registration",
        { p_auth_user_id: userData.user.id },
      );

      if (registrationError) {
        await supabase.auth.signOut({ scope: "local" });
        loginUrl.searchParams.set("error", "registration_failed");
        return privateRedirect(loginUrl);
      }
    }
  } catch {
    loginUrl.searchParams.set("error", "configuration");
    return privateRedirect(loginUrl);
  }

  return privateRedirect(new URL(next ?? "/venue/status", request.url));
}
