import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Icon } from "@/components/ui/Icon";
import { getVenue } from "@/prototype/data";
import type { PrototypePlan } from "@/prototype/types";

export function ActivePlanCard({
  plan,
  onView,
  onChange,
  onCancel,
  onCheckin,
}: {
  plan: PrototypePlan;
  onView: () => void;
  onChange: () => void;
  onCancel: () => void;
  onCheckin?: () => void;
}) {
  const venue = getVenue(plan.venueId);
  return (
    <Card className="overflow-hidden" variant="elevated">
      <div className="border-border-subtle bg-accent-muted flex items-center gap-3 border-b px-4 py-3">
        <span className="bg-accent-primary text-accent-foreground flex size-8 items-center justify-center rounded-full">
          <Icon className="size-4" name="check" />
        </span>
        <div>
          <p className="text-accent-primary text-[0.65rem] font-semibold tracking-[0.12em] uppercase">
            Your plan tonight
          </p>
          <p className="text-text-primary text-sm font-semibold">
            {venue.name}
          </p>
        </div>
      </div>
      <div className="p-4">
        <p className="text-text-primary text-sm">
          {plan.arrivalWindow} · Group of {plan.groupSize}
        </p>
        <div className="mt-4 flex flex-wrap gap-2">
          <Button
            className="min-h-10 px-3 text-xs"
            onClick={onView}
            variant="secondary"
          >
            View venue
          </Button>
          <Button
            className="min-h-10 px-3 text-xs"
            onClick={onChange}
            variant="ghost"
          >
            Change
          </Button>
          {onCheckin ? (
            <Button className="min-h-10 px-3 text-xs" onClick={onCheckin}>
              Check in
            </Button>
          ) : null}
          <Button
            className="text-error min-h-10 px-3 text-xs"
            onClick={onCancel}
            variant="ghost"
          >
            Cancel
          </Button>
        </div>
      </div>
    </Card>
  );
}
