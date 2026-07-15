import { OutlyLogo } from "@/components/OutlyLogo";
import { FlowFooter, ScreenHeader } from "@/components/prototype/ScreenChrome";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Icon } from "@/components/ui/Icon";
import { Input } from "@/components/ui/Input";
import { StatusBadge } from "@/components/ui/StatusBadge";
import type { PrototypeVenue } from "@/prototype/data";

export function CheckinIntroScreen({
  venue,
  onBack,
  onScan,
}: {
  venue: PrototypeVenue;
  onBack: () => void;
  onScan: () => void;
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <ScreenHeader onBack={onBack} title="Check in" />
      <main className="flex min-h-0 flex-1 flex-col items-center justify-center px-7 text-center">
        <div className="rounded-sheet border-border-strong bg-surface-sunken city-grid relative flex size-36 items-center justify-center border">
          <QrCode compact />
        </div>
        <p className="text-accent-primary mt-7 text-xs font-semibold tracking-[0.14em] uppercase">
          {venue.name}
        </p>
        <h1 className="text-text-primary mt-3 text-3xl font-semibold tracking-[-0.05em]">
          Check in at the venue
        </h1>
        <p className="text-text-secondary mt-4 max-w-xs text-sm leading-6">
          Find the Outly code near the entrance. We’ll also ask for approximate
          location to verify you’re actually here.
        </p>
        <Card className="mt-6 w-full p-4 text-left" variant="outlined">
          <div className="flex gap-3">
            <Icon
              className="text-text-muted mt-0.5 size-5 shrink-0"
              name="location"
            />
            <p className="text-text-secondary text-xs leading-5">
              Your exact coordinates are discarded immediately after the venue
              check.
            </p>
          </div>
        </Card>
      </main>
      <FlowFooter>
        <Button fullWidth onClick={onScan} size="lg">
          Scan Outly code
        </Button>
      </FlowFooter>
    </div>
  );
}

export function CheckinScanScreen({
  onBack,
  onCodeRead,
}: {
  onBack: () => void;
  onCodeRead: () => void;
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <ScreenHeader onBack={onBack} title="Scan code" />
      <main className="min-h-0 flex-1 overflow-y-auto px-5 pt-5 pb-6">
        <div className="rounded-sheet border-border-strong bg-surface-sunken relative aspect-square overflow-hidden border">
          <div className="city-grid absolute inset-0 opacity-35" />
          <div className="rounded-card border-text-primary/60 absolute inset-10 border">
            <span className="rounded-tl-control border-accent-primary absolute -top-px -left-px size-9 border-t-3 border-l-3" />
            <span className="rounded-tr-control border-accent-primary absolute -top-px -right-px size-9 border-t-3 border-r-3" />
            <span className="rounded-bl-control border-accent-primary absolute -bottom-px -left-px size-9 border-b-3 border-l-3" />
            <span className="rounded-br-control border-accent-primary absolute -right-px -bottom-px size-9 border-r-3 border-b-3" />
            <span className="bg-accent-primary shadow-accent absolute top-1/2 right-3 left-3 h-px motion-safe:animate-pulse" />
          </div>
          <p className="text-text-secondary absolute inset-x-0 bottom-5 text-center text-xs">
            Camera preview placeholder
          </p>
        </div>
        <p className="text-text-secondary mt-4 text-center text-sm">
          Position the Outly code inside the frame.
        </p>
        <div className="border-border-subtle mt-6 border-t pt-5">
          <p className="text-text-muted mb-3 text-[0.65rem] font-semibold tracking-[0.12em] uppercase">
            Prototype controls
          </p>
          <Button fullWidth onClick={onCodeRead}>
            Use demo Outly code
          </Button>
          <Input
            className="mt-4"
            label="Manual token"
            placeholder="Development only"
            trailingElement={
              <button
                className="text-accent-primary text-xs font-semibold"
                onClick={onCodeRead}
                type="button"
              >
                Verify
              </button>
            }
          />
        </div>
      </main>
    </div>
  );
}

