"use client";

import { AlertCircle } from "lucide-react";
import { Button } from "@/components/ui/button";

export default function AdminError({ reset }: { reset: () => void }) {
  return (
    <div className="mx-auto max-w-xl rounded-lg border border-destructive/24 bg-card p-6 sm:p-8">
      <AlertCircle className="size-5 text-red-200/80" />
      <h1 className="mt-5 text-xl font-medium">Live operations data is unavailable</h1>
      <p className="mt-2 text-sm leading-6 text-white/46">
        The founder dashboard failed closed, so no demo or cached operational records
        are being shown. Check the Supabase function deployment and try again.
      </p>
      <Button type="button" onClick={reset} className="mt-6 h-11">
        Try again
      </Button>
    </div>
  );
}
