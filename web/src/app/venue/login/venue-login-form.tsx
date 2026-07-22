"use client";

import Link from "next/link";
import { useTransition, type FormEvent } from "react";
import { ArrowRight } from "lucide-react";
import { signInVenue } from "@/app/venue/actions";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

type VenueLoginFormProps = {
  founder: boolean;
  next: string | null;
};

export function VenueLoginForm({ founder, next }: VenueLoginFormProps) {
  const [isPending, startTransition] = useTransition();

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const formData = new FormData(event.currentTarget);

    startTransition(async () => {
      await signInVenue(formData);
    });
  }

  return (
    <>
      {/*
        This is deliberately an explicit POST form instead of a bare native
        form. Before hydration, a submit can only place fields in the request
        body; after hydration, the Server Action establishes the auth session.
      */}
      <form
        method="post"
        onSubmit={handleSubmit}
        className="space-y-5"
        aria-busy={isPending}
      >
        {next && <input type="hidden" name="next" value={next} />}
        <div className="space-y-2">
          <Label htmlFor="email">{founder ? "Email" : "Business email"}</Label>
          <Input
            id="email"
            name="email"
            type="email"
            autoComplete="email"
            placeholder={founder ? "you@getoutly.app" : "you@venue.com"}
            required
            disabled={isPending}
            className="h-12 bg-white/[0.035]"
          />
        </div>
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <Label htmlFor="password">Password</Label>
            <Link
              href="/venue/forgot-password"
              className="text-xs text-white/46 hover:text-white"
            >
              Forgot password?
            </Link>
          </div>
          <Input
            id="password"
            name="password"
            type="password"
            autoComplete="current-password"
            required
            disabled={isPending}
            className="h-12 bg-white/[0.035]"
          />
        </div>
        <Button
          type="submit"
          size="lg"
          className="h-12 w-full"
          disabled={isPending}
        >
          {isPending ? "Signing in…" : "Sign in"}
          {!isPending && <ArrowRight className="size-4" />}
        </Button>
      </form>
      {!founder && (
        <p className="mt-6 text-center text-sm text-white/42">
          New to Outly?{" "}
          <Link
            href="/venue/register"
            className="text-white underline underline-offset-4"
          >
            Get started
          </Link>
        </p>
      )}
    </>
  );
}
