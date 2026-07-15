"use client";

import { AgeDistributionSparkline } from "@/components/prototype/AgeDistributionSparkline";
import {
  AppNavigation,
  type AppTab,
} from "@/components/prototype/AppNavigation";
import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { cn } from "@/lib/cn";
import { getVenue, venues, type PrototypeVenue } from "@/prototype/data";
import type { PrototypePlan } from "@/prototype/types";

type ExploreScreenProps = {
  selectedVenueId: string;
  plan: PrototypePlan | null;
  onSelectVenue: (venueId: string) => void;
  onViewVenue: (venueId: string) => void;
  onStartRsvp: (venueId: string) => void;
  onNavigate: (tab: AppTab) => void;
};

export function ExploreScreen({
  onNavigate,
  onSelectVenue,
  onStartRsvp,
  onViewVenue,
  plan,
  selectedVenueId,
}: ExploreScreenProps) {
  const selectedVenue = getVenue(selectedVenueId);

  return (
    <div className="relative flex min-h-0 flex-1 flex-col overflow-hidden">
      <header className="absolute inset-x-0 top-0 z-30 flex items-start justify-between px-4 pt-3">
        <button
          className="rounded-control border-border-subtle bg-background-secondary/88 shadow-card border px-3 py-2 text-left backdrop-blur-xl"
          type="button"
        >
          <span className="text-text-primary block text-sm font-semibold">
            Toronto⌄
          </span>
          <span className="text-text-secondary block text-[0.6875rem]">
            Tonight
          </span>
        </button>
        <div className="flex gap-2">
          <MapControl label="Search venues" icon="search" />
          <MapControl label="Filter venues" icon="spark" />
        </div>
      </header>

      <div className="bg-map-background relative min-h-0 flex-1">
        <h1 className="sr-only">Explore Toronto</h1>
        <MockTorontoMap
          selectedVenueId={selectedVenueId}
          onSelectVenue={onSelectVenue}
        />

        {plan ? (
          <button
            className="rounded-control border-accent-primary/25 bg-background-secondary/92 shadow-card absolute top-20 right-4 left-4 z-20 flex items-center gap-3 border p-3 text-left backdrop-blur-xl"
            onClick={() => onViewVenue(plan.venueId)}
            type="button"
          >
            <span className="bg-accent-muted text-accent-primary flex size-9 items-center justify-center rounded-full">
              <Icon className="size-4" name="check" />
            </span>
            <span className="min-w-0 flex-1">
              <span className="text-accent-primary block text-[0.65rem] font-semibold tracking-[0.12em] uppercase">
                Your plan tonight
              </span>
              <span className="text-text-primary block truncate text-sm font-medium">
                {getVenue(plan.venueId).name} · {plan.arrivalWindow}
              </span>
            </span>
            <Icon className="text-text-muted size-4" name="chevron-right" />
          </button>
        ) : null}

        <VenuePreviewSheet
          venue={selectedVenue}
          onStartRsvp={onStartRsvp}
          onViewVenue={onViewVenue}
        />
      </div>

      <AppNavigation active="explore" onChange={onNavigate} />
    </div>
  );
}

function MapControl({
  label,
  icon,
}: {
  label: string;
  icon: "search" | "spark";
}) {
  return (
    <button
      aria-label={label}
      className="rounded-control border-border-subtle bg-background-secondary/88 text-text-primary shadow-card flex size-11 items-center justify-center border backdrop-blur-xl"
      type="button"
    >
      <Icon className="size-4.5" name={icon} />
    </button>
  );
}

