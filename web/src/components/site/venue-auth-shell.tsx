import Link from "next/link";
import { BrandMark } from "@/components/brand/mark";

export function VenueAuthShell({ children, title, copy }: { children: React.ReactNode; title: string; copy: string }) {
  return (
    <main className="grid min-h-screen bg-[#080b10] lg:grid-cols-[.82fr_1.18fr]">
      <aside className="relative hidden overflow-hidden border-r border-white/10 bg-[#0b0f14] p-10 lg:flex lg:flex-col">
        <div className="absolute inset-0 hairline-grid opacity-35" />
        <div className="relative"><Link href="/venues" aria-label="Outly for venues"><BrandMark /></Link></div>
        <div className="relative mt-auto max-w-lg">
          <p className="font-mono text-[11px] uppercase tracking-[0.2em] text-primary">Outly for venues</p>
          <p className="mt-5 text-5xl font-medium leading-[.98] tracking-[-0.05em]">From decision to verified visit.</p>
          <div className="mt-10 flex gap-2">
            {["Discovery", "Plan", "Check-in", "Offer"].map((step, index) => <span key={step} className="flex-1 border-t border-white/16 pt-3 text-[10px] text-white/34"><b className="mr-1 font-mono text-primary">0{index + 1}</b>{step}</span>)}
          </div>
        </div>
      </aside>

      <section className="flex min-h-screen items-center justify-center px-5 py-12 sm:px-8">
        <div className="w-full max-w-md">
          <Link href="/venues" className="mb-12 inline-flex lg:hidden" aria-label="Outly for venues"><BrandMark /></Link>
          <p className="font-mono text-[10px] uppercase tracking-[0.18em] text-primary">Venue access</p>
          <h1 className="mt-4 text-4xl font-medium tracking-[-0.04em]">{title}</h1>
          <p className="mt-3 text-sm leading-6 text-white/46">{copy}</p>
          <div className="mt-9">{children}</div>
        </div>
      </section>
    </main>
  );
}
