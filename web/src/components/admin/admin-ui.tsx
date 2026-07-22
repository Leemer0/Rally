import Link from "next/link";
import type { ReactNode } from "react";
import { AlertCircle, ArrowLeft, Info } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { buttonVariants } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { cn } from "@/lib/utils";

export function AdminPageHeader({
  title,
  description,
  action,
  backHref,
}: {
  title: string;
  description: string;
  action?: ReactNode;
  backHref?: string;
}) {
  return (
    <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
      <div>
        {backHref ? (
          <Link
            href={backHref}
            className="mb-3 inline-flex min-h-11 items-center gap-1.5 text-xs text-white/48 transition-colors hover:text-white"
          >
            <ArrowLeft className="size-3.5" />
            Back
          </Link>
        ) : null}
        <h1 className="text-2xl font-medium tracking-[-0.025em] sm:text-3xl">
          {title}
        </h1>
        <p className="mt-1.5 max-w-2xl text-sm leading-6 text-white/48">
          {description}
        </p>
      </div>
      {action ? <div className="shrink-0">{action}</div> : null}
    </div>
  );
}

export function ConfirmationNotice({ children }: { children: ReactNode }) {
  return (
    <div
      role="status"
      className="flex items-start gap-2.5 rounded-md border border-primary/20 bg-primary/[0.05] px-3.5 py-3 text-sm text-white/72"
    >
      <Info className="mt-0.5 size-4 shrink-0 text-primary" />
      <p>{children}</p>
    </div>
  );
}

export function ErrorNotice({ children }: { children: ReactNode }) {
  return (
    <div
      role="alert"
      className="flex items-start gap-2.5 rounded-md border border-destructive/24 bg-destructive/[0.06] px-3.5 py-3 text-sm text-red-100/78"
    >
      <AlertCircle className="mt-0.5 size-4 shrink-0 text-red-200/80" />
      <p>{children}</p>
    </div>
  );
}

export function StatusBadge({ status }: { status: string }) {
  const normalized = status.toLowerCase();
  const className =
    normalized === "approved" ||
    normalized === "active" ||
    normalized === "ready" ||
    normalized === "published" ||
    normalized === "complete"
      ? "border-primary/24 bg-primary/[0.045] text-primary"
      : normalized === "pending" ||
          normalized === "pending review" ||
          normalized === "changes requested" ||
          normalized === "onboarding" ||
          normalized === "awaiting venue"
        ? "border-amber-300/20 bg-amber-300/[0.04] text-amber-100/80"
        : normalized === "paused" ||
            normalized === "suspended" ||
            normalized === "rejected" ||
            normalized === "deletion pending" ||
            normalized === "deletion requested"
          ? "border-destructive/24 bg-destructive/[0.06] text-red-200/80"
          : "border-white/12 bg-white/[0.025] text-white/50";

  return (
    <Badge variant="outline" className={cn("rounded-sm", className)}>
      {status}
    </Badge>
  );
}

export function Field({
  id,
  label,
  hint,
  children,
}: {
  id: string;
  label: string;
  hint?: string;
  children: ReactNode;
}) {
  return (
    <div className="space-y-2">
      <Label htmlFor={id} className="text-xs text-white/72">
        {label}
      </Label>
      {children}
      {hint ? <p className="text-[11px] leading-4 text-white/34">{hint}</p> : null}
    </div>
  );
}

export function AdminSelect({
  id,
  name,
  defaultValue,
  children,
  required,
}: {
  id: string;
  name: string;
  defaultValue?: string;
  children: ReactNode;
  required?: boolean;
}) {
  return (
    <select
      id={id}
      name={name}
      defaultValue={defaultValue}
      required={required}
      className="h-11 w-full rounded-lg border border-input bg-[#11151c] px-3 text-sm text-white outline-none transition-colors focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/40"
    >
      {children}
    </select>
  );
}

export function FormActions({
  cancelHref,
  submitLabel,
}: {
  cancelHref: string;
  submitLabel: string;
}) {
  return (
    <div className="flex flex-col-reverse gap-3 border-t border-white/10 pt-5 sm:flex-row sm:justify-end">
      <Link
        href={cancelHref}
        className={cn(
          buttonVariants({ variant: "outline", size: "lg" }),
          "h-11 border-white/12 px-4",
        )}
      >
        Cancel
      </Link>
      <button
        type="submit"
        className={cn(buttonVariants({ size: "lg" }), "h-11 px-4")}
      >
        {submitLabel}
      </button>
    </div>
  );
}
