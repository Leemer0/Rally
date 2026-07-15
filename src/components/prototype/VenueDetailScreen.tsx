import { AgeDistributionSparkline } from "@/components/prototype/AgeDistributionSparkline";
import { ScreenHeader } from "@/components/prototype/ScreenChrome";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Icon } from "@/components/ui/Icon";
import { StatusBadge } from "@/components/ui/StatusBadge";
import type { PrototypeVenue } from "@/prototype/data";
import type { PrototypePlan } from "@/prototype/types";

type VenueDetailScreenProps = {
  venue: PrototypeVenue;
  plan: PrototypePlan | null;
  onBack: () => void;
  onStartRsvp: (venueId: string) => void;
  onStartCheckin: (venueId: string) => void;
};

export function VenueDetailScreen({
  venue,
  plan,
  onBack,
  onStartCheckin,
  onStartRsvp,
}: VenueDetailScreenProps) {
  const isActivePlan = plan?.venueId === venue.id;

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <ScreenHeader onBack={onBack} title={venue.name} />
      <main className="min-h-0 flex-1 overflow-y-auto pb-6">
        <VenueHero venue={venue} />
        <div className="px-5 pt-5">
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="text-text-secondary text-xs">
                {venue.neighbourhood} · {venue.category}
              </p>
              <h2 className="text-text-primary mt-1 text-3xl font-semibold tracking-[-0.05em]">
                {venue.name}
              </h2>
              <p className="text-text-secondary mt-2 text-sm">{venue.hours}</p>
              <p className="text-text-muted mt-1 text-xs">{venue.address}</p>
            </div>
            {isActivePlan ? (
              <StatusBadge dot tone="success">
                Your plan
              </StatusBadge>
            ) : null}
          </div>

          <dl className="divide-border-subtle border-border-subtle mt-6 grid grid-cols-3 divide-x border-y py-4 text-center">
            <Metric
              label="Going"
              value={String(
                venue.goingCount + (isActivePlan ? plan.groupSize : 0),
              )}
            />
            <Metric label="Verified" value={String(venue.verifiedCount)} />
            <Metric label="Peak" value={venue.expectedPeakTime} compact />
          </dl>

          <section className="mt-6">
            <div className="flex items-end justify-between gap-3">
              <h3 className="text-text-primary text-sm font-semibold">
                Ages going tonight
              </h3>
              <span className="text-text-muted text-[0.65rem]">
                Registered users only
              </span>
            </div>
            <AgeDistributionSparkline
              className="mt-2"
              {...venue.ageDistribution}
            />
          </section>

          <p className="text-text-secondary mt-7 text-sm leading-6">
            {venue.description}
          </p>

          <Card
            className="mt-7 flex items-start gap-3 p-4"
            variant={venue.offer ? "accent" : "outlined"}
          >
            <span className="rounded-control bg-accent-muted text-accent-primary flex size-10 shrink-0 items-center justify-center">
              <Icon className="size-5" name="ticket" />
            </span>
            <div>
              <p className="text-text-muted text-xs font-semibold tracking-[0.1em] uppercase">
                Tonight’s offer
              </p>
              <p className="text-text-primary mt-1 text-sm font-semibold">
                {venue.offer ?? "No check-in offer is available tonight."}
              </p>
              {venue.offerDetails ? (
                <p className="text-text-secondary mt-1 text-xs leading-5">
                  {venue.offerDetails}
                </p>
              ) : null}
            </div>
          </Card>
        </div>
      </main>

      <footer className="border-border-subtle bg-background-primary/96 grid shrink-0 grid-cols-[1fr_auto] gap-2 border-t px-4 pt-3 pb-[max(0.8rem,env(safe-area-inset-bottom))] backdrop-blur-xl">
        <Button fullWidth onClick={() => onStartRsvp(venue.id)}>
          {isActivePlan ? "Change plan" : "I’m Going"}
        </Button>
        <Button
          aria-label="Check in at this venue"
          onClick={() => onStartCheckin(venue.id)}
          size="icon"
          variant="secondary"
        >
          <Icon className="size-5" name="location" />
        </Button>
      </footer>
    </div>
  );
}

function VenueHero({ venue }: { venue: PrototypeVenue }) {
  return (
    <div className="bg-surface-sunken relative h-44 overflow-hidden">
      <div
        aria-hidden="true"
        className="city-grid absolute inset-0 opacity-35"
      />
      <div
        aria-hidden="true"
        className="border-accent-primary/30 bg-accent-muted absolute -right-8 -bottom-16 h-44 w-64 rotate-[-14deg] rounded-[3rem] border"
      />
      <div className="absolute inset-x-5 bottom-4 flex items-end justify-between">
        <span className="text-accent-primary text-[0.65rem] font-semibold tracking-[0.16em] uppercase">
          Toronto tonight
        </span>
        <StatusBadge tone={venue.activity === "peak" ? "accent" : "neutral"}>
          {venue.activity}
        </StatusBadge>
      </div>
    </div>
  );
}

function Metric({
  label,
  value,
  compact = false,
}: {
  label: string;
  value: string;
  compact?: boolean;
}) {
  return (
    <div className="px-2">
      <dt className="text-text-muted text-[0.65rem]">{label}</dt>
      <dd
        className={`text-text-primary mt-1 font-semibold ${compact ? "text-xs" : "text-xl"}`}
      >
        {value}
      </dd>
    </div>
  );
}
