import type { HTMLAttributes, ReactNode } from "react";

import { cn } from "@/lib/cn";

type SheetProps = HTMLAttributes<HTMLElement> & {
  title: string;
  description?: string;
  children: ReactNode;
  footer?: ReactNode;
  showHandle?: boolean;
};

export function Sheet({
  children,
  className,
  description,
  footer,
  showHandle = true,
  title,
  ...props
}: SheetProps) {
  return (
    <section
      aria-label={title}
      className={cn(
        "rounded-sheet border-border-subtle bg-surface-secondary shadow-elevated overflow-hidden border",
        className,
      )}
      {...props}
    >
      {showHandle ? (
        <div
          aria-hidden="true"
          className="flex h-6 items-center justify-center"
        >
          <span className="bg-text-muted/50 h-1 w-9 rounded-full" />
        </div>
      ) : null}
      <div className={cn("px-5", showHandle ? "pt-2" : "pt-5")}>
        <h2 className="text-text-primary text-xl leading-tight font-semibold tracking-[-0.03em]">
          {title}
        </h2>
        {description ? (
          <p className="text-text-secondary mt-1 text-sm leading-5">
            {description}
          </p>
        ) : null}
      </div>
      <div className="px-5 py-5">{children}</div>
      {footer ? (
        <footer className="border-border-subtle bg-surface-primary/55 border-t px-5 py-4">
          {footer}
        </footer>
      ) : null}
    </section>
  );
}
