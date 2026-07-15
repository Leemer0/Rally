import type { ReactNode } from "react";

import { Icon } from "@/components/ui/Icon";

export function ScreenHeader({
  title,
  onBack,
  action,
}: {
  title?: string;
  onBack?: () => void;
  action?: ReactNode;
}) {
  return (
    <header className="border-border-subtle bg-background-primary/94 flex h-14 shrink-0 items-center justify-between gap-3 border-b px-4 backdrop-blur-xl">
      <div className="flex min-w-11 items-center">
        {onBack ? (
          <button
            aria-label="Go back"
            className="text-text-secondary hover:bg-surface-primary hover:text-text-primary flex size-11 items-center justify-center rounded-full"
            onClick={onBack}
            type="button"
          >
            <Icon className="size-5" name="arrow-left" />
          </button>
        ) : null}
      </div>
      {title ? (
        <h1 className="text-text-primary truncate text-base font-semibold tracking-[-0.02em]">
          {title}
        </h1>
      ) : null}
      <div className="flex min-w-11 justify-end">{action}</div>
    </header>
  );
}

export function FlowFooter({ children }: { children: ReactNode }) {
  return (
    <footer className="border-border-subtle bg-background-primary/96 shrink-0 border-t px-5 pt-4 pb-[max(1rem,env(safe-area-inset-bottom))] backdrop-blur-xl">
      {children}
    </footer>
  );
}
