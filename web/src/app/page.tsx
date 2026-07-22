import type { Metadata } from "next";
import Image from "next/image";
import { ArrowRight } from "lucide-react";
import { DevicePreview } from "@/components/site/device-preview";
import { SiteFooter } from "@/components/site/site-footer";
import { SiteHeader } from "@/components/site/site-header";
import { buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";

export const metadata: Metadata = {
  title: { absolute: "Outly — Toronto Nightlife App" },
  description:
    "Outly is a free Toronto nightlife app for people tired of dating apps. See where people are going, choose a bar, and meet in real life.",
  alternates: { canonical: "/" },
};

const decisions = [
  {
    title: "See tonight",
    copy: "Open the map to see where people are heading across Toronto right now.",
  },
  {
    title: "Choose one bar",
    copy: "Make a plan around a place—not another match, poll, or endless chat.",
  },
  {
    title: "Arrive and check in",
    copy: "Confirm you’re at the venue and unlock the night’s offer.",
  },
];

const questions = [
  {
    question: "What is the Outly app?",
    answer:
      "Outly is a Toronto nightlife app for people who would rather meet in person than keep swiping. It shows participating bars, where people are planning to go, and offers that unlock after a verified check-in.",
  },
  {
    question: "Is Outly a dating app?",
    answer:
      "No. Outly has no dating profiles, matches, direct messages, or swiping. You choose a venue and meet people there in real life.",
  },
  {
    question: "Is Outly free?",
    answer:
      "Yes. The Outly iPhone app will be free to download and use. Participating venues may also provide exclusive offers when you check in.",
  },
  {
    question: "Where is Outly available?",
    answer:
      "Outly is launching first in Toronto, beginning with neighbourhoods including King West, Ossington, College, and Chinatown.",
  },
];

const structuredData = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      "@id": "https://www.getoutly.app/#organization",
      name: "Outly",
      legalName: "Outly Labs Inc.",
      url: "https://www.getoutly.app/",
      logo: {
        "@type": "ImageObject",
        url: "https://www.getoutly.app/brand/outly-mark.png",
        width: 512,
        height: 512,
      },
      email: "hello@getoutly.app",
      address: {
        "@type": "PostalAddress",
        addressLocality: "Toronto",
        addressRegion: "ON",
        addressCountry: "CA",
      },
    },
    {
      "@type": "WebSite",
      "@id": "https://www.getoutly.app/#website",
      name: "Outly",
      alternateName: "Outly App",
      url: "https://www.getoutly.app/",
      inLanguage: "en-CA",
      publisher: { "@id": "https://www.getoutly.app/#organization" },
    },
    {
      "@type": "MobileApplication",
      "@id": "https://www.getoutly.app/#app",
      name: "Outly",
      url: "https://www.getoutly.app/",
      operatingSystem: "iOS",
      applicationCategory: "LifestyleApplication",
      description:
        "A free Toronto nightlife app that helps people see where others are going, choose a bar, and meet in real life.",
      areaServed: {
        "@type": "City",
        name: "Toronto",
      },
      offers: {
        "@type": "Offer",
        price: "0",
        priceCurrency: "CAD",
      },
      publisher: { "@id": "https://www.getoutly.app/#organization" },
    },
  ],
};

