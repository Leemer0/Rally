import { cn } from "@/lib/cn";
import type { AgeDistribution } from "@/prototype/data";

type AgeDistributionSparklineProps = AgeDistribution & {
  compact?: boolean;
  className?: string;
};

const WIDTH = 300;
const HEIGHT = 48;
const X_PADDING = 8;
const TOP_PADDING = 5;
const BASELINE = 38;

export function AgeDistributionSparkline({
  className,
  compact = false,
  maxAge,
  minAge,
  peakAge,
  points,
  status,
}: AgeDistributionSparklineProps) {
  if (status === "limited_data" || points.length === 0) {
    return (
      <div className={cn("grid gap-1.5", className)}>
        <svg
          aria-label="Age distribution is unavailable because there is not enough attendance data."
          className={cn("w-full", compact ? "h-10" : "h-12")}
          role="img"
          viewBox={`0 0 ${WIDTH} ${HEIGHT}`}
        >
          <path
            d="M8 34 C55 29 80 36 118 32 S190 27 230 33 S270 30 292 34"
            fill="none"
            stroke="var(--text-muted)"
            strokeDasharray="3 5"
            strokeOpacity=".55"
            strokeWidth="1.5"
          />
        </svg>
        {!compact ? (
          <p className="text-text-muted text-[0.6875rem]">
            More attendance data needed
          </p>
        ) : null}
      </div>
    );
  }

  const mapped = points.map((point) => ({
    x:
      X_PADDING +
      ((point.age - minAge) / (maxAge - minAge)) * (WIDTH - X_PADDING * 2),
    y: BASELINE - point.intensity * (BASELINE - TOP_PADDING),
  }));
  const path = buildSmoothPath(mapped);
  const peakPoint = points.find((point) => point.age === peakAge);
  const peakX = peakAge
    ? X_PADDING +
      ((peakAge - minAge) / (maxAge - minAge)) * (WIDTH - X_PADDING * 2)
    : null;
  const peakY = peakPoint
    ? BASELINE - peakPoint.intensity * (BASELINE - TOP_PADDING)
    : null;

  return (
    <div className={cn("grid gap-0.5", className)}>
      <svg
        aria-label={`Age distribution from ${minAge} to ${maxAge}, peaking around age ${peakAge}.`}
        className={cn("w-full overflow-visible", compact ? "h-10" : "h-12")}
        role="img"
        viewBox={`0 0 ${WIDTH} ${HEIGHT}`}
      >
        <path
          d={`M${X_PADDING} ${BASELINE}H${WIDTH - X_PADDING}`}
          stroke="var(--border-strong)"
          strokeWidth="1"
        />
        <path
          d={path}
          fill="none"
          stroke="var(--accent-primary)"
          strokeLinecap="round"
          strokeWidth="1.8"
          vectorEffect="non-scaling-stroke"
        />
        {peakX !== null && peakY !== null ? (
          <circle cx={peakX} cy={peakY} fill="var(--accent-primary)" r="2.5" />
        ) : null}
      </svg>
      {!compact ? (
        <div className="text-text-muted flex justify-between text-[0.625rem]">
          <span>{minAge}</span>
          {peakAge ? <span>Most are around {peakAge}</span> : null}
          <span>{maxAge}</span>
        </div>
      ) : null}
    </div>
  );
}

function buildSmoothPath(points: Array<{ x: number; y: number }>) {
  if (points.length === 0) return "";
  if (points.length === 1) return `M${points[0].x} ${points[0].y}`;

  return (
    points.slice(1).reduce((path, point, index) => {
      const previous = points[index];
      const midpointX = (previous.x + point.x) / 2;
      const midpointY = (previous.y + point.y) / 2;
      return `${path} Q${previous.x} ${previous.y} ${midpointX} ${midpointY}`;
    }, `M${points[0].x} ${points[0].y}`) +
    ` T${points.at(-1)?.x} ${points.at(-1)?.y}`
  );
}
