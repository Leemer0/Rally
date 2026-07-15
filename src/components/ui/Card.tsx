import type { HTMLAttributes, ReactNode } from "react";

import { cn } from "@/lib/cn";

type CardVariant = "default" | "elevated" | "outlined" | "accent";

type CardProps = HTMLAttributes<HTMLElement> & {
  as?: "article" | "div" | "section";
  variant?: CardVariant;
};

const variants: Record<CardVariant, string> = {
  default: "border-border-subtle bg-surface-primary",
  elevated: "border-border-subtle bg-surface-secondary shadow-card",
  outlined: "border-border-strong bg-transparent",
  accent: "border-accent-primary/25 bg-accent-muted",
};

export function Card({
  as: Component = "article",
  className,
  variant = "default",
  ...props
}: CardProps) {
  return (
    <Component
      className={cn("rounded-card border", variants[variant], className)}
      {...props}
    />
  );
}

export function CardHeader({
  className,
  ...props
}: HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn("flex items-start justify-between gap-4", className)}
      {...props}
    />
  );
}

export function CardTitle({
  className,
  ...props
}: HTMLAttributes<HTMLHeadingElement>) {
  return (
    <h3
      className={cn(
        "text-text-primary text-lg leading-tight font-semibold tracking-[-0.025em]",
        className,
      )}
      {...props}
    />
  );
}

export function CardDescription({
  className,
  ...props
}: HTMLAttributes<HTMLParagraphElement>) {
  return (
    <p
      className={cn("text-text-secondary text-sm leading-6", className)}
      {...props}
    />
  );
}

export function CardContent({
  children,
  className,
}: {
  children: ReactNode;
  className?: string;
}) {
  return <div className={className}>{children}</div>;
}
