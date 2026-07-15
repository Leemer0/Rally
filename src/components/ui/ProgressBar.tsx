import { cn } from "@/lib/cn";

type ProgressBarProps = {
  value: number;
  max?: number;
  label: string;
  showValue?: boolean;
  className?: string;
};

export function ProgressBar({
  className,
  label,
  max = 100,
  showValue = false,
  value,
}: ProgressBarProps) {
  const safeMax = max > 0 ? max : 100;
  const safeValue = Math.min(Math.max(value, 0), safeMax);
  const percentage = Math.round((safeValue / safeMax) * 100);

  return (
    <div className={cn("grid gap-2", className)}>
      <div
        className={cn(
          "items-center justify-between gap-4",
          showValue ? "flex" : "sr-only",
        )}
      >
        <span className="text-text-primary text-sm font-medium">{label}</span>
        {showValue ? (
          <span className="text-text-muted text-xs">{percentage}%</span>
        ) : null}
      </div>
      <div
        aria-label={label}
        aria-valuemax={safeMax}
        aria-valuemin={0}
        aria-valuenow={safeValue}
        className="bg-surface-elevated h-1.5 overflow-hidden rounded-full"
        role="progressbar"
      >
        <span
          className="bg-accent-primary block h-full origin-left rounded-full transition-transform duration-300 ease-out"
          style={{ transform: `scaleX(${percentage / 100})` }}
        />
      </div>
    </div>
  );
}
