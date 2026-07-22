import Link from "next/link";
import { Download, Info, LockKeyhole } from "lucide-react";
import { DashboardUnavailable } from "@/components/dashboard/dashboard-unavailable";
import { Badge } from "@/components/ui/badge";
import { Button, buttonVariants } from "@/components/ui/button";
import { requireVenueSession } from "@/lib/auth/venue";
import {
  loadVenueDashboardSnapshot,
  type VenueDashboardSnapshot,
} from "@/lib/data/venue-dashboard";
import { cn } from "@/lib/utils";

export default async function AnalyticsPage() {
  const session = await requireVenueSession();
  const result = await loadVenueDashboardSnapshot(session.userId);

  if (!result.data) {
    return (
      <DashboardUnavailable
        configuration={result.error === "configuration"}
        title="We couldn’t load venue analytics."
      />
    );
  }

  const snapshot = result.data;
  const period = formatPeriod(snapshot.period.start, snapshot.period.end);
  const returning = snapshot.metrics.returningVisitors;
  const summary = [
    {
      label: "Verified visitors",
      value: snapshot.metrics.verifiedCheckIns.toLocaleString("en-CA"),
      note: `${snapshot.metrics.checkInAttempts.toLocaleString("en-CA")} check-in attempts`,
    },
    {
      label: "Returning visitors",
      value: returning === null ? "Pro" : returning.toLocaleString("en-CA"),
      note:
        returning === null
          ? "Repeat-visitor insights not included"
          : "Prior verified visit in the configured window",
    },
    {
      label: "Plans",
      value: snapshot.metrics.plans.toLocaleString("en-CA"),
      note: "People who selected this venue",
    },
    {
      label: "Offers unlocked",
      value: snapshot.metrics.offersUnlocked.toLocaleString("en-CA"),
      note: "After verified arrival",
    },
  ];

  return (
    <div className="space-y-8">
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
        <div>
          <p className="font-mono text-[10px] uppercase tracking-[0.17em] text-primary">
            Analytics
          </p>
          <h1 className="mt-2 text-3xl font-medium tracking-[-0.035em] sm:text-4xl">
            Attendance and return visits
          </h1>
          <p className="mt-2 text-sm text-white/46">
            Aggregated venue trends. No individual guest profiles.
          </p>
        </div>
        <Button
          variant="outline"
          size="lg"
          className="h-11 border-white/12"
          disabled
          title="Analytics export is not connected yet"
        >
          <Download className="size-4" />
          Export not connected
        </Button>
      </div>

      <div className="flex flex-wrap items-center gap-3 border-b border-white/10 pb-5">
        <Badge
          variant="outline"
          className="h-8 rounded-sm border-primary/25 px-3 text-primary"
        >
          Current period
        </Badge>
        <span className="text-[11px] text-white/34">{period}</span>
        <span className="ml-auto text-[11px] text-white/30">
          {snapshot.period.maximumHistoryDays}-day history entitlement ·{" "}
          {presentStatus(snapshot.subscription.planCode)} plan
        </span>
      </div>

      <section
        className="grid overflow-hidden rounded-lg border border-white/10 bg-card sm:grid-cols-2 xl:grid-cols-4"
        aria-label="Analytics summary"
      >
        {summary.map((metric) => (
          <AnalyticMetric key={metric.label} {...metric} />
        ))}
      </section>

      <div className="grid gap-5 xl:grid-cols-[1.12fr_.88fr]">
        <section className="rounded-lg border border-white/10 bg-card p-5 sm:p-6">
          <div>
            <h2 className="font-medium">Plans and verified arrivals</h2>
            <p className="mt-1 text-xs text-white/38">
              Unique people by nightlife date
            </p>
          </div>
          <AttendanceChart activity={snapshot.dailyActivity} />
          <div className="mt-5 flex gap-5 border-t border-white/8 pt-4 text-[11px] text-white/42">
            <Legend color="bg-white/26" label="Plans" />
            <Legend color="bg-primary" label="Verified check-ins" />
          </div>
        </section>

        <section className="rounded-lg border border-white/10 bg-card p-5 sm:p-6">
          <div className="flex items-start justify-between gap-4">
            <div>
              <h2 className="font-medium">Check-ins by time</h2>
              <p className="mt-1 text-xs text-white/38">
                {snapshot.metrics.verifiedCheckIns.toLocaleString("en-CA")} verified
                arrivals · venue-local time
              </p>
            </div>
            <Info className="size-4 text-white/32" aria-hidden="true" />
          </div>
          <HourlyCheckIns entries={snapshot.checkInsByHour} />
          <p className="mt-6 border-t border-white/8 pt-4 text-[10px] leading-4 text-white/30">
            Observed check-ins only. This is not a demand forecast.
          </p>
        </section>
      </div>

      <section className="grid overflow-hidden rounded-lg border border-white/10 bg-card lg:grid-cols-2">
        <VisitorMix snapshot={snapshot} />
        <Demographics snapshot={snapshot} />
      </section>

      <p className="flex max-w-3xl gap-2 text-[11px] leading-5 text-white/32">
        <Info className="mt-0.5 size-3.5 shrink-0" />
        Demographics are hidden below the minimum cohort and never expose dates
        of birth, individual genders, names, contact information, or precise
        location history.
      </p>
    </div>
  );
}

