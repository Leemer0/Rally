import type { Metadata } from "next";
import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { VenueAuthShell } from "@/components/site/venue-auth-shell";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export const metadata: Metadata = { title: "Venue sign in" };

export default function VenueLoginPage() {
  return (
    <VenueAuthShell title="Welcome back." copy="Sign in with the business email connected to your venue.">
      <form action="/dashboard" className="space-y-5">
        <div className="space-y-2">
          <Label htmlFor="email">Business email</Label>
          <Input id="email" name="email" type="email" autoComplete="email" placeholder="you@venue.com" required className="h-12 bg-white/[0.035]" />
        </div>
        <div className="space-y-2">
          <div className="flex items-center justify-between"><Label htmlFor="password">Password</Label><a href="mailto:support@getoutly.app?subject=Venue%20password%20reset" className="text-xs text-white/46 hover:text-white">Forgot password?</a></div>
          <Input id="password" name="password" type="password" autoComplete="current-password" required className="h-12 bg-white/[0.035]" />
        </div>
        <Button type="submit" size="lg" className="h-12 w-full">Sign in <ArrowRight className="size-4" /></Button>
      </form>
      <p className="mt-6 text-center text-sm text-white/42">New to Outly? <Link href="/venue/register" className="text-white underline underline-offset-4">Get started</Link></p>
      <p className="mt-8 border-t border-white/10 pt-5 text-center text-[11px] leading-5 text-white/26">Authentication will connect to Supabase in the backend phase. This form currently opens the demo dashboard.</p>
    </VenueAuthShell>
  );
}
