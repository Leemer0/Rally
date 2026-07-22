import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import {
  getPublicSupabaseConfig,
  isSupabaseConfigured,
} from "@/lib/supabase/config";

const protectedPrefixes = [
  "/dashboard",
  "/admin",
  "/venue/status",
  "/venue/reset-password",
];

const credentialQueryKeys = ["email", "password", "password-confirmation"];

function isProtectedPath(pathname: string) {
  return protectedPrefixes.some(
    (prefix) => pathname === prefix || pathname.startsWith(`${prefix}/`),
  );
}

function loginRedirect(request: NextRequest, error?: string) {
  const url = request.nextUrl.clone();
  url.pathname = "/venue/login";
  url.search = "";
  url.searchParams.set("next", request.nextUrl.pathname);

  if (error) {
    url.searchParams.set("error", error);
  }

  return NextResponse.redirect(url);
}

function stripCredentialsFromUrl(request: NextRequest) {
  if (
    request.method !== "GET" ||
    !credentialQueryKeys.some((key) => request.nextUrl.searchParams.has(key))
  ) {
    return null;
  }

  const url = request.nextUrl.clone();
  credentialQueryKeys.forEach((key) => url.searchParams.delete(key));

  const response = NextResponse.redirect(url, 303);
  response.headers.set("Cache-Control", "private, no-store");
  response.headers.set("Referrer-Policy", "no-referrer");
  return response;
}

export async function updateSession(request: NextRequest) {
  const credentialRedirect = stripCredentialsFromUrl(request);
  if (credentialRedirect) {
    return credentialRedirect;
  }

  if (!isSupabaseConfigured()) {
    return isProtectedPath(request.nextUrl.pathname)
      ? loginRedirect(request, "configuration")
      : NextResponse.next({ request });
  }

  const { url, publishableKey } = getPublicSupabaseConfig();
  let response = NextResponse.next({ request });

  const supabase = createServerClient(url, publishableKey, {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(cookiesToSet, headersToSet) {
        cookiesToSet.forEach(({ name, value }) => {
          request.cookies.set(name, value);
        });

        response = NextResponse.next({ request });

        cookiesToSet.forEach(({ name, value, options }) => {
          response.cookies.set(name, value, options);
        });

        Object.entries(headersToSet).forEach(([name, value]) => {
          response.headers.set(name, value);
        });
      },
    },
  });

  const { data, error } = await supabase.auth.getClaims();

  if (
    isProtectedPath(request.nextUrl.pathname) &&
    (error || !data?.claims?.sub)
  ) {
    const redirectResponse = loginRedirect(request);

    response.cookies.getAll().forEach((cookie) => {
      redirectResponse.cookies.set(cookie);
    });

    redirectResponse.headers.set("Cache-Control", "private, no-store");
    return redirectResponse;
  }

  return response;
}
