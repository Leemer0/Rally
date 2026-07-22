import Image from "next/image";
import {
  AlertCircle,
  Clock3,
  ExternalLink,
  LockKeyhole,
  MapPin,
  ShieldCheck,
} from "lucide-react";
import { deleteVenueAccount } from "@/app/dashboard/venue/actions";
import { DashboardUnavailable } from "@/components/dashboard/dashboard-unavailable";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { requireVenueSession } from "@/lib/auth/venue";
import { loadVenueDashboardSnapshot } from "@/lib/data/venue-dashboard";
import { cn } from "@/lib/utils";

type SearchParams = Promise<{ error?: string }>;

export default async function VenueProfilePage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const params = await searchParams;
  const session = await requireVenueSession();
  const result = await loadVenueDashboardSnapshot(session.userId);

  if (!result.data) {
    return (
      <DashboardUnavailable
        configuration={result.error === "configuration"}
        title="We couldn’t load your venue profile."
      />
    );
  }

  const snapshot = result.data;
  const venue = snapshot.venue;
  const mapsHref = venue.address
    ? `https://maps.apple.com/?q=${encodeURIComponent(venue.address)}`
    : null;

  return (
    <div className="space-y-8">
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
        <div>
          <p className="font-mono text-[10px] uppercase tracking-[0.17em] text-primary">
            Venue profile
          </p>
          <h1 className="mt-2 text-3xl font-medium tracking-[-0.035em] sm:text-4xl">
            {venue.name}
          </h1>
          <p className="mt-2 text-sm text-white/40">
            The approved listing currently used by Outly discovery.
          </p>
        </div>
        <Badge
          variant="outline"
          className={cn(
            "h-7 rounded-sm px-2.5 capitalize",
            venue.publicationStatus === "published"
              ? "border-primary/25 text-primary"
              : "border-white/12 text-white/48",
          )}
        >
          {presentStatus(venue.publicationStatus)}
        </Badge>
      </div>

      <div className="grid gap-5 xl:grid-cols-[1.1fr_.9fr]">
        <section className="rounded-lg border border-white/10 bg-card p-5 sm:p-7">
          <div className="flex items-start justify-between gap-4 border-b border-white/10 pb-5">
            <div>
              <h2 className="font-medium">Listing details</h2>
              <p className="mt-1 text-xs text-white/34">
                Read-only while venue profile editing is being connected.
              </p>
            </div>
            <Badge
              variant="outline"
              className="rounded-sm border-primary/25 text-primary"
            >
              <ShieldCheck className="size-3" />
              {presentStatus(venue.registrationStatus)}
            </Badge>
          </div>

          <dl className="mt-6 grid gap-x-6 gap-y-5 sm:grid-cols-2">
            <ReadOnlyField label="Venue name" value={venue.name} />
            <ReadOnlyField
              label="Neighbourhood"
              value={venue.neighbourhood ?? session.venue.city ?? "Not set"}
            />
            <ReadOnlyField label="Listing slug" value={venue.slug || "Not set"} />
            <ReadOnlyField
              label="Business email"
              value={session.email ?? "Not available"}
            />
            <ReadOnlyField
              label="Time zone"
              value={session.venue.timezone || "Not set"}
            />
            <ReadOnlyField
              label="Account status"
              value={presentStatus(venue.accountStatus)}
            />
          </dl>

          <div className="mt-6 border-t border-white/10 pt-6">
            <p className="text-xs text-white/36">Address</p>
            <p className="mt-2 flex items-start gap-2 text-sm text-white/72">
              <MapPin className="mt-0.5 size-4 shrink-0 text-primary" />
              {venue.address || "No address is available in the approved listing."}
            </p>
            {mapsHref ? (
              <a
                href={mapsHref}
                target="_blank"
                rel="noreferrer"
                className="mt-3 inline-flex min-h-9 items-center gap-1.5 text-xs text-white/44 hover:text-white"
              >
                Open in Apple Maps <ExternalLink className="size-3" />
              </a>
            ) : null}
          </div>

          <div className="mt-6 flex items-start gap-3 border-l-2 border-white/14 bg-white/[0.02] p-4">
            <LockKeyhole className="mt-0.5 size-4 shrink-0 text-white/38" />
            <div>
              <p className="text-sm font-medium">Profile editing is not connected yet</p>
              <p className="mt-1 text-xs leading-5 text-white/38">
                Contact Outly support when an approved name, address, or neighbourhood needs to change.
              </p>
            </div>
          </div>
        </section>

        <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
          <div className="relative h-56">
            <Image
              src="/brand/nightlife.png"
              alt="Outly nightlife discovery background"
              fill
              sizes="(max-width: 1280px) 100vw, 35vw"
              className="object-cover object-center opacity-72"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-card via-card/15 to-transparent" />
          </div>
          <div className="p-5 sm:p-6">
            <p className="font-mono text-[9px] uppercase tracking-[.16em] text-primary">
              Discovery preview
            </p>
            <h2 className="mt-3 text-2xl font-medium">{venue.name}</h2>
            <p className="mt-1 text-sm text-white/42">
              {venue.neighbourhood ?? session.venue.city ?? "Toronto"}
            </p>
            <div className="mt-5 grid grid-cols-2 gap-4 border-t border-white/8 pt-4 text-xs">
              <div>
                <p className="text-white/34">Publication</p>
                <p className="mt-1 text-white/70">
                  {presentStatus(venue.publicationStatus)}
                </p>
              </div>
              <div>
                <p className="text-white/34">Plan</p>
                <p className="mt-1 text-white/70">
                  {presentStatus(snapshot.subscription.planCode)}
                </p>
              </div>
            </div>
          </div>
        </section>
      </div>

      <section className="rounded-lg border border-white/10 bg-card p-5 sm:p-7">
        <div className="flex items-start gap-3">
          <Clock3 className="mt-0.5 size-4 shrink-0 text-white/36" />
          <div>
            <h2 className="font-medium">Venue hours</h2>
            <p className="mt-2 max-w-2xl text-sm leading-6 text-white/40">
              Hours are not included in the current dashboard snapshot, so this page does not show editable placeholders. The hours editor is not connected yet.
            </p>
            <p className="mt-3 text-[11px] text-white/30">
              Venue time zone: {session.venue.timezone}
            </p>
          </div>
        </div>
      </section>

      <section className="rounded-lg border border-destructive/25 bg-destructive/[0.035] p-5 sm:p-7">
        <h2 className="font-medium">Delete venue account</h2>
        <p className="mt-2 max-w-2xl text-sm leading-6 text-white/40">
          This immediately removes dashboard access, unpublishes the venue, archives its offers, and deletes the business contact record. Aggregated, anonymized attendance totals may be retained.
        </p>
        {params.error ? (
          <div className="mt-4 flex items-start gap-2 text-xs leading-5 text-destructive">
            <AlertCircle className="mt-0.5 size-4 shrink-0" />
            <span>
              {params.error === "delete_confirmation"
                ? "The venue name did not match. Nothing was deleted."
                : params.error === "delete_reauthentication"
                  ? "The password was incorrect. Nothing was deleted."
                : "The account could not be deleted. Try again or contact Outly support."}
            </span>
          </div>
        ) : null}
        <form action={deleteVenueAccount} className="mt-5 max-w-md space-y-3">
          <div className="space-y-2">
            <Label htmlFor="delete-venue-name" className="text-xs text-white/58">
              Type <span className="font-medium text-white">{venue.name}</span> to confirm
            </Label>
            <Input
              id="delete-venue-name"
              name="venueName"
              autoComplete="off"
              required
              className="h-11 border-destructive/25 bg-black/20"
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="delete-password" className="text-xs text-white/58">
              Confirm your current password
            </Label>
            <Input
              id="delete-password"
              name="password"
              type="password"
              autoComplete="current-password"
              required
              className="h-11 border-destructive/25 bg-black/20"
            />
          </div>
          <Button type="submit" variant="destructive">
            Permanently delete account
          </Button>
        </form>
      </section>
    </div>
  );
}

function ReadOnlyField({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <dt className="text-xs text-white/36">{label}</dt>
      <dd className="mt-1.5 break-words text-sm text-white/72">{value}</dd>
    </div>
  );
}

function presentStatus(value: string) {
  return value.replaceAll("_", " ").replace(/\b\w/g, (letter) =>
    letter.toUpperCase(),
  );
}
