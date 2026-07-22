import type { Metadata } from "next";
import { ArrowRight, Clock3, LogOut, ShieldCheck } from "lucide-react";
import Link from "next/link";
import { redirect } from "next/navigation";
import { BrandMark } from "@/components/brand/mark";
import { Button } from "@/components/ui/button";
import {
  deletePendingVenueAccount,
  signOutVenue,
} from "@/app/venue/actions";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { loadVenueRegistrationStatus } from "@/lib/data/venue-registration";
import { cn } from "@/lib/utils";

export const metadata: Metadata = { title: "Venue status" };
export const dynamic = "force-dynamic";

const statusCopy: Record<string, { title: string; copy: string }> = {
  approved: {
    title: "Your listing is approved.",
    copy: "Your venue login is being activated. Check back shortly.",
  },
  changes_requested: {
    title: "We need one more detail.",
    copy: "The Outly team will contact the business email on file with the requested change.",
  },
  pending_review: {
    title: "Your venue is in review.",
    copy: "We’ll email the business contact when the listing is approved or if anything is missing.",
  },
  rejected: {
    title: "This listing was not approved.",
    copy: "Contact the Outly team if you believe this decision was made in error.",
  },
  suspended: {
    title: "Venue access is paused.",
    copy: "Contact the Outly team to resolve the account status.",
  },
};

type SearchParams = Promise<{ resubmitted?: string; error?: string }>;

export default async function VenueStatusPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const [params, registration] = await Promise.all([
    searchParams,
    loadVenueRegistrationStatus(),
  ]);

  if (!registration) {
    redirect("/venue/login?error=not_venue");
  }

  if (
    registration.accountStatus === "active" &&
    registration.registrationStatus === "approved" &&
    (!registration.claimStatus || registration.claimStatus === "approved")
  ) {
    redirect("/dashboard");
  }

  const effectiveStatus = registration.claimStatus ?? registration.registrationStatus;
  const status = registration.workflowType === "existing_listing_claim"
    ? claimStatusCopy[effectiveStatus] ?? {
        title: "Your venue access is being prepared.",
        copy: "We’ll email the business contact when the next step is ready.",
      }
    : statusCopy[effectiveStatus] ?? {
    title: "Your venue account is being prepared.",
    copy: "We’ll email the business contact when the next step is ready.",
  };

  return (
    <main className="flex min-h-[100dvh] items-center justify-center bg-[#080b10] px-5 py-12">
      <div className="w-full max-w-lg">
        <BrandMark className="h-9 w-auto" />
        {params.resubmitted === "1" ? (
          <p className="mt-8 border-l-2 border-primary bg-primary/[0.045] px-4 py-3 text-sm text-white/68">
            Your updated access request is back in review.
          </p>
        ) : null}
        <div className="mt-12 border-y border-white/10 py-10">
          <div className="flex size-11 items-center justify-center rounded-full border border-primary/30 bg-primary/[0.06] text-primary">
            {effectiveStatus === "approved" ? (
              <ShieldCheck className="size-5" />
            ) : (
              <Clock3 className="size-5" />
            )}
          </div>
          <p className="mt-8 font-mono text-[10px] uppercase tracking-[0.18em] text-primary">
            {registration.venueName}
          </p>
          <h1 className="mt-3 text-4xl font-medium tracking-[-0.04em]">
            {status.title}
          </h1>
          <p className="mt-4 max-w-md text-sm leading-6 text-white/48">
            {status.copy}
          </p>
          {registration.publicResponse ? (
            <div className="mt-6 border-l-2 border-white/16 pl-4">
              <p className="font-mono text-[9px] uppercase tracking-[.16em] text-white/34">
                Note from Outly
              </p>
              <p className="mt-2 text-sm leading-6 text-white/68">
                {registration.publicResponse}
              </p>
            </div>
          ) : null}
          {registration.canResubmit ? (
            <Link
              href={`/venue/register?resubmit=${encodeURIComponent(registration.venueId)}`}
              className={cn(
                "mt-7 inline-flex min-h-11 items-center justify-center gap-2 bg-white px-5 text-sm font-medium text-black transition-opacity hover:opacity-90",
              )}
            >
              Update access request <ArrowRight className="size-4" />
            </Link>
          ) : null}
        </div>
        <div className="mt-6 flex items-center justify-between gap-4">
          <a
            href="mailto:support@getoutly.app?subject=Venue%20account%20status"
            className="text-sm text-white/48 underline underline-offset-4 hover:text-white"
          >
            Contact support
          </a>
          <form action={signOutVenue}>
            <Button type="submit" variant="outline" className="border-white/12">
              <LogOut className="size-4" /> Sign out
            </Button>
          </form>
        </div>
        <details
          open={Boolean(params.error)}
          className="mt-10 border-t border-white/8 pt-5"
        >
          <summary className="cursor-pointer text-xs text-white/34 hover:text-white/58">
            Delete this business account
          </summary>
          <div className="mt-4 border border-destructive/20 bg-destructive/[0.025] p-4">
            <p className="text-xs leading-5 text-white/42">
              This permanently removes the login and submitted business details. An existing public venue listing remains unchanged.
            </p>
            {params.error ? (
              <p role="alert" className="mt-3 text-xs text-destructive">
                {params.error === "delete_reauthentication"
                  ? "The password was incorrect. Nothing was deleted."
                  : "The account could not be deleted. Try again or contact Outly support."}
              </p>
            ) : null}
            <form action={deletePendingVenueAccount} className="mt-4 space-y-3">
              <div className="space-y-2">
                <Label htmlFor="status-delete-password" className="text-xs text-white/54">
                  Confirm your password
                </Label>
                <Input
                  id="status-delete-password"
                  name="password"
                  type="password"
                  autoComplete="current-password"
                  required
                  className="h-11 border-destructive/20 bg-black/20"
                />
              </div>
              <Button type="submit" variant="destructive">
                Permanently delete account
              </Button>
            </form>
          </div>
        </details>
      </div>
    </main>
  );
}

const claimStatusCopy: Record<string, { title: string; copy: string }> = {
  pending_review: {
    title: "Your access request is in review.",
    copy: "The public listing stays live while Outly verifies the business account.",
  },
  changes_requested: {
    title: "We need an update.",
    copy: "Review the note below, update the business details, and resubmit.",
  },
  approved: {
    title: "Venue access approved.",
    copy: "Your dashboard access is being activated. Check back shortly.",
  },
  rejected: {
    title: "This access request was not approved.",
    copy: "The public venue listing is unchanged. Contact Outly if you believe this decision was made in error.",
  },
};
