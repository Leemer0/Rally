import "server-only";

import { createClient } from "@supabase/supabase-js";
import { getPublicSupabaseConfig } from "@/lib/supabase/config";

export function createAdminClient() {
  const { url } = getPublicSupabaseConfig();
  const secretKey = process.env.SUPABASE_SECRET_KEY?.trim();

  if (!secretKey) {
    throw new Error("SUPABASE_SECRET_KEY is not configured.");
  }

  return createClient(url, secretKey, {
    auth: {
      autoRefreshToken: false,
      detectSessionInUrl: false,
      persistSession: false,
    },
  });
}
