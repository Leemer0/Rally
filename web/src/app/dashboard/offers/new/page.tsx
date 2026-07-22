import Link from "next/link";
import { AlertCircle, ArrowLeft, Info, MapPinCheck } from "lucide-react";
import { submitVenueOffer } from "@/app/dashboard/offers/actions";
import { Button, buttonVariants } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { requireVenueSession } from "@/lib/auth/venue";
import { loadVenueDashboardSnapshot } from "@/lib/data/venue-dashboard";
import { cn } from "@/lib/utils";

type SearchParams = Promise<{ error?: string }>;

const weekdays = [
  { value: 1, label: "Mon" },
  { value: 2, label: "Tue" },
  { value: 3, label: "Wed" },
  { value: 4, label: "Thu" },
  { value: 5, label: "Fri" },
  { value: 6, label: "Sat" },
  { value: 0, label: "Sun" },
];

export default async function NewOfferPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const [params, session] = await Promise.all([
    searchParams,
    requireVenueSession(),
  ]);
  const snapshotResult = await loadVenueDashboardSnapshot(session.userId);
  const snapshot = snapshotResult.data;
  const activeOfferCount =
    snapshot?.offers.filter((offer) =>
      [
        "draft",
        "pending_review",
        "changes_requested",
        "approved",
        "scheduled",
        "live",
        "paused",
      ].includes(offer.status),
    ).length ?? null;

  return (
    <div className="mx-auto max-w-3xl">
      <Link
        href="/dashboard/offers"
        className="inline-flex min-h-10 items-center gap-2 text-sm text-white/42 hover:text-white"
      >
        <ArrowLeft className="size-4" />
        Offers
      </Link>

      <div className="mt-5">
        <p className="font-mono text-[10px] uppercase tracking-[0.17em] text-primary">
          New offer
        </p>
        <h1 className="mt-2 text-3xl font-medium tracking-[-0.035em] sm:text-4xl">
          Create a check-in incentive
        </h1>
        <p className="mt-2 text-sm text-white/40">
          Guests unlock this only after Outly verifies they are at your venue.
        </p>
        {snapshot ? (
          <p className="mt-3 text-[11px] text-white/30">
            {activeOfferCount} of {snapshot.subscription.entitlements.activeOfferLimit}{" "}
            active offer slots currently used
          </p>
        ) : null}
      </div>

      {params.error ? <OfferError code={params.error} /> : null}

      <form
        action={submitVenueOffer}
        className="mt-9 space-y-7 rounded-lg border border-white/10 bg-card p-5 sm:p-7"
      >
        <FormSection number="01" title="What guests see">
          <Field
            id="public-title"
            label="Offer headline"
            hint="One clear sentence. Keep exclusions out of the headline."
          >
            <Input
              id="public-title"
              name="publicTitle"
              placeholder="Free cover with Outly before 10 PM"
              required
              maxLength={140}
              className="h-11 bg-white/[0.03]"
            />
          </Field>
          <Field
            id="short-explanation"
            label="Short explanation"
            hint="Optional. This appears beneath the offer."
          >
            <Textarea
              id="short-explanation"
              name="shortExplanation"
              placeholder="Check in at the venue, then show the active offer to staff."
              maxLength={240}
              className="min-h-24 bg-white/[0.03]"
            />
          </Field>
        </FormSection>

        <FormSection number="02" title="What staff see">
          <Field id="staff-title" label="Staff-facing title">
            <Input
              id="staff-title"
              name="staffDisplayTitle"
              placeholder="Outly guest — free cover"
              required
              maxLength={140}
              className="h-11 bg-white/[0.03]"
            />
          </Field>
          <Field
            id="staff-instruction"
            label="Staff instruction"
            hint="Make the acceptance step unambiguous for the door or service team."
          >
            <Textarea
              id="staff-instruction"
              name="staffInstruction"
              placeholder="Confirm the screen says Valid now and admit one guest without cover."
              required
              maxLength={240}
              className="min-h-24 bg-white/[0.03]"
            />
          </Field>
        </FormSection>

        <FormSection number="03" title="Dates and nights">
          <div className="grid gap-5 sm:grid-cols-2">
            <Field id="start-date" label="First nightlife date">
              <Input
                id="start-date"
                name="nightlifeStartDate"
                type="date"
                required
                className="h-11 bg-white/[0.03]"
              />
            </Field>
            <Field
              id="end-date"
              label="Last nightlife date"
              hint="Optional. Leave blank for no end date."
            >
              <Input
                id="end-date"
                name="nightlifeEndDate"
                type="date"
                className="h-11 bg-white/[0.03]"
              />
            </Field>
          </div>

          <fieldset className="space-y-3">
            <legend className="text-xs font-medium text-white/72">
              Eligible nights
            </legend>
            <div className="grid grid-cols-4 gap-2 sm:grid-cols-7">
              {weekdays.map((day) => (
                <label
                  key={day.value}
                  className="flex min-h-11 cursor-pointer items-center justify-center gap-2 rounded-md border border-white/10 bg-white/[0.02] px-2 text-xs text-white/56 has-checked:border-primary/35 has-checked:bg-primary/[0.06] has-checked:text-white"
                >
                  <input
                    type="checkbox"
                    name="eligibleWeekdays"
                    value={day.value}
                    defaultChecked={day.value === 5 || day.value === 6}
                    className="size-3.5 accent-[var(--primary)]"
                  />
                  {day.label}
                </label>
              ))}
            </div>
          </fieldset>

          <div className="grid gap-5 sm:grid-cols-2">
            <Field
              id="daily-start"
              label="Daily offer start"
              hint="Optional. If set, both times are required."
            >
              <Input
                id="daily-start"
                name="dailyStartsAt"
                type="time"
                className="h-11 bg-white/[0.03]"
              />
            </Field>
            <Field id="daily-end" label="Daily offer end">
              <Input
                id="daily-end"
                name="dailyEndsAt"
                type="time"
                className="h-11 bg-white/[0.03]"
              />
            </Field>
          </div>
        </FormSection>

        <FormSection number="04" title="Unlock rules">
          <div className="flex gap-3 border-l-2 border-primary/60 bg-primary/[0.035] p-4">
            <MapPinCheck className="mt-0.5 size-4 shrink-0 text-primary" />
            <div>
              <p className="text-sm font-medium">Verified check-in is required</p>
              <p className="mt-1 text-xs leading-5 text-white/40">
                The existing precise-location and venue geofence check applies automatically.
              </p>
            </div>
          </div>

          <div className="grid gap-5 sm:grid-cols-2">
            <Field
              id="check-in-start"
              label="Check-in opens"
              hint="Optional. Setting a start requires a cutoff."
            >
              <Input
                id="check-in-start"
                name="checkInStartsAt"
                type="time"
                className="h-11 bg-white/[0.03]"
              />
            </Field>
            <Field
              id="check-in-cutoff"
              label="Check-in cutoff"
              hint="Set this alone to require arrival before a time."
            >
              <Input
                id="check-in-cutoff"
                name="checkInCutoffAt"
                type="time"
                className="h-11 bg-white/[0.03]"
              />
            </Field>
          </div>

          <div className="grid gap-5 sm:grid-cols-2">
            <Field
              id="plan-cutoff"
              label="Plan must be made by"
              hint="Optional. Leave blank if a prior plan is not required."
            >
              <Input
                id="plan-cutoff"
                name="planCutoffAt"
                type="time"
                className="h-11 bg-white/[0.03]"
              />
            </Field>
            <Field
              id="claim-limit"
              label="Unlock limit per night"
              hint="Optional. The offer closes when this many guests unlock it."
            >
              <Input
                id="claim-limit"
                name="occurrenceClaimLimit"
                type="number"
                min={1}
                step={1}
                inputMode="numeric"
                placeholder="No limit"
                className="h-11 bg-white/[0.03]"
              />
            </Field>
          </div>

          <Field
            id="claim-duration"
            label="Redeem-by timer (minutes)"
            hint="Optional. Leave blank for no countdown, or enter any whole-minute duration from 1 to 1,440."
          >
            <Input
              id="claim-duration"
              name="claimDurationMinutes"
              type="number"
              min={1}
              max={1_440}
              step={1}
              inputMode="numeric"
              placeholder="No timer"
              className="h-11 bg-white/[0.03]"
            />
          </Field>

          <div className="flex gap-2 text-xs leading-5 text-white/36">
            <Info className="mt-0.5 size-3.5 shrink-0 text-primary" />
            Drafts stay private. Submitting for review sends the offer to Outly before it can appear in the app.
          </div>
        </FormSection>

        <div className="flex flex-col-reverse gap-3 border-t border-white/10 pt-6 sm:flex-row sm:justify-end">
          <Link
            href="/dashboard/offers"
            className={cn(
              buttonVariants({ variant: "ghost", size: "lg" }),
              "h-11 px-4",
            )}
          >
            Cancel
          </Link>
          <Button
            type="submit"
            name="intent"
            value="draft"
            variant="outline"
            size="lg"
            className="h-11 border-white/12 px-4"
          >
            Save draft
          </Button>
          <Button
            type="submit"
            name="intent"
            value="review"
            size="lg"
            className="h-11 px-4"
          >
            Submit for review
          </Button>
        </div>
      </form>
    </div>
  );
}

