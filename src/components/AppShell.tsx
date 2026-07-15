import type { ReactNode } from "react";

import { RallyLogo } from "@/components/RallyLogo";
import { Navigation, type NavigationItem } from "@/components/ui/Navigation";
import { StatusBadge } from "@/components/ui/StatusBadge";

const systemNavigation: NavigationItem[] = [
  { label: "Foundation", href: "#foundation", icon: "compass" },
  { label: "Components", href: "#components", icon: "list" },
  { label: "Brand", href: "#brand", icon: "profile" },
];

type AppShellProps = {
  children: ReactNode;
};

export function AppShell({ children }: AppShellProps) {
  return (
    <div className="bg-background-primary text-text-primary min-h-svh">
      <a className="skip-link" href="#main-content">
        Skip to main content
      </a>

      <aside className="border-border-subtle bg-background-secondary fixed inset-y-0 left-0 z-30 hidden w-64 flex-col border-r px-5 py-6 lg:flex">
        <div className="border-border-subtle flex items-center justify-between border-b pb-5">
          <RallyLogo size="sm" />
          <StatusBadge tone="accent">System 01</StatusBadge>
        </div>

        <div className="mt-10">
          <p className="text-text-muted mb-3 px-3 text-[0.6875rem] font-semibold tracking-[0.16em] uppercase">
            Foundation
          </p>
          <Navigation
            activeHref="#foundation"
            items={systemNavigation}
            variant="rail"
          />
        </div>

        <div className="border-border-subtle mt-auto border-t pt-5">
          <p className="text-text-muted text-xs leading-5">
            Mobile-first primitives for nights in motion.
          </p>
        </div>
      </aside>

      <div className="lg:pl-64">
        <header className="border-border-subtle bg-background-primary/88 sticky top-0 z-20 border-b px-4 pt-[max(0.75rem,env(safe-area-inset-top))] pb-3 backdrop-blur-xl sm:px-6 lg:px-10">
          <div className="mx-auto flex max-w-6xl items-center justify-between gap-4">
            <div className="lg:hidden">
              <RallyLogo size="sm" />
            </div>
            <div className="hidden lg:block">
              <p className="text-text-secondary text-sm">Toronto · 10:42 PM</p>
            </div>
            <StatusBadge dot tone="success">
              Theme online
            </StatusBadge>
          </div>
        </header>

        <main
          className="mx-auto w-full max-w-6xl px-4 pt-8 pb-28 sm:px-6 sm:pt-12 lg:px-10 lg:pb-16"
          id="main-content"
        >
          {children}
        </main>
      </div>

      <Navigation
        activeHref="#foundation"
        className="fixed inset-x-0 bottom-0 z-40 lg:hidden"
        items={systemNavigation}
      />
    </div>
  );
}
