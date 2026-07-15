"use client";

import { useMemo, useState } from "react";

import { AgeDistributionSparkline } from "@/components/prototype/AgeDistributionSparkline";
import {
  AppNavigation,
  type AppTab,
} from "@/components/prototype/AppNavigation";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Chip } from "@/components/ui/Chip";
import { Icon } from "@/components/ui/Icon";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { venues } from "@/prototype/data";

type SortOption = "most-going" | "peak-soon" | "nearest" | "recommended";

export function ListScreen({
  onNavigate,
  onViewVenue,
  onStartRsvp,
}: {
  onNavigate: (tab: AppTab) => void;
  onViewVenue: (venueId: string) => void;
  onStartRsvp: (venueId: string) => void;
}) {
  const [sort, setSort] = useState<SortOption>("most-going");
  const [showFilters, setShowFilters] = useState(false);
  const [openNow, setOpenNow] = useState(false);
  const [hasOffer, setHasOffer] = useState(false);
  const [neighbourhood, setNeighbourhood] = useState<string | null>(null);

  const filteredVenues = useMemo(() => {
    const result = venues.filter(
      (venue) =>
        (!hasOffer || venue.offer) &&
        (!neighbourhood || venue.neighbourhood === neighbourhood),
    );
    if (sort === "nearest")
      return [...result].sort(
        (a, b) => Number.parseFloat(a.distance) - Number.parseFloat(b.distance),
      );
    if (sort === "peak-soon")
      return [...result].sort((a, b) =>
        a.expectedPeakTime.localeCompare(b.expectedPeakTime),
      );
    return [...result].sort((a, b) => b.goingCount - a.goingCount);
  }, [hasOffer, neighbourhood, sort]);

  return (
    <div className="relative flex min-h-0 flex-1 flex-col">
      <header className="shrink-0 px-5 pt-3 pb-4">
        <div className="flex items-end justify-between gap-3">
          <div>
            <p className="text-text-secondary text-xs">Toronto · Tonight</p>
            <h1 className="text-text-primary mt-1 text-3xl font-semibold tracking-[-0.05em]">
              Venue list
            </h1>
          </div>
          <button
            aria-label="Open filters"
            className="rounded-control border-border-subtle bg-surface-primary text-text-primary flex size-11 items-center justify-center border"
            onClick={() => setShowFilters(true)}
            type="button"
          >
            <Icon className="size-5" name="spark" />
          </button>
        </div>
        <label className="text-text-muted mt-4 flex items-center gap-2 text-xs">
          Sort
          <select
            className="rounded-control border-border-subtle bg-surface-primary text-text-primary min-h-10 flex-1 border px-3 text-sm"
            onChange={(event) => setSort(event.target.value as SortOption)}
            value={sort}
          >
            <option value="most-going">Most going</option>
            <option value="peak-soon">Peak soon</option>
            <option value="nearest">Nearest</option>
            <option value="recommended">Recommended</option>
          </select>
        </label>
      </header>

      <main className="min-h-0 flex-1 overflow-y-auto px-4 pb-5">
        <div className="grid gap-3">
          {filteredVenues.map((venue) => (
            <Card key={venue.id} className="overflow-hidden" variant="elevated">
              <button
                className="flex w-full gap-3 p-3 text-left"
                onClick={() => onViewVenue(venue.id)}
                type="button"
              >
                <span className="rounded-control bg-surface-sunken city-grid relative h-24 w-24 shrink-0 overflow-hidden">
                  <span className="bg-accent-muted absolute right-2 bottom-2 size-8 rounded-full" />
                </span>
                <span className="min-w-0 flex-1">
                  <span className="flex items-start justify-between gap-2">
                    <span className="text-text-primary font-semibold">
                      {venue.name}
                    </span>
                    <span className="text-text-muted text-[0.65rem]">
                      {venue.distance}
                    </span>
                  </span>
                  <span className="text-text-secondary mt-1 block text-xs">
                    {venue.neighbourhood} · {venue.category}
                  </span>
                  <span className="text-text-muted mt-1 block text-[0.65rem]">
                    {venue.hours}
                  </span>
                  <span className="mt-3 flex items-center gap-2">
                    <strong className="text-text-primary text-sm">
                      {venue.goingCount} going
                    </strong>
                    <span className="text-text-muted text-[0.65rem]">
                      Peak {venue.expectedPeakTime}
                    </span>
                  </span>
                </span>
              </button>
              <div className="border-border-subtle border-t px-3 py-2">
                <AgeDistributionSparkline compact {...venue.ageDistribution} />
                <div className="mt-1 flex items-center gap-2">
                  <div className="min-w-0 flex-1">
                    {venue.offer ? (
                      <StatusBadge
                        className="max-w-full truncate"
                        tone="accent"
                      >
                        {venue.offer}
                      </StatusBadge>
                    ) : (
                      <span className="text-text-muted text-[0.65rem]">
                        No offer tonight
                      </span>
                    )}
                  </div>
                  <Button
                    className="min-h-10 px-4 text-xs"
                    onClick={() => onStartRsvp(venue.id)}
                  >
                    I’m Going
                  </Button>
                </div>
              </div>
            </Card>
          ))}
        </div>
      </main>
      <AppNavigation active="list" onChange={onNavigate} />

      {showFilters ? (
        <div className="bg-background-primary/72 absolute inset-0 z-50 flex items-end backdrop-blur-sm">
          <section
            aria-label="Venue filters"
            aria-modal="true"
            className="rounded-t-sheet border-border-subtle bg-background-secondary shadow-elevated w-full border-t p-5 pb-[max(1rem,env(safe-area-inset-bottom))]"
            role="dialog"
          >
            <div className="flex items-center justify-between">
              <h2 className="text-text-primary text-xl font-semibold">
                Filters
              </h2>
              <button
                className="text-text-secondary min-h-11 px-2 text-sm"
                onClick={() => setShowFilters(false)}
                type="button"
              >
                Done
              </button>
            </div>
            <p className="text-text-muted mt-5 text-xs font-semibold">
              Neighbourhood
            </p>
            <div className="mt-2 flex flex-wrap gap-2">
              <Chip
                onClick={() => setNeighbourhood(null)}
                selected={!neighbourhood}
              >
                All
              </Chip>
              <Chip
                onClick={() => setNeighbourhood("King West")}
                selected={neighbourhood === "King West"}
              >
                King West
              </Chip>
              <Chip
                onClick={() => setNeighbourhood("Ossington")}
                selected={neighbourhood === "Ossington"}
              >
                Ossington
              </Chip>
            </div>
            <p className="text-text-muted mt-5 text-xs font-semibold">
              Tonight
            </p>
            <div className="mt-2 flex flex-wrap gap-2">
              <Chip
                onClick={() => setOpenNow((current) => !current)}
                selected={openNow}
              >
                Open now
              </Chip>
              <Chip
                onClick={() => setHasOffer((current) => !current)}
                selected={hasOffer}
              >
                Has offer
              </Chip>
              <Chip>24–27 age peak</Chip>
              <Chip>20+ going</Chip>
            </div>
            <Button
              className="mt-6"
              fullWidth
              onClick={() => setShowFilters(false)}
            >
              Show {filteredVenues.length} venues
            </Button>
          </section>
        </div>
      ) : null}
    </div>
  );
}
