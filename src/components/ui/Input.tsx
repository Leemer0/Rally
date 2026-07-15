"use client";

import {
  forwardRef,
  useId,
  type InputHTMLAttributes,
  type ReactNode,
} from "react";

import { cn } from "@/lib/cn";

export type InputProps = Omit<InputHTMLAttributes<HTMLInputElement>, "size"> & {
  label: string;
  hint?: string;
  error?: string;
  leadingIcon?: ReactNode;
  trailingElement?: ReactNode;
};

export const Input = forwardRef<HTMLInputElement, InputProps>(function Input(
  { className, error, hint, id, label, leadingIcon, trailingElement, ...props },
  ref,
) {
  const generatedId = useId();
  const inputId = id ?? generatedId;
  const descriptionId = `${inputId}-description`;

  return (
    <div className="grid gap-2">
      <label
        className="text-text-primary text-sm font-medium"
        htmlFor={inputId}
      >
        {label}
      </label>
      <div className="relative">
        {leadingIcon ? (
          <span
            aria-hidden="true"
            className="text-text-muted pointer-events-none absolute top-1/2 left-4 flex -translate-y-1/2"
          >
            {leadingIcon}
          </span>
        ) : null}
        <input
          ref={ref}
          aria-describedby={hint || error ? descriptionId : undefined}
          aria-invalid={error ? true : undefined}
          className={cn(
            "rounded-control border-border-subtle bg-surface-sunken text-text-primary placeholder:text-text-muted hover:border-border-strong focus:border-accent-primary focus:ring-accent-muted min-h-12 w-full border px-4 text-base transition duration-150 outline-none focus:ring-3 disabled:cursor-not-allowed disabled:opacity-50",
            leadingIcon && "pl-11",
            trailingElement && "pr-12",
            error && "border-error focus:border-error focus:ring-error-muted",
            className,
          )}
          id={inputId}
          {...props}
        />
        {trailingElement ? (
          <span className="absolute top-1/2 right-3 flex -translate-y-1/2">
            {trailingElement}
          </span>
        ) : null}
      </div>
      {error ? (
        <p
          className="text-error text-sm leading-5"
          id={descriptionId}
          role="alert"
        >
          {error}
        </p>
      ) : hint ? (
        <p className="text-text-muted text-sm leading-5" id={descriptionId}>
          {hint}
        </p>
      ) : null}
    </div>
  );
});
