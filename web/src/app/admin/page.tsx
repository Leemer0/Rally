import Link from "next/link";
import { ArrowRight, Plus, Send } from "lucide-react";
import { AdminPageHeader, StatusBadge } from "@/components/admin/admin-ui";
import { buttonVariants } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  formatAdminDate,
  getFounderDashboardSnapshot,
  presentStatus,
} from "@/lib/data/founder-dashboard";
import { cn } from "@/lib/utils";

export default async function AdminOverviewPage() {
  const snapshot = await getFounderDashboardSnapshot();
  const metrics = [
    {
      label: "Active consumers",
      value: snapshot.metrics.activeConsumers,
      note: "Server-side account status",
    },
    {
      label: "Published venues",
      value: snapshot.metrics.publishedVenues,
      note: `${snapshot.metrics.pendingVenues + snapshot.metrics.pendingVenueClaims} reviews waiting`,
    },
    {
      label: "Verified check-ins",
      value: snapshot.metrics.verifiedCheckIns,
      note: "All-time verified arrivals",
    },
    {
      label: "Live offers",
      value: snapshot.metrics.liveOffers,
      note: `${snapshot.metrics.offerClaims} non-voided claims`,
    },
  ];
  const approvedVenues = snapshot.venues.filter(
    (venue) => venue.registrationStatus === "approved",
  ).length;
  const pendingVenues = snapshot.venues.filter((venue) =>
    ["pending_review", "changes_requested"].includes(venue.registrationStatus),
  ).length;
  const activePartners = snapshot.partners.filter(
    (partner) => partner.status === "active",
  ).length;
  const pendingWork = [
    ...snapshot.venues
      .filter((venue) =>
        ["pending_review", "changes_requested"].includes(
          venue.registrationStatus,
        ),
      )
      .map((venue) => ({
        key: `venue-${venue.id}`,
        label: "Venue review",
        detail: `${venue.name} · ${presentStatus(venue.registrationStatus)}`,
        href: `/admin/venues/${venue.id}`,
      })),
    ...snapshot.venues
      .filter((venue) =>
        ["pending_review", "changes_requested"].includes(
          venue.claimStatus ?? "",
        ),
      )
      .map((venue) => ({
        key: `claim-${venue.id}`,
        label: "Venue access claim",
        detail: `${venue.name} · ${presentStatus(venue.claimStatus ?? "pending_review")}`,
        href: `/admin/venues/${venue.id}`,
      })),
    ...snapshot.offerReviewQueue.map((offer) => ({
      key: `offer-${offer.offerVersionId}`,
      label: "Offer review",
      detail: `${offer.title} · ${offer.venueName}`,
      href: "/admin/assignments",
    })),
  ];

  return (
    <div className="space-y-7">
      <AdminPageHeader
        title="Network operations"
        description="Review live account, venue, check-in, offer, and partner state from Supabase."
        action={
          <div className="flex gap-2">
            <Link
              href="/admin/partners/new?mode=offer"
              className={cn(
                buttonVariants({ variant: "outline", size: "lg" }),
                "h-11 border-white/12 px-4",
              )}
            >
              <Send className="size-4" />
              Partner offer
            </Link>
            <Link
              href="/admin/venues/new"
              className={cn(buttonVariants({ size: "lg" }), "h-11 px-4")}
            >
              <Plus className="size-4" />
              Add venue
            </Link>
          </div>
        }
      />

      <section
        className="grid overflow-hidden rounded-lg border border-white/10 bg-card sm:grid-cols-2 xl:grid-cols-4"
        aria-label="Network summary"
      >
        {metrics.map((metric) => (
          <div
            key={metric.label}
            className="border-b border-white/10 p-4 sm:border-r sm:p-5 sm:nth-[3]:border-b-0 sm:nth-[4]:border-b-0 sm:even:border-r-0 xl:border-b-0 xl:even:border-r xl:last:border-r-0"
          >
            <p className="text-xs text-white/46">{metric.label}</p>
            <p className="numeric mt-4 font-mono text-3xl font-medium tracking-[-0.04em]">
              {metric.value.toLocaleString("en-CA")}
            </p>
            <p className="mt-1.5 text-[11px] text-white/36">{metric.note}</p>
          </div>
        ))}
      </section>

      <div className="grid gap-5 xl:grid-cols-[.78fr_1.22fr]">
        <section className="rounded-lg border border-white/10 bg-card p-5 sm:p-6">
          <h2 className="font-medium">Network state</h2>
          <p className="mt-1 text-xs text-white/38">
            Current operational records, not estimated analytics
          </p>
          <div className="mt-7 space-y-5">
            <BreakdownRow
              label="Approved venues"
              value={approvedVenues}
              total={snapshot.venues.length}
            />
            <BreakdownRow
              label="Awaiting venue review"
              value={pendingVenues}
              total={snapshot.venues.length}
              warning
            />
            <BreakdownRow
              label="Awaiting access review"
              value={snapshot.metrics.pendingVenueClaims}
              total={snapshot.venues.length}
              warning
            />
            <BreakdownRow
              label="Active partners"
              value={activePartners}
              total={snapshot.partners.length}
            />
          </div>
          <p className="mt-7 border-t border-white/8 pt-4 text-[11px] leading-5 text-white/34">
            Refreshed from Supabase at {formatAdminDate(snapshot.serverTime)}.
          </p>
        </section>

        <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
          <div className="flex items-start justify-between gap-4 px-5 py-5 sm:px-6">
            <div>
              <h2 className="font-medium">Recent venues</h2>
              <p className="mt-1 text-xs text-white/38">
                Latest founder-created and self-registered records
              </p>
            </div>
            <Link
              href="/admin/venues"
              className="inline-flex min-h-11 shrink-0 items-center gap-1 text-xs text-white/48 transition-colors hover:text-white"
            >
              All venues
              <ArrowRight className="size-3.5" />
            </Link>
          </div>
          {snapshot.venues.length ? (
            <Table>
              <TableHeader>
                <TableRow className="border-white/8 hover:bg-transparent">
                  <TableHead className="pl-5 sm:pl-6">Venue</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="hidden sm:table-cell">Publication</TableHead>
                  <TableHead className="hidden md:table-cell">Created</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {snapshot.venues.slice(0, 5).map((venue) => (
                  <TableRow key={venue.id} className="border-white/8">
                    <TableCell className="pl-5 sm:pl-6">
                      <Link
                        href={`/admin/venues/${venue.id}`}
                        className="font-medium text-white/82 hover:text-primary"
                      >
                        {venue.name}
                      </Link>
                      <p className="mt-0.5 text-[11px] text-white/34">
                        {venue.neighbourhood || "Neighbourhood pending"}
                      </p>
                    </TableCell>
                    <TableCell>
                      <StatusBadge status={presentStatus(venue.registrationStatus)} />
                    </TableCell>
                    <TableCell className="hidden text-white/54 sm:table-cell">
                      {presentStatus(venue.publicationStatus)}
                    </TableCell>
                    <TableCell className="hidden text-white/50 md:table-cell">
                      {formatAdminDate(venue.createdAt)}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          ) : (
            <EmptyState message="No venue records have been created yet." />
          )}
        </section>
      </div>

      <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
        <div className="border-b border-white/8 px-5 py-5 sm:px-6">
          <h2 className="font-medium">Needs attention</h2>
          <p className="mt-1 text-xs text-white/38">
            Pending venue and offer reviews from the live approval queues
          </p>
        </div>
        {pendingWork.length ? (
          <div className="divide-y divide-white/8">
            {pendingWork.slice(0, 8).map((item) => (
              <Link
                key={item.key}
                href={item.href}
                className="grid min-h-16 grid-cols-[1fr_auto] items-center gap-4 px-5 py-3 transition-colors hover:bg-white/[0.025] sm:px-6"
              >
                <div>
                  <p className="text-sm font-medium text-white/76">{item.label}</p>
                  <p className="mt-0.5 text-xs text-white/38">{item.detail}</p>
                </div>
                <ArrowRight className="size-3.5 text-white/34" />
              </Link>
            ))}
          </div>
        ) : (
          <EmptyState message="No venue or offer reviews are waiting." />
        )}
      </section>
    </div>
  );
}

function BreakdownRow({
  label,
  value,
  total,
  warning = false,
}: {
  label: string;
  value: number;
  total: number;
  warning?: boolean;
}) {
  const percentage = total > 0 ? Math.max(3, (value / total) * 100) : 0;
  return (
    <div>
      <div className="mb-2 flex items-baseline justify-between gap-4">
        <span className="text-xs text-white/54">{label}</span>
        <span className="numeric font-mono text-xs">{value}</span>
      </div>
      <div className="h-1 bg-white/[0.055]">
        <div
          className={cn("h-full", warning ? "bg-amber-200/70" : "bg-primary/80")}
          style={{ width: `${percentage}%` }}
        />
      </div>
    </div>
  );
}

function EmptyState({ message }: { message: string }) {
  return <p className="px-5 py-12 text-center text-sm text-white/42">{message}</p>;
}
