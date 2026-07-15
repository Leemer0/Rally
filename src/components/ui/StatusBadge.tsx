import type { HTMLAttributes } from "react";

import { cn } from "@/lib/cn";

type StatusTone = "neutral" | "accent" | "success" | "warning" | "error";

type StatusBadgeProps = HTMLAttributes<HTMLSpanElement> & {
  tone?: StatusTone;
  dot?: boolean;
};

const tones: Record<StatusTone, string> = {
  neutral: "bg-surface-elevated text-text-secondary",
  accent: "bg-accent-muted text-accent-primary",
  success: "bg-success-muted text-success",
  warning: "bg-warning-muted text-warning",
  error: "bg-error-muted text-error",
};

export function StatusBadge({
  children,
  className,
  dot = false,
  tone = "neutral",
  ...props
}: StatusBadgeProps) {
  return (
    <span
      className={cn(
        "inline-flex min-h-6 items-center gap-1.5 rounded-full px-2.5 py-1 text-xs leading-none font-semibold whitespace-nowrap",
        tones[tone],
        className,
      )}
      {...props}
    >
      {dot ? (
        <span aria-hidden="true" className="size-1.5 rounded-full bg-current" />
      ) : null}
      {children}
    </span>
  );
}
