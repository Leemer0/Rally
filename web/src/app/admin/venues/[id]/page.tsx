import { notFound } from "next/navigation";
import { AdminPageHeader, ConfirmationNotice, DemoNotice, StatusBadge } from "@/components/admin/admin-ui";
import { Button } from "@/components/ui/button";
import { venues } from "@/lib/admin-demo-data";

type Params = Promise<{ id: string }>;
type SearchParams = Promise<{ status?: string }>;

export default async function VenueReviewPage({
  params,
  searchParams,
}: {
  params: Params;
  searchParams: SearchParams;
}) {
  const [{ id }, query] = await Promise.all([params, searchParams]);
  const venue = venues.find((item) => item.id === id);
  if (!venue) notFound();

  return (
    <div className="mx-auto max-w-6xl space-y-7">
      <AdminPageHeader
        title={venue.name}
        description={`${venue.neighborhood} venue record and network performance.`}
        backHref="/admin/venues"
        action={<StatusBadge status={venue.status} />}
      />

      {query.status ? (
        <ConfirmationNotice>
          Prototype status changed to {query.status}. The source record was not updated.
        </ConfirmationNotice>
      ) : null}
      <DemoNotice />

      <section className="grid overflow-hidden rounded-lg border border-white/10 bg-card sm:grid-cols-3">
        <Metric label="Tonight's plans" value={String(venue.tonight)} />
        <Metric label="30-day check-ins" value={String(venue.checkIns30d)} />
        <Metric label="30-day repeat rate" value={venue.repeatRate} />
      </section>

      <div className="grid gap-5 lg:grid-cols-[1.25fr_.75fr]">
        <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
          <div className="border-b border-white/8 px-5 py-4 sm:px-6">
            <h2 className="font-medium">Venue record</h2>
          </div>
          <dl className="grid gap-px bg-white/8 sm:grid-cols-2">
            <Detail label="Public name" value={venue.name} />
            <Detail label="Neighborhood" value={venue.neighborhood} />
            <Detail label="Subscription" value={venue.plan} />
            <Detail label="Current offer" value={venue.offer} />
            <Detail label="Business contact" value={venue.contact} />
            <Detail label="Geofence" value="75 metres, on-site check pending" />
          </dl>
        </section>

        <section className="rounded-lg border border-white/10 bg-card p-5 sm:p-6">
          <h2 className="font-medium">Approval controls</h2>
          <p className="mt-1 text-xs leading-5 text-white/38">
            Prototype actions return a confirmation state only.
          </p>
          <form method="get" className="mt-6 grid gap-3">
            <Button name="status" value="Approved" type="submit" className="h-11">
              Approve venue
            </Button>
            <Button name="status" value="Pending" type="submit" variant="outline" className="h-11 border-white/12">
              Return to pending
            </Button>
            <Button name="status" value="Paused" type="submit" variant="destructive" className="h-11">
              Pause listing
            </Button>
          </form>
        </section>
      </div>
    </div>
  );
}

function Metric({ label, value }: { label: string; value: string }) {
  return (
    <div className="border-b border-white/10 p-5 last:border-b-0 sm:border-b-0 sm:border-r sm:last:border-r-0">
      <p className="text-xs text-white/42">{label}</p>
      <p className="numeric mt-3 font-mono text-3xl font-medium">{value}</p>
    </div>
  );
}

function Detail({ label, value }: { label: string; value: string }) {
  return (
    <div className="bg-card px-5 py-4 sm:px-6">
      <dt className="text-[11px] text-white/36">{label}</dt>
      <dd className="mt-1.5 text-sm text-white/72">{value}</dd>
    </div>
  );
}
