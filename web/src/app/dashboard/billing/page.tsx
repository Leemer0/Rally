import { Check, CreditCard, ExternalLink, Minus } from "lucide-react";
import { DashboardUnavailable } from "@/components/dashboard/dashboard-unavailable";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { requireVenueSession } from "@/lib/auth/venue";
import { loadVenueDashboardSnapshot } from "@/lib/data/venue-dashboard";

const proCapabilities = [
  "Advanced attendance and demographic analytics",
  "Featured discovery placement",
  "More active offers and campaign controls",
  "Repeat-visitor and neighbourhood insights",
  "Matching with Outly partner campaigns",
];

export default async function BillingPage() {
  const session = await requireVenueSession();
  const result = await loadVenueDashboardSnapshot(session.userId);

  if (!result.data) {
    return (
      <DashboardUnavailable
        configuration={result.error === "configuration"}
        title="We couldn’t load your venue plan."
      />
    );
  }

  const snapshot = result.data;
  const subscription = snapshot.subscription;
  const effectivePlan = presentStatus(subscription.planCode);
  const billingPlan = presentStatus(subscription.billingPlanCode);

  return (
    <div className="space-y-8">
      <div>
        <p className="font-mono text-[10px] uppercase tracking-[0.17em] text-primary">
          Plan &amp; billing
        </p>
        <h1 className="mt-2 text-3xl font-medium tracking-[-0.035em] sm:text-4xl">
          Your venue plan
        </h1>
        <p className="mt-2 text-sm text-white/40">
          Live access and entitlement status from the Outly backend.
        </p>
      </div>

      <section className="grid overflow-hidden rounded-lg border border-white/10 bg-card lg:grid-cols-[.72fr_1.28fr]">
        <div className="border-b border-white/10 p-6 lg:border-b-0 lg:border-r lg:p-8">
          <div className="flex items-center justify-between gap-4">
            <p className="font-mono text-[10px] uppercase tracking-[.17em] text-white/38">
              Effective plan
            </p>
            <Badge
              variant="outline"
              className="rounded-sm border-primary/25 text-primary"
            >
              {effectivePlan}
            </Badge>
          </div>
          <p className="mt-8 text-4xl font-medium tracking-[-0.05em]">
            {effectivePlan}
          </p>
          <dl className="mt-7 space-y-4 border-t border-white/8 pt-5 text-sm">
            <StatusRow label="Subscription status" value={subscription.status} />
            <StatusRow label="Billing plan" value={billingPlan} />
            <StatusRow
              label="Active offer limit"
              value={String(subscription.entitlements.activeOfferLimit)}
              preserveCase
            />
            <StatusRow
              label="Analytics history"
              value={`${subscription.entitlements.analyticsHistoryDays} days`}
              preserveCase
            />
          </dl>
          {subscription.planCode !== subscription.billingPlanCode ? (
            <p className="mt-5 text-[11px] leading-5 text-white/32">
              Effective access differs from the stored billing plan because subscription status is applied server-side.
            </p>
          ) : null}
        </div>

        <div className="p-6 lg:p-8">
          <div>
            <p className="font-mono text-[10px] uppercase tracking-[.17em] text-primary">
              Current entitlements
            </p>
            <h2 className="mt-3 text-2xl font-medium">What this venue can use</h2>
          </div>
          <div className="mt-7 grid gap-x-8 gap-y-3 sm:grid-cols-2">
            <Entitlement
              label="Advanced demographics"
              enabled={subscription.entitlements.advancedDemographics}
            />
            <Entitlement
              label="Custom map marker"
              enabled={subscription.entitlements.customMapMarker}
            />
            <Entitlement
              label="Featured placement"
              enabled={subscription.entitlements.featuredPlacement}
            />
            <Entitlement
              label="Campaign customization"
              enabled={subscription.entitlements.campaignCustomization}
            />
            <Entitlement
              label="Neighbourhood benchmarks"
              enabled={subscription.entitlements.neighbourhoodBenchmarks}
            />
            <Entitlement
              label="Repeat-visitor insights"
              enabled={subscription.entitlements.repeatVisitorInsights}
            />
            <Entitlement
              label="Detailed attribution"
              enabled={subscription.entitlements.detailedAttribution}
            />
            <Entitlement
              label="Partner campaign access"
              enabled={subscription.entitlements.partnerCampaignAccess}
            />
          </div>
        </div>
      </section>

      <section className="rounded-lg border border-white/10 bg-[#11161d] p-6 lg:p-8">
        <div className="flex flex-col justify-between gap-6 lg:flex-row lg:items-start">
          <div className="max-w-xl">
            <p className="font-mono text-[10px] uppercase tracking-[.17em] text-primary">
              Outly Pro
            </p>
            <h2 className="mt-3 text-2xl font-medium">
              More control over demand and retention
            </h2>
            <p className="mt-3 text-sm leading-6 text-white/42">
              Pro is designed for venues running more offers, measuring repeat visits, and joining relevant Outly partner campaigns.
            </p>
          </div>
          <div className="shrink-0 text-left lg:text-right">
            <p className="text-sm font-medium">Pricing not connected</p>
            <p className="mt-1 text-[11px] text-white/30">
              No checkout or charge will occur here.
            </p>
          </div>
        </div>
        <div className="mt-7 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {proCapabilities.map((item) => (
            <p key={item} className="flex gap-2 text-sm text-white/56">
              <Check className="size-4 shrink-0 text-primary" />
              {item}
            </p>
          ))}
        </div>
        <Button size="lg" className="mt-8 h-11" disabled>
          Stripe checkout not connected
        </Button>
      </section>

      <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
        <div className="flex items-center justify-between p-5 sm:p-6">
          <div>
            <h2 className="font-medium">Billing history</h2>
            <p className="mt-1 text-xs text-white/34">
              Invoice data will appear after Stripe billing is connected.
            </p>
          </div>
          <CreditCard className="size-4 text-white/28" />
        </div>
        <Table>
          <TableHeader>
            <TableRow className="border-white/8">
              <TableHead>Date</TableHead>
              <TableHead>Description</TableHead>
              <TableHead>Amount</TableHead>
              <TableHead>
                <span className="sr-only">Invoice</span>
              </TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            <TableRow className="border-white/8">
              <TableCell
                colSpan={4}
                className="h-28 text-center text-sm text-white/32"
              >
                Stripe billing history is not connected.
              </TableCell>
            </TableRow>
          </TableBody>
        </Table>
      </section>

      <div className="flex items-center gap-2 text-[11px] text-white/28">
        <ExternalLink className="size-3" />
        Stripe customer portal is not connected yet.
      </div>
    </div>
  );
}

function StatusRow({
  label,
  value,
  preserveCase = false,
}: {
  label: string;
  value: string;
  preserveCase?: boolean;
}) {
  return (
    <div className="flex items-center justify-between gap-4">
      <dt className="text-white/38">{label}</dt>
      <dd className="text-right text-white/72">
        {preserveCase ? value : presentStatus(value)}
      </dd>
    </div>
  );
}

function Entitlement({ label, enabled }: { label: string; enabled: boolean }) {
  return (
    <p className="flex items-center gap-2 text-sm text-white/56">
      {enabled ? (
        <Check className="size-4 shrink-0 text-primary" />
      ) : (
        <Minus className="size-4 shrink-0 text-white/24" />
      )}
      <span>{label}</span>
      <span className="ml-auto text-[10px] uppercase tracking-[.08em] text-white/28">
        {enabled ? "Included" : "Not included"}
      </span>
    </p>
  );
}

function presentStatus(value: string) {
  return value.replaceAll("_", " ").replace(/\b\w/g, (letter) =>
    letter.toUpperCase(),
  );
}
