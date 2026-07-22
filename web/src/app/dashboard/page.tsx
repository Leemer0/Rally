import Link from "next/link";
import {
  ArrowRight,
  CheckCircle2,
  Clock3,
  MoreHorizontal,
  RefreshCw,
} from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { buttonVariants } from "@/components/ui/button";
import { requireVenueSession } from "@/lib/auth/venue";
import {
  loadVenueDashboardSnapshot,
  type VenueDashboardSnapshot,
} from "@/lib/data/venue-dashboard";
import { cn } from "@/lib/utils";

export default async function DashboardOverviewPage() {
  const session = await requireVenueSession();
  const result = await loadVenueDashboardSnapshot(session.userId);

  if (!result.data) {
    return <DashboardUnavailable configuration={result.error === "configuration"} />;
  }

  const snapshot = result.data;
  const activeOffer =
    snapshot.offers.find((offer) => offer.status === "live") ??
    snapshot.offers.find((offer) => offer.status === "scheduled") ??
    snapshot.offers.find((offer) => offer.status === "approved") ??
    null;
  const period = formatPeriod(snapshot.period.start, snapshot.period.end);
  const planLabel = snapshot.subscription.planCode === "free" ? "Free" : "Pro";

  const metrics = [
    {
      label: "Venue impressions",
      value: snapshot.metrics.impressions,
      note: "Unique people who saw this venue",
    },
    {
      label: "Plans",
      value: snapshot.metrics.plans,
      note: "People who selected this venue",
    },
    {
      label: "Verified check-ins",
      value: snapshot.metrics.verifiedCheckIns,
      note: `${snapshot.metrics.checkInAttempts} total attempts`,
    },
    {
      label: "Offers unlocked",
      value: snapshot.metrics.offersUnlocked,
      note: "After verified arrival",
    },
  ];

  return (
    <div className="space-y-8">
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
        <div>
          <p className="font-mono text-[10px] uppercase tracking-[0.17em] text-primary">
            Overview
          </p>
          <h1 className="mt-2 text-3xl font-medium tracking-[-0.035em] sm:text-4xl">
            Performance at a glance
          </h1>
          <p className="mt-2 text-sm text-white/46">
            {period} · {planLabel} plan
          </p>
        </div>
        <Link
          href="/dashboard/offers/new"
          className={cn(buttonVariants({ size: "lg" }), "h-11 px-4")}
        >
          Create offer
        </Link>
      </div>

      <section
        className="grid grid-cols-2 overflow-hidden rounded-lg border border-white/10 bg-card xl:grid-cols-4"
        aria-label="Key metrics"
      >
        {metrics.map((metric) => (
          <div
            key={metric.label}
            className="border-b border-r border-white/10 p-4 odd:border-r even:border-r-0 nth-[3]:border-b-0 nth-[4]:border-b-0 sm:p-5 xl:border-b-0 xl:border-r xl:nth-[3]:border-r xl:last:border-r-0"
          >
            <p className="text-xs text-white/38">{metric.label}</p>
            <p className="numeric mt-5 text-4xl font-medium tracking-[-0.05em]">
              {metric.value.toLocaleString("en-CA")}
            </p>
            <p className="mt-2 text-[11px] text-white/28">{metric.note}</p>
          </div>
        ))}
      </section>

      <div className="grid gap-5 xl:grid-cols-[1.45fr_.55fr]">
        <section className="rounded-lg border border-white/10 bg-card p-5 sm:p-6">
          <div className="flex items-start justify-between gap-4">
            <div>
              <h2 className="font-medium">Plans and arrivals</h2>
              <p className="mt-1 text-xs text-white/34">
                Same-night plans compared with verified check-ins
              </p>
            </div>
            <Link
              href="/dashboard/analytics"
              className="text-xs text-white/44 hover:text-white"
            >
              Full analytics
            </Link>
          </div>
          <ActivityChart activity={snapshot.dailyActivity} />
          <div className="mt-5 flex flex-wrap gap-5 border-t border-white/8 pt-4 text-[11px] text-white/38">
            <Legend color="bg-white/28" label="Plans" />
            <Legend color="bg-primary" label="Verified check-ins" />
          </div>
        </section>

        <section className="rounded-lg border border-white/10 bg-card p-5 sm:p-6">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="font-medium">Current offer</h2>
              <p className="mt-1 text-xs text-white/34">Approved venue offer</p>
            </div>
            <Link
              href="/dashboard/offers"
              className={cn(buttonVariants({ variant: "ghost", size: "icon-sm" }))}
              aria-label="Manage offers"
            >
              <MoreHorizontal />
            </Link>
          </div>

          {activeOffer ? (
            <>
              <div className="mt-7 border-l-2 border-primary pl-4">
                <p className="text-lg font-medium tracking-[-0.02em]">
                  {activeOffer.title}
                </p>
                <p className="mt-2 flex items-center gap-2 text-xs text-white/56">
                  <Clock3 className="size-3.5" />
                  {activeOffer.claimDurationSeconds
                    ? `${Math.ceil(activeOffer.claimDurationSeconds / 60)} minute claim window`
                    : "No countdown after unlock"}
                </p>
              </div>
              <div className="mt-7 space-y-4">
                <div className="flex justify-between border-y border-white/8 py-4 text-xs">
                  <span className="text-white/42">Offers unlocked</span>
                  <span className="numeric">{activeOffer.unlockedCount}</span>
                </div>
                <div className="flex items-center gap-2 border-t border-white/8 pt-4 text-xs text-white/42">
                  <CheckCircle2 className="size-4 text-primary" />
                  Available after verified check-in
                </div>
              </div>
            </>
          ) : (
            <div className="mt-7 border-y border-white/8 py-8">
              <p className="text-sm font-medium">No active offer</p>
              <p className="mt-2 text-xs leading-5 text-white/38">
                Create an offer, then submit it for approval.
              </p>
            </div>
          )}

          <Link
            href="/dashboard/offers"
            className="mt-6 inline-flex items-center gap-1 text-xs text-white/48 hover:text-white"
          >
            Manage offers <ArrowRight className="size-3" />
          </Link>
        </section>
      </div>

      <section className="grid overflow-hidden rounded-lg border border-white/10 bg-card lg:grid-cols-[1.25fr_.75fr]">
        <div className="border-b border-white/10 p-5 sm:p-6 lg:border-b-0 lg:border-r">
          <div className="flex items-start justify-between gap-4">
            <div>
              <h2 className="font-medium">Check-ins by time</h2>
              <p className="mt-1 text-xs text-white/38">
                Verified arrivals in venue-local time
              </p>
            </div>
            <span className="numeric text-xs text-white/42">
              {snapshot.metrics.verifiedCheckIns} total
            </span>
          </div>
          <HourlyCheckIns entries={snapshot.checkInsByHour} />
        </div>

        <VisitorMix snapshot={snapshot} />
      </section>

      <p className="max-w-3xl text-[11px] leading-5 text-white/30">
        Dashboard totals are aggregated. Venues never receive guest names,
        contact details, individual timelines, or precise location data.
      </p>
    </div>
  );
}