export function CheckinLocationScreen({
  venue,
  onBack,
  onVerify,
}: {
  venue: PrototypeVenue;
  onBack: () => void;
  onVerify: () => void;
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <ScreenHeader onBack={onBack} title="Verify location" />
      <main className="flex min-h-0 flex-1 flex-col items-center justify-center px-7 text-center">
        <span className="bg-accent-muted text-accent-primary relative flex size-24 items-center justify-center rounded-full">
          <span className="border-accent-primary/30 absolute inset-2 rounded-full border" />
          <Icon className="relative size-10" name="location" />
        </span>
        <h1 className="text-text-primary mt-8 text-3xl font-semibold tracking-[-0.05em]">
          Are you at {venue.name}?
        </h1>
        <p className="text-text-secondary mt-4 text-sm leading-6">
          Allow approximate location once so Outly can confirm you’re close
          enough to check in.
        </p>
        <div className="mt-7 grid w-full gap-3 text-left">
          <PrivacyPoint title="Used once" copy="Only during this check-in." />
          <PrivacyPoint
            title="Never stored"
            copy="Exact coordinates are discarded after validation."
          />
          <PrivacyPoint
            title="No background tracking"
            copy="Outly does not follow you after check-in."
          />
        </div>
      </main>
      <FlowFooter>
        <Button fullWidth onClick={onVerify} size="lg">
          Allow approximate location
        </Button>
      </FlowFooter>
    </div>
  );
}

export function CheckinSuccessScreen({
  venue,
  onViewOffer,
  onExplore,
}: {
  venue: PrototypeVenue;
  onViewOffer: () => void;
  onExplore: () => void;
}) {
  return (
    <SuccessLayout
      eyebrow="Verified here"
      title="You’re checked in."
      copy={`${venue.name} · 9:48 PM`}
    >
      <Card className="mt-7 w-full p-4 text-left" variant="accent">
        <div className="flex gap-3">
          <span className="rounded-control bg-accent-muted text-accent-primary flex size-10 shrink-0 items-center justify-center">
            <Icon className="size-5" name="ticket" />
          </span>
          <div>
            <p className="text-text-secondary text-xs">Offer unlocked</p>
            <p className="text-text-primary mt-1 text-sm font-semibold">
              {venue.offer ?? "No offer is available tonight"}
            </p>
          </div>
        </div>
      </Card>
      <div className="mt-6 grid w-full gap-2">
        <Button
          disabled={!venue.offer}
          fullWidth
          onClick={onViewOffer}
          size="lg"
        >
          View Offer
        </Button>
        <Button fullWidth onClick={onExplore} variant="ghost">
          Back to Explore
        </Button>
      </div>
    </SuccessLayout>
  );
}

export function OfferScreen({
  venue,
  redeemed,
  onBack,
  onRedeem,
}: {
  venue: PrototypeVenue;
  redeemed: boolean;
  onBack: () => void;
  onRedeem: () => void;
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <ScreenHeader onBack={onBack} title="Your offer" />
      <main className="min-h-0 flex-1 overflow-y-auto px-5 pt-6 pb-6">
        <div className="flex flex-col items-center text-center">
          <VerificationSeal />
          <StatusBadge
            className="mt-5"
            dot
            tone={redeemed ? "neutral" : "success"}
          >
            {redeemed ? "Redeemed" : "Active now"}
          </StatusBadge>
          <p className="text-text-secondary mt-4 text-xs">{venue.name}</p>
          <h1 className="text-text-primary mt-2 text-3xl font-semibold tracking-[-0.05em]">
            {venue.offer}
          </h1>
          <p className="text-text-secondary mt-3 max-w-xs text-sm leading-6">
            {venue.offerDetails}
          </p>
        </div>
        <Card className="mt-7 p-4" variant="elevated">
          <div className="border-border-subtle flex justify-between gap-4 border-b pb-3">
            <span className="text-text-muted text-xs">Valid until</span>
            <span className="text-text-primary text-sm font-medium">
              11:00 PM tonight
            </span>
          </div>
          <ol className="mt-4 grid gap-3">
            <Instruction
              number="1"
              copy="Show this animated screen to venue staff."
            />
            <Instruction
              number="2"
              copy="Tap Redeem only when they’re ready."
            />
          </ol>
        </Card>
        <p className="text-text-muted mt-4 text-center text-[0.65rem]">
          One use only · Redemption cannot be undone
        </p>
      </main>
      <FlowFooter>
        <Button disabled={redeemed} fullWidth onClick={onRedeem} size="lg">
          {redeemed ? "Offer redeemed" : "Redeem offer"}
        </Button>
      </FlowFooter>
    </div>
  );
}

export function RedeemConfirmScreen({
  venue,
  onBack,
  onConfirm,
}: {
  venue: PrototypeVenue;
  onBack: () => void;
  onConfirm: () => void;
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <ScreenHeader onBack={onBack} title="Confirm redemption" />
      <main className="flex flex-1 flex-col items-center justify-center px-7 text-center">
        <span className="bg-warning-muted text-warning flex size-16 items-center justify-center rounded-full">
          <Icon className="size-7" name="ticket" />
        </span>
        <h1 className="text-text-primary mt-7 text-3xl font-semibold tracking-[-0.05em]">
          Redeem this offer now?
        </h1>
        <p className="text-text-secondary mt-4 text-sm leading-6">
          Only tap confirm when {venue.name} staff are ready. This offer can be
          used once.
        </p>
      </main>
      <FlowFooter>
        <div className="grid gap-2">
          <Button fullWidth onClick={onConfirm} size="lg">
            Confirm redemption
          </Button>
          <Button fullWidth onClick={onBack} variant="ghost">
            Keep offer active
          </Button>
        </div>
      </FlowFooter>
    </div>
  );
}

