import type { Metadata } from "next";
import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { BrandMark } from "@/components/brand/mark";

export const metadata: Metadata = {
  title: "Privacy policy",
  robots: { index: false, follow: true },
};

export default function PrivacyPage() {
  return (
    <main className="min-h-screen bg-background px-5 py-10 sm:px-8">
      <div className="mx-auto max-w-3xl">
        <div className="flex items-center justify-between"><Link href="/" aria-label="Outly home"><BrandMark/></Link><Link href="/" className="flex min-h-11 items-center gap-2 text-sm text-white/44 hover:text-white"><ArrowLeft className="size-4"/>Back</Link></div>
        <article className="mt-16 border-t border-white/12 pt-10">
          <p className="font-mono text-[10px] uppercase tracking-[.17em] text-primary">Draft</p>
          <h1 className="mt-4 text-4xl font-medium tracking-[-0.04em] sm:text-6xl">Privacy policy</h1>
          <p className="mt-6 text-sm leading-7 text-white/48">This page is a frontend placeholder and is not a finalized legal policy. Before launch, counsel should review Outly’s handling of date of birth, required gender data, precise location used for check-in, account deletion, venue analytics, and retention periods.</p>
          <div className="mt-10 space-y-8 border-t border-white/10 pt-8 text-sm leading-7 text-white/52">
            <section><h2 className="text-lg font-medium text-white">MVP principles</h2><p className="mt-2">Outly requests precise location when a user initiates a venue check-in. Venues receive aggregated attendance information, not an individual user’s live location or identity.</p></section>
            <section><h2 className="text-lg font-medium text-white">Account deletion</h2><p className="mt-2">Consumer and venue accounts will include a deletion flow once Supabase authentication is connected.</p></section>
            <section><h2 className="text-lg font-medium text-white">Contact</h2><p className="mt-2">Questions can be sent to <a href="mailto:privacy@getoutly.app" className="text-white underline underline-offset-4">privacy@getoutly.app</a>.</p></section>
          </div>
        </article>
      </div>
    </main>
  );
}
