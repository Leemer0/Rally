import Link from "next/link";
import {
  createFounderPartnerCampaign,
  upsertFounderPartner,
} from "@/app/admin/actions";
import {
  AdminPageHeader,
  AdminSelect,
  ErrorNotice,
  Field,
  FormActions,
  StatusBadge,
} from "@/components/admin/admin-ui";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { buttonVariants } from "@/components/ui/button";
import {
  getFounderDashboardSnapshot,
  presentStatus,
  type FounderDashboardSnapshot,
} from "@/lib/data/founder-dashboard";
import { cn } from "@/lib/utils";

type SearchParams = Promise<{ mode?: string; error?: string }>;

export default async function NewPartnerPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const [params, snapshot] = await Promise.all([
    searchParams,
    getFounderDashboardSnapshot(),
  ]);
  const mode = params.mode === "partner" ? "partner" : "offer";

  return (
    <div className="mx-auto max-w-5xl space-y-7">
      <AdminPageHeader
        title={mode === "partner" ? "Add partner" : "Create partner campaign"}
        description={
          mode === "partner"
            ? "Create the approved commercial identity used by funded offers."
            : "Create one location-verified campaign across selected Pro venues."
        }
        backHref="/admin/partners"
      />

      <div className="flex border-b border-white/10">
        <Link
          href="/admin/partners/new?mode=offer"
          className={cn(
            buttonVariants({ variant: "ghost", size: "lg" }),
            "h-11 rounded-b-none border-b-2 px-4",
            mode === "offer"
              ? "border-primary text-white"
              : "border-transparent text-white/46",
          )}
        >
          Partner campaign
        </Link>
        <Link
          href="/admin/partners/new?mode=partner"
          className={cn(
            buttonVariants({ variant: "ghost", size: "lg" }),
            "h-11 rounded-b-none border-b-2 px-4",
            mode === "partner"
              ? "border-primary text-white"
              : "border-transparent text-white/46",
          )}
        >
          Partner record
        </Link>
      </div>

      {params.error ? (
        <ErrorNotice>
          The record could not be saved. Check every required field and venue eligibility.
        </ErrorNotice>
      ) : null}
      {mode === "partner" ? <PartnerForm /> : <CampaignForm snapshot={snapshot} />}
    </div>
  );
}

function PartnerForm() {
  return (
    <form action={upsertFounderPartner} className="space-y-5">
      <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
        <div className="border-b border-white/8 px-5 py-4 sm:px-6">
          <h2 className="font-medium">Commercial identity</h2>
          <p className="mt-1 text-xs text-white/38">
            Partner branding is reused on the premium app offer and staff screen.
          </p>
        </div>
        <div className="grid gap-5 p-5 sm:grid-cols-2 sm:p-6">
          <Field id="brand-name" label="Brand name">
            <Input id="brand-name" name="brandName" required maxLength={120} className="h-11" />
          </Field>
          <Field id="legal-name" label="Legal name">
            <Input id="legal-name" name="legalName" required maxLength={180} className="h-11" />
          </Field>
          <Field id="industry" label="Industry">
            <Input id="industry" name="industry" maxLength={120} className="h-11" />
          </Field>
          <Field id="website-url" label="Website">
            <Input id="website-url" name="websiteUrl" type="url" placeholder="https://" className="h-11" />
          </Field>
          <Field
            id="logo-storage-path"
            label="Approved logo storage path"
            hint="Paste the full public object path, including the partner-media bucket."
          >
            <Input
              id="logo-storage-path"
              name="logoStoragePath"
              required
              placeholder="partner-media/northline/logo.webp"
              maxLength={1024}
              className="h-11"
            />
          </Field>
          <Field id="logo-alt-text" label="Logo description">
            <Input id="logo-alt-text" name="logoAltText" required maxLength={180} className="h-11" />
          </Field>
        </div>
      </section>

      <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
        <div className="border-b border-white/8 px-5 py-4 sm:px-6">
          <h2 className="font-medium">Primary contact</h2>
        </div>
        <div className="grid gap-5 p-5 sm:grid-cols-2 sm:p-6">
          <Field id="contact-name" label="Contact name">
            <Input id="contact-name" name="contactName" required maxLength={120} className="h-11" />
          </Field>
          <Field id="contact-email" label="Business email">
            <Input id="contact-email" name="contactEmail" type="email" required className="h-11" />
          </Field>
          <Field id="contact-phone" label="Phone">
            <Input id="contact-phone" name="contactPhone" type="tel" className="h-11" />
          </Field>
        </div>
      </section>
      <FormActions cancelHref="/admin/partners" submitLabel="Create partner" />
    </form>
  );
}

