import Link from "next/link";
import { BrandMark } from "@/components/brand/mark";

export function SiteFooter({ audience = "consumer" }: { audience?: "consumer" | "venue" }) {
  return (
    <footer className="border-t border-white/10 bg-[#07090d]">
      <div className="mx-auto grid max-w-[90rem] gap-10 px-5 py-12 sm:px-8 md:grid-cols-[1fr_auto] lg:px-12">
        <div>
          <BrandMark />
          <p className="mt-4 max-w-sm text-sm leading-6 text-white/58">
            {audience === "venue"
              ? "Reach people deciding where to go, run offers on your schedule, and measure verified visits."
              : "See where people are heading tonight. Pick a bar. Meet in real life."}
          </p>
        </div>
        <nav className="grid grid-cols-2 gap-x-10 gap-y-3 text-sm text-white/60 sm:grid-cols-3" aria-label="Footer">
          <Link href="/venues" className="hover:text-white">For venues</Link>
          <Link href="/venue/login" className="hover:text-white">Venue sign in</Link>
          <a href="mailto:hello@getoutly.app" className="hover:text-white">Contact</a>
          <Link href="/privacy" className="hover:text-white">Privacy</Link>
          <Link href="/terms" className="hover:text-white">Terms</Link>
        </nav>
        <div className="border-t border-white/8 pt-5 text-xs text-white/35 md:col-span-2 md:flex md:items-center md:justify-between">
          <p>© {new Date().getFullYear()} Outly Labs Inc. Toronto, Canada.</p>
          <p className="mt-2 md:mt-0">Built in Toronto for nights that happen offline.</p>
        </div>
      </div>
    </footer>
  );
}
