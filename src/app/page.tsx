import { AppShell } from "@/components/AppShell";
import { RallyLogo } from "@/components/RallyLogo";
import { ComponentPlayground } from "@/components/system/ComponentPlayground";
import { Card } from "@/components/ui/Card";
import { Icon } from "@/components/ui/Icon";
import { StatusBadge } from "@/components/ui/StatusBadge";

export default function Home() {
  return (
    <AppShell>
      <section
        className="border-border-subtle relative isolate overflow-hidden border-b pb-14 sm:pb-18"
        id="foundation"
      >
        <div
          aria-hidden="true"
          className="city-grid absolute -inset-x-20 -top-16 -z-10 h-[30rem] opacity-30"
        />
        <div className="rally-enter text-accent-primary flex items-center gap-2 text-xs font-semibold tracking-[0.16em] uppercase">
          <span className="bg-accent-primary h-px w-7" />
          Rally foundation
        </div>

        <div className="mt-7 grid items-end gap-8 md:grid-cols-[minmax(0,1fr)_17rem]">
          <div>
            <h1 className="text-text-primary max-w-4xl text-[clamp(3rem,8.5vw,7rem)] leading-[0.88] font-semibold tracking-[-0.075em] text-balance">
              Tonight,
              <br />
              made legible.
            </h1>
            <p className="text-text-secondary mt-7 max-w-xl text-[clamp(1rem,2vw,1.2rem)] leading-7">
              A premium, private interface for reading Toronto&apos;s social
              momentum—without turning people into pins.
            </p>
          </div>

          <Card className="relative overflow-hidden p-5" variant="elevated">
            <div
              className="absolute -top-6 -right-5 opacity-20"
              aria-hidden="true"
            >
              <RallyLogo decorative size="md" />
            </div>
            <StatusBadge dot tone="success">
              Phase 1 stable
            </StatusBadge>
            <div className="mt-12 flex items-end justify-between gap-4">
              <div>
                <p className="text-text-primary text-3xl font-semibold tracking-[-0.05em]">
                  44 px
                </p>
                <p className="text-text-muted mt-1 text-xs">
                  Minimum touch target
                </p>
              </div>
              <span className="bg-accent-muted text-accent-primary flex size-11 items-center justify-center rounded-full">
                <Icon className="size-5" name="check" />
              </span>
            </div>
          </Card>
        </div>
      </section>

      <section className="pt-12 sm:pt-16">
        <div className="mb-7 flex flex-col justify-between gap-3 sm:flex-row sm:items-end">
          <div>
            <p className="text-text-muted text-xs font-semibold tracking-[0.14em] uppercase">
              Primitives
            </p>
            <h2 className="text-text-primary mt-2 text-3xl font-semibold tracking-[-0.045em] sm:text-4xl">
              One visual grammar.
            </h2>
          </div>
          <p className="text-text-secondary max-w-md text-sm leading-6">
            Shared components keep RSVP, check-in, offers, and discovery
            consistent as the product loop grows.
          </p>
        </div>

        <ComponentPlayground />
      </section>
    </AppShell>
  );
}
