import type { Metadata } from "next";
import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { requestVenuePasswordReset } from "@/app/venue/actions";
import { VenueAuthShell } from "@/components/site/venue-auth-shell";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { getAuthMessage } from "@/lib/auth/messages";

export const metadata: Metadata = { title: "Reset venue password" };

type SearchParams = Promise<{ error?: string }>;

export default async function ForgotVenuePasswordPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const params = await searchParams;
  const error = getAuthMessage(params.error);

  return (
    <VenueAuthShell
      title="Reset your password."
      copy="Enter the business email connected to your venue and we’ll send a secure reset link."
    >
      {error ? (
        <p
          role="alert"
          className="mb-5 border-l-2 border-red-400/80 bg-red-400/[0.055] px-4 py-3 text-sm leading-5 text-red-100/80"
        >
          {error}
        </p>
      ) : null}
      <form action={requestVenuePasswordReset} className="space-y-5">
        <div className="space-y-2">
          <Label htmlFor="email">Business email</Label>
          <Input
            id="email"
            name="email"
            type="email"
            autoComplete="email"
            placeholder="you@venue.com"
            required
            className="h-12 bg-white/[0.035]"
          />
        </div>
        <Button type="submit" size="lg" className="h-12 w-full">
          Send reset link <ArrowRight className="size-4" />
        </Button>
      </form>
      <p className="mt-6 text-center text-sm text-white/42">
        <Link
          href="/venue/login"
          className="text-white underline underline-offset-4"
        >
          Back to sign in
        </Link>
      </p>
    </VenueAuthShell>
  );
}