function CampaignForm({ snapshot }: { snapshot: FounderDashboardSnapshot }) {
  const partners = snapshot.partners.filter((partner) => partner.status === "active");
  const venues = snapshot.venues.filter(
    (venue) =>
      venue.registrationStatus === "approved" &&
      venue.publicationStatus === "published" &&
      venue.partnerCampaignAccess,
  );

  return (
    <form action={createFounderPartnerCampaign} className="space-y-5">
      <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
        <div className="border-b border-white/8 px-5 py-4 sm:px-6">
          <h2 className="font-medium">Campaign and reward</h2>
          <p className="mt-1 text-xs text-white/38">
            The external destination is released only after a verified venue check-in.
          </p>
        </div>
        <div className="grid gap-5 p-5 sm:grid-cols-2 sm:p-6">
          <Field id="partner-id" label="Funding partner">
            <AdminSelect id="partner-id" name="partnerId" required>
              <option value="">Choose partner</option>
              {partners.map((partner) => (
                <option key={partner.id} value={partner.id}>{partner.brandName}</option>
              ))}
            </AdminSelect>
          </Field>
          <Field id="internal-name" label="Internal campaign name">
            <Input id="internal-name" name="internalName" required maxLength={160} className="h-11" />
          </Field>
          <div className="sm:col-span-2">
            <Field id="public-title" label="Offer shown to users">
              <Input id="public-title" name="publicTitle" required maxLength={140} className="h-11" />
            </Field>
          </div>
          <div className="sm:col-span-2">
            <Field id="short-explanation" label="Short explanation">
              <Input id="short-explanation" name="shortExplanation" maxLength={240} className="h-11" />
            </Field>
          </div>
          <Field id="cta-label" label="Call to action">
            <Input id="cta-label" name="ctaLabel" required maxLength={60} placeholder="Claim ride credit" className="h-11" />
          </Field>
          <Field id="destination-url" label="Destination link">
            <Input id="destination-url" name="destinationUrl" type="url" required placeholder="https://" className="h-11" />
          </Field>
          <Field
            id="claim-duration-seconds"
            label="Claim timer in seconds"
            hint="Leave blank for an open-ended claim. Maximum 86,400 seconds."
          >
            <Input id="claim-duration-seconds" name="claimDurationSeconds" type="number" min="1" max="86400" className="h-11" />
          </Field>
          <Field id="total-claim-limit" label="Maximum total claims">
            <Input id="total-claim-limit" name="totalClaimLimit" type="number" min="1" className="h-11" />
          </Field>
          <Field id="starts-at" label="Starts (Toronto time)">
            <Input id="starts-at" name="startsAt" type="datetime-local" required className="h-11" />
          </Field>
          <Field id="ends-at" label="Ends (optional)">
            <Input id="ends-at" name="endsAt" type="datetime-local" className="h-11" />
          </Field>
          <Field id="discovery-badge" label="Map and list badge">
            <Input id="discovery-badge" name="discoveryBadgeLabel" defaultValue="Outly exclusive" maxLength={60} className="h-11" />
          </Field>
          <Field id="per-user-limit" label="Claims per user">
            <Input id="per-user-limit" name="perUserLimit" type="number" min="1" max="100" defaultValue="1" required className="h-11" />
          </Field>
          <div className="sm:col-span-2">
            <Field id="sponsor-disclosure" label="Sponsor disclosure">
              <Input id="sponsor-disclosure" name="sponsorDisclosure" required maxLength={240} placeholder="Offer provided by Northline" className="h-11" />
            </Field>
          </div>
          <div className="sm:col-span-2">
            <Field id="fine-print" label="Fine print">
              <Textarea id="fine-print" name="finePrint" maxLength={1000} rows={4} />
            </Field>
          </div>
        </div>
      </section>

      <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
        <div className="border-b border-white/8 px-5 py-4 sm:px-6">
          <h2 className="font-medium">Venues</h2>
          <p className="mt-1 text-xs text-white/38">
            Supabase will accept only approved, published venues with active Pro access.
          </p>
        </div>
        {venues.length ? (
          <fieldset className="grid gap-px bg-white/8 sm:grid-cols-2">
            <legend className="sr-only">Choose venues</legend>
            {venues.map((venue) => (
              <label
                key={venue.id}
                className="flex min-h-20 cursor-pointer items-center gap-3 bg-card px-5 py-4 transition-colors hover:bg-white/[0.025] sm:px-6"
              >
                <input
                  type="checkbox"
                  name="venueIds"
                  value={venue.id}
                  className="size-4 shrink-0 accent-[var(--primary)]"
                />
                <span className="min-w-0 flex-1">
                  <span className="block text-sm font-medium text-white/78">{venue.name}</span>
                  <span className="mt-0.5 block text-[11px] text-white/36">
                    {venue.neighbourhood || "Neighbourhood pending"}
                  </span>
                </span>
                <StatusBadge status={presentStatus(venue.publicationStatus)} />
              </label>
            ))}
          </fieldset>
        ) : (
          <p className="px-5 py-12 text-center text-sm text-white/42">
            No approved Pro venues with partner campaign access are available.
          </p>
        )}
      </section>

      <FormActions cancelHref="/admin/partners" submitLabel="Create partner campaign" />
    </form>
  );
}