function MockTorontoMap({
  selectedVenueId,
  onSelectVenue,
}: {
  selectedVenueId: string;
  onSelectVenue: (venueId: string) => void;
}) {
  return (
    <div
      className="absolute inset-0 overflow-hidden"
      aria-label="Toronto nightlife map placeholder"
    >
      <svg
        aria-hidden="true"
        className="absolute inset-0 h-full w-full"
        preserveAspectRatio="xMidYMid slice"
        viewBox="0 0 430 720"
      >
        <rect width="430" height="720" fill="var(--map-background)" />
        <g
          fill="var(--map-building)"
          stroke="var(--map-building-edge)"
          strokeWidth="1"
        >
          {Array.from({ length: 45 }, (_, index) => {
            const x = (index * 79) % 390;
            const y = 35 + ((index * 113) % 620);
            const width = 24 + ((index * 11) % 38);
            const height = 18 + ((index * 7) % 45);
            return (
              <rect
                key={index}
                x={x}
                y={y}
                width={width}
                height={height}
                rx="2"
                transform={`rotate(-18 ${x} ${y})`}
              />
            );
          })}
        </g>
        <g fill="none" stroke="var(--map-road)" strokeLinecap="round">
          <path
            d="M-60 120C70 180 125 240 190 365s133 185 300 220"
            strokeWidth="10"
          />
          <path d="M-20 510C100 450 220 400 455 362" strokeWidth="8" />
          <path
            d="M60 -20c20 190 65 400 100 760M300-20c-45 190-25 500 25 760"
            strokeWidth="5"
          />
        </g>
        <g
          fill="none"
          stroke="var(--map-street)"
          strokeOpacity=".35"
          strokeWidth="1.2"
        >
          <path d="M-40 140 470 625M-50 400 420 80M10 680 390 20" />
        </g>
      </svg>

      <div className="bg-background-secondary/70 text-text-muted absolute right-3 bottom-[20rem] rounded-md px-2 py-1 text-[0.55rem] tracking-[0.12em] uppercase backdrop-blur-sm">
        Mapbox connects later
      </div>

      {venues.map((venue) => {
        const selected = venue.id === selectedVenueId;
        return (
          <button
            key={venue.id}
            aria-label={`${venue.name}, ${venue.goingCount} going`}
            aria-pressed={selected}
            className="absolute z-10 -translate-x-1/2 -translate-y-1/2"
            onClick={() => onSelectVenue(venue.id)}
            style={{
              left: `${venue.marker.left}%`,
              top: `${venue.marker.top}%`,
            }}
            type="button"
          >
            <span
              className={cn(
                "shadow-card relative flex items-center justify-center rounded-full border-2 text-[0.65rem] font-bold transition-transform duration-200",
                selected
                  ? "border-text-primary bg-accent-primary text-accent-foreground ring-accent-muted size-13 scale-110 ring-4"
                  : "size-10",
                !selected &&
                  venue.activity === "low" &&
                  "border-text-muted bg-surface-elevated text-text-primary",
                !selected &&
                  venue.activity === "building" &&
                  "border-accent-primary/60 bg-surface-secondary text-accent-primary",
                !selected &&
                  venue.activity === "busy" &&
                  "border-accent-primary bg-accent-muted text-accent-primary",
                !selected &&
                  venue.activity === "peak" &&
                  "border-accent-primary bg-accent-primary text-accent-foreground shadow-accent motion-safe:animate-[pulse_2.4s_ease-in-out_infinite]",
              )}
            >
              {venue.goingCount}
            </span>
            {selected ? (
              <span className="bg-background-secondary text-text-primary shadow-card absolute top-[3.6rem] left-1/2 -translate-x-1/2 rounded-md px-2 py-1 text-[0.6rem] font-semibold whitespace-nowrap">
                {venue.name}
              </span>
            ) : null}
          </button>
        );
      })}
    </div>
  );
}

function VenuePreviewSheet({
  venue,
  onStartRsvp,
  onViewVenue,
}: {
  venue: PrototypeVenue;
  onStartRsvp: (venueId: string) => void;
  onViewVenue: (venueId: string) => void;
}) {
  return (
    <section
      aria-label={`${venue.name} preview`}
      className="rounded-sheet border-border-subtle bg-background-secondary/96 shadow-elevated absolute inset-x-2 bottom-2 z-20 border p-4 backdrop-blur-xl"
    >
      <div
        aria-hidden="true"
        className="bg-text-muted/40 mx-auto mb-3 h-1 w-9 rounded-full"
      />
      <button
        className="flex w-full items-start justify-between gap-3 text-left"
        onClick={() => onViewVenue(venue.id)}
        type="button"
      >
        <span>
          <span className="text-text-primary block text-xl font-semibold tracking-[-0.035em]">
            {venue.name}
          </span>
          <span className="text-text-secondary mt-0.5 block text-xs">
            {venue.neighbourhood} · {venue.category}
          </span>
          <span className="text-text-muted mt-1 block text-[0.6875rem]">
            {venue.hours}
          </span>
        </span>
        <Icon className="text-text-muted mt-1 size-4" name="chevron-right" />
      </button>

      <div className="border-border-subtle mt-3 grid grid-cols-2 gap-4 border-y py-2.5">
        <p>
          <span className="text-text-primary block text-lg font-semibold">
            {venue.goingCount}
          </span>
          <span className="text-text-muted block text-[0.65rem]">
            going tonight
          </span>
        </p>
        <p>
          <span className="text-text-primary block text-sm font-semibold">
            {venue.expectedPeakTime}
          </span>
          <span className="text-text-muted block text-[0.65rem]">
            expected peak
          </span>
        </p>
      </div>

      <AgeDistributionSparkline
        compact
        className="mt-1"
        {...venue.ageDistribution}
      />

      <div className="mt-2 flex items-center gap-2">
        {venue.offer ? (
          <StatusBadge className="min-w-0 flex-1 truncate" tone="accent">
            {venue.offer}
          </StatusBadge>
        ) : (
          <span className="text-text-muted flex-1 text-xs">
            No check-in offer tonight
          </span>
        )}
        <Button className="min-h-11 px-5" onClick={() => onStartRsvp(venue.id)}>
          I’m Going
        </Button>
      </div>
    </section>
  );
}