function AttendanceChart({
  activity,
}: {
  activity: VenueDashboardSnapshot["dailyActivity"];
}) {
  const max = Math.max(
    1,
    ...activity.flatMap((item) => [item.plans, item.verifiedCheckIns]),
  );

  if (!activity.length) {
    return <EmptyState copy="No plan or arrival activity in this period." />;
  }

  return (
    <>
      <div
        className="mt-10 grid h-64 items-end gap-3 sm:gap-6"
        style={{
          gridTemplateColumns: `repeat(${activity.length}, minmax(0, 1fr))`,
        }}
        aria-label="Plans and verified check-ins by nightlife date"
      >
        {activity.map((item) => (
          <div key={item.date} className="flex h-full flex-col justify-end gap-2">
            <div
              className="mx-auto flex h-[82%] w-full max-w-12 items-end gap-1"
              title={`${item.date}: ${item.plans} plans and ${item.verifiedCheckIns} verified check-ins`}
            >
              <span
                className="w-1/2 bg-white/24"
                style={{ height: `${Math.max(2, (item.plans / max) * 100)}%` }}
              />
              <span
                className="w-1/2 bg-primary"
                style={{
                  height: `${Math.max(2, (item.verifiedCheckIns / max) * 100)}%`,
                }}
              />
            </div>
            <span className="text-center font-mono text-[9px] text-white/32">
              {formatDay(item.date)}
            </span>
          </div>
        ))}
      </div>
      <table className="sr-only">
        <caption>Plans and verified check-ins by nightlife date</caption>
        <thead>
          <tr>
            <th>Date</th>
            <th>Plans</th>
            <th>Verified check-ins</th>
          </tr>
        </thead>
        <tbody>
          {activity.map((item) => (
            <tr key={item.date}>
              <td>{item.date}</td>
              <td>{item.plans}</td>
              <td>{item.verifiedCheckIns}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </>
  );
}

function HourlyCheckIns({
  entries,
}: {
  entries: VenueDashboardSnapshot["checkInsByHour"];
}) {
  const sorted = [...entries].sort((a, b) => a.hour - b.hour);
  const max = Math.max(1, ...sorted.map((item) => item.count));

  if (!sorted.length) {
    return <EmptyState copy="No verified arrivals in this period." compact />;
  }

  return (
    <div className="mt-8 space-y-4">
      {sorted.map((item) => (
        <div
          key={item.hour}
          className="grid grid-cols-[4rem_1fr_2.5rem] items-center gap-3"
        >
          <span className="text-xs text-white/48">{formatHour(item.hour)}</span>
          <span className="h-2 bg-white/6">
            <i
              className="block h-full bg-primary/72"
              style={{ width: `${(item.count / max) * 100}%` }}
            />
          </span>
          <span className="numeric text-right text-xs text-white/54">
            {item.count}
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
      <div className="border-b border-white/10 p-5 sm:p-6 lg:border-b-0 lg:border-r">
        <LockedInsight
          title="First-time and returning visitors"
          copy="Privacy-safe repeat-visitor insights are not included in your current plan."
        />
      </div>
    );
  }

  const returningCount = Math.min(total, returning);
  const firstTime = Math.max(0, total - returningCount);
  const returningPercent = total
    ? Math.round((returningCount / total) * 100)
    : 0;
  const firstTimePercent = 100 - returningPercent;

  return (
    <div className="border-b border-white/10 p-5 sm:p-6 lg:border-b-0 lg:border-r">
      <h2 className="font-medium">Visitor mix</h2>
      <p className="mt-1 text-xs text-white/38">Verified visits in this period</p>
      <div
        className="mt-9 flex h-3 overflow-hidden bg-white/6"
        aria-label={`${firstTimePercent} percent first-time and ${returningPercent} percent returning visitors`}
      >
        <span
          className="bg-white/26"
          style={{ width: `${firstTimePercent}%` }}
        />
        <span className="bg-primary" style={{ width: `${returningPercent}%` }} />
      </div>
      <div className="mt-7 space-y-5">
        <VisitorRow
          label="First-time"
          value={firstTime}
          percent={firstTimePercent}
        />
        <VisitorRow
          label="Returning"
          value={returningCount}
          percent={returningPercent}
          accent
        />
      </div>
      <p className="mt-7 border-t border-white/8 pt-4 text-[10px] leading-4 text-white/30">
        Returning means at least one earlier verified visit within the configured
        privacy-safe window.
      </p>
    </div>
  );
}

function Demographics({ snapshot }: { snapshot: VenueDashboardSnapshot }) {
  const demographics = snapshot.demographics;

  if (!demographics) {
    return (
      <div className="p-5 sm:p-6">
        <LockedInsight
          title="Verified visitor profile"
          copy={
            snapshot.subscription.entitlements.advancedDemographics
              ? "This period has not reached the minimum privacy cohort, so demographics remain hidden."
              : "Aggregated age and gender insights are not included in your current plan."
          }
          privacy={snapshot.subscription.entitlements.advancedDemographics}
        />
      </div>
    );
  }

  const gender = demographics.gender;

  return (
    <div className="p-5 sm:p-6">
      <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-start">
        <div>
          <h2 className="font-medium">Verified visitor profile</h2>
          <p className="mt-1 text-xs text-white/38">
            Aggregated for the current period
          </p>
        </div>
        <Badge
          variant="outline"
          className="w-fit rounded-sm border-white/12 text-white/48"
        >
          {demographics.cohortSize.toLocaleString("en-CA")} people
        </Badge>
      </div>

      <div className="mt-9 grid gap-8 sm:grid-cols-[.65fr_1.35fr] sm:items-end">
        <div>
          <p className="text-xs text-white/40">Average age</p>
          <p className="numeric mt-3 text-5xl font-medium tracking-[-0.05em]">
            {demographics.averageAge}
          </p>
        </div>
        <div>
          <p className="text-xs text-white/40">Gender distribution</p>
          <div
            className="mt-5 flex h-2 gap-1"
            aria-label={`${gender.man} percent men, ${gender.woman} percent women, and ${gender.other} percent another gender`}
          >
            <span className="bg-[#57a6ff]" style={{ width: `${gender.man}%` }} />
            <span
              className="bg-[#ff70b8]"
              style={{ width: `${gender.woman}%` }}
            />
            <span className="bg-white/35" style={{ width: `${gender.other}%` }} />
          </div>
          <div className="mt-4 space-y-3 text-xs">
            <GenderRow color="bg-[#57a6ff]" label="Man" value={gender.man} />
            <GenderRow
              color="bg-[#ff70b8]"
              label="Woman"
              value={gender.woman}
            />
            <GenderRow
              color="bg-white/35"
              label="Another gender"
              value={gender.other}
            />
          </div>
        </div>
      </div>
    </div>
  );
}

function LockedInsight({
  title,
  copy,
  privacy = false,
}: {
  title: string;
  copy: string;
  privacy?: boolean;
}) {
  return (
    <div>
      <div className="flex items-center gap-2">
        <LockKeyhole className="size-4 text-white/32" />
        <h2 className="font-medium">{title}</h2>
      </div>
      <p className="mt-4 max-w-md text-sm leading-6 text-white/42">{copy}</p>
      {privacy ? (
        <p className="mt-5 text-[11px] text-white/30">Privacy threshold active</p>
      ) : (
        <Link
          href="/dashboard/billing"
          className={cn(
            buttonVariants({ variant: "outline", size: "sm" }),
            "mt-6 border-white/12",
          )}
        >
          View plan
        </Link>
      )}
    </div>
  );
}

function AnalyticMetric({
  label,
  value,
  note,
}: {
  label: string;
  value: string;
  note: string;
}) {
  return (
    <div className="border-b border-white/10 p-5 odd:border-r sm:nth-[3]:border-b-0 sm:nth-[4]:border-b-0 xl:border-b-0 xl:border-r xl:last:border-r-0">
      <p className="text-xs text-white/42">{label}</p>
      <p className="numeric mt-4 text-4xl font-medium tracking-[-0.05em]">
        {value}
      </p>
      <p className="mt-2 text-[11px] text-white/32">{note}</p>
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
        <span className={accent ? "size-2 bg-primary" : "size-2 bg-white/26"} />
        {label}
      </div>
      <div className="text-right">
        <span className="numeric text-xl font-medium">{value}</span>
        <span className="numeric ml-2 text-xs text-white/38">{percent}%</span>
      </div>
    </div>
  );
}

function GenderRow({
  color,
  label,
  value,
}: {
  color: string;
  label: string;
  value: number;
}) {
  return (
    <div className="flex items-center">
      <span className={`mr-2 size-2 ${color}`} />
      <span className="text-white/50">{label}</span>
      <span className="numeric ml-auto">{value}%</span>
    </div>
  );
}

function EmptyState({
  copy,
  compact = false,
}: {
  copy: string;
  compact?: boolean;
}) {
  return (
    <div
      className={cn(
        "mt-8 flex items-center justify-center border-y border-white/8 text-xs text-white/32",
        compact ? "h-40" : "h-64",
      )}
    >
      {copy}
    </div>
  );
}

function Legend({ color, label }: { color: string; label: string }) {
  return (
    <span className="flex items-center gap-2">
      <i className={`size-2 ${color}`} />
      {label}
    </span>
  );
}

function formatDay(value: string) {
  const date = new Date(value.includes("T") ? value : `${value}T12:00:00Z`);
  if (Number.isNaN(date.valueOf())) return value;

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
  return `${display}:00 ${normalized < 12 ? "AM" : "PM"}`;
}

function presentStatus(value: string) {
  return value.replaceAll("_", " ").replace(/\b\w/g, (letter) =>
    letter.toUpperCase(),
  );
}
