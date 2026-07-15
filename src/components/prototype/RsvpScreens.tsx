import { ChoiceRow } from "@/components/prototype/OnboardingScreen";
import { FlowFooter, ScreenHeader } from "@/components/prototype/ScreenChrome";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Icon } from "@/components/ui/Icon";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { cn } from "@/lib/cn";
import { getVenue, type PrototypeVenue } from "@/prototype/data";
import type { ArrivalWindow, PrototypePlan } from "@/prototype/types";

export function RsvpArrivalScreen({
  venue,
  selected,
  onSelect,
  onBack,
  onNext,
}: {
  venue: PrototypeVenue;
  selected: ArrivalWindow;
  onSelect: (value: ArrivalWindow) => void;
  onBack: () => void;
  onNext: () => void;
}) {
  return (
    <FlowLayout
      onBack={onBack}
      title="When are you getting there?"
      eyebrow={venue.name}
      footer={
        <Button fullWidth onClick={onNext} size="lg">
          Choose group size
        </Button>
      }
    >
      <div className="grid gap-2.5">
        {venue.arrivalWindows.map((window) => (
          <ChoiceRow
            key={window}
            label={window}
            onClick={() => onSelect(window)}
            selected={selected === window}
          />
        ))}
      </div>
    </FlowLayout>
  );
}

export function RsvpGroupScreen({
  groupSize,
  onChange,
  onBack,
  onNext,
}: {
  groupSize: number;
  onChange: (value: number) => void;
  onBack: () => void;
  onNext: () => void;
}) {
  const primaryChoice = groupSize >= 5 ? 5 : groupSize;
  return (
    <FlowLayout
      onBack={onBack}
      title="How many people are in your group?"
      description="Include yourself. Group size affects the going count, not the age line."
      footer={
        <Button fullWidth onClick={onNext} size="lg">
          Review plan
        </Button>
      }
    >
      <div className="grid grid-cols-5 gap-2">
        {[1, 2, 3, 4, 5].map((size) => (
          <button
            key={size}
            aria-pressed={primaryChoice === size}
            className={cn(
              "rounded-control flex aspect-square items-center justify-center border text-lg font-semibold transition",
              primaryChoice === size
                ? "border-accent-primary bg-accent-muted text-accent-primary"
                : "border-border-subtle bg-surface-primary text-text-secondary",
            )}
            onClick={() => onChange(size)}
            type="button"
          >
            {size === 5 ? "5+" : size}
          </button>
        ))}
      </div>
      {groupSize >= 5 ? (
        <div className="rounded-card border-border-subtle bg-surface-primary mt-6 border p-4">
          <p className="text-text-primary text-sm font-medium">
            Exact group size
          </p>
          <div className="mt-3 grid grid-cols-4 gap-2">
            {[5, 6, 7, 8].map((size) => (
              <button
                key={size}
                aria-pressed={groupSize === size}
                className={cn(
                  "rounded-control min-h-11 border text-sm font-semibold",
                  groupSize === size
                    ? "border-accent-primary bg-accent-primary text-accent-foreground"
                    : "border-border-subtle text-text-secondary",
                )}
                onClick={() => onChange(size)}
                type="button"
              >
                {size}
              </button>
            ))}
          </div>
        </div>
      ) : null}
    </FlowLayout>
  );
}

