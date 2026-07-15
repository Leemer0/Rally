import Image from "next/image";

import { cn } from "@/lib/cn";

type OutlyLogoProps = {
  size?: "sm" | "md" | "lg";
  className?: string;
  priority?: boolean;
  decorative?: boolean;
};

const sizes = {
  sm: { width: 96, height: 48, className: "w-24" },
  md: { width: 144, height: 72, className: "w-36" },
  lg: { width: 216, height: 108, className: "w-54" },
} as const;

export function OutlyLogo({
  className,
  decorative = false,
  priority = false,
  size = "md",
}: OutlyLogoProps) {
  const dimensions = sizes[size];

  return (
    <Image
      alt={decorative ? "" : "Outly"}
      aria-hidden={decorative || undefined}
      className={cn("h-auto select-none", dimensions.className, className)}
      height={dimensions.height}
      priority={priority}
      src="/brand/outly-mark.svg"
      width={dimensions.width}
    />
  );
}
