import Link from "next/link";
import { ArrowRight, Plus, Send } from "lucide-react";
import { AdminPageHeader, DemoNotice, StatusBadge } from "@/components/admin/admin-ui";
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
  adminOverviewMetrics,
  adminQueue,
  checkInDistribution,
  networkActivity,
  returnCohorts,
  venues,
} from "@/lib/admin-demo-data";
import { cn } from "@/lib/utils";

export default function AdminOverviewPage() {
  return (
    <div className="space-y-7">
      <AdminPageHeader
        title="Network operations"
        description="Review demand, verified arrivals, venue health, and work that needs founder attention."
        action={
          <div className="flex gap-2">
            <Link
              href="/admin/assignments/new"
              className={cn(
                buttonVariants({ variant: "outline", size: "lg" }),
                "h-11 border-white/12 px-4",
              )}
            >
              <Send className="size-4" />
              Assign offer
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

      <DemoNotice />

      <section
        className="grid overflow-hidden rounded-lg border border-white/10 bg-card sm:grid-cols-2 xl:grid-cols-4"
        aria-label="Network summary"
      >
        {adminOverviewMetrics.map((metric) => (
          <div
            key={metric.label}
            className="border-b border-white/10 p-4 sm:border-r sm:p-5 sm:nth-[3]:border-b-0 sm:nth-[4]:border-b-0 sm:even:border-r-0 xl:border-b-0 xl:even:border-r xl:last:border-r-0"
          >
            <p className="text-xs text-white/46">{metric.label}</p>
            <p className="numeric mt-4 font-mono text-3xl font-medium tracking-[-0.04em]">
              {metric.value}
            </p>
            <p className="mt-1.5 text-[11px] text-white/36">{metric.note}</p>
          </div>
        ))}
      </section>

      <div className="grid gap-5 xl:grid-cols-[1.45fr_.55fr]">
        <section className="rounded-lg border border-white/10 bg-card p-5 sm:p-6">
          <div>
            <h2 className="font-medium">Network activity</h2>
            <p className="mt-1 text-xs text-white/38">
              Plans and verified check-ins across the network, last 7 days
            </p>
          </div>
          <NetworkChart />
        </section>

        <section className="rounded-lg border border-white/10 bg-card p-5 sm:p-6">
          <div>
            <h2 className="font-medium">Check-in time</h2>
            <p className="mt-1 text-xs text-white/38">
              Verified arrivals by hour, Friday and Saturday
            </p>
          </div>
          <CheckInChart />
        </section>
      </div>

      <div className="grid gap-5 xl:grid-cols-[.72fr_1.28fr]">
        <section className="rounded-lg border border-white/10 bg-card p-5 sm:p-6">
          <div>
            <h2 className="font-medium">Returning visitors</h2>
            <p className="mt-1 text-xs text-white/38">
              Verified visitors by visit frequency in the last 90 days
            </p>
          </div>
          <div className="mt-7 space-y-5">
            {returnCohorts.map((cohort) => (
              <div key={cohort.label}>
                <div className="mb-2 flex items-baseline justify-between gap-4">
                  <span className="text-xs text-white/54">{cohort.label}</span>
                  <span className="numeric font-mono text-xs">{cohort.value}%</span>
                </div>
                <div className="h-1 bg-white/[0.055]">
                  <div
                    className={cn(
                      "h-full",
                      cohort.label === "First visit" ? "bg-white/30" : "bg-primary/80",
                    )}
                    style={{ width: `${cohort.value}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
          <p className="mt-7 border-t border-white/8 pt-4 text-[11px] leading-5 text-white/34">
            A returning visitor has an earlier verified check-in within 90 days.
          </p>
        </section>

        <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
          <div className="flex items-start justify-between gap-4 px-5 py-5 sm:px-6">
            <div>
              <h2 className="font-medium">Venue health</h2>
              <p className="mt-1 text-xs text-white/38">
                Highest verified activity in this demo cohort
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
          <Table>
            <TableHeader>
              <TableRow className="border-white/8 hover:bg-transparent">
                <TableHead className="pl-5 sm:pl-6">Venue</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="hidden sm:table-cell">30-day check-ins</TableHead>
                <TableHead className="hidden md:table-cell">Repeat rate</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {venues.slice(0, 4).map((venue) => (
                <TableRow key={venue.id} className="border-white/8">
                  <TableCell className="pl-5 sm:pl-6">
                    <Link
                      href={`/admin/venues/${venue.id}`}
                      className="font-medium text-white/82 hover:text-primary"
                    >
                      {venue.name}
                    </Link>
                    <p className="mt-0.5 text-[11px] text-white/34">
                      {venue.neighborhood}
                    </p>
                  </TableCell>
                  <TableCell>
                    <StatusBadge status={venue.status} />
                  </TableCell>
                  <TableCell className="numeric hidden font-mono sm:table-cell">
                    {venue.checkIns30d}
                  </TableCell>
                  <TableCell className="numeric hidden font-mono md:table-cell">
                    {venue.repeatRate}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </section>
      </div>

      <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
        <div className="border-b border-white/8 px-5 py-5 sm:px-6">
          <h2 className="font-medium">Needs attention</h2>
          <p className="mt-1 text-xs text-white/38">
            Founder actions waiting in the prototype queue
          </p>
        </div>
        <div className="divide-y divide-white/8">
          {adminQueue.map((item) => (
            <Link
              key={item.label}
              href={item.href}
              className="grid min-h-16 grid-cols-[1fr_auto] items-center gap-4 px-5 py-3 transition-colors hover:bg-white/[0.025] sm:px-6"
            >
              <div>
                <p className="text-sm font-medium text-white/76">{item.label}</p>
                <p className="mt-0.5 text-xs text-white/38">{item.detail}</p>
              </div>
              <div className="flex items-center gap-3">
                <span className="text-xs text-white/48">{item.priority}</span>
                <ArrowRight className="size-3.5 text-white/34" />
              </div>
            </Link>
          ))}
        </div>
      </section>
    </div>
  );
}

function NetworkChart() {
  const max = Math.max(...networkActivity.map((item) => item.plans));

  return (
    <>
      <div
        className="mt-8 grid h-56 grid-cols-7 items-end gap-2 sm:gap-4"
        aria-label="Network activity bar chart. Saturday had the highest activity with 238 plans and 169 verified check-ins."
      >
        {networkActivity.map((item) => (
          <div key={item.day} className="flex h-full flex-col justify-end gap-2">
            <div
              className="mx-auto flex h-[88%] w-full max-w-12 items-end justify-center gap-1"
              title={`${item.day}: ${item.plans} plans, ${item.checkIns} verified check-ins`}
            >
              <span
                className="w-1/2 bg-white/18"
                style={{ height: `${(item.plans / max) * 100}%` }}
              />
              <span
                className="w-1/2 bg-primary/82"
                style={{ height: `${(item.checkIns / max) * 100}%` }}
              />
            </div>
            <span className="text-center font-mono text-[10px] text-white/36">
              {item.day}
            </span>
          </div>
        ))}
      </div>
      <div className="mt-5 flex gap-5 border-t border-white/8 pt-4 text-[11px] text-white/46">
        <span className="flex items-center gap-2">
          <i className="size-2 bg-white/22" /> Plans
        </span>
        <span className="flex items-center gap-2">
          <i className="size-2 bg-primary/82" /> Verified check-ins
        </span>
      </div>
      <table className="sr-only">
        <caption>Network activity by day</caption>
        <thead>
          <tr><th>Day</th><th>Plans</th><th>Verified check-ins</th></tr>
        </thead>
        <tbody>
          {networkActivity.map((item) => (
            <tr key={item.day}><td>{item.day}</td><td>{item.plans}</td><td>{item.checkIns}</td></tr>
          ))}
        </tbody>
      </table>
    </>
  );
}

function CheckInChart() {
  const max = Math.max(...checkInDistribution.map((item) => item.count));

  return (
    <div className="mt-7 space-y-4" aria-label="Check-in distribution by hour">
      {checkInDistribution.map((item) => (
        <div key={item.label} className="grid grid-cols-[3rem_1fr_2rem] items-center gap-3">
          <span className="font-mono text-[10px] text-white/42">{item.label}</span>
          <div className="h-1 bg-white/[0.055]">
            <div
              className="h-full bg-primary/72"
              style={{ width: `${(item.count / max) * 100}%` }}
            />
          </div>
          <span className="numeric text-right font-mono text-[11px] text-white/58">
            {item.count}
          </span>
        </div>
      ))}
      <p className="border-t border-white/8 pt-4 text-[11px] text-white/34">
        Most verified arrivals in this demo set occurred between 11 PM and midnight.
      </p>
    </div>
  );
}
