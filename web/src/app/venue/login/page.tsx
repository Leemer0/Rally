import type { Metadata } from "next";
import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { VenueAuthShell } from "@/components/site/venue-auth-shell";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { signInVenue } from "@/app/venue/actions";
import { getAuthMessage } from "@/lib/auth/messages";
import { safeNextPath } from "@/lib/auth/paths";

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
  const error = getAuthMessage(params.error);
  const message = getAuthMessage(params.message);
  const next = safeNextPath(params.next);

  return (
    <VenueAuthShell title="Welcome back." copy="Sign in with the business email connected to your venue.">
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
      <form action={signInVenue} className="space-y-5">
        {next && <input type="hidden" name="next" value={next} />}
        <div className="space-y-2">
          <Label htmlFor="email">Business email</Label>
          <Input id="email" name="email" type="email" autoComplete="email" placeholder="you@venue.com" required className="h-12 bg-white/[0.035]" />
        </div>
        <div className="space-y-2">
          <div className="flex items-center justify-between"><Label htmlFor="password">Password</Label><Link href="/venue/forgot-password" className="text-xs text-white/46 hover:text-white">Forgot password?</Link></div>
          <Input id="password" name="password" type="password" autoComplete="current-password" required className="h-12 bg-white/[0.035]" />
        </div>
        <Button type="submit" size="lg" className="h-12 w-full">Sign in <ArrowRight className="size-4" /></Button>
      </form>
      <p className="mt-6 text-center text-sm text-white/42">New to Outly? <Link href="/venue/register" className="text-white underline underline-offset-4">Get started</Link></p>
    </VenueAuthShell>
  );
}