function DashboardUnavailable({ configuration }: { configuration: boolean }) {
  return (
    <div className="mx-auto max-w-2xl py-16">
      <Badge variant="outline" className="rounded-sm border-white/12 text-white/48">
        Dashboard unavailable
      </Badge>
      <h1 className="mt-5 text-3xl font-medium tracking-[-0.035em]">
        We couldn’t load venue analytics.
      </h1>
      <p className="mt-3 max-w-xl text-sm leading-6 text-white/46">
        {configuration
          ? "The secure server connection has not been configured for this environment."
          : "Your account is secure. The analytics service did not return a snapshot, so no sample data is being shown."}
      </p>
      <Link
        href="/dashboard"
        className={cn(buttonVariants({ variant: "outline" }), "mt-7 border-white/12")}
      >
        <RefreshCw className="size-4" /> Try again
      </Link>
    </div>
  );
}

function ActivityChart({
  activity,
}: {
  activity: VenueDashboardSnapshot["dailyActivity"];
}) {
  const max = Math.max(
    1,
    ...activity.flatMap((item) => [item.plans, item.verifiedCheckIns]),
  );

  if (activity.length === 0) {
    return <EmptyChart copy="No activity in this period." />;
  }

  return (
    <div
      className="mt-8 grid h-56 items-end gap-2 sm:gap-4"
      style={{ gridTemplateColumns: `repeat(${activity.length}, minmax(0, 1fr))` }}
      aria-label="Plans and verified check-ins by date"
    >
      {activity.map((item) => (
        <div key={item.date} className="flex h-full flex-col justify-end gap-2">
          <div
            className="relative mx-auto flex h-[85%] w-full max-w-12 items-end justify-center gap-1"
            title={`${item.date}: ${item.plans} plans, ${item.verifiedCheckIns} verified check-ins`}
          >
            <span
              className="w-1/2 bg-white/20"
              style={{ height: `${Math.max(2, (item.plans / max) * 100)}%` }}
            />
            <span
              className="w-1/2 bg-primary"
              style={{
                height: `${Math.max(2, (item.verifiedCheckIns / max) * 100)}%`,
              }}
            />
          </div>
          <span className="text-center font-mono text-[9px] text-white/28">
            {formatDay(item.date)}
          </span>
        </div>
      ))}
    </div>
  );
}

