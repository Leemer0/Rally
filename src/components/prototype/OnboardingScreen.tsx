"use client";

import type { ReactNode } from "react";

import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { ProgressBar } from "@/components/ui/ProgressBar";
import { cn } from "@/lib/cn";

type OnboardingScreenProps = {
  step: number;
  title: string;
  description?: string;
  children: ReactNode;
  onBack: () => void;
  onNext: () => void;
  nextLabel?: string;
  nextDisabled?: boolean;
};

export function OnboardingScreen({
  children,
  description,
  nextDisabled = false,
  nextLabel = "Next",
  onBack,
  onNext,
  step,
  title,
}: OnboardingScreenProps) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <header className="flex shrink-0 items-center gap-3 px-5 pt-2">
        <button
          aria-label="Go back"
          className="text-text-secondary hover:bg-surface-primary hover:text-text-primary flex size-11 shrink-0 items-center justify-center rounded-full transition"
          onClick={onBack}
          type="button"
        >
          <Icon className="size-5" name="arrow-left" />
        </button>
        <ProgressBar
          className="flex-1"
          label={`Onboarding step ${step} of 5`}
          max={5}
          value={step}
        />
        <span className="text-text-muted w-11 text-right text-xs">
          {step}/5
        </span>
      </header>

      <div className="min-h-0 flex-1 overflow-y-auto px-6 pt-10 pb-8">
        <h1 className="text-text-primary max-w-sm text-[2rem] leading-[1.04] font-semibold tracking-[-0.045em] text-balance">
          {title}
        </h1>
        {description ? (
          <p className="text-text-secondary mt-3 max-w-sm text-sm leading-6">
            {description}
          </p>
        ) : null}
        <div className="mt-10">{children}</div>
      </div>

      <footer className="border-border-subtle bg-background-primary/96 shrink-0 border-t px-5 pt-4 pb-[max(1rem,env(safe-area-inset-bottom))] backdrop-blur-xl">
        <Button disabled={nextDisabled} fullWidth onClick={onNext} size="lg">
          {nextLabel}
        </Button>
      </footer>
    </div>
  );
}

type ChoiceRowProps = {
  label: string;
  selected: boolean;
  onClick: () => void;
  detail?: string;
};

export function ChoiceRow({
  detail,
  label,
  onClick,
  selected,
}: ChoiceRowProps) {
  return (
    <button
      aria-pressed={selected}
      className={cn(
        "rounded-control flex min-h-14 w-full items-center justify-between gap-4 border px-4 py-3 text-left transition duration-150",
        selected
          ? "border-accent-primary bg-accent-muted text-text-primary"
          : "border-border-subtle bg-surface-primary text-text-primary hover:border-border-strong",
      )}
      onClick={onClick}
      type="button"
    >
      <span>
        <span className="block text-[0.9375rem] font-medium">{label}</span>
        {detail ? (
          <span className="text-text-muted mt-0.5 block text-xs">{detail}</span>
        ) : null}
      </span>
      <span
        aria-hidden="true"
        className={cn(
          "flex size-5 items-center justify-center rounded-full border",
          selected
            ? "border-accent-primary bg-accent-primary text-accent-foreground"
            : "border-border-strong",
        )}
      >
        {selected ? <Icon className="size-3" name="check" /> : null}
      </span>
    </button>
  );
}
