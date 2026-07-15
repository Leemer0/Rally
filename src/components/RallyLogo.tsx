import Image from "next/image";

import { cn } from "@/lib/cn";

type RallyLogoProps = {
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

export function RallyLogo({
  className,
  decorative = false,
  priority = false,
  size = "md",
}: RallyLogoProps) {
  const dimensions = sizes[size];

  return (
    <Image
      alt={decorative ? "" : "Rally"}
      aria-hidden={decorative || undefined}
      className={cn("h-auto select-none", dimensions.className, className)}
      height={dimensions.height}
      priority={priority}
      src="/brand/rally-mark.svg"
      width={dimensions.width}
    />
  );
}