export function RsvpConfirmScreen({
  venue,
  arrivalWindow,
  groupSize,
  currentPlan,
  onBack,
  onConfirm,
}: {
  venue: PrototypeVenue;
  arrivalWindow: ArrivalWindow;
  groupSize: number;
  currentPlan: PrototypePlan | null;
  onBack: () => void;
  onConfirm: () => void;
}) {
  const switchingVenue =
    currentPlan && currentPlan.venueId !== venue.id
      ? getVenue(currentPlan.venueId)
      : null;
  return (
    <FlowLayout
      onBack={onBack}
      title="Review your plan"
      footer={
        <Button fullWidth onClick={onConfirm} size="lg">
          Confirm
        </Button>
      }
    >
      <Card className="overflow-hidden" variant="elevated">
        <div className="bg-surface-sunken city-grid h-24 opacity-70" />
        <div className="p-5">
          <StatusBadge tone="accent">Tonight</StatusBadge>
          <h2 className="text-text-primary mt-3 text-2xl font-semibold tracking-[-0.04em]">
            {venue.name}
          </h2>
          <p className="text-text-secondary mt-1 text-sm">
            {venue.neighbourhood} · {venue.category}
          </p>
          <dl className="border-border-subtle mt-5 grid gap-4 border-t pt-4">
            <ReviewRow label="Date" value="Tonight · July 14" />
            <ReviewRow label="Arrival" value={arrivalWindow} />
            <ReviewRow
              label="Group"
              value={`${groupSize} ${groupSize === 1 ? "person" : "people"}`}
            />
          </dl>
        </div>
      </Card>
      {switchingVenue ? (
        <p className="rounded-control bg-warning-muted text-warning mt-4 p-3 text-xs leading-5">
          Confirming will replace your current plan at {switchingVenue.name}.
        </p>
      ) : null}
    </FlowLayout>
  );
}

export function RsvpSuccessScreen({
  venue,
  plan,
  onViewVenue,
  onCheckin,
  onExplore,
}: {
  venue: PrototypeVenue;
  plan: PrototypePlan;
  onViewVenue: () => void;
  onCheckin: () => void;
  onExplore: () => void;
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col px-5">
      <main className="flex flex-1 flex-col items-center justify-center text-center">
        <span className="border-accent-primary/30 bg-accent-muted text-accent-primary shadow-accent relative flex size-24 items-center justify-center rounded-full border">
          <span className="border-accent-primary/30 absolute inset-3 rounded-full border" />
          <Icon className="relative size-11" name="check" />
        </span>
        <p className="text-accent-primary mt-7 text-xs font-semibold tracking-[0.14em] uppercase">
          Plan confirmed
        </p>
        <h1 className="text-text-primary mt-3 text-3xl font-semibold tracking-[-0.05em]">
          You’re going to {venue.name}.
        </h1>
        <p className="text-text-secondary mt-3 text-sm">
          {plan.arrivalWindow} · Group of {plan.groupSize}
        </p>
        <Card className="mt-7 w-full p-4 text-left" variant="elevated">
          <p className="text-text-muted text-xs font-semibold">
            When you arrive
          </p>
          <p className="text-text-primary mt-1 text-sm leading-5">
            Scan the Outly code to verify you’re there and unlock tonight’s
            offer.
          </p>
        </Card>
      </main>
      <footer className="grid gap-2 pb-[max(1rem,env(safe-area-inset-bottom))]">
        <Button fullWidth onClick={onCheckin} size="lg">
          I’m at the venue
        </Button>
        <div className="grid grid-cols-2 gap-2">
          <Button fullWidth onClick={onViewVenue} variant="secondary">
            See venue
          </Button>
          <Button fullWidth onClick={onExplore} variant="ghost">
            Back to Explore
          </Button>
        </div>
      </footer>
    </div>
  );
}

function FlowLayout({
  title,
  eyebrow,
  description,
  onBack,
  children,
  footer,
}: {
  title: string;
  eyebrow?: string;
  description?: string;
  onBack: () => void;
  children: React.ReactNode;
  footer: React.ReactNode;
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <ScreenHeader onBack={onBack} />
      <main className="min-h-0 flex-1 overflow-y-auto px-5 pt-6 pb-8">
        {eyebrow ? (
          <p className="text-accent-primary text-xs font-semibold tracking-[0.12em] uppercase">
            {eyebrow}
          </p>
        ) : null}
        <h1 className="text-text-primary mt-2 text-[2rem] leading-[1.03] font-semibold tracking-[-0.05em] text-balance">
          {title}
        </h1>
        {description ? (
          <p className="text-text-secondary mt-3 text-sm leading-6">
            {description}
          </p>
        ) : null}
        <div className="mt-8">{children}</div>
      </main>
      <FlowFooter>{footer}</FlowFooter>
    </div>
  );
}

function ReviewRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between gap-4">
      <dt className="text-text-muted text-xs">{label}</dt>
      <dd className="text-text-primary text-right text-sm font-medium">
        {value}
      </dd>
    </div>
  );
}
