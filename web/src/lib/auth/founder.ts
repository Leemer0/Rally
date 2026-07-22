import "server-only";

import { redirect } from "next/navigation";
import type { SupabaseClient } from "@supabase/supabase-js";
import { createClient } from "@/lib/supabase/server";

type FounderSession = {
  userId: string;
  email: string | null;
};

function isAuthorizedResponse(value: unknown) {
  if (typeof value !== "object" || value === null) {
    return false;
  }

  if ("authorized" in value && value.authorized === true) {
    return true;
  }

  return (
    "data" in value &&
    typeof value.data === "object" &&
    value.data !== null &&
    "authorized" in value.data &&
    value.data.authorized === true
  );
}

export async function isFounderAuthorized(supabase: SupabaseClient) {
  const functionName = process.env.SUPABASE_FOUNDER_ACCESS_FUNCTION?.trim();

  if (!functionName) {
    return false;
  }

  const { data, error } = await supabase.functions.invoke(functionName, {
    body: {},
  });

  return !error && isAuthorizedResponse(data);
}

export async function requireFounderSession(): Promise<FounderSession> {
  let supabase;

  try {
    supabase = await createClient();
  } catch {
    redirect("/venue/login?error=configuration&next=/admin");
  }

  const { data, error } = await supabase.auth.getClaims();
  const claims = data?.claims;
  const userId = claims?.sub;

  if (error || typeof userId !== "string") {
    redirect("/venue/login?next=/admin");
  }

  if (!(await isFounderAuthorized(supabase))) {
    redirect("/venue/login?error=founder_access_required&next=/admin");
  }

  const email = claims?.email;

  return {
    userId,
    email: typeof email === "string" ? email : null,
  };
}
