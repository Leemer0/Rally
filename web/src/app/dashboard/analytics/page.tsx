import { Download, Info } from "lucide-react";
import {
  checkInTimeDistribution,
  visitorHistory,
  visitorMix,
  weeklyActivity,
} from "@/lib/demo-data";
import { Badge } from "@/components/ui/badge";
import { Button, buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";

const ages = [4, 8, 16, 29, 52, 74, 92, 76, 58, 38, 22, 12];

const summary = [
  { label: "Verified visitors", value: "126", note: "Unique people · 7 days" },
  { label: "Returning visitors", value: "38", note: "30% repeat rate" },
  { label: "Plan-to-check-in", value: "64%", note: "Matching planner cohort" },
  { label: "Offers unlocked", value: "98", note: "Sample claims data" },
];

export default function AnalyticsPage() {
  return (
    <div className="space-y-8">
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
        <div>
          <p className="font-mono text-[10px] uppercase tracking-[0.17em] text-primary">Analytics</p>
          <h1 className="mt-2 text-3xl font-medium tracking-[-0.035em] sm:text-4xl">Attendance and return visits</h1>
          <p className="mt-2 text-sm text-white/46">Aggregated venue trends. No individual guest profiles.</p>
        </div>
        <a
          href="/demo/venue-analytics.csv"
          download
          className={cn(buttonVariants({ variant: "outline", size: "lg" }), "h-11 border-white/12")}
        >
          <Download className="size-4" />Export
        </a>
      </div>

      <div className="flex flex-wrap gap-2 border-b border-white/10 pb-5">
        <Button variant="secondary" size="sm" className="h-8">7 days</Button>
        <Button variant="ghost" size="sm" className="h-8" disabled>30 days</Button>
        <Button variant="ghost" size="sm" className="h-8" disabled>90 days</Button>
        <span className="ml-auto self-center text-[11px] text-white/32">Sample data · Jul 13–19</span>
      </div>

      <section className="grid overflow-hidden rounded-lg border border-white/10 bg-card sm:grid-cols-2 xl:grid-cols-4" aria-label="Analytics summary">
        {summary.map((metric) => (
          <AnalyticMetric key={metric.label} {...metric} />
        ))}
      </section>

      <div className="grid gap-5 xl:grid-cols-[1.12fr_.88fr]">
        <section className="rounded-lg border border-white/10 bg-card p-5 sm:p-6">
          <div>
            <h2 className="font-medium">Plans and verified arrivals</h2>
            <p className="mt-1 text-xs text-white/38">Unique people by nightlife date</p>
          </div>
          <AttendanceChart />
          <div className="mt-5 flex gap-5 border-t border-white/8 pt-4 text-[11px] text-white/42">
            <Legend color="bg-white/26" label="Plans" />
            <Legend color="bg-primary" label="Verified check-ins" />
          </div>
        </section>

        <section className="rounded-lg border border-white/10 bg-card p-5 sm:p-6">
          <div className="flex items-start justify-between gap-4">
            <div>
              <h2 className="font-medium">Check-ins by time</h2>
              <p className="mt-1 text-xs text-white/38">126 verified arrivals · venue-local time</p>
            </div>
            <Info className="size-4 text-white/32" aria-hidden="true" />
          </div>
          <div className="mt-8 space-y-4">
            {checkInTimeDistribution.map((item) => (
              <div key={item.label} className="grid grid-cols-[6.75rem_1fr_2rem] items-center gap-3">
                <span className="text-xs text-white/48">{item.label}</span>
                <span className="h-2 bg-white/6">
                  <i className="block h-full bg-primary/72" style={{ width: `${(item.count / 37) * 100}%` }} />
                </span>
                <span className="numeric text-right text-xs text-white/54">{item.count}</span>
              </div>
            ))}
          </div>
          <p className="mt-6 border-t border-white/8 pt-4 text-[10px] leading-4 text-white/30">
            Observed check-ins only. This is not a demand forecast.
          </p>
        </section>
      </div>

      <section className="grid overflow-hidden rounded-lg border border-white/10 bg-card lg:grid-cols-[1.2fr_.8fr]">
        <div className="border-b border-white/10 p-5 sm:p-6 lg:border-b-0 lg:border-r">
          <div>
            <h2 className="font-medium">First-time and returning visitors</h2>
            <p className="mt-1 text-xs text-white/38">Five-week verified visitor history</p>
          </div>
          <VisitorHistoryChart />
          <div className="mt-5 flex gap-5 border-t border-white/8 pt-4 text-[11px] text-white/42">
            <Legend color="bg-white/26" label="First-time" />
            <Legend color="bg-primary" label="Returning" />
          </div>
        </div>

        <div className="p-5 sm:p-6">
          <h2 className="font-medium">Visitor mix</h2>
          <p className="mt-1 text-xs text-white/38">Current seven-day period</p>
          <div className="mt-9 flex h-3 overflow-hidden bg-white/6" aria-label="70 percent first-time and 30 percent returning visitors">
            <span className="w-[70%] bg-white/26" />
            <span className="w-[30%] bg-primary" />
          </div>
          <div className="mt-7 space-y-5">
            {visitorMix.map((item, index) => (
              <div key={item.label} className="flex items-end justify-between gap-4">
                <div className="flex items-center gap-2 text-sm text-white/54">
                  <span className={index === 0 ? "size-2 bg-white/26" : "size-2 bg-primary"} />
                  {item.label}
                </div>
                <div className="text-right">
                  <span className="numeric text-xl font-medium">{item.value}</span>
                  <span className="numeric ml-2 text-xs text-white/38">{item.percent}%</span>
                </div>
              </div>
            ))}
          </div>
          <p className="mt-7 border-t border-white/8 pt-4 text-[10px] leading-4 text-white/30">
            Returning means at least one earlier verified check-in at this venue within 90 days.
          </p>
        </div>
      </section>

      <section className="rounded-lg border border-white/10 bg-card p-5 sm:p-6">
        <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-start">
          <div>
            <h2 className="font-medium">Verified visitor profile</h2>
            <p className="mt-1 text-xs text-white/38">Aggregated demographics for this seven-day period</p>
          </div>
          <Badge variant="outline" className="w-fit rounded-sm border-white/12 text-white/48">Sample cohort · 126 people</Badge>
        </div>
        <div className="mt-9 grid gap-10 lg:grid-cols-[1.25fr_.75fr]">
          <div>
            <div className="flex items-end justify-between">
              <p className="text-sm text-white/46">Age distribution</p>
              <p className="numeric text-3xl font-medium">27 <span className="text-xs font-normal text-white/38">average</span></p>
            </div>
            <div className="mt-6 flex h-32 items-end gap-1.5 border-b border-white/10" aria-label="Age distribution from 19 to 40 plus, average age 27">
              {ages.map((height, index) => (
                <span key={index} className={index === 6 ? "flex-1 bg-primary" : "flex-1 bg-white/23"} style={{ height: `${height}%` }} />
              ))}
            </div>
            <div className="mt-2 flex justify-between font-mono text-[9px] text-white/30"><span>19</span><span>27</span><span>40+</span></div>
          </div>
          <div className="lg:border-l lg:border-white/10 lg:pl-10">
            <p className="text-sm text-white/46">Gender distribution</p>
            <div className="mt-7 flex h-2 gap-1" aria-label="44 percent men, 51 percent women, and 5 percent another gender">
              <span className="w-[44%] bg-[#57a6ff]" />
              <span className="w-[51%] bg-[#ff70b8]" />
              <span className="w-[5%] bg-white/35" />
            </div>
            <div className="mt-4 space-y-3 text-xs">
              <GenderRow color="bg-[#57a6ff]" label="Man" value="44%" />
              <GenderRow color="bg-[#ff70b8]" label="Woman" value="51%" />
              <GenderRow color="bg-white/35" label="Another gender" value="5%" />
            </div>
          </div>
        </div>
      </section>

      <p className="flex max-w-3xl gap-2 text-[11px] leading-5 text-white/32">
        <Info className="mt-0.5 size-3.5 shrink-0" />
        Demographics are hidden below the minimum cohort and never expose dates of birth, individual genders, names, or contact information.
      </p>
    </div>
  );
}

function AttendanceChart() {
  const max = Math.max(...weeklyActivity.flatMap((item) => [item.plans, item.checkIns]));
  return (
    <>
      <div className="mt-10 grid h-64 grid-cols-7 items-end gap-3 sm:gap-6" aria-label="Plans and verified check-ins across seven nightlife dates">
        {weeklyActivity.map((item) => (
          <div key={item.day} className="flex h-full flex-1 flex-col justify-end gap-2">
            <div className="mx-auto flex h-[82%] w-full max-w-12 items-end gap-1" title={`${item.day}: ${item.plans} plans and ${item.checkIns} verified check-ins`}>
              <span className="w-1/2 bg-white/24" style={{ height: `${(item.plans / max) * 100}%` }} />
              <span className="w-1/2 bg-primary" style={{ height: `${(item.checkIns / max) * 100}%` }} />
            </div>
            <span className="text-center font-mono text-[9px] text-white/32">{item.day}</span>
          </div>
        ))}
      </div>
      <table className="sr-only">
        <caption>Plans and verified check-ins by nightlife date</caption>
        <thead><tr><th>Day</th><th>Plans</th><th>Verified check-ins</th></tr></thead>
        <tbody>{weeklyActivity.map((item) => <tr key={item.day}><td>{item.day}</td><td>{item.plans}</td><td>{item.checkIns}</td></tr>)}</tbody>
      </table>
    </>
  );
}

function VisitorHistoryChart() {
  const max = Math.max(...visitorHistory.map((item) => item.firstTime + item.returning));
  return (
    <>
      <div className="mt-10 grid h-56 grid-cols-5 items-end gap-3 sm:gap-6" aria-label="First-time and returning visitors over five weeks">
        {visitorHistory.map((item) => (
          <div key={item.period} className="flex h-full flex-col justify-end gap-2">
            <div className="mx-auto flex h-[82%] w-full max-w-14 flex-col justify-end" title={`${item.period}: ${item.firstTime} first-time and ${item.returning} returning visitors`}>
              <span className="w-full bg-primary" style={{ height: `${(item.returning / max) * 100}%` }} />
              <span className="w-full bg-white/24" style={{ height: `${(item.firstTime / max) * 100}%` }} />
            </div>
            <span className="text-center font-mono text-[9px] text-white/32">{item.period.replace("Jun ", "6/").replace("Jul ", "7/")}</span>
          </div>
        ))}
      </div>
      <table className="sr-only">
        <caption>First-time and returning visitors by week</caption>
        <thead><tr><th>Week</th><th>First-time</th><th>Returning</th></tr></thead>
        <tbody>{visitorHistory.map((item) => <tr key={item.period}><td>{item.period}</td><td>{item.firstTime}</td><td>{item.returning}</td></tr>)}</tbody>
      </table>
    </>
  );
}

function AnalyticMetric({ label, value, note }: { label: string; value: string; note: string }) {
  return (
    <div className="border-b border-white/10 p-5 odd:border-r sm:nth-[3]:border-b-0 sm:nth-[4]:border-b-0 xl:border-b-0 xl:border-r xl:last:border-r-0">
      <p className="text-xs text-white/42">{label}</p>
      <p className="numeric mt-4 text-4xl font-medium tracking-[-0.05em]">{value}</p>
      <p className="mt-2 text-[11px] text-white/32">{note}</p>
    </div>
  );
}

function Legend({ color, label }: { color: string; label: string }) {
  return <span className="flex items-center gap-2"><i className={`size-2 ${color}`} />{label}</span>;
}

function GenderRow({ color, label, value }: { color: string; label: string; value: string }) {
  return (
    <div className="flex items-center">
      <span className={`mr-2 size-2 ${color}`} />
      <span className="text-white/50">{label}</span>
      <span className="numeric ml-auto">{value}</span>
    </div>
  );
}
