import type { ButtonHTMLAttributes, ReactNode } from "react";

import { cn } from "@/lib/cn";

export type ChipProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  selected?: boolean;
  leadingIcon?: ReactNode;
};

export function Chip({
  children,
  className,
  leadingIcon,
  selected = false,
  type = "button",
  ...props
}: ChipProps) {
  return (
    <button
      aria-pressed={selected}
      className={cn(
        "inline-flex min-h-11 cursor-pointer items-center justify-center gap-2 rounded-full border px-4 text-sm font-medium transition duration-150 active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-45",
        selected
          ? "border-accent-primary/50 bg-accent-muted text-accent-primary"
          : "border-border-subtle bg-surface-primary text-text-secondary hover:border-border-strong hover:text-text-primary",
        className,
      )}
      type={type}
      {...props}
    >
      {leadingIcon}
      {children}
    </button>
  );
}
