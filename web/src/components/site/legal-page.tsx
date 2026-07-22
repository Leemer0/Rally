import type { ReactNode } from "react";
import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { BrandMark } from "@/components/brand/mark";

type LegalPageProps = {
  title: string;
  summary: string;
  updated: string;
  children: ReactNode;
};

export function LegalPage({ title, summary, updated, children }: LegalPageProps) {
  return (
    <main className="min-h-screen bg-background">
      <header className="border-b border-white/10">
        <div className="mx-auto flex min-h-20 max-w-6xl items-center justify-between px-5 sm:px-8">
          <Link href="/" aria-label="Outly home">
            <BrandMark />
          </Link>
          <nav
            aria-label="Legal pages"
            className="flex items-center gap-5 text-sm text-white/55 sm:gap-7"
          >
            <Link href="/privacy" className="transition-colors hover:text-white">
              Privacy
            </Link>
            <Link href="/terms" className="transition-colors hover:text-white">
              Terms
            </Link>
          </nav>
        </div>
      </header>

      <div className="mx-auto max-w-6xl px-5 pb-24 pt-10 sm:px-8 sm:pt-16">
        <Link
          href="/"
          className="inline-flex min-h-11 items-center gap-2 text-sm text-white/50 transition-colors hover:text-white"
        >
          <ArrowLeft className="size-4" aria-hidden="true" />
          Back to Outly
        </Link>

        <article className="mt-10 max-w-3xl sm:mt-14">
          <header>
            <p className="font-mono text-[11px] font-medium uppercase tracking-[0.18em] text-primary">
              Legal
            </p>
            <h1 className="mt-4 text-4xl font-medium tracking-[-0.045em] text-white sm:text-6xl">
              {title}
            </h1>
            <p className="mt-6 max-w-2xl text-base leading-7 text-white/62 sm:text-lg sm:leading-8">
              {summary}
            </p>
            <p className="mt-5 font-mono text-[11px] uppercase tracking-[0.12em] text-white/36">
              Effective {updated}
            </p>
          </header>

          <div className="mt-12 space-y-12 border-t border-white/10 pt-10 text-[15px] leading-7 text-white/62 sm:mt-16 sm:pt-12">
            {children}
          </div>
        </article>
      </div>
    </main>
  );
}

export function LegalSection({
  title,
  children,
}: {
  title: string;
  children: ReactNode;
}) {
  return (
    <section className="scroll-mt-8">
      <h2 className="text-xl font-medium tracking-[-0.02em] text-white sm:text-2xl">
        {title}
      </h2>
      <div className="mt-4 space-y-4 [&_a]:text-white [&_a]:underline [&_a]:decoration-white/30 [&_a]:underline-offset-4 [&_a]:transition-colors hover:[&_a]:decoration-white/80 [&_li]:pl-1 [&_strong]:font-medium [&_strong]:text-white/88 [&_ul]:ml-5 [&_ul]:list-disc [&_ul]:space-y-2">
        {children}
      </div>
    </section>
  );
}
