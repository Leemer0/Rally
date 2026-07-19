import Link from "next/link";
import { ArrowRight, CheckCircle2, Clock3, MoreHorizontal } from "lucide-react";
import {
  checkInTimeDistribution,
  overviewMetrics,
  tonightVisitorMix,
  weeklyActivity,
} from "@/lib/demo-data";
import { Badge } from "@/components/ui/badge";
import { buttonVariants } from "@/components/ui/button";
import { Progress } from "@/components/ui/progress";
import { cn } from "@/lib/utils";

export default function DashboardOverviewPage() {
  return (
    <div className="space-y-8">
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
        <div>
          <p className="font-mono text-[10px] uppercase tracking-[0.17em] text-primary">Overview</p>
          <h1 className="mt-2 text-3xl font-medium tracking-[-0.035em] sm:text-4xl">Tonight at a glance</h1>
          <p className="mt-2 text-sm text-white/56">Sample Friday · Demo activity through 11:45 PM</p>
        </div>
        <Link href="/dashboard/offers/new" className={cn(buttonVariants({ size: "lg" }), "h-11 px-4")}>Create offer</Link>
      </div>

      <section className="grid grid-cols-2 overflow-hidden rounded-lg border border-white/10 bg-card xl:grid-cols-4" aria-label="Key metrics">
        {overviewMetrics.map((metric) => (
          <div key={metric.label} className="border-b border-r border-white/10 p-4 odd:border-r even:border-r-0 nth-[3]:border-b-0 nth-[4]:border-b-0 sm:p-5 xl:border-b-0 xl:border-r xl:nth-[3]:border-r xl:last:border-r-0">
            <p className="text-xs text-white/38">{metric.label}</p>
            <div className="mt-5 flex items-end justify-between gap-3">
              <p className="numeric text-4xl font-medium tracking-[-0.05em]">{metric.value}</p>
              <Badge variant="secondary" className="rounded-sm text-[10px] text-primary">{metric.change}</Badge>
            </div>
            <p className="mt-2 text-[11px] text-white/28">{metric.note}</p>
          </div>
        ))}
      </section>

      <div className="grid gap-5 xl:grid-cols-[1.45fr_.55fr]">
        <section className="rounded-lg border border-white/10 bg-card p-5 sm:p-6">
          <div className="flex items-start justify-between">
            <div><h2 className="font-medium">Plans and arrivals</h2><p className="mt-1 text-xs text-white/34">Same-night plans compared with verified check-ins</p></div>
            <Link href="/dashboard/analytics" className="text-xs text-white/44 hover:text-white">Full analytics</Link>
          </div>
          <ActivityChart />
          <div className="mt-5 flex flex-wrap gap-5 border-t border-white/8 pt-4 text-[11px] text-white/38">
            <Legend color="bg-white/28" label="Plans" /><Legend color="bg-primary" label="Verified check-ins" />
          </div>
        </section>

        <section className="rounded-lg border border-white/10 bg-card p-5 sm:p-6">
          <div className="flex items-center justify-between"><div><h2 className="font-medium">Active offer</h2><p className="mt-1 text-xs text-white/34">Tonight</p></div><Link href="/dashboard/offers" className={cn(buttonVariants({ variant: "ghost", size: "icon-sm" }))} aria-label="Manage active offer"><MoreHorizontal /></Link></div>
          <div className="mt-7 border-l-2 border-primary pl-4">
            <p className="text-lg font-medium tracking-[-0.02em]">Free cover with Outly before 10 PM</p>
            <p className="mt-2 flex items-center gap-2 text-xs text-white/56"><Clock3 className="size-3.5" />8:00-10:00 PM</p>
          </div>
          <div className="mt-7 space-y-4">
            <div><div className="flex justify-between text-xs"><span className="text-white/42">Offers unlocked</span><span className="numeric">24</span></div><Progress value={77} className="mt-2 h-1.5" /></div>
            <div className="flex items-center gap-2 border-t border-white/8 pt-4 text-xs text-white/42"><CheckCircle2 className="size-4 text-primary" />Available after verified check-in</div>
          </div>
          <Link href="/dashboard/offers" className="mt-6 inline-flex items-center gap-1 text-xs text-white/48 hover:text-white">Manage offers <ArrowRight className="size-3" /></Link>
        </section>
      </div>

      <section className="grid overflow-hidden rounded-lg border border-white/10 bg-card lg:grid-cols-[1.25fr_.75fr]">
        <div className="border-b border-white/10 p-5 sm:p-6 lg:border-b-0 lg:border-r">
          <div className="flex items-start justify-between gap-4">
            <div>
              <h2 className="font-medium">Check-ins by time</h2>
              <p className="mt-1 text-xs text-white/38">Verified arrivals tonight</p>
            </div>
            <span className="numeric text-xs text-white/42">31 total</span>
          </div>
          <div className="mt-8 flex h-32 items-end gap-2 sm:gap-4" aria-label="Tonight's verified check-ins by time window">
            {checkInTimeDistribution.map((item) => {
              const tonightCount = Math.max(1, Math.round(item.count * (31 / 126)));
              return (
                <div key={item.label} className="flex h-full flex-1 flex-col justify-end gap-2" title={`${item.label}: ${tonightCount} verified check-ins`}>
                  <span className="numeric text-center text-[10px] text-white/42">{tonightCount}</span>
                  <span className="mx-auto w-full max-w-10 bg-white/24" style={{ height: `${Math.max(10, (item.count / 37) * 72)}%` }} />
                  <span className="text-center font-mono text-[9px] text-white/30">{item.shortLabel}</span>
                </div>
              );
            })}
          </div>
          <p className="mt-3 text-[10px] text-white/28">Hours shown in venue-local time.</p>
        </div>

        <div className="p-5 sm:p-6">
          <div>
            <h2 className="font-medium">Visitor mix</h2>
            <p className="mt-1 text-xs text-white/38">Based on prior verified check-ins</p>
          </div>
          <div className="mt-8 flex h-2 overflow-hidden bg-white/6" aria-label="71 percent first-time and 29 percent returning visitors">
            <span className="w-[71%] bg-white/32" />
            <span className="w-[29%] bg-primary" />
          </div>
          <div className="mt-6 space-y-4">
            {tonightVisitorMix.map((item, index) => (
              <div key={item.label} className="flex items-end justify-between gap-4">
                <div className="flex items-center gap-2 text-sm text-white/54">
                  <span className={cn("size-2", index === 0 ? "bg-white/32" : "bg-primary")} />
                  {item.label}
                </div>
                <div className="text-right">
                  <span className="numeric text-lg font-medium">{item.value}</span>
                  <span className="numeric ml-2 text-xs text-white/34">{item.percent}%</span>
                </div>
              </div>
            ))}
          </div>
          <p className="mt-6 border-t border-white/8 pt-4 text-[10px] leading-4 text-white/30">
            Returning means a prior verified visit to this venue within 90 days.
          </p>
        </div>
      </section>

      <p className="max-w-3xl text-[11px] leading-5 text-white/30">
        Dashboard totals are aggregated. Venues never receive guest names, contact details, individual timelines, or precise location data.
      </p>
    </div>
  );
}

function ActivityChart() {
  const max = Math.max(...weeklyActivity.flatMap((item) => [item.plans, item.checkIns]));
  return (
    <div className="mt-8 grid h-56 grid-cols-7 items-end gap-2 sm:gap-4" aria-label="Weekly plans and verified check-ins chart">
      {weeklyActivity.map((item) => (
        <div key={item.day} className="flex h-full flex-col justify-end gap-2">
          <div className="relative mx-auto flex h-[85%] w-full max-w-12 items-end justify-center gap-1" title={`${item.day}: ${item.plans} plans, ${item.checkIns} verified check-ins`}>
            <span className="w-1/2 bg-white/20" style={{ height: `${(item.plans / max) * 100}%` }} />
            <span className="w-1/2 bg-primary" style={{ height: `${(item.checkIns / max) * 100}%` }} />
          </div>
          <span className="text-center font-mono text-[9px] text-white/28">{item.day}</span>
        </div>
      ))}
    </div>
  );
}

function Legend({ color, label }: { color: string; label: string }) { return <span className="flex items-center gap-2"><i className={cn("size-2", color)} />{label}</span>; }
