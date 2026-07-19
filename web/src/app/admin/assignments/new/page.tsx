import { AdminPageHeader, AdminSelect, Field, FormActions, PersistenceWarning, StatusBadge } from "@/components/admin/admin-ui";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { partnerOffers, venues } from "@/lib/admin-demo-data";

export default function NewAssignmentPage() {
  const assignableOffers = partnerOffers.filter((offer) => offer.status !== "Draft");
  const eligibleVenues = venues.filter((venue) => venue.status === "Approved");

  return (
    <div className="mx-auto max-w-5xl space-y-7">
      <AdminPageHeader
        title="Assign partner offer"
        description="Choose an approved offer, select venues, and set the proposed activation window."
        backHref="/admin/assignments"
      />
      <PersistenceWarning />

      <form action="/admin/assignments" method="get" className="space-y-5">
        <input type="hidden" name="assigned" value="1" />

        <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
          <div className="border-b border-white/8 px-5 py-4 sm:px-6">
            <h2 className="font-medium">Offer and schedule</h2>
            <p className="mt-1 text-xs text-white/38">
              Only founder-approved partner offers can be assigned.
            </p>
          </div>
          <div className="grid gap-5 p-5 sm:grid-cols-2 sm:p-6">
            <div className="sm:col-span-2">
              <Field id="assignment-offer" label="Partner offer">
                <AdminSelect id="assignment-offer" name="offer" required>
                  <option value="">Choose an offer</option>
                  {assignableOffers.map((offer) => (
                    <option key={offer.id} value={offer.id}>
                      {offer.name} by {offer.partner}
                    </option>
                  ))}
                </AdminSelect>
              </Field>
            </div>
            <Field id="assignment-start" label="Starts">
              <Input id="assignment-start" name="startsAt" type="datetime-local" required className="h-11" />
            </Field>
            <Field id="assignment-end" label="Ends">
              <Input id="assignment-end" name="endsAt" type="datetime-local" required className="h-11" />
            </Field>
            <Field id="assignment-response" label="Venue response due">
              <Input id="assignment-response" name="responseDue" type="date" required className="h-11" />
            </Field>
            <Field id="assignment-claims" label="Claim allocation per venue">
              <Input id="assignment-claims" name="claimsPerVenue" type="number" min="1" required className="h-11" />
            </Field>
          </div>
        </section>

        <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
          <div className="border-b border-white/8 px-5 py-4 sm:px-6">
            <h2 className="font-medium">Eligible venues</h2>
            <p className="mt-1 text-xs text-white/38">
              Select one or more approved venues to receive the proposal.
            </p>
          </div>
          <fieldset className="grid gap-px bg-white/8 sm:grid-cols-2">
            <legend className="sr-only">Choose venues</legend>
            {eligibleVenues.map((venue) => (
              <label
                key={venue.id}
                className="flex min-h-20 cursor-pointer items-center gap-3 bg-card px-5 py-4 transition-colors hover:bg-white/[0.025] sm:px-6"
              >
                <input
                  type="checkbox"
                  name="venues"
                  value={venue.id}
                  className="size-4 shrink-0 accent-[var(--primary)]"
                />
                <span className="min-w-0 flex-1">
                  <span className="block text-sm font-medium text-white/78">{venue.name}</span>
                  <span className="mt-0.5 block text-[11px] text-white/36">
                    {venue.neighborhood} · {venue.plan}
                  </span>
                </span>
                <StatusBadge status={venue.status} />
              </label>
            ))}
          </fieldset>
        </section>

        <section className="rounded-lg border border-white/10 bg-card p-5 sm:p-6">
          <Field
            id="assignment-note"
            label="Message to venue"
            hint="Explain the reward, operational requirements, and response deadline."
          >
            <Textarea id="assignment-note" name="message" required rows={5} />
          </Field>
        </section>

        <FormActions cancelHref="/admin/assignments" submitLabel="Send to selected venues" />
      </form>
    </div>
  );
}
