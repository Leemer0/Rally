import Link from "next/link";
import {
  AdminPageHeader,
  AdminSelect,
  Field,
  FormActions,
  PersistenceWarning,
} from "@/components/admin/admin-ui";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";

type SearchParams = Promise<{ mode?: string }>;

export default async function NewPartnerPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const params = await searchParams;
  const mode = params.mode === "partner" ? "partner" : "offer";

  return (
    <div className="mx-auto max-w-5xl space-y-7">
      <AdminPageHeader
        title={mode === "partner" ? "Add partner" : "Create partner offer"}
        description={
          mode === "partner"
            ? "Create the commercial record before adding a funded campaign."
            : "Define the reward, eligibility rules, funding, and approval state."
        }
        backHref="/admin/partners"
      />

      <div className="flex border-b border-white/10">
        <Link
          href="/admin/partners/new?mode=offer"
          className={cn(
            buttonVariants({ variant: "ghost", size: "lg" }),
            "h-11 rounded-b-none border-b-2 px-4",
            mode === "offer" ? "border-primary text-white" : "border-transparent text-white/46",
          )}
        >
          Partner offer
        </Link>
        <Link
          href="/admin/partners/new?mode=partner"
          className={cn(
            buttonVariants({ variant: "ghost", size: "lg" }),
            "h-11 rounded-b-none border-b-2 px-4",
            mode === "partner" ? "border-primary text-white" : "border-transparent text-white/46",
          )}
        >
          Partner record
        </Link>
      </div>

      <PersistenceWarning />
      {mode === "partner" ? <PartnerForm /> : <OfferForm />}
    </div>
  );
}

function PartnerForm() {
  return (
    <form action="/admin/partners" method="get" className="space-y-5">
      <input type="hidden" name="created" value="partner" />
      <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
        <div className="border-b border-white/8 px-5 py-4 sm:px-6">
          <h2 className="font-medium">Commercial record</h2>
          <p className="mt-1 text-xs text-white/38">
            Contact and agreement details for a fictional partner.
          </p>
        </div>
        <div className="grid gap-5 p-5 sm:grid-cols-2 sm:p-6">
          <Field id="partner-name" label="Partner name">
            <Input id="partner-name" name="name" required className="h-11" />
          </Field>
          <Field id="partner-category" label="Category">
            <AdminSelect id="partner-category" name="category" required>
              <option value="">Choose category</option>
              <option>Transportation</option>
              <option>Beverage</option>
              <option>Food delivery</option>
              <option>Entertainment</option>
              <option>Retail</option>
            </AdminSelect>
          </Field>
          <Field id="partner-contact" label="Primary contact">
            <Input id="partner-contact" name="contactName" required className="h-11" />
          </Field>
          <Field id="partner-email" label="Business email">
            <Input id="partner-email" name="email" type="email" required className="h-11" />
          </Field>
          <Field id="partner-budget" label="Initial campaign budget">
            <Input id="partner-budget" name="budget" inputMode="decimal" className="h-11" />
          </Field>
          <Field id="partner-status" label="Status">
            <AdminSelect id="partner-status" name="status" defaultValue="Onboarding">
              <option>Onboarding</option>
              <option>Active</option>
              <option>Paused</option>
            </AdminSelect>
          </Field>
          <div className="sm:col-span-2">
            <Field id="partner-notes" label="Agreement notes">
              <Textarea id="partner-notes" name="notes" rows={4} />
            </Field>
          </div>
        </div>
      </section>
      <FormActions cancelHref="/admin/partners" submitLabel="Create partner record" />
    </form>
  );
}

function OfferForm() {
  return (
    <form action="/admin/partners" method="get" className="space-y-5">
      <input type="hidden" name="created" value="offer" />
      <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
        <div className="border-b border-white/8 px-5 py-4 sm:px-6">
          <h2 className="font-medium">Offer definition</h2>
          <p className="mt-1 text-xs text-white/38">
            Staff-facing copy should be short enough to verify in one glance.
          </p>
        </div>
        <div className="grid gap-5 p-5 sm:grid-cols-2 sm:p-6">
          <Field id="offer-partner" label="Funding partner">
            <AdminSelect id="offer-partner" name="partner" required>
              <option value="">Choose partner</option>
              <option>Northline</option>
              <option>Afterglow Tickets</option>
              <option>Side Street Eats</option>
            </AdminSelect>
          </Field>
          <Field id="offer-status" label="Approval status">
            <AdminSelect id="offer-status" name="status" defaultValue="Draft">
              <option>Draft</option>
              <option>Ready</option>
              <option>Active</option>
            </AdminSelect>
          </Field>
          <div className="sm:col-span-2">
            <Field id="offer-title" label="Offer shown to users">
              <Input id="offer-title" name="title" required className="h-11" />
            </Field>
          </div>
          <Field id="offer-value" label="Funded value">
            <Input id="offer-value" name="value" required className="h-11" />
          </Field>
          <Field id="offer-claim-limit" label="Maximum claims">
            <Input id="offer-claim-limit" name="claimLimit" type="number" min="1" required className="h-11" />
          </Field>
          <Field id="offer-start" label="Campaign start">
            <Input id="offer-start" name="startsAt" type="date" required className="h-11" />
          </Field>
          <Field id="offer-end" label="Campaign end">
            <Input id="offer-end" name="endsAt" type="date" required className="h-11" />
          </Field>
          <Field id="offer-window-start" label="Daily start time">
            <Input id="offer-window-start" name="windowStart" type="time" required className="h-11" />
          </Field>
          <Field id="offer-window-end" label="Daily end time">
            <Input id="offer-window-end" name="windowEnd" type="time" required className="h-11" />
          </Field>
          <div className="sm:col-span-2">
            <Field
              id="offer-terms"
              label="Eligibility and staff instructions"
              hint="Include check-in timing, redemption rules, and exclusions."
            >
              <Textarea id="offer-terms" name="terms" required rows={5} />
            </Field>
          </div>
        </div>
      </section>
      <FormActions cancelHref="/admin/partners" submitLabel="Create partner offer" />
    </form>
  );
}
