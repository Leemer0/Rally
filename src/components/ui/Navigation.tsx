import Link from "next/link";

import { Icon, type IconName } from "@/components/ui/Icon";
import { cn } from "@/lib/cn";

export type NavigationItem = {
  label: string;
  href: string;
  icon: IconName;
};

type NavigationProps = {
  items: NavigationItem[];
  activeHref: string;
  variant?: "bottom" | "rail";
  className?: string;
};

export function Navigation({
  activeHref,
  className,
  items,
  variant = "bottom",
}: NavigationProps) {
  return (
    <nav
      aria-label="Primary navigation"
      className={cn(
        variant === "bottom"
          ? "border-border-subtle bg-background-secondary/95 grid grid-cols-3 border-t px-3 pt-2 pb-[max(0.6rem,env(safe-area-inset-bottom))] backdrop-blur-xl"
          : "grid gap-2",
        className,
      )}
    >
      {items.map((item) => {
        const isActive = item.href === activeHref;

        return (
          <Link
            key={item.label}
            aria-current={isActive ? "page" : undefined}
            className={cn(
              "group rounded-control relative flex min-h-12 items-center justify-center gap-2 text-xs font-medium transition duration-150",
              variant === "bottom"
                ? "flex-col gap-1"
                : "justify-start px-3 text-sm",
              isActive
                ? "text-accent-primary"
                : "text-text-muted hover:bg-surface-primary hover:text-text-primary",
            )}
            href={item.href}
          >
            {isActive && variant === "bottom" ? (
              <span
                aria-hidden="true"
                className="bg-accent-primary absolute -top-2 h-0.5 w-7 rounded-full"
              />
            ) : null}
            <Icon className="size-5" name={item.icon} />
            <span>{item.label}</span>
          </Link>
        );
      })}
    </nav>
  );
}
