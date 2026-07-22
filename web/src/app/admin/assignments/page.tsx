import Link from "next/link";
import { Plus } from "lucide-react";
import { reviewFounderOffer } from "@/app/admin/actions";
import {
  AdminPageHeader,
  ConfirmationNotice,
  ErrorNotice,
  StatusBadge,
} from "@/components/admin/admin-ui";
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

type SearchParams = Promise<{ reviewed?: string; error?: string }>;

export default async function AdminAssignmentsPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const [params, snapshot] = await Promise.all([
    searchParams,
    getFounderDashboardSnapshot(),
  ]);

  return (
    <div className="space-y-7">
      <AdminPageHeader
        title="Offer approvals"
        description="Review venue-submitted offers and create founder-approved partner campaigns."
        action={
          <Link
            href="/admin/partners/new?mode=offer"
            className={cn(buttonVariants({ size: "lg" }), "h-11 px-4")}
          >
            <Plus className="size-4" />
            Partner campaign
          </Link>
        }
      />

      {params.reviewed === "1" ? (
        <ConfirmationNotice>The offer review decision was saved.</ConfirmationNotice>
      ) : null}
      {params.error ? (
        <ErrorNotice>The offer review failed. Refresh and try again.</ErrorNotice>
      ) : null}

      <section className="grid overflow-hidden rounded-lg border border-white/10 bg-card sm:grid-cols-3">
        <Metric
          label="Awaiting review"
          value={snapshot.offerReviewQueue.length}
          note="Submitted offer versions"
        />
        <Metric
          label="Live offers"
          value={snapshot.metrics.liveOffers}
          note="Across approved venues"
        />
        <Metric
          label="Offer claims"
          value={snapshot.metrics.offerClaims}
          note="Excludes voided claims"
        />
      </section>

      <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
        <div className="border-b border-white/8 px-5 py-5 sm:px-6">
          <h2 className="font-medium">Review queue</h2>
          <p className="mt-1 text-xs text-white/38">
            Every decision is checked again by the founder-only Edge Function
          </p>
        </div>
        {snapshot.offerReviewQueue.length ? (
          <Table>
            <TableHeader>
              <TableRow className="border-white/8 hover:bg-transparent">
                <TableHead className="pl-5 sm:pl-6">Offer</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="hidden md:table-cell">Type</TableHead>
                <TableHead className="hidden lg:table-cell">Submitted</TableHead>
                <TableHead className="pr-5 text-right">Decision</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {snapshot.offerReviewQueue.map((offer) => (
                <TableRow key={offer.offerVersionId} className="border-white/8">
                  <TableCell className="pl-5 sm:pl-6">
                    <p className="font-medium text-white/82">{offer.title}</p>
                    <p className="mt-0.5 text-[11px] text-white/36">
                      {offer.venueName}
                    </p>
                  </TableCell>
                  <TableCell>
                    <StatusBadge status={presentStatus(offer.approvalState)} />
                  </TableCell>
                  <TableCell className="hidden text-white/54 md:table-cell">
                    {presentStatus(offer.kind)}
                  </TableCell>
                  <TableCell className="hidden text-white/50 lg:table-cell">
                    {offer.submittedAt
                      ? formatAdminDate(offer.submittedAt)
                      : "Not recorded"}
                  </TableCell>
                  <TableCell className="pr-5">
                    <form
                      action={reviewFounderOffer}
                      className="flex justify-end gap-1.5"
                    >
                      <input
                        type="hidden"
                        name="offerVersionId"
                        value={offer.offerVersionId}
                      />
                      <button
                        type="submit"
                        name="decision"
                        value="approved"
                        className={cn(
                          buttonVariants({ variant: "ghost", size: "sm" }),
                          "h-9 px-2.5 text-primary",
                        )}
                      >
                        Approve
                      </button>
                      <button
                        type="submit"
                        name="decision"
                        value="changes_requested"
                        className={cn(
                          buttonVariants({ variant: "ghost", size: "sm" }),
                          "hidden h-9 px-2.5 text-amber-100/72 sm:inline-flex",
                        )}
                      >
                        Changes
                      </button>
                      <button
                        type="submit"
                        name="decision"
                        value="rejected"
                        className={cn(
                          buttonVariants({ variant: "ghost", size: "sm" }),
                          "h-9 px-2.5 text-red-200/72",
                        )}
                      >
                        Reject
                      </button>
                    </form>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        ) : (
          <div className="px-5 py-16 text-center">
            <p className="font-medium">The review queue is clear</p>
            <p className="mx-auto mt-2 max-w-sm text-sm text-white/42">
              Submitted venue offers will appear here for founder approval.
            </p>
          </div>
        )}
      </section>
    </div>
  );
}

function Metric({ label, value, note }: { label: string; value: number; note: string }) {
  return (
    <div className="border-b border-white/10 p-5 last:border-b-0 sm:border-b-0 sm:border-r sm:last:border-r-0">
      <p className="text-xs text-white/42">{label}</p>
      <p className="numeric mt-3 font-mono text-3xl font-medium">{value}</p>
      <p className="mt-1.5 text-[11px] text-white/34">{note}</p>
    </div>
  );
}