export default function Home() {
  return (
    <main id="main-content" className="overflow-x-clip bg-background">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(structuredData) }}
      />
      <section className="relative border-b border-white/10">
        <SiteHeader />
        <div className="mx-auto grid min-h-[50rem] max-w-[96rem] lg:min-h-[44rem] lg:grid-cols-[1.18fr_.82fr] 2xl:min-h-[50rem]">
          <div className="relative z-10 flex items-center px-5 pb-16 pt-28 sm:px-8 lg:px-12 lg:pb-24 lg:pt-24">
            <div className="max-w-[49rem]">
              <p className="font-mono text-[11px] font-medium uppercase tracking-[0.18em] text-primary">
                Toronto · launching soon
              </p>
              <h1 className="mt-7 text-[clamp(3.4rem,5.5vw,5.4rem)] font-semibold leading-[0.9] tracking-[-0.06em] text-[#f5f4ef]">
                Say you met at a bar,{" "}
                <span className="mt-2 block text-primary">not a dating app.</span>
              </h1>
              <p className="mt-7 max-w-md text-lg leading-8 text-white/68 sm:text-xl">
                For people who are done with endless swiping. See where Toronto is going, pick a bar, and meet in real life.
              </p>
              <a
                href="mailto:hello@getoutly.app?subject=Outly%20Toronto%20launch"
                className={cn(buttonVariants({ size: "lg" }), "mt-8 h-13 px-6 text-base")}
              >
                Get launch updates <ArrowRight className="size-4" />
              </a>
            </div>
          </div>

          <div className="relative min-h-[36rem] overflow-hidden border-t border-white/10 lg:min-h-[44rem] lg:border-l lg:border-t-0 2xl:min-h-[50rem]">
            <Image
              src="/brand/outly-night-arrival.png"
              alt="Friends arriving together at an anonymous city bar on a rainy night"
              fill
              priority
              sizes="(max-width: 1023px) 100vw, 58vw"
              className="object-cover object-[68%_center]"
            />
            <div className="absolute inset-0 bg-gradient-to-r from-background/70 via-background/8 to-transparent lg:from-background/58" />
            <div className="absolute inset-x-0 bottom-0 h-52 bg-gradient-to-t from-background/62 to-transparent" />
            <DevicePreview
              priority
              className="absolute bottom-6 left-5 w-[13rem] sm:bottom-8 sm:left-8 sm:w-[15rem] lg:bottom-8 lg:left-8 lg:w-[16rem] xl:left-10 2xl:w-[18rem]"
              sizes="(max-width: 640px) 208px, (max-width: 1023px) 240px, (max-width: 1535px) 256px, 288px"
            />
          </div>
        </div>
      </section>

      <section id="the-app" className="border-b border-white/10 py-24 sm:py-32">
        <div className="mx-auto max-w-[90rem] px-5 sm:px-8 lg:px-12">
          <div className="max-w-3xl">
            <h2 className="text-4xl font-medium leading-[1.02] tracking-[-0.045em] sm:text-6xl">
              Built to get you off your phone.
            </h2>
            <p className="mt-5 max-w-xl text-lg leading-8 text-white/62">
              See where people are going, choose one venue, and unlock a verified offer when you arrive.
            </p>
          </div>

          <div className="mt-16 grid items-start gap-16 lg:grid-cols-[1.05fr_.95fr] lg:gap-20">
            <ProductScreen
              src="/product/venues-v2.png"
              alt="Outly venue list showing fictional venues across Toronto neighbourhoods"
              title="See where people are going"
              copy="Browse tonight’s venues by neighbourhood and hours—without another group chat."
              className="mx-auto w-full max-w-[25rem]"
            />

            <div className="grid gap-16 sm:grid-cols-2 lg:pt-28">
              <ProductScreen
                src="/product/venue-detail-v2.png"
                alt="Fictional venue details and tonight's crowd in Outly"
                title="Know enough to choose"
                copy="Hours, crowd context, and the night’s offer stay together on one clear screen."
                className="mx-auto w-full max-w-[18rem]"
              />
              <ProductScreen
                src="/product/offer-active-v2.png"
                alt="Active Outly offer with a countdown timer for the fictional venue Vesper Row"
                title="Unlock the offer when you arrive"
                copy="Check in at the venue, then show staff a clear, time-limited offer."
                className="mx-auto w-full max-w-[18rem]"
              />
            </div>
          </div>
        </div>
      </section>

      <section id="how-it-works" className="border-b border-white/10 py-24 sm:py-32">
        <div className="mx-auto max-w-[90rem] px-5 sm:px-8 lg:px-12">
          <div className="max-w-3xl">
            <h2 className="text-4xl font-medium tracking-[-0.045em] sm:text-6xl">Less swiping. More arriving.</h2>
            <p className="mt-5 max-w-xl text-lg leading-8 text-white/62">
              Outly helps you choose one place, then gets out of the way so the night can happen in real life.
            </p>
          </div>

          <div className="mt-14 grid gap-10 md:grid-cols-3 md:gap-8">
            {decisions.map((decision) => (
              <article key={decision.title} className="border-t border-white/18 pt-6">
                <h3 className="text-2xl font-medium tracking-[-0.025em]">{decision.title}</h3>
                <p className="mt-3 max-w-sm leading-7 text-white/60">{decision.copy}</p>
              </article>
            ))}
          </div>

          <p className="mt-14 max-w-xl border-l-2 border-primary pl-5 text-sm leading-6 text-white/66">
            Location is checked only when you tap Check in. Venues and other users never see where you are.
          </p>
        </div>
      </section>

      <section aria-labelledby="about-outly" className="border-b border-white/10 py-24 sm:py-32">
        <div className="mx-auto grid max-w-[90rem] gap-14 px-5 sm:px-8 lg:grid-cols-[.62fr_1.38fr] lg:px-12">
          <div className="max-w-lg">
            <p className="font-mono text-[11px] font-medium uppercase tracking-[0.18em] text-primary">
              About Outly
            </p>
            <h2 id="about-outly" className="mt-6 text-4xl font-medium leading-[1.02] tracking-[-0.045em] sm:text-5xl">
              Nightlife, explained simply.
            </h2>
          </div>
          <div>
            {questions.map((item) => (
              <article key={item.question} className="grid gap-3 border-t border-white/16 py-7 sm:grid-cols-[15rem_1fr] sm:gap-8">
                <h3 className="text-lg font-medium tracking-[-0.02em]">{item.question}</h3>
                <p className="max-w-2xl leading-7 text-white/62">{item.answer}</p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="border-b border-white/10 py-20 sm:py-24">
        <div className="mx-auto flex max-w-[90rem] flex-col items-start justify-between gap-8 px-5 sm:px-8 lg:flex-row lg:items-end lg:px-12">
          <div className="max-w-3xl">
            <h2 className="text-4xl font-medium leading-[1.02] tracking-[-0.045em] sm:text-5xl">
              Spend less time matching. Meet in real life.
            </h2>
            <p className="mt-4 text-lg leading-8 text-white/62">Outly is launching in Toronto. Get the date when it’s ready.</p>
          </div>
          <a
            href="mailto:hello@getoutly.app?subject=Outly%20Toronto%20launch"
            className={cn(buttonVariants({ size: "lg" }), "h-13 shrink-0 px-6 text-base")}
          >
            Get launch updates <ArrowRight className="size-4" />
          </a>
        </div>
      </section>

      <SiteFooter />
    </main>
  );
}

function ProductScreen({
  src,
  alt,
  title,
  copy,
  className,
}: {
  src: string;
  alt: string;
  title: string;
  copy: string;
  className: string;
}) {
  return (
    <figure>
      <DevicePreview src={src} alt={alt} className={className} sizes="(max-width: 639px) 78vw, (max-width: 1023px) 42vw, 25vw" />
      <figcaption className="mx-auto mt-6 max-w-sm">
        <h3 className="text-lg font-medium">{title}</h3>
        <p className="mt-2 text-sm leading-6 text-white/58">{copy}</p>
      </figcaption>
    </figure>
  );
}
