import type { Metadata } from "next";
import { ArrowRight } from "lucide-react";
import { updateVenuePassword } from "@/app/venue/actions";
import { VenueAuthShell } from "@/components/site/venue-auth-shell";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { getAuthMessage } from "@/lib/auth/messages";

export const metadata: Metadata = { title: "Choose a new password" };
export const dynamic = "force-dynamic";

type SearchParams = Promise<{ error?: string }>;

export default async function ResetVenuePasswordPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const params = await searchParams;
  const error = getAuthMessage(params.error);

  return (
    <VenueAuthShell
      title="Choose a new password."
      copy="Use at least 10 characters. You’ll sign in again after the password is saved."
    >
      {error ? (
        <p
          role="alert"
          className="mb-5 border-l-2 border-red-400/80 bg-red-400/[0.055] px-4 py-3 text-sm leading-5 text-red-100/80"
        >
          {error}
        </p>
      ) : null}
      <form action={updateVenuePassword} className="space-y-5">
        <div className="space-y-2">
          <Label htmlFor="password">New password</Label>
          <Input
            id="password"
            name="password"
            type="password"
            autoComplete="new-password"
            minLength={10}
            required
            className="h-12 bg-white/[0.035]"
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="password-confirmation">Confirm new password</Label>
          <Input
            id="password-confirmation"
            name="password-confirmation"
            type="password"
            autoComplete="new-password"
            minLength={10}
            required
            className="h-12 bg-white/[0.035]"
          />
        </div>
        <Button type="submit" size="lg" className="h-12 w-full">
          Save password <ArrowRight className="size-4" />
        </Button>
      </form>
    </VenueAuthShell>
  );
}
