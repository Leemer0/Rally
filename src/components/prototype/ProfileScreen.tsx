import { ActivePlanCard } from "@/components/prototype/ActivePlanCard";
import {
  AppNavigation,
  type AppTab,
} from "@/components/prototype/AppNavigation";
import { OutlyLogo } from "@/components/OutlyLogo";
import { Card } from "@/components/ui/Card";
import { Icon } from "@/components/ui/Icon";
import { getVenue } from "@/prototype/data";
import type { PrototypePlan, PrototypeProfile } from "@/prototype/types";

const genderLabels = {
  woman: "Woman",
  man: "Man",
  non_binary: "Non-binary",
  self_describe: "Self-described",
  prefer_not_to_say: "Prefer not to say",
} as const;
const interestedLabels = {
  women: "Women",
  men: "Men",
  everyone: "Everyone",
} as const;

export function ProfileScreen({
  profile,
  plan,
  checkedInVenueId,
  onNavigate,
  onViewVenue,
  onChangePlan,
  onCancelPlan,
  onCheckin,
  onLogOut,
}: {
  profile: PrototypeProfile;
  plan: PrototypePlan | null;
  checkedInVenueId: string | null;
  onNavigate: (tab: AppTab) => void;
  onViewVenue: (venueId: string) => void;
  onChangePlan: (venueId: string) => void;
  onCancelPlan: () => void;
  onCheckin: (venueId: string) => void;
  onLogOut: () => void;
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <header className="flex shrink-0 items-center justify-between px-5 pt-3 pb-4">
        <h1 className="text-text-primary text-3xl font-semibold tracking-[-0.05em]">
          Profile
        </h1>
        <button
          aria-label="Settings"
          className="border-border-subtle bg-surface-primary text-text-secondary flex size-11 items-center justify-center rounded-full border"
          type="button"
        >
          <Icon className="size-5" name="spark" />
        </button>
      </header>
      <main className="min-h-0 flex-1 overflow-y-auto px-4 pb-6">
        <div className="border-border-subtle flex flex-col items-center border-b pb-6 text-center">
          <span className="border-border-strong bg-surface-secondary flex size-24 items-center justify-center rounded-full border">
            <OutlyLogo size="sm" />
          </span>
          <h2 className="text-text-primary mt-3 text-xl font-semibold">
            {profile.firstName || "Outly User"}
          </h2>
          <p className="text-text-secondary mt-1 text-xs">
            Toronto · Private profile
          </p>
        </div>

        <section className="mt-5">
          <h3 className="text-text-muted mb-3 px-1 text-xs font-semibold tracking-[0.12em] uppercase">
            Tonight
          </h3>
          {plan ? (
            <ActivePlanCard
              plan={plan}
              onCancel={onCancelPlan}
              onChange={() => onChangePlan(plan.venueId)}
              onCheckin={() => onCheckin(plan.venueId)}
              onView={() => onViewVenue(plan.venueId)}
            />
          ) : (
            <Card className="p-4" variant="outlined">
              <p className="text-text-primary text-sm font-medium">
                Pick a venue and say where you’re going.
              </p>
              <p className="text-text-muted mt-1 text-xs">
                Your active plan will appear here.
              </p>
            </Card>
          )}
        </section>

        <section className="mt-6">
          <h3 className="text-text-muted mb-3 px-1 text-xs font-semibold tracking-[0.12em] uppercase">
            Private details
          </h3>
          <Card
            className="divide-border-subtle divide-y px-4"
            variant="default"
          >
            <ProfileRow label="Age" value={String(profile.age)} />
            <ProfileRow
              label="Gender"
              value={
                profile.genderIdentity
                  ? genderLabels[profile.genderIdentity]
                  : "Not set"
              }
            />
            <ProfileRow
              label="Interested in"
              value={
                profile.interestedIn[0]
                  ? interestedLabels[profile.interestedIn[0]]
                  : "Not set"
              }
            />
          </Card>
        </section>

        <section className="mt-6">
          <h3 className="text-text-muted mb-3 px-1 text-xs font-semibold tracking-[0.12em] uppercase">
            Previous check-ins
          </h3>
          {checkedInVenueId ? (
            <Card className="flex items-center gap-3 p-4">
              <span className="bg-success-muted text-success flex size-9 items-center justify-center rounded-full">
                <Icon className="size-4" name="check" />
              </span>
              <div>
                <p className="text-text-primary text-sm font-medium">
                  {getVenue(checkedInVenueId).name}
                </p>
                <p className="text-text-muted text-xs">
                  Verified tonight · 9:48 PM
                </p>
              </div>
            </Card>
          ) : (
            <p className="text-text-muted px-1 text-sm">
              No verified check-ins yet.
            </p>
          )}
        </section>

        <section className="mt-7 grid gap-1">
          <MenuRow label="Privacy" />
          <MenuRow label="Help & support" />
          <button
            className="border-border-subtle text-text-secondary flex min-h-12 items-center justify-between border-t px-2 text-left text-sm"
            onClick={onLogOut}
            type="button"
          >
            Log out
            <Icon className="size-4" name="chevron-right" />
          </button>
          <button
            className="text-error min-h-12 px-2 text-left text-sm"
            type="button"
          >
            Delete account
          </button>
        </section>
      </main>
      <AppNavigation active="profile" onChange={onNavigate} />
    </div>
  );
}

function ProfileRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex min-h-12 items-center justify-between gap-4">
      <span className="text-text-secondary text-sm">{label}</span>
      <span className="text-text-primary text-sm font-medium">{value}</span>
    </div>
  );
}
function MenuRow({ label }: { label: string }) {
  return (
    <button
      className="border-border-subtle text-text-secondary flex min-h-12 items-center justify-between border-t px-2 text-left text-sm"
      type="button"
    >
      {label}
      <Icon className="size-4" name="chevron-right" />
    </button>
  );
}
