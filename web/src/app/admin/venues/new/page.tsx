import { createFounderVenue } from "@/app/admin/actions";
import {
  AdminPageHeader,
  AdminSelect,
  ErrorNotice,
  Field,
  FormActions,
} from "@/components/admin/admin-ui";
import { Input } from "@/components/ui/input";

type SearchParams = Promise<{ error?: string }>;

export default async function AddVenuePage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const params = await searchParams;

  return (
    <div className="mx-auto max-w-5xl space-y-7">
      <AdminPageHeader
        title="Add venue"
        description="Create an approved founder-managed listing with its check-in geofence."
        backHref="/admin/venues"
      />
      {params.error ? (
        <ErrorNotice>
          The venue could not be created. Check the address, coordinates, and radius.
        </ErrorNotice>
      ) : null}

      <form action={createFounderVenue} className="space-y-5">
        <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
          <div className="border-b border-white/8 px-5 py-4 sm:px-6">
            <h2 className="font-medium">Public listing</h2>
            <p className="mt-1 text-xs text-white/38">
              Founder-created venues are approved and published immediately.
            </p>
          </div>
          <div className="grid gap-5 p-5 sm:grid-cols-2 sm:p-6">
            <Field id="display-name" label="Public venue name">
              <Input id="display-name" name="displayName" required maxLength={100} className="h-11" />
            </Field>
            <Field id="neighbourhood" label="Neighbourhood">
              <AdminSelect id="neighbourhood" name="neighbourhood" required>
                <option value="">Choose neighbourhood</option>
                <option>King West</option>
                <option>Ossington</option>
                <option>College</option>
                <option>Chinatown</option>
              </AdminSelect>
            </Field>
            <div className="sm:col-span-2">
              <Field id="address-line-1" label="Street address">
                <Input id="address-line-1" name="addressLine1" required maxLength={160} className="h-11" />
              </Field>
            </div>
            <Field id="postal-code" label="Postal code">
              <Input id="postal-code" name="postalCode" required maxLength={16} autoCapitalize="characters" className="h-11" />
            </Field>
            <Field
              id="geofence-radius"
              label="Geofence radius"
              hint="Start with 75 metres and adjust after on-site testing."
            >
              <AdminSelect
                id="geofence-radius"
                name="geofenceRadiusMetres"
                defaultValue="75"
              >
                <option value="50">50 metres</option>
                <option value="75">75 metres</option>
                <option value="100">100 metres</option>
              </AdminSelect>
            </Field>
            <Field id="latitude" label="Latitude">
              <Input
                id="latitude"
                name="latitude"
                type="number"
                min="-90"
                max="90"
                step="any"
                required
                className="h-11"
              />
            </Field>
            <Field id="longitude" label="Longitude">
              <Input
                id="longitude"
                name="longitude"
                type="number"
                min="-180"
                max="180"
                step="any"
                required
                className="h-11"
              />
            </Field>
          </div>
        </section>

        <div className="rounded-lg border border-white/10 bg-white/[0.018] px-4 py-3 text-xs leading-5 text-white/46">
          Business contact, legal identity, venue hours, and login access are completed
          through venue self-registration. This form creates only the public listing and
          verified check-in boundary.
        </div>

        <FormActions cancelHref="/admin/venues" submitLabel="Create and publish venue" />
      </form>
    </div>
  );
}
