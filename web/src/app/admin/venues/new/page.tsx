import { AdminPageHeader, AdminSelect, Field, FormActions, PersistenceWarning } from "@/components/admin/admin-ui";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";

export default function AddVenuePage() {
  return (
    <div className="mx-auto max-w-5xl space-y-7">
      <AdminPageHeader
        title="Add venue"
        description="Create a founder-managed listing or prepare a record before venue approval."
        backHref="/admin/venues"
      />
      <PersistenceWarning />

      <form action="/admin/venues" method="get" className="space-y-5">
        <input type="hidden" name="created" value="1" />

        <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
          <div className="border-b border-white/8 px-5 py-4 sm:px-6">
            <h2 className="font-medium">Business identity</h2>
            <p className="mt-1 text-xs text-white/38">
              Public name, legal record, and the venue contact.
            </p>
          </div>
          <div className="grid gap-5 p-5 sm:grid-cols-2 sm:p-6">
            <Field id="venue-name" label="Public venue name">
              <Input id="venue-name" name="name" required className="h-11" />
            </Field>
            <Field id="legal-name" label="Legal business name">
              <Input id="legal-name" name="legalName" required className="h-11" />
            </Field>
            <Field id="business-email" label="Business email">
              <Input id="business-email" name="email" type="email" required className="h-11" />
            </Field>
            <Field id="business-phone" label="Business phone">
              <Input id="business-phone" name="phone" type="tel" required className="h-11" />
            </Field>
          </div>
        </section>

        <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
          <div className="border-b border-white/8 px-5 py-4 sm:px-6">
            <h2 className="font-medium">Location and geofence</h2>
            <p className="mt-1 text-xs text-white/38">
              The app uses precise location only when a user checks in.
            </p>
          </div>
          <div className="grid gap-5 p-5 sm:grid-cols-2 sm:p-6">
            <div className="sm:col-span-2">
              <Field id="street-address" label="Street address">
                <Input id="street-address" name="address" required className="h-11" />
              </Field>
            </div>
            <Field id="neighborhood" label="Neighborhood">
              <AdminSelect id="neighborhood" name="neighborhood" required>
                <option value="">Choose neighborhood</option>
                <option>King West</option>
                <option>Ossington</option>
                <option>College</option>
                <option>Chinatown</option>
              </AdminSelect>
            </Field>
            <Field
              id="geofence-radius"
              label="Geofence radius"
              hint="Start with 75 metres and adjust after on-site testing."
            >
              <AdminSelect id="geofence-radius" name="geofenceRadius" defaultValue="75">
                <option value="50">50 metres</option>
                <option value="75">75 metres</option>
                <option value="100">100 metres</option>
              </AdminSelect>
            </Field>
            <Field id="latitude" label="Latitude">
              <Input id="latitude" name="latitude" inputMode="decimal" required className="h-11" />
            </Field>
            <Field id="longitude" label="Longitude">
              <Input id="longitude" name="longitude" inputMode="decimal" required className="h-11" />
            </Field>
          </div>
        </section>

        <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
          <div className="border-b border-white/8 px-5 py-4 sm:px-6">
            <h2 className="font-medium">Listing controls</h2>
            <p className="mt-1 text-xs text-white/38">
              Set the starting approval, subscription, and public hours.
            </p>
          </div>
          <div className="grid gap-5 p-5 sm:grid-cols-2 sm:p-6">
            <Field id="approval-status" label="Approval status">
              <AdminSelect id="approval-status" name="status" defaultValue="Pending">
                <option>Pending</option>
                <option>Approved</option>
                <option>Paused</option>
              </AdminSelect>
            </Field>
            <Field id="subscription" label="Subscription">
              <AdminSelect id="subscription" name="subscription" defaultValue="Free">
                <option>Free</option>
                <option>Outly Pro</option>
              </AdminSelect>
            </Field>
            <Field id="opens-at" label="Opens at">
              <Input id="opens-at" name="opensAt" type="time" required className="h-11" />
            </Field>
            <Field id="closes-at" label="Closes at">
              <Input id="closes-at" name="closesAt" type="time" required className="h-11" />
            </Field>
            <div className="sm:col-span-2">
              <Field
                id="internal-note"
                label="Internal note"
                hint="Founder-only context. Do not place sensitive personal information here."
              >
                <Textarea id="internal-note" name="note" rows={4} />
              </Field>
            </div>
          </div>
        </section>

        <FormActions cancelHref="/admin/venues" submitLabel="Create venue record" />
      </form>
    </div>
  );
}
