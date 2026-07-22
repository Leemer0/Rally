import { notFound } from "next/navigation";
import {
  reviewFounderVenue,
  setFounderVenuePlan,
} from "@/app/admin/actions";
import {
  AdminPageHeader,
  ConfirmationNotice,
  ErrorNotice,
  Field,
  StatusBadge,
} from "@/components/admin/admin-ui";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import {
  formatAdminDate,
  getFounderDashboardSnapshot,
  presentStatus,
} from "@/lib/data/founder-dashboard";

type Params = Promise<{ id: string }>;
type SearchParams = Promise<{
  updated?: string;
  planUpdated?: string;
  error?: string;
}>;

export default async function VenueReviewPage({
  params,
  searchParams,
}: {
  params: Params;
  searchParams: SearchParams;
}) {
  const [{ id }, query, snapshot] = await Promise.all([
    params,
    searchParams,
    getFounderDashboardSnapshot(),
  ]);
  const venue = snapshot.venues.find((item) => item.id === id);
  if (!venue) notFound();
  const claimNeedsReview = ["pending_review", "changes_requested"].includes(
    venue.claimStatus ?? "",
  );

  return (
    <div className="mx-auto max-w-6xl space-y-7">
      <AdminPageHeader
        title={venue.name}
        description={`${venue.neighbourhood || "Neighbourhood pending"} venue record and approval controls.`}
        backHref="/admin/venues"
        action={
          <StatusBadge status={presentStatus(venue.registrationStatus)} />
        }
      />

      {query.updated === "1" ? (
        <ConfirmationNotice>The venue review decision was saved.</ConfirmationNotice>
      ) : null}
      {query.planUpdated === "1" ? (
        <ConfirmationNotice>The venue subscription state was updated.</ConfirmationNotice>
      ) : null}
      {query.error ? (
        <ErrorNotice>The requested venue operation failed. Refresh and try again.</ErrorNotice>
      ) : null}

      <section className="grid overflow-hidden rounded-lg border border-white/10 bg-card sm:grid-cols-2 lg:grid-cols-4">
        <Metric
          label="Registration"
          value={presentStatus(venue.registrationStatus)}
        />
        <Metric
          label="Publication"
          value={presentStatus(venue.publicationStatus)}
        />
        <Metric label="Placement" value={presentStatus(venue.placementState)} />
        <Metric
          label="Venue access"
          value={venue.claimStatus ? presentStatus(venue.claimStatus) : venue.accountStatus ? presentStatus(venue.accountStatus) : "Not linked"}
        />
      </section>

      <div className="grid gap-5 lg:grid-cols-[1.25fr_.75fr]">
        <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
          <div className="border-b border-white/8 px-5 py-4 sm:px-6">
            <h2 className="font-medium">Venue record</h2>
          </div>
          <dl className="grid gap-px bg-white/8 sm:grid-cols-2">
            <Detail label="Public name" value={venue.name} />
            <Detail
              label="Neighbourhood"
              value={venue.neighbourhood || "Not provided"}
            />
            <Detail label="Slug" value={venue.slug} mono />
            <Detail
              label="Venue login"
              value={venue.accountStatus ? presentStatus(venue.accountStatus) : "Not linked"}
            />
            <Detail
              label="Business contact"
              value={venue.businessEmail || "Not provided"}
            />
            <Detail
              label="Subscription"
              value={venue.planCode ? `${presentStatus(venue.planCode)} · ${presentStatus(venue.subscriptionStatus ?? "unknown")}` : "Not configured"}
            />
            <Detail label="Created" value={formatAdminDate(venue.createdAt)} />
          </dl>
        </section>

        <section className="rounded-lg border border-white/10 bg-card p-5 sm:p-6">
          <h2 className="font-medium">Approval controls</h2>
          <p className="mt-1 text-xs leading-5 text-white/38">
            Decisions are applied by the founder-only Edge Function and recorded in
            the review audit trail.
          </p>
          {claimNeedsReview ? (
            <div className="mt-6 border-b border-white/8 pb-6">
              <p className="text-sm font-medium text-white/76">Existing listing claim</p>
              <p className="mt-1 text-xs leading-5 text-white/38">
                Approving links the verified business login. The public listing and check-in boundary do not change.
              </p>
              <form action={reviewFounderVenue} className="mt-4">
                <input type="hidden" name="venueId" value={venue.id} />
                <input type="hidden" name="decision" value="approved" />
                <Button type="submit" className="h-11 w-full">
                  Approve venue access
                </Button>
              </form>
              <form action={reviewFounderVenue} className="mt-5 grid gap-3">
                <input type="hidden" name="venueId" value={venue.id} />
                <Field
                  id="claim-public-response"
                  label="Message to claimant"
                  hint="Required when requesting another update or rejecting access."
                >
                  <Textarea
                    id="claim-public-response"
                    name="publicResponse"
                    rows={3}
                    required
                    maxLength={1000}
                  />
                </Field>
                <Field id="claim-private-note" label="Internal review note">
                  <Textarea
                    id="claim-private-note"
                    name="privateNote"
                    rows={3}
                    maxLength={4000}
                  />
                </Field>
                <Button
                  name="decision"
                  value="changes_requested"
                  type="submit"
                  variant="outline"
                  className="h-11 border-white/12"
                >
                  Request an update
                </Button>
                <Button
                  name="decision"
                  value="rejected"
                  type="submit"
                  variant="destructive"
                  className="h-11"
                >
                  Reject venue access
                </Button>
              </form>
            </div>
          ) : null}
          {["draft", "pending_review", "changes_requested", "rejected", "suspended"].includes(
            venue.registrationStatus,
          ) ? (
            <form
              action={reviewFounderVenue}
              className="mt-6 grid gap-4 border-b border-white/8 pb-6"
            >
              <input type="hidden" name="venueId" value={venue.id} />
              <p className="text-sm font-medium text-white/76">
                Confirm the check-in boundary
              </p>
              <p className="-mt-2 text-xs leading-5 text-white/38">
                These fields are required to publish the venue and verify arrivals.
              </p>
              <Field id="approval-neighbourhood" label="Neighbourhood">
                <Input
                  id="approval-neighbourhood"
                  name="neighbourhood"
                  defaultValue={venue.neighbourhood || ""}
                  placeholder="Ossington"
                  required
                  maxLength={80}
                  className="h-11"
                />
              </Field>
              <Field id="approval-postal-code" label="Postal code">
                <Input
                  id="approval-postal-code"
                  name="postalCode"
                  placeholder="M6J 2Z9"
                  required
                  maxLength={16}
                  autoCapitalize="characters"
                  className="h-11"
                />
              </Field>
              <div className="grid gap-3 sm:grid-cols-2">
                <Field id="approval-latitude" label="Latitude">
                  <Input
                    id="approval-latitude"
                    name="latitude"
                    type="number"
                    inputMode="decimal"
                    min={-90}
                    max={90}
                    step="any"
                    placeholder="43.6500"
                    required
                    className="h-11"
                  />
                </Field>
                <Field id="approval-longitude" label="Longitude">
                  <Input
                    id="approval-longitude"
                    name="longitude"
                    type="number"
                    inputMode="decimal"
                    min={-180}
                    max={180}
                    step="any"
                    placeholder="-79.4200"
                    required
                    className="h-11"
                  />
                </Field>
              </div>
              <Field
                id="approval-geofence-radius"
                label="Check-in radius"
                hint="Metres from the venue pin. Start with 75 m."
              >
                <Input
                  id="approval-geofence-radius"
                  name="geofenceRadiusMetres"
                  type="number"
                  min={25}
                  max={200}
                  step={1}
                  defaultValue={75}
                  required
                  className="h-11"
                />
              </Field>
              <Button
                name="decision"
                value={venue.registrationStatus === "suspended" ? "reinstated" : "approved"}
                type="submit"
                className="h-11"
              >
                {venue.registrationStatus === "suspended"
                  ? "Confirm and reinstate"
                  : "Confirm and publish"}
              </Button>
            </form>
          ) : null}

          {["pending_review", "changes_requested", "approved"].includes(
            venue.registrationStatus,
          ) ? (
            <form action={reviewFounderVenue} className="mt-6 grid gap-3">
              <input type="hidden" name="venueId" value={venue.id} />
              {["pending_review", "changes_requested"].includes(
                venue.registrationStatus,
              ) ? (
                <Field
                  id="public-response"
                  label="Message to venue"
                  hint="Explain what must change before approval."
                >
                  <Textarea id="public-response" name="publicResponse" rows={3} required maxLength={1000} />
                </Field>
              ) : null}
              <Field id="private-note" label="Internal review note">
                <Textarea id="private-note" name="privateNote" rows={3} maxLength={4000} />
              </Field>
              {["pending_review", "changes_requested"].includes(
                venue.registrationStatus,
              ) ? (
                <>
                  <Button
                    name="decision"
                    value="changes_requested"
                    type="submit"
                    variant="outline"
                    className="h-11 border-white/12"
                  >
                    Request changes
                  </Button>
                  <Button
                    name="decision"
                    value="rejected"
                    type="submit"
                    variant="destructive"
                    className="h-11"
                  >
                    Reject registration
                  </Button>
                </>
              ) : null}
              {venue.registrationStatus === "approved" ? (
                <Button
                  name="decision"
                  value="suspended"
                  type="submit"
                  variant="destructive"
                  className="h-11"
                >
                  Suspend listing
                </Button>
              ) : null}
            </form>
          ) : null}
        </section>
      </div>

      <section className="rounded-lg border border-white/10 bg-card p-5 sm:p-6">
        <div>
          <h2 className="font-medium">MVP subscription override</h2>
          <p className="mt-1 text-xs leading-5 text-white/38">
            Use this manual control until Stripe lifecycle events become the source of truth.
          </p>
          <p className="mt-3 text-sm text-white/62">
            Current: {venue.planCode ? presentStatus(venue.planCode) : "Not configured"} · {venue.subscriptionStatus ? presentStatus(venue.subscriptionStatus) : "No billing state"}
          </p>
          <div className="mt-5 grid gap-3 lg:grid-cols-3">
            <form action={setFounderVenuePlan} className="rounded-md border border-white/8 p-4">
              <input type="hidden" name="venueId" value={venue.id} />
              <input type="hidden" name="planCode" value="free" />
              <input type="hidden" name="status" value="free" />
              <p className="text-sm font-medium text-white/76">Free</p>
              <p className="mt-1 min-h-10 text-xs leading-5 text-white/38">
                Standard listing and basic offer access.
              </p>
              <Button type="submit" variant="outline" className="mt-4 h-11 w-full border-white/12">
                Set Free
              </Button>
            </form>
            <form action={setFounderVenuePlan} className="rounded-md border border-white/8 p-4">
              <input type="hidden" name="venueId" value={venue.id} />
              <input type="hidden" name="planCode" value="pro" />
              <input type="hidden" name="status" value="active" />
              <p className="text-sm font-medium text-white/76">Outly Pro</p>
              <p className="mt-1 min-h-10 text-xs leading-5 text-white/38">
                Activates paid entitlements without a trial period.
              </p>
              <Button type="submit" className="mt-4 h-11 w-full">
                Activate Pro
              </Button>
            </form>
            <form action={setFounderVenuePlan} className="rounded-md border border-white/8 p-4">
              <input type="hidden" name="venueId" value={venue.id} />
              <input type="hidden" name="planCode" value="pro" />
              <input type="hidden" name="status" value="trialing" />
              <Field
                id="trial-ends-at"
                label="Pro trial ends"
                hint="Toronto local time."
              >
                <Input
                  id="trial-ends-at"
                  name="trialEndsAt"
                  type="datetime-local"
                  required
                  className="h-11"
                />
              </Field>
              <Button type="submit" variant="outline" className="mt-4 h-11 w-full border-white/12">
                Start Pro trial
              </Button>
            </form>
          </div>
        </div>
      </section>
    </div>
  );
}

function Metric({ label, value }: { label: string; value: string }) {
  return (
    <div className="border-b border-white/10 p-5 last:border-b-0 sm:border-b-0 sm:border-r sm:last:border-r-0">
      <p className="text-xs text-white/42">{label}</p>
      <p className="mt-3 text-lg font-medium">{value}</p>
    </div>
  );
}

function Detail({
  label,
  value,
  mono = false,
}: {
  label: string;
  value: string;
  mono?: boolean;
}) {
  return (
    <div className="bg-card px-5 py-4 sm:px-6">
      <dt className="text-[11px] text-white/36">{label}</dt>
      <dd className={mono ? "mt-1.5 font-mono text-xs text-white/72" : "mt-1.5 text-sm text-white/72"}>
        {value}
      </dd>
    </div>
  );
}
