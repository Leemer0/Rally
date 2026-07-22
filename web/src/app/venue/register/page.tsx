import type { Metadata } from "next";
import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { VenueAuthShell } from "@/components/site/venue-auth-shell";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { registerVenue } from "@/app/venue/actions";
import { getAuthMessage } from "@/lib/auth/messages";
import { loadClaimableVenues } from "@/lib/data/venue-registration";

export const metadata: Metadata = { title: "Venue access" };

type SearchParams = Promise<{ error?: string; resubmit?: string }>;

export default async function VenueRegisterPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const params = await searchParams;
  const error = getAuthMessage(params.error);
  let venues = [] as Awaited<ReturnType<typeof loadClaimableVenues>>;

  try {
    venues = await loadClaimableVenues(params.resubmit);
  } catch {
    // Registration itself will fail closed with a configuration message. The
    // page remains useful for a new listing when the backend is temporarily down.
  }

  const resubmission = params.resubmit
    ? venues.find((venue) => venue.id === params.resubmit) ?? null
    : null;

  return (
    <VenueAuthShell
      title={resubmission ? "Update your access request." : "Create your venue account."}
      copy={
        resubmission
          ? `Resubmit the requested business details for ${resubmission.name}.`
          : "Claim an existing Outly listing or submit a new venue for review."
      }
    >
      {error && (
        <p
          role="alert"
          className="mb-5 border-l-2 border-red-400/80 bg-red-400/[0.055] px-4 py-3 text-sm leading-5 text-red-100/80"
        >
          {error}
        </p>
      )}
      <form action={registerVenue} className="space-y-5">
        {resubmission ? (
          <div className="border-l-2 border-primary bg-primary/[0.045] px-4 py-3">
            <input type="hidden" name="existingVenueId" value={resubmission.id} />
            <p className="text-sm font-medium text-white/82">{resubmission.name}</p>
            <p className="mt-1 text-xs text-white/42">
              {resubmission.neighbourhood || "Toronto"} · Existing Outly listing
            </p>
          </div>
        ) : venues.length ? (
          <div className="space-y-2">
            <Label htmlFor="existing-venue-id">Is your venue already on Outly?</Label>
            <select
              id="existing-venue-id"
              name="existingVenueId"
              defaultValue=""
              className="h-12 w-full border border-white/10 bg-white/[0.035] px-3 text-sm text-white outline-none focus:border-primary/60"
            >
              <option value="" className="bg-[#0b0e13]">No — create a new listing</option>
              {venues.map((venue) => (
                <option key={venue.id} value={venue.id} className="bg-[#0b0e13]">
                  {venue.name}{venue.neighbourhood ? ` — ${venue.neighbourhood}` : ""}
                </option>
              ))}
            </select>
            <p className="text-[11px] leading-5 text-white/34">
              Existing listings stay live while Outly verifies the business account.
            </p>
          </div>
        ) : null}
        <div className="grid gap-5 sm:grid-cols-2">
          <Field
            id="venue-name"
            label="Venue name"
            placeholder="Your venue"
            defaultValue={resubmission?.name}
          />
          <Field id="legal-name" label="Legal business name" placeholder="Business Inc." />
        </div>
        <Field
          id="address"
          label="Venue address"
          placeholder="Street address, city"
          autoComplete="street-address"
          defaultValue={resubmission?.address}
        />
        <Field id="legal-address" label="Legal business address" placeholder="Street address, city" autoComplete="street-address" />
        <div className="grid gap-5 sm:grid-cols-2">
          <Field id="contact-name" label="Contact name" placeholder="First and last name" autoComplete="name" />
          <Field id="contact-title" label="Role (optional)" placeholder="General manager" required={false} />
        </div>
        <Field id="phone" label="Business phone" placeholder="(416) 555-0123" type="tel" autoComplete="tel" />
        <Field id="email" label="Business email" placeholder="you@venue.com" type="email" autoComplete="email" />
        <Field id="password" label="Password" placeholder="At least 10 characters" type="password" autoComplete="new-password" minLength={10} />
        <label className="flex gap-3 text-xs leading-5 text-white/46">
          <input name="authority" type="checkbox" required className="mt-1 size-4 accent-[#c7ff3d]" />
          <span>
            I confirm I’m authorized to manage this venue and agree to the{" "}
            <Link
              href="/terms"
              target="_blank"
              rel="noreferrer"
              className="text-white underline decoration-white/30 underline-offset-4"
            >
              Terms of Service
            </Link>{" "}
            and{" "}
            <Link
              href="/privacy"
              target="_blank"
              rel="noreferrer"
              className="text-white underline decoration-white/30 underline-offset-4"
            >
              Privacy Policy
            </Link>
            .
          </span>
        </label>
        <Button type="submit" size="lg" className="h-12 w-full">Submit for review <ArrowRight className="size-4" /></Button>
      </form>
      <p className="mt-6 text-center text-sm text-white/42">Already registered? <Link href="/venue/login" className="text-white underline underline-offset-4">Sign in</Link></p>
    </VenueAuthShell>
  );
}

function Field({ id, label, placeholder, type = "text", autoComplete, minLength, required = true, defaultValue }: { id: string; label: string; placeholder: string; type?: string; autoComplete?: string; minLength?: number; required?: boolean; defaultValue?: string }) {
  return <div className="space-y-2"><Label htmlFor={id}>{label}</Label><Input id={id} name={id} type={type} placeholder={placeholder} autoComplete={autoComplete} minLength={minLength} required={required} defaultValue={defaultValue} className="h-12 bg-white/[0.035]" /></div>;
}
