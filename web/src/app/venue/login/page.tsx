import type { Metadata } from "next";
import Link from "next/link";
import { VenueAuthShell } from "@/components/site/venue-auth-shell";
import { Button } from "@/components/ui/button";
import { getAuthMessage } from "@/lib/auth/messages";
import { safeNextPath } from "@/lib/auth/paths";
import { isSupabaseConfigured } from "@/lib/supabase/config";
import { VenueLoginForm } from "@/app/venue/login/venue-login-form";

export const metadata: Metadata = { title: "Venue sign in" };

type SearchParams = Promise<{
  error?: string;
  message?: string;
  next?: string;
}>;

export default async function VenueLoginPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const params = await searchParams;
  const configured = isSupabaseConfigured();
  const error = getAuthMessage(configured ? params.error : "configuration");
  const message = getAuthMessage(params.message);
  const next = safeNextPath(params.next);
  const founder = Boolean(next?.startsWith("/admin"));

  return (
    <VenueAuthShell
      title={founder ? "Founder sign in." : "Welcome back."}
      copy={
        founder
          ? "Use your Outly founder account to continue."
          : "Sign in with the business email connected to your venue."
      }
    >
      {(error || message) && (
        <p
          role={error ? "alert" : "status"}
          className={
            error
              ? "mb-5 border-l-2 border-red-400/80 bg-red-400/[0.055] px-4 py-3 text-sm leading-5 text-red-100/80"
              : "mb-5 border-l-2 border-primary bg-primary/[0.045] px-4 py-3 text-sm leading-5 text-white/68"
          }
        >
          {error ?? message}
        </p>
      )}
      {configured ? (
        <VenueLoginForm founder={founder} next={next} />
      ) : (
        <div className="space-y-4">
          <Button type="button" size="lg" className="h-12 w-full" disabled>
            Sign in unavailable
          </Button>
          <p className="text-center text-xs leading-5 text-white/40">
            Site administrator? Finish the Supabase environment setup, then
            redeploy this site.
          </p>
          <p className="text-center text-sm text-white/42">
            <Link href="/" className="text-white underline underline-offset-4">
              Return to Outly
            </Link>
          </p>
        </div>
      )}
    </VenueAuthShell>
  );
}
