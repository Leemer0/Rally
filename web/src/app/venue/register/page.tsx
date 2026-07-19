import type { Metadata } from "next";
import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { VenueAuthShell } from "@/components/site/venue-auth-shell";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export const metadata: Metadata = { title: "Venue access" };

export default function VenueRegisterPage() {
  return (
    <VenueAuthShell title="Create your venue account." copy="Tell us about your venue. The Outly team reviews every listing before it goes live.">
      <form action="/dashboard" className="space-y-5">
        <div className="grid gap-5 sm:grid-cols-2">
          <Field id="venue-name" label="Venue name" placeholder="Your venue" />
          <Field id="legal-name" label="Legal business name" placeholder="Business Inc." />
        </div>
        <Field id="address" label="Venue address" placeholder="Street address, city" autoComplete="street-address" />
        <div className="grid gap-5 sm:grid-cols-2">
          <Field id="contact-name" label="Contact name" placeholder="First and last name" autoComplete="name" />
          <Field id="phone" label="Business phone" placeholder="(416) 555-0123" type="tel" autoComplete="tel" />
        </div>
        <Field id="email" label="Business email" placeholder="you@venue.com" type="email" autoComplete="email" />
        <Field id="password" label="Password" placeholder="At least 10 characters" type="password" autoComplete="new-password" minLength={10} />
        <label className="flex gap-3 text-xs leading-5 text-white/46">
          <input type="checkbox" required className="mt-1 size-4 accent-[#c7ff3d]" />
          <span>I confirm I’m authorized to manage this venue and agree to the venue terms and privacy policy.</span>
        </label>
        <Button type="submit" size="lg" className="h-12 w-full">Submit for review <ArrowRight className="size-4" /></Button>
      </form>
      <p className="mt-6 text-center text-sm text-white/42">Already registered? <Link href="/venue/login" className="text-white underline underline-offset-4">Sign in</Link></p>
      <p className="mt-8 border-t border-white/10 pt-5 text-center text-[11px] leading-5 text-white/26">Demo only: submission currently opens the sample dashboard. Supabase account creation and founder approval will be connected next.</p>
    </VenueAuthShell>
  );
}

function Field({ id, label, placeholder, type = "text", autoComplete, minLength }: { id: string; label: string; placeholder: string; type?: string; autoComplete?: string; minLength?: number }) {
  return <div className="space-y-2"><Label htmlFor={id}>{label}</Label><Input id={id} name={id} type={type} placeholder={placeholder} autoComplete={autoComplete} minLength={minLength} required className="h-12 bg-white/[0.035]" /></div>;
}