function HourlyCheckIns({
  entries,
}: {
  entries: VenueDashboardSnapshot["checkInsByHour"];
}) {
  const sorted = [...entries].sort((a, b) => a.hour - b.hour);
  const max = Math.max(1, ...sorted.map((entry) => entry.count));

  if (sorted.length === 0) {
    return <EmptyChart copy="No verified arrivals in this period." />;
  }

  return (
    <div
      className="mt-8 flex h-32 items-end gap-2 sm:gap-4"
      aria-label="Verified check-ins by hour"
    >
      {sorted.map((entry) => (
        <div
          key={entry.hour}
          className="flex h-full flex-1 flex-col justify-end gap-2"
          title={`${formatHour(entry.hour)}: ${entry.count} verified check-ins`}
        >
          <span className="numeric text-center text-[10px] text-white/42">
            {entry.count}
          </span>
          <span
            className="mx-auto w-full max-w-10 bg-primary/72"
            style={{ height: `${Math.max(8, (entry.count / max) * 78)}%` }}
          />
          <span className="text-center font-mono text-[9px] text-white/30">
            {formatHour(entry.hour)}
          </span>
        </div>
      ))}
    </div>
  );
}

function VisitorMix({ snapshot }: { snapshot: VenueDashboardSnapshot }) {
  const returning = snapshot.metrics.returningVisitors;
  const total = snapshot.metrics.verifiedCheckIns;

  if (returning === null) {
    return (
      <div className="p-5 sm:p-6">
        <h2 className="font-medium">Returning visitors</h2>
        <p className="mt-1 text-xs text-white/38">Available with Outly Pro</p>
        <div className="mt-8 border-l-2 border-primary pl-4">
          <p className="text-3xl font-medium tracking-[-0.04em]">Know who comes back.</p>
          <p className="mt-3 text-xs leading-5 text-white/42">
            Pro adds privacy-safe repeat visitor trends without exposing guest profiles.
          </p>
        </div>
        <Link
          href="/dashboard/billing"
          className="mt-7 inline-flex items-center gap-1 text-xs text-white/48 hover:text-white"
        >
          Compare plans <ArrowRight className="size-3" />
        </Link>
      </div>
    );
  }

  const returningCount = Math.min(total, returning);
  const firstTime = Math.max(0, total - returningCount);
  const returningPercent = total > 0 ? Math.round((returningCount / total) * 100) : 0;
  const firstTimePercent = 100 - returningPercent;

  return (
    <div className="p-5 sm:p-6">
      <h2 className="font-medium">Visitor mix</h2>
      <p className="mt-1 text-xs text-white/38">Verified visits in this period</p>
      <div
        className="mt-8 flex h-2 overflow-hidden bg-white/6"
        aria-label={`${firstTimePercent} percent first-time and ${returningPercent} percent returning visitors`}
      >
        <span className="bg-white/32" style={{ width: `${firstTimePercent}%` }} />
        <span className="bg-primary" style={{ width: `${returningPercent}%` }} />
      </div>
      <div className="mt-6 space-y-4">
        <VisitorRow label="First-time" value={firstTime} percent={firstTimePercent} />
        <VisitorRow
          label="Returning"
          value={returningCount}
          percent={returningPercent}
          accent
        />
      </div>
      <p className="mt-6 border-t border-white/8 pt-4 text-[10px] leading-4 text-white/30">
        Returning means a prior verified visit within the configured privacy-safe window.
      </p>
    </div>
  );
}

function VisitorRow({
  label,
  value,
  percent,
  accent = false,
}: {
  label: string;
  value: number;
  percent: number;
  accent?: boolean;
}) {
  return (
    <div className="flex items-end justify-between gap-4">
      <div className="flex items-center gap-2 text-sm text-white/54">
        <span className={cn("size-2", accent ? "bg-primary" : "bg-white/32")} />
        {label}
      </div>
      <div className="text-right">
        <span className="numeric text-lg font-medium">{value}</span>
        <span className="numeric ml-2 text-xs text-white/34">{percent}%</span>
      </div>
    </div>
  );
}

function EmptyChart({ copy }: { copy: string }) {
  return (
    <div className="mt-8 flex h-56 items-center justify-center border-y border-white/8 text-xs text-white/32">
      {copy}
    </div>
  );
}

function formatDay(value: string) {
  const date = new Date(value.includes("T") ? value : `${value}T12:00:00Z`);

  if (Number.isNaN(date.valueOf())) {
    return value;
  }

  return new Intl.DateTimeFormat("en-CA", {
    weekday: "short",
    timeZone: "UTC",
  }).format(date);
}

function formatPeriod(start: string, end: string) {
  const startDate = new Date(`${start}T12:00:00Z`);
  const endDate = new Date(`${end}T12:00:00Z`);

  if (Number.isNaN(startDate.valueOf()) || Number.isNaN(endDate.valueOf())) {
    return "Current reporting period";
  }

  const formatter = new Intl.DateTimeFormat("en-CA", {
    month: "short",
    day: "numeric",
    timeZone: "UTC",
  });

  return `${formatter.format(startDate)}–${formatter.format(endDate)}`;
}

function formatHour(hour: number) {
  const normalized = ((hour % 24) + 24) % 24;
  const display = normalized % 12 || 12;
  return `${display}${normalized < 12 ? "a" : "p"}`;
}

function Legend({ color, label }: { color: string; label: string }) {
  return (
    <span className="flex items-center gap-2">
      <i className={cn("size-2", color)} />
      {label}
    </span>
  );
}