function OfferError({ code }: { code: string }) {
  return (
    <div
      role="alert"
      className="mt-6 flex items-start gap-2.5 rounded-md border border-destructive/24 bg-destructive/[0.06] px-3.5 py-3 text-sm text-red-100/78"
    >
      <AlertCircle className="mt-0.5 size-4 shrink-0 text-red-200/80" />
      <p>
        {code === "invalid_form"
          ? "Review the required fields, select at least one night, and complete any paired time window."
          : "The offer could not be saved. Check your active-offer limit and try again."}
      </p>
    </div>
  );
}

function FormSection({
  number,
  title,
  children,
}: {
  number: string;
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section className="grid gap-5 border-b border-white/10 pb-7 last:border-b-0">
      <div className="flex items-center gap-3">
        <span className="font-mono text-[10px] text-primary">{number}</span>
        <h2 className="font-medium">{title}</h2>
      </div>
      {children}
    </section>
  );
}

function Field({
  id,
  label,
  hint,
  children,
}: {
  id: string;
  label: string;
  hint?: string;
  children: React.ReactNode;
}) {
  return (
    <div className="space-y-2">
      <Label htmlFor={id}>{label}</Label>
      {children}
      {hint ? <p className="text-[11px] leading-4 text-white/30">{hint}</p> : null}
    </div>
  );
}
