import { forwardRef, type ButtonHTMLAttributes, type ReactNode } from "react";

import { cn } from "@/lib/cn";

type ButtonVariant = "primary" | "secondary" | "ghost" | "destructive";
type ButtonSize = "sm" | "md" | "lg" | "icon";

export type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: ButtonVariant;
  size?: ButtonSize;
  fullWidth?: boolean;
  loading?: boolean;
  leadingIcon?: ReactNode;
  trailingIcon?: ReactNode;
};

const variants: Record<ButtonVariant, string> = {
  primary:
    "border-accent-primary bg-accent-primary text-accent-foreground shadow-accent hover:border-accent-hover hover:bg-accent-hover",
  secondary:
    "border-border-strong bg-surface-secondary text-text-primary hover:border-border-strong hover:bg-surface-elevated",
  ghost:
    "border-transparent bg-transparent text-text-secondary hover:bg-surface-primary hover:text-text-primary",
  destructive:
    "border-error/30 bg-error-muted text-error hover:border-error/50 hover:bg-error/20",
};

const sizes: Record<ButtonSize, string> = {
  sm: "min-h-11 px-4 text-sm",
  md: "min-h-12 px-5 text-[0.9375rem]",
  lg: "min-h-14 px-6 text-base",
  icon: "size-12 shrink-0 p-0",
};

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  function Button(
    {
      children,
      className,
      disabled,
      fullWidth,
      leadingIcon,
      loading = false,
      size = "md",
      trailingIcon,
      type = "button",
      variant = "primary",
      ...props
    },
    ref,
  ) {
    const isDisabled = disabled || loading;

    return (
      <button
        ref={ref}
        aria-busy={loading || undefined}
        className={cn(
          "rounded-control inline-flex cursor-pointer items-center justify-center gap-2 border font-semibold tracking-[-0.01em] transition duration-150 ease-out select-none active:translate-y-px disabled:cursor-not-allowed disabled:opacity-45",
          variants[variant],
          sizes[size],
          fullWidth && "w-full",
          className,
        )}
        disabled={isDisabled}
        type={type}
        {...props}
      >
        {loading ? (
          <span
            aria-hidden="true"
            className="size-4 rounded-full border-2 border-current border-r-transparent motion-safe:animate-[outly-spin_700ms_linear_infinite]"
          />
        ) : (
          leadingIcon
        )}
        <span>{children}</span>
        {!loading ? trailingIcon : null}
      </button>
    );
  },
);
