import { randomUUID } from "node:crypto";
import { Check, CreditCard, ExternalLink, Minus } from "lucide-react";
import { openBillingPortal, startProCheckout } from "@/app/dashboard/billing/actions";
import { DashboardUnavailable } from "@/components/dashboard/dashboard-unavailable";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { requireVenueSession } from "@/lib/auth/venue";
import { loadProPriceSummary, loadVenueBillingContext } from "@/lib/data/venue-billing";
import { loadVenueDashboardSnapshot } from "@/lib/data/venue-dashboard";

const proCapabilities = [
  "Advanced attendance and demographic analytics",
  "Featured discovery placement",
  "More active offers and campaign controls",
  "Repeat-visitor and neighbourhood insights",
  "Matching with Outly partner campaigns",
];

type SearchParams = Promise<{ checkout?: string; error?: string }>;

export default async function BillingPage({ searchParams }: { searchParams: SearchParams }) {
  const session = await requireVenueSession();
  const [params, result, billing, price] = await Promise.all([
    searchParams,
    loadVenueDashboardSnapshot(session.userId),
    loadVenueBillingContext(session.userId),
    loadProPriceSummary(),
  ]);

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
  const hasStripeSubscription = Boolean(billing?.stripeSubscriptionId);
  const managesBilling = Boolean(billing?.stripeCustomerId && hasStripeSubscription);
  const checkoutAttemptId = randomUUID();

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

      {params.checkout === "success" ? (
        <Notice>
          Subscription confirmed. Pro access will appear as soon as Stripe finishes syncing the payment.
        </Notice>
      ) : null}
      {params.checkout === "cancelled" ? (
        <Notice muted>No charge was made. You can return to checkout whenever you’re ready.</Notice>
      ) : null}
      {params.error ? (
        <Notice error>
          Billing is temporarily unavailable. No charge was made. Please try again shortly.
        </Notice>
      ) : null}

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
            <p className="text-2xl font-medium tracking-[-0.03em]">
              {price?.displayPrice ?? "Current pricing"}
            </p>
            <p className="mt-1 text-[11px] text-white/36">
              {price ? `per ${price.interval}, billed by Stripe` : "Shown securely at checkout"}
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
        {managesBilling ? (
          <form action={openBillingPortal} className="mt-8">
            <Button size="lg" className="h-11">
              Manage subscription <ExternalLink className="size-4" />
            </Button>
          </form>
        ) : (
          <form action={startProCheckout} className="mt-8">
            <input type="hidden" name="checkoutAttemptId" value={checkoutAttemptId} />
            <Button size="lg" className="h-11" disabled={!price}>
              Upgrade to Pro <ExternalLink className="size-4" />
            </Button>
          </form>
        )}
        {billing?.cancelAtPeriodEnd && billing.currentPeriodEndsAt ? (
          <p className="mt-4 text-xs text-amber-100/65">
            Pro remains active until {formatDate(billing.currentPeriodEndsAt)}, then moves to Free.
          </p>
        ) : null}
      </section>

      <section className="rounded-lg border border-white/10 bg-card p-5 sm:p-6">
        <div className="flex flex-col justify-between gap-5 sm:flex-row sm:items-center">
          <div>
            <h2 className="font-medium">Invoices and payment details</h2>
            <p className="mt-1 max-w-xl text-xs leading-5 text-white/34">
              Stripe securely manages payment methods, invoices, billing details, and cancellation.
            </p>
          </div>
          {billing?.stripeCustomerId ? (
            <form action={openBillingPortal}>
              <Button variant="outline" className="h-10">
                Open billing portal <CreditCard className="size-4" />
              </Button>
            </form>
          ) : (
            <CreditCard className="size-5 text-white/28" />
          )}
        </div>
      </section>

      <div className="flex items-center gap-2 text-[11px] text-white/28">
        <ExternalLink className="size-3" />
        Checkout and subscription management open on Stripe’s secure, Outly-branded pages.
      </div>
    </div>
  );
}

function Notice({
  children,
  error = false,
  muted = false,
}: {
  children: React.ReactNode;
  error?: boolean;
  muted?: boolean;
}) {
  return (
    <p
      role={error ? "alert" : "status"}
      className={`border-l-2 px-4 py-3 text-sm leading-5 ${
        error
          ? "border-red-400/80 bg-red-400/[0.055] text-red-100/80"
          : muted
            ? "border-white/20 bg-white/[0.025] text-white/52"
            : "border-primary/70 bg-primary/[0.045] text-white/72"
      }`}
    >
      {children}
    </p>
  );
}

function formatDate(value: string) {
  return new Intl.DateTimeFormat("en-CA", {
    month: "long",
    day: "numeric",
    year: "numeric",
    timeZone: "America/Toronto",
  }).format(new Date(value));
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
