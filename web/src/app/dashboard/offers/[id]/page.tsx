import Link from "next/link";
import { ArrowLeft, MessageSquareText } from "lucide-react";
import {
  reviseVenueOffer,
  setVenueOfferStatus,
} from "@/app/dashboard/offers/actions";
import { DashboardUnavailable } from "@/components/dashboard/dashboard-unavailable";
import { Badge } from "@/components/ui/badge";
import { Button, buttonVariants } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { requireVenueSession } from "@/lib/auth/venue";
import { loadVenueOfferEditor } from "@/lib/data/venue-dashboard";
import { cn } from "@/lib/utils";

type RouteParams = Promise<{ id: string }>;
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

export default async function EditOfferPage({
  params,
  searchParams,
}: {
  params: RouteParams;
  searchParams: SearchParams;
}) {
  const [{ id }, query, session] = await Promise.all([
    params,
    searchParams,
    requireVenueSession(),
  ]);
  const result = await loadVenueOfferEditor(session.userId, id);

  if (!result.data) {
    return (
      <DashboardUnavailable
        configuration={result.error === "configuration"}
        title="We couldn’t load that offer."
      />
    );
  }

  const offer = result.data;
  const durationMinutes = offer.claimDurationSeconds === null
    ? undefined
    : Math.ceil(offer.claimDurationSeconds / 60);

  return (
    <div className="mx-auto max-w-3xl">
      <Link
        href="/dashboard/offers"
        className="inline-flex min-h-10 items-center gap-2 text-sm text-white/42 hover:text-white"
      >
        <ArrowLeft className="size-4" />
        Offers
      </Link>

      <div className="mt-5 flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
        <div>
          <p className="font-mono text-[10px] uppercase tracking-[0.17em] text-primary">
            Offer revision · v{offer.versionNumber}
          </p>
          <h1 className="mt-2 text-3xl font-medium tracking-[-0.035em] sm:text-4xl">
            {offer.lifecycleStatus === "changes_requested"
              ? "Make the requested changes"
              : "Edit your draft"}
          </h1>
        </div>
        <Badge
          variant="outline"
          className="w-fit rounded-sm border-white/12 text-white/58"
        >
          {presentStatus(offer.lifecycleStatus)}
        </Badge>
      </div>

      {offer.latestFeedback?.publicResponse ? (
        <section className="mt-7 border-l-2 border-amber-200/45 bg-amber-100/[0.035] px-4 py-3.5">
          <div className="flex items-center gap-2 text-xs font-medium text-amber-50/76">
            <MessageSquareText className="size-3.5" />
            Feedback from Outly
          </div>
          <p className="mt-2 text-sm leading-6 text-white/64">
            {offer.latestFeedback.publicResponse}
          </p>
        </section>
      ) : null}

      {query.error ? (
        <div
          role="alert"
          className="mt-5 rounded-md border border-red-300/15 bg-red-300/[0.04] px-3.5 py-3 text-sm text-red-100/72"
        >
          {query.error === "invalid_form"
            ? "Check the required fields and time windows."
            : "We couldn’t save that revision. Reload the page and try again."}
        </div>
      ) : null}

      {offer.canEdit ? (
        <form
          action={reviseVenueOffer}
          className="mt-7 space-y-8 rounded-lg border border-white/10 bg-card p-5 sm:p-7"
        >
          <input type="hidden" name="offerId" value={offer.offerId} />
          <input
            type="hidden"
            name="offerVersionId"
            value={offer.offerVersionId}
          />
          <input
            type="hidden"
            name="idempotencyKey"
            value={crypto.randomUUID()}
          />

          <FormSection number="01" title="Guest-facing offer">
            <Field id="public-title" label="Offer headline">
              <Input
                id="public-title"
                name="publicTitle"
                defaultValue={offer.publicTitle}
                required
                maxLength={140}
                className="h-11 bg-white/[0.03]"
              />
            </Field>
            <Field
              id="short-explanation"
              label="Short explanation"
              hint="Optional. Keep exclusions and operational detail out of the headline."
            >
              <Textarea
                id="short-explanation"
                name="shortExplanation"
                defaultValue={offer.shortExplanation ?? undefined}
                maxLength={240}
                className="min-h-24 bg-white/[0.03]"
              />
            </Field>
          </FormSection>

          <FormSection number="02" title="Staff confirmation">
            <Field id="staff-title" label="Staff-facing title">
              <Input
                id="staff-title"
                name="staffDisplayTitle"
                defaultValue={offer.staffDisplayTitle}
                required
                maxLength={140}
                className="h-11 bg-white/[0.03]"
              />
            </Field>
            <Field id="staff-instruction" label="Staff instruction">
              <Textarea
                id="staff-instruction"
                name="staffInstruction"
                defaultValue={offer.staffInstruction}
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
                  defaultValue={offer.schedule.nightlifeStartDate}
                  required
                  className="h-11 bg-white/[0.03]"
                />
              </Field>
              <Field id="end-date" label="Last nightlife date" hint="Optional">
                <Input
                  id="end-date"
                  name="nightlifeEndDate"
                  type="date"
                  defaultValue={offer.schedule.nightlifeEndDate ?? undefined}
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
                      defaultChecked={offer.schedule.eligibleWeekdays.includes(
                        day.value,
                      )}
                      className="size-3.5 accent-[var(--primary)]"
                    />
                    {day.label}
                  </label>
                ))}
              </div>
            </fieldset>

            <div className="grid gap-5 sm:grid-cols-2">
              <Field id="daily-start" label="Daily offer start" hint="Optional">
                <Input
                  id="daily-start"
                  name="dailyStartsAt"
                  type="time"
                  defaultValue={timeValue(offer.schedule.dailyStartsAt)}
                  className="h-11 bg-white/[0.03]"
                />
              </Field>
              <Field id="daily-end" label="Daily offer end">
                <Input
                  id="daily-end"
                  name="dailyEndsAt"
                  type="time"
                  defaultValue={timeValue(offer.schedule.dailyEndsAt)}
                  className="h-11 bg-white/[0.03]"
                />
              </Field>
            </div>
          </FormSection>

          <FormSection number="04" title="Unlock rules">
            <div className="grid gap-5 sm:grid-cols-2">
              <Field id="check-in-start" label="Check-in opens" hint="Optional">
                <Input
                  id="check-in-start"
                  name="checkInStartsAt"
                  type="time"
                  defaultValue={timeValue(offer.schedule.checkInStartsAt)}
                  className="h-11 bg-white/[0.03]"
                />
              </Field>
              <Field id="check-in-cutoff" label="Check-in cutoff" hint="Optional">
                <Input
                  id="check-in-cutoff"
                  name="checkInCutoffAt"
                  type="time"
                  defaultValue={timeValue(offer.schedule.checkInCutoffAt)}
                  className="h-11 bg-white/[0.03]"
                />
              </Field>
              <Field id="plan-cutoff" label="Plan must be made by" hint="Optional">
                <Input
                  id="plan-cutoff"
                  name="planCutoffAt"
                  type="time"
                  defaultValue={timeValue(offer.schedule.planCutoffAt)}
                  className="h-11 bg-white/[0.03]"
                />
              </Field>
              <Field id="claim-limit" label="Unlock limit per night" hint="Optional">
                <Input
                  id="claim-limit"
                  name="occurrenceClaimLimit"
                  type="number"
                  min={1}
                  step={1}
                  defaultValue={
                    offer.schedule.occurrenceClaimLimit ?? undefined
                  }
                  className="h-11 bg-white/[0.03]"
                />
              </Field>
            </div>
            <Field
              id="claim-duration"
              label="Redeem-by timer (minutes)"
              hint="Optional. Leave blank for no countdown."
            >
              <Input
                id="claim-duration"
                name="claimDurationMinutes"
                type="number"
                min={1}
                max={1_440}
                step={1}
                defaultValue={durationMinutes}
                className="h-11 bg-white/[0.03]"
              />
            </Field>
          </FormSection>

          <div className="flex flex-col-reverse gap-2 border-t border-white/8 pt-5 sm:flex-row sm:justify-end">
            <Button
              type="submit"
              name="intent"
              value="draft"
              variant="outline"
              className="h-11"
            >
              Save draft
            </Button>
            <Button
              type="submit"
              name="intent"
              value="review"
              className="h-11"
            >
              Submit revision
            </Button>
          </div>
        </form>
      ) : (
        <section className="mt-7 rounded-lg border border-white/10 bg-card p-6">
          <p className="font-medium">This version is read-only.</p>
          <p className="mt-2 text-sm leading-6 text-white/42">
            Submitted and approved offers stay locked so the version reviewed by Outly remains unchanged.
          </p>
          <Link
            href="/dashboard/offers"
            className={cn(buttonVariants({ variant: "outline" }), "mt-5")}
          >
            Back to offers
          </Link>
        </section>
      )}

      {offer.lifecycleStatus !== "archived" ? (
        <section className="mt-8 border-t border-white/10 pt-6">
          <p className="text-xs font-medium text-white/62">
            Remove this offer from circulation
          </p>
          <p className="mt-1 text-xs leading-5 text-white/34">
            Existing redeemed offers keep their record. New guests will not be able to unlock it.
          </p>
          <form action={setVenueOfferStatus} className="mt-3">
            <input type="hidden" name="offerId" value={offer.offerId} />
            <input
              type="hidden"
              name="idempotencyKey"
              value={crypto.randomUUID()}
            />
            <input
              type="hidden"
              name="targetStatus"
              value={archiveDirectly(offer.lifecycleStatus) ? "archived" : "ended"}
            />
            <Button variant="ghost" className="px-0 text-white/46 hover:text-white/76">
              {archiveDirectly(offer.lifecycleStatus) ? "Archive offer" : "End offer"}
            </Button>
          </form>
        </section>
      ) : null}
    </div>
  );
}

function archiveDirectly(status: string) {
  return ["draft", "changes_requested", "rejected", "ended"].includes(status);
}

function timeValue(value: string | null) {
  return value ? value.slice(0, 5) : undefined;
}

function presentStatus(value: string) {
  return value.replaceAll("_", " ").replace(/\b\w/g, (letter) =>
    letter.toUpperCase(),
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
    <section className="space-y-5">
      <div className="flex items-center gap-3 border-b border-white/8 pb-3">
        <span className="font-mono text-[10px] text-primary">{number}</span>
        <h2 className="text-sm font-medium">{title}</h2>
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
      {hint ? <p className="text-[11px] leading-5 text-white/32">{hint}</p> : null}
    </div>
  );
}
