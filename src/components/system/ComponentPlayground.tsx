"use client";

import { useState } from "react";

import { Button } from "@/components/ui/Button";
import {
  Card,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/Card";
import { Chip } from "@/components/ui/Chip";
import { Icon } from "@/components/ui/Icon";
import { Input } from "@/components/ui/Input";
import { ProgressBar } from "@/components/ui/ProgressBar";
import { Sheet } from "@/components/ui/Sheet";
import { StatusBadge } from "@/components/ui/StatusBadge";

const vibes = ["Easygoing", "Dance floor", "Good conversation"] as const;

export function ComponentPlayground() {
  const [name, setName] = useState("");
  const [vibe, setVibe] = useState<(typeof vibes)[number]>("Good conversation");
  const [groupSize, setGroupSize] = useState(3);
  const [notice, setNotice] = useState("Plan preview ready");

  return (
    <div
      className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_23rem]"
      id="components"
    >
      <div className="grid content-start gap-6">
        <Card className="p-5 sm:p-6" variant="elevated">
          <CardHeader>
            <div>
              <CardTitle>Controls with a clear pulse</CardTitle>
              <CardDescription className="mt-1">
                Touch-ready, keyboard-visible, and restrained in motion.
              </CardDescription>
            </div>
            <StatusBadge dot tone="accent">
              Interactive
            </StatusBadge>
          </CardHeader>

          <div className="mt-6 grid gap-5">
            <Input
              hint="Only you can see this."
              label="What should we call you?"
              onChange={(event) => setName(event.target.value)}
              placeholder="Enter your name"
              value={name}
            />

            <fieldset>
              <legend className="text-text-primary mb-2 text-sm font-medium">
                Pick tonight&apos;s energy
              </legend>
              <div className="flex flex-wrap gap-2">
                {vibes.map((item) => (
                  <Chip
                    key={item}
                    onClick={() => setVibe(item)}
                    selected={vibe === item}
                  >
                    {item}
                  </Chip>
                ))}
              </div>
            </fieldset>

            <div className="border-border-subtle grid gap-3 border-t pt-5 sm:grid-cols-2">
              <Button
                fullWidth
                onClick={() =>
                  setNotice(`${name || "Your"} plan is ready to review`)
                }
                trailingIcon={<Icon className="size-4" name="arrow-right" />}
              >
                Preview plan
              </Button>
              <Button
                fullWidth
                onClick={() => setNotice("Draft saved for tonight")}
                variant="secondary"
              >
                Save draft
              </Button>
            </div>
            <p aria-live="polite" className="text-text-secondary text-sm">
              {notice}
            </p>
          </div>
        </Card>

        <Card className="p-5 sm:p-6" variant="outlined">
          <CardHeader>
            <div>
              <CardTitle>Status language</CardTitle>
              <CardDescription className="mt-1">
                Meaning comes from copy and shape, not colour alone.
              </CardDescription>
            </div>
          </CardHeader>
          <div className="mt-6 flex flex-wrap gap-2">
            <StatusBadge dot>Low activity</StatusBadge>
            <StatusBadge dot tone="accent">
              Strong fit
            </StatusBadge>
            <StatusBadge dot tone="success">
              Verified here
            </StatusBadge>
            <StatusBadge tone="warning">Peak soon</StatusBadge>
            <StatusBadge tone="error">Check-in failed</StatusBadge>
          </div>
          <ProgressBar
            className="mt-7"
            label="Onboarding progress"
            showValue
            value={62}
          />
        </Card>

        <Card className="overflow-hidden" id="brand">
          <div className="grid sm:grid-cols-5">
            <div className="bg-surface-sunken relative min-h-48 overflow-hidden sm:col-span-2">
              <div
                aria-hidden="true"
                className="city-grid absolute inset-0 opacity-50"
              />
              <div className="absolute inset-x-6 bottom-6">
                <StatusBadge tone="accent">Night palette</StatusBadge>
                <p className="text-text-secondary mt-3 text-sm leading-6">
                  Inked navy surfaces leave the activity signal room to speak.
                </p>
              </div>
            </div>
            <div className="grid gap-3 p-5 sm:col-span-3 sm:p-6">
              <ColorToken
                colorClass="bg-background-primary"
                label="Night"
                token="#080B10"
              />
              <ColorToken
                colorClass="bg-surface-primary"
                label="Graphite"
                token="#151B23"
              />
              <ColorToken
                colorClass="bg-accent-primary"
                label="Signal"
                token="#C8FF2E"
              />
              <ColorToken
                colorClass="bg-success"
                label="Verified"
                token="#63E681"
              />
            </div>
          </div>
        </Card>
      </div>

      <div className="xl:sticky xl:top-28 xl:self-start">
        <p className="text-text-muted mb-3 text-[0.6875rem] font-semibold tracking-[0.16em] uppercase">
          Mobile sheet specimen
        </p>
        <Sheet
          description="Entertainment District · Lounge"
          footer={
            <Button
              fullWidth
              onClick={() => setNotice(`Plan set for ${groupSize} people`)}
              trailingIcon={<Icon className="size-4" name="arrow-right" />}
            >
              I&apos;m going
            </Button>
          }
          title="Lavelle"
        >
          <div className="flex items-center justify-between gap-4">
            <div className="flex items-center gap-2">
              <StatusBadge tone="accent">Strong fit</StatusBadge>
              <span className="text-text-secondary text-sm">Surging</span>
            </div>
            <span className="text-text-primary text-sm font-medium">
              Peak 10:30 PM
            </span>
          </div>

          <dl className="border-border-subtle mt-5 grid grid-cols-2 gap-3 border-y py-4">
            <Metric label="Going" value="42" />
            <Metric label="Verified" value="18" />
          </dl>

          <Card className="mt-5 flex items-center gap-3 p-3.5" variant="accent">
            <span className="rounded-control bg-accent-muted text-accent-primary flex size-10 shrink-0 items-center justify-center">
              <Icon className="size-5" name="ticket" />
            </span>
            <div>
              <p className="text-text-primary text-sm font-semibold">
                Free cover before 11 PM
              </p>
              <p className="text-text-secondary mt-0.5 text-xs">
                Show your unlocked offer to the host.
              </p>
            </div>
          </Card>

          <div className="mt-5 flex items-center justify-between gap-4">
            <span className="text-text-secondary text-sm">Group size</span>
            <div className="rounded-control border-border-subtle bg-surface-primary flex items-center gap-1 border p-1">
              <button
                aria-label="Decrease group size"
                className="text-text-secondary hover:bg-surface-elevated hover:text-text-primary flex size-10 items-center justify-center rounded-[0.65rem] text-lg transition disabled:opacity-40"
                disabled={groupSize <= 1}
                onClick={() =>
                  setGroupSize((current) => Math.max(1, current - 1))
                }
                type="button"
              >
                −
              </button>
              <output
                aria-live="polite"
                className="text-text-primary w-8 text-center font-semibold"
              >
                {groupSize}
              </output>
              <button
                aria-label="Increase group size"
                className="text-text-secondary hover:bg-surface-elevated hover:text-text-primary flex size-10 items-center justify-center rounded-[0.65rem] text-lg transition disabled:opacity-40"
                disabled={groupSize >= 8}
                onClick={() =>
                  setGroupSize((current) => Math.min(8, current + 1))
                }
                type="button"
              >
                +
              </button>
            </div>
          </div>
        </Sheet>
      </div>
    </div>
  );
}

function Metric({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <dt className="text-text-muted text-xs">{label}</dt>
      <dd className="text-text-primary mt-1 text-2xl font-semibold tracking-[-0.04em]">
        {value}
      </dd>
    </div>
  );
}

function ColorToken({
  colorClass,
  label,
  token,
}: {
  colorClass: string;
  label: string;
  token: string;
}) {
  return (
    <div className="rounded-control border-border-subtle bg-surface-primary flex items-center gap-3 border p-3">
      <span
        aria-hidden="true"
        className={`border-border-strong size-9 rounded-[0.65rem] border ${colorClass}`}
      />
      <div className="min-w-0 flex-1">
        <p className="text-text-primary text-sm font-medium">{label}</p>
        <p className="text-text-muted mt-0.5 text-xs">{token}</p>
      </div>
    </div>
  );
}
