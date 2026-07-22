import Link from "next/link";
import { Archive, CheckCircle2, PencilLine, Plus, Square } from "lucide-react";
import { setVenueOfferStatus } from "@/app/dashboard/offers/actions";
import { DashboardUnavailable } from "@/components/dashboard/dashboard-unavailable";
import { Badge } from "@/components/ui/badge";
import { buttonVariants } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { requireVenueSession } from "@/lib/auth/venue";
import {
  loadVenueDashboardSnapshot,
  loadVenueOfferManagement,
} from "@/lib/data/venue-dashboard";
import { cn } from "@/lib/utils";

type SearchParams = Promise<{
  created?: string;
  updated?: string;
  error?: string;
}>;

const activeStatuses = new Set([
  "draft",
  "pending_review",
  "changes_requested",
  "approved",
  "scheduled",
  "live",
  "paused",
]);

export default async function OffersPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const [params, session] = await Promise.all([
    searchParams,
    requireVenueSession(),
  ]);
  const [result, managementResult] = await Promise.all([
    loadVenueDashboardSnapshot(session.userId),
    loadVenueOfferManagement(session.userId),
  ]);

  if (!result.data || !managementResult.data) {
    return (
      <DashboardUnavailable
        configuration={
          result.error === "configuration" ||
          managementResult.error === "configuration"
        }
        title="We couldn’t load your offers."
      />
    );
  }

  const snapshot = result.data;
  const offers = managementResult.data.map((offer) => ({
    ...offer,
    unlockedCount:
      snapshot.offers.find((candidate) => candidate.id === offer.offerId)
        ?.unlockedCount ?? 0,
  }));
  const activeOfferCount = offers.filter((offer) =>
    activeStatuses.has(offer.lifecycleStatus),
  ).length;
  const activeOfferLimit = snapshot.subscription.entitlements.activeOfferLimit;

  return (
    <div className="space-y-8">
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
        <div>
          <p className="font-mono text-[10px] uppercase tracking-[0.17em] text-primary">
            Offers
          </p>
          <h1 className="mt-2 text-3xl font-medium tracking-[-0.035em] sm:text-4xl">
            Check-in incentives
          </h1>
          <p className="mt-2 text-sm text-white/40">
            Create offers guests can unlock after a verified arrival.
          </p>
        </div>
        <Link
          href="/dashboard/offers/new"
          className={cn(buttonVariants({ size: "lg" }), "h-11 px-4")}
        >
          <Plus className="size-4" />
          Create offer
        </Link>
      </div>

      {params.created ? (
        <div
          role="status"
          className="flex items-start gap-2.5 rounded-md border border-primary/20 bg-primary/[0.05] px-3.5 py-3 text-sm text-white/72"
        >
          <CheckCircle2 className="mt-0.5 size-4 shrink-0 text-primary" />
          <p>
            {params.created === "review"
              ? "Offer submitted for Outly review."
              : "Draft saved. It will remain private until you submit it for review."}
          </p>
        </div>
      ) : null}

      {params.updated ? (
        <div
          role="status"
          className="flex items-start gap-2.5 rounded-md border border-primary/20 bg-primary/[0.05] px-3.5 py-3 text-sm text-white/72"
        >
          <CheckCircle2 className="mt-0.5 size-4 shrink-0 text-primary" />
          <p>{updateMessage(params.updated)}</p>
        </div>
      ) : null}

      {params.error ? (
        <div
          role="alert"
          className="rounded-md border border-red-300/15 bg-red-300/[0.04] px-3.5 py-3 text-sm text-red-100/72"
        >
          We couldn’t update that offer. Reload the page and try again.
        </div>
      ) : null}

      <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
        {offers.length ? (
          <Table>
            <TableHeader>
              <TableRow className="border-white/8 hover:bg-transparent">
                <TableHead>Offer</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="hidden md:table-cell">Review</TableHead>
                <TableHead className="hidden sm:table-cell">Timer</TableHead>
                <TableHead className="text-right">Unlocked</TableHead>
                <TableHead className="text-right">Action</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {offers.map((offer) => (
                <TableRow key={offer.offerId} className="border-white/8 align-top">
                  <TableCell>
                    <p className="font-medium text-white/82">{offer.title}</p>
                    {offer.latestFeedback?.publicResponse ? (
                      <div className="mt-2 max-w-lg border-l border-amber-200/35 pl-2.5">
                        <p className="text-[10px] uppercase tracking-[0.13em] text-amber-100/48">
                          Outly feedback
                        </p>
                        <p className="mt-1 text-xs leading-5 text-white/52">
                          {offer.latestFeedback.publicResponse}
                        </p>
                      </div>
                    ) : null}
                    <p className="mt-1 text-[11px] text-white/30 sm:hidden">
                      {formatTimer(offer.claimDurationSeconds)}
                    </p>
                  </TableCell>
                  <TableCell>
                    <StatusBadge status={offer.lifecycleStatus} />
                  </TableCell>
                  <TableCell className="hidden md:table-cell">
                    <span className="text-xs text-white/48">
                      {presentStatus(offer.approvalState ?? "not_submitted")}
                    </span>
                  </TableCell>
                  <TableCell className="hidden text-white/42 sm:table-cell">
                    {formatTimer(offer.claimDurationSeconds)}
                  </TableCell>
                  <TableCell className="numeric text-right">
                    {offer.unlockedCount.toLocaleString("en-CA")}
                  </TableCell>
                  <TableCell>
                    <div className="flex min-w-32 justify-end gap-1.5">
                      {offer.canEdit ? (
                        <Link
                          href={`/dashboard/offers/${offer.offerId}`}
                          className={cn(
                            buttonVariants({ variant: "ghost", size: "sm" }),
                            "h-9 px-2.5 text-white/72",
                          )}
                        >
                          <PencilLine className="size-3.5" />
                          {offer.lifecycleStatus === "changes_requested"
                            ? "Revise"
                            : "Edit"}
                        </Link>
                      ) : null}
                      {offer.canArchive ? (
                        <StatusAction
                          offerId={offer.offerId}
                          targetStatus="archived"
                          label="Archive"
                        />
                      ) : offer.canEnd ? (
                        <StatusAction
                          offerId={offer.offerId}
                          targetStatus="ended"
                          label="End"
                        />
                      ) : null}
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        ) : (
          <div className="px-5 py-14 text-center sm:px-6">
            <p className="font-medium">No offers yet</p>
            <p className="mx-auto mt-2 max-w-md text-sm leading-6 text-white/40">
              Create a clear incentive, choose when it is available, and submit it for review.
            </p>
            <Link
              href="/dashboard/offers/new"
              className={cn(buttonVariants({ size: "lg" }), "mt-6 h-11 px-4")}
            >
              <Plus className="size-4" />
              Create first offer
            </Link>
          </div>
        )}
        <div className="border-t border-white/8 px-5 py-4 text-[11px] text-white/32">
          {activeOfferCount} of {activeOfferLimit} active offer slots used ·{" "}
          {presentStatus(snapshot.subscription.planCode)} plan
        </div>
      </section>

      <section className="grid gap-5 md:grid-cols-3">
        <OfferPrinciple
          number="01"
          title="Clear value"
          copy="Staff and guests should understand the offer in one glance."
        />
        <OfferPrinciple
          number="02"
          title="Your timing"
          copy="Set a schedule and an optional redeem-by timer, or leave the offer open-ended."
        />
        <OfferPrinciple
          number="03"
          title="Verified arrival"
          copy="The offer only appears after the app confirms the venue geofence."
        />
      </section>
    </div>
  );
}

function StatusAction({
  offerId,
  targetStatus,
  label,
}: {
  offerId: string;
  targetStatus: "ended" | "archived";
  label: string;
}) {
  return (
    <form action={setVenueOfferStatus}>
      <input type="hidden" name="offerId" value={offerId} />
      <input type="hidden" name="idempotencyKey" value={crypto.randomUUID()} />
      <input type="hidden" name="targetStatus" value={targetStatus} />
      <Button
        type="submit"
        variant="ghost"
        size="sm"
        className="h-9 px-2.5 text-white/42 hover:text-white/76"
      >
        {targetStatus === "archived" ? (
          <Archive className="size-3.5" />
        ) : (
          <Square className="size-3.5" />
        )}
        {label}
      </Button>
    </form>
  );
}

function updateMessage(value: string) {
  if (value === "review") return "Your revised offer is back with Outly for review.";
  if (value === "draft") return "Your revised draft was saved.";
  if (value === "ended") return "The offer has ended and no new guests can unlock it.";
  if (value === "archived") return "The offer was archived.";
  return "The offer was updated.";
}

function StatusBadge({ status }: { status: string }) {
  const live = ["live", "approved", "scheduled"].includes(status);
  const review = ["pending_review", "changes_requested"].includes(status);

  return (
    <Badge
      variant="outline"
      className={cn(
        "rounded-sm capitalize",
        live
          ? "border-primary/25 text-primary"
          : review
            ? "border-amber-300/20 text-amber-100/80"
            : "border-white/12 text-white/46",
      )}
    >
      {presentStatus(status)}
    </Badge>
  );
}

function formatTimer(seconds: number | null) {
  if (seconds === null) return "No timer";
  if (seconds < 60) return `${seconds} sec`;
  if (seconds % 60 === 0) return `${seconds / 60} min`;
  return `${Math.floor(seconds / 60)}m ${seconds % 60}s`;
}

function presentStatus(value: string) {
  return value.replaceAll("_", " ").replace(/\b\w/g, (letter) =>
    letter.toUpperCase(),
  );
}

function OfferPrinciple({
  number,
  title,
  copy,
}: {
  number: string;
  title: string;
  copy: string;
}) {
  return (
    <div className="border-t border-white/12 pt-5">
      <p className="font-mono text-[10px] text-primary">{number}</p>
      <h2 className="mt-5 font-medium">{title}</h2>
      <p className="mt-2 text-sm leading-6 text-white/38">{copy}</p>
    </div>
  );
}
