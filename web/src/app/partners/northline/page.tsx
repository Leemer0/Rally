import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { redirect } from "next/navigation";

export const metadata: Metadata = {
  title: "Northline offer",
  robots: { index: false, follow: false },
};

export default function NorthlinePartnerHandoff() {
  const destination = process.env.NORTHLINE_SIGNUP_URL;

  if (destination) {
    redirect(destination);
  }

  return (
    <main className="relative grid min-h-screen place-items-center overflow-hidden bg-[#030509] px-5 py-12 text-white">
      <div className="pointer-events-none absolute inset-x-0 top-0 h-80 bg-[radial-gradient(circle_at_50%_0%,rgba(127,168,245,0.16),transparent_68%)]" />
      <section className="relative w-full max-w-md text-center">
        <p className="font-mono text-[10px] uppercase tracking-[0.24em] text-white/46">Outly partner</p>
        <p className="mt-5 text-2xl font-semibold tracking-[0.18em] text-[#9ab9f8]">NORTHLINE</p>
        <div className="mx-auto mt-6 h-px w-40 bg-white/12" />

        <p className="mt-12 font-mono text-[10px] uppercase tracking-[0.2em] text-[#9ab9f8]">Offer applied</p>
        <h1 className="mt-4 text-4xl font-semibold tracking-[-0.04em] sm:text-5xl">50% off your ride home</h1>
        <p className="mx-auto mt-5 max-w-sm text-sm leading-6 text-white/52">
          Create a new Northline account to claim the Outly rider offer.
        </p>

        <div className="mt-12 border-y border-white/10 py-8">
          <Image
            src="/brand/winged-o.png"
            width={116}
            height={58}
            alt="Outly"
            className="mx-auto h-auto w-[92px]"
          />
          <p className="mt-4 text-xs text-white/34">Northline is a fictional partner destination for the Outly MVP.</p>
        </div>

        <Link
          href="/"
          className="mt-8 inline-flex min-h-11 items-center justify-center text-sm text-white/54 transition-colors hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#9ab9f8]"
        >
          Return to Outly
        </Link>
      </section>
    </main>
  );
}
