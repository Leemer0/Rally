import Link from "next/link";
import { RefreshCw } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";

export function DashboardUnavailable({
  configuration = false,
  title = "We couldn’t load this venue data.",
}: {
  configuration?: boolean;
  title?: string;
}) {
  return (
    <div className="mx-auto max-w-2xl py-16">
      <Badge
        variant="outline"
        className="rounded-sm border-white/12 text-white/48"
      >
        Dashboard unavailable
      </Badge>
      <h1 className="mt-5 text-3xl font-medium tracking-[-0.035em]">
        {title}
      </h1>
      <p className="mt-3 max-w-xl text-sm leading-6 text-white/46">
        {configuration
          ? "The secure server connection has not been configured for this environment."
          : "The venue service did not return a snapshot. No sample data is being shown in its place."}
      </p>
      <Link
        href="/dashboard"
        className={cn(
          buttonVariants({ variant: "outline" }),
          "mt-7 border-white/12",
        )}
      >
        <RefreshCw className="size-4" />
        Try again
      </Link>
    </div>
  );
}