export function RedeemedScreen({
  venue,
  onExplore,
}: {
  venue: PrototypeVenue;
  onExplore: () => void;
}) {
  return (
    <SuccessLayout
      eyebrow="Redeemed"
      title="Offer used."
      copy={`${venue.name} · 9:51 PM`}
    >
      <p className="text-text-secondary mt-6 max-w-xs text-sm leading-6">
        You’re all set. Enjoy your night.
      </p>
      <Button className="mt-8" fullWidth onClick={onExplore} size="lg">
        Back to Explore
      </Button>
    </SuccessLayout>
  );
}

function SuccessLayout({
  eyebrow,
  title,
  copy,
  children,
}: {
  eyebrow: string;
  title: string;
  copy: string;
  children: React.ReactNode;
}) {
  return (
    <main className="flex min-h-0 flex-1 flex-col items-center justify-center overflow-y-auto px-5 py-8 text-center">
      <span className="border-accent-primary/30 bg-accent-muted text-accent-primary shadow-accent relative flex size-24 items-center justify-center rounded-full border">
        <Icon className="size-11" name="check" />
      </span>
      <p className="text-accent-primary mt-7 text-xs font-semibold tracking-[0.14em] uppercase">
        {eyebrow}
      </p>
      <h1 className="text-text-primary mt-3 text-3xl font-semibold tracking-[-0.05em]">
        {title}
      </h1>
      <p className="text-text-secondary mt-2 text-sm">{copy}</p>
      {children}
    </main>
  );
}
function PrivacyPoint({ title, copy }: { title: string; copy: string }) {
  return (
    <div className="flex gap-3">
      <span className="bg-success-muted text-success mt-0.5 flex size-6 shrink-0 items-center justify-center rounded-full">
        <Icon className="size-3.5" name="check" />
      </span>
      <p>
        <strong className="text-text-primary block text-sm">{title}</strong>
        <span className="text-text-muted text-xs">{copy}</span>
      </p>
    </div>
  );
}
function Instruction({ number, copy }: { number: string; copy: string }) {
  return (
    <li className="text-text-secondary flex items-center gap-3 text-sm">
      <span className="bg-surface-elevated text-text-primary flex size-6 shrink-0 items-center justify-center rounded-full text-xs">
        {number}
      </span>
      {copy}
    </li>
  );
}

function VerificationSeal() {
  return (
    <div className="relative flex size-28 items-center justify-center">
      <span className="border-accent-primary/30 absolute inset-0 rounded-full border [background:conic-gradient(from_0deg,transparent,var(--accent-muted),transparent)] motion-safe:animate-[spin_8s_linear_infinite]" />
      <span className="border-accent-primary/50 bg-accent-muted absolute inset-3 rounded-full border" />
      <OutlyLogo className="relative w-20" decorative size="sm" />
    </div>
  );
}

function QrCode({ compact = false }: { compact?: boolean }) {
  return (
    <svg
      aria-label="Demo Outly QR code"
      className={compact ? "size-24" : "size-44"}
      role="img"
      viewBox="0 0 21 21"
    >
      <rect width="21" height="21" rx="1" fill="var(--text-primary)" />
      <g fill="var(--background-primary)">
        <path
          d="M2 2h6v6H2zm2 2v2h2V4H4Zm9-2h6v6h-6zm2 2v2h2V4h-2ZM2 13h6v6H2zm2 2v2h2v-2H4Z"
          fillRule="evenodd"
        />
        <path d="M10 2h2v3h-2zm0 5h2v2h-2zm-1 3h3v2H9zm4 0h2v3h-2zm3 0h3v2h-3zm-6 4h2v5h-2zm3 1h2v2h-2zm3-2h3v2h-3zm0 4h3v2h-3z" />
      </g>
      <circle cx="10.5" cy="10.5" r="2.2" fill="var(--background-primary)" />
      <text
        x="10.5"
        y="11.6"
        textAnchor="middle"
        fontSize="3"
        fontWeight="800"
        fill="var(--text-primary)"
      >
        R
      </text>
    </svg>
  );
}
