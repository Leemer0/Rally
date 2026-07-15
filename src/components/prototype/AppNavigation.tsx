import { Icon } from "@/components/ui/Icon";
import { cn } from "@/lib/cn";

export type AppTab = "explore" | "list" | "profile";

type AppNavigationProps = {
  active: AppTab;
  onChange: (tab: AppTab) => void;
};

const tabs = [
  { id: "explore", label: "Explore", icon: "compass" },
  { id: "list", label: "List", icon: "list" },
  { id: "profile", label: "Profile", icon: "profile" },
] as const;

export function AppNavigation({ active, onChange }: AppNavigationProps) {
  return (
    <nav
      aria-label="Primary navigation"
      className="border-border-subtle bg-background-secondary/96 grid h-[4.5rem] shrink-0 grid-cols-3 border-t px-3 pb-[max(0.4rem,env(safe-area-inset-bottom))] backdrop-blur-xl"
    >
      {tabs.map((tab) => {
        const isActive = tab.id === active;
        return (
          <button
            key={tab.id}
            aria-current={isActive ? "page" : undefined}
            className={cn(
              "relative flex min-h-11 flex-col items-center justify-center gap-0.5 text-[0.65rem] font-medium transition",
              isActive ? "text-accent-primary" : "text-text-muted",
            )}
            onClick={() => onChange(tab.id)}
            type="button"
          >
            {isActive ? (
              <span className="bg-accent-primary absolute top-0 h-0.5 w-7 rounded-full" />
            ) : null}
            <Icon className="size-[1.15rem]" name={tab.icon} />
            <span>{tab.label}</span>
          </button>
        );
      })}
    </nav>
  );
}
