import type { ReactNode } from "react";

import { cn } from "@/lib/cn";

type PrototypeFrameProps = {
  children: ReactNode;
  className?: string;
};

export function PrototypeFrame({ children, className }: PrototypeFrameProps) {
  return (
    <div className="bg-background-primary min-h-svh md:grid md:place-items-center md:p-6">
      <div
        aria-hidden="true"
        className="city-grid fixed inset-0 hidden opacity-15 md:block"
      />
      <div className="fixed top-8 left-8 z-10 hidden max-w-56 md:block">
        <p className="text-accent-primary text-xs font-semibold tracking-[0.16em] uppercase">
          Interactive prototype
        </p>
        <p className="text-text-secondary mt-2 text-sm leading-6">
          Click through the complete night-out journey in the phone.
        </p>
        <a
          className="text-text-muted hover:text-text-primary mt-4 inline-block text-xs underline underline-offset-4"
          href="/system"
        >
          View design system
        </a>
      </div>

      <div
        className={cn(
          "bg-background-primary md:border-border-strong md:shadow-elevated relative z-10 flex min-h-svh w-full flex-col overflow-hidden md:h-[min(860px,calc(100svh-3rem))] md:min-h-0 md:max-w-[430px] md:rounded-[2.5rem] md:border",
          className,
        )}
      >
        <PhoneStatusBar />
        {children}
      </div>
    </div>
  );
}

function PhoneStatusBar() {
  return (
    <div className="text-text-primary z-50 flex h-9 shrink-0 items-end justify-between px-6 pb-1 text-[0.6875rem] font-semibold">
      <span>9:41</span>
      <div className="flex items-center gap-1.5" aria-hidden="true">
        <span className="flex h-3 items-end gap-px">
          <i className="bg-text-primary h-1 w-0.5 rounded-full" />
          <i className="bg-text-primary h-1.5 w-0.5 rounded-full" />
          <i className="bg-text-primary h-2 w-0.5 rounded-full" />
          <i className="bg-text-primary h-2.5 w-0.5 rounded-full" />
        </span>
        <span className="border-text-primary size-2.5 rounded-full border" />
        <span className="border-text-primary/80 relative h-2.5 w-5 rounded-[0.2rem] border">
          <span className="bg-text-primary absolute inset-0.5 right-1 rounded-[0.1rem]" />
        </span>
      </div>
    </div>
  );
}
