import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { ArrowRight, Check } from "lucide-react";
import { DevicePreview } from "@/components/site/device-preview";
import { SiteFooter } from "@/components/site/site-footer";
import { SiteHeader } from "@/components/site/site-header";
import { buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";

export const metadata: Metadata = {
  title: "For venues",
  description: "Reach people choosing where to go tonight, create check-in offers for the hours you want to fill, and measure verified visits with Outly.",
};

const outcomes = [
  {
    title: "Be seen while tonight is still undecided",
    copy: "Keep your venue, hours, and current offers visible to people choosing where to go.",
  },
  {
    title: "Drive visits when you choose",
    copy: "Run an exclusive offer for a slower window, an early arrival, or any night you want more traffic.",
  },
  {
    title: "See what became a visit",
    copy: "Track plans, verified check-ins, arrival times, offer claims, and returning visitors.",
  },
];

const freeFeatures = [
  "Venue listing",
  "Business details and hours",
  "Standard discovery placement",
  "Basic offer creation",
  "Essential plan and check-in analytics",
];

const paidFeatures = [
  "Advanced attendance and repeat-visitor analytics",
  "Featured discovery placement",
  "More active offers and campaign controls",
  "Schedule and audience targeting",
  "Neighbourhood benchmarks where data is sufficient",
  "Partner campaign matching and brand-funded guest offers",
];

const partnerCampaignSteps = [
  {
    number: "01",
    title: "Matched for fit",
    copy: "Outly proposes campaigns based on the venue, neighbourhood, audience, and timing.",
  },
  {
    number: "02",
    title: "Reviewed by your team",
    copy: "See the offer value, schedule, limits, and staff instructions before you accept.",
  },
  {
    number: "03",
    title: "Verified at check-in",
    copy: "Guests unlock the campaign only after Outly confirms they are at your venue.",
  },
];

const questions = [
  {
    question: "Who can get started?",
    answer: "Bars, clubs, lounges, and other Toronto nightlife venues can create an account. Outly reviews each listing before it goes live.",
  },
  {
    question: "What can we measure?",
    answer: "Your dashboard reports plans, verified check-ins, offer claims, arrival times, and returning-visitor share as aggregated totals.",
  },
  {
    question: "How is a check-in verified?",
    answer: "Guests choose to share precise location at check-in. Outly confirms that they are within the venue area.",
  },
  {
    question: "Can we create our own offers?",
    answer: "Yes. Choose the value, dates, hours, claim limit, and staff instructions. You decide when the offer runs.",
  },
  {
    question: "How do partner offers work?",
    answer: "Outly Pro venues can be matched with relevant campaigns from Outly partners. Offers depend on campaign fit, timing, budget, and partner approval.",
  },
  {
    question: "When will we be billed?",
    answer: "Nothing is charged without your confirmation. We’ll publish final Outly Pro pricing before paid subscriptions begin.",
  },
];

export default function VenuesPage() {
  return (
    <main id="main-content" className="overflow-x-clip bg-background">
      <section className="relative border-b border-white/10">
        <SiteHeader audience="venue" />
        <div className="mx-auto grid min-h-[48rem] max-w-[96rem] items-center gap-14 px-5 pb-20 pt-32 sm:px-8 lg:grid-cols-[.82fr_1.18fr] lg:px-12 lg:pt-24">
          <div className="max-w-[44rem]">
            <p className="font-mono text-[11px] font-medium uppercase tracking-[0.18em] text-primary">
              Outly for venues
            </p>
            <h1 className="mt-7 text-[clamp(3.5rem,5.8vw,6.6rem)] font-medium leading-[0.91] tracking-[-0.06em]">
              Turn intent into <span className="text-primary">verified visits.</span>
            </h1>
            <p className="mt-7 max-w-xl text-lg leading-8 text-white/66">
              Reach people choosing where to go tonight. Create your own check-in offers for the hours you want to fill, then see which plans became verified visits.
            </p>
            <div className="mt-8 flex flex-col gap-3 sm:flex-row">
              <Link href="/venue/register" className={cn(buttonVariants({ size: "lg" }), "h-13 px-6 text-base")}>
                Get Started <ArrowRight className="size-4" />
              </Link>
              <Link
                href="/venue/login"
                className={cn(buttonVariants({ variant: "outline", size: "lg" }), "h-13 border-white/18 bg-transparent px-6 text-base")}
              >
                Venue sign in
              </Link>
            </div>
          </div>

          <div className="relative">
            <div className="overflow-hidden rounded-xl border border-white/16 bg-[#080b10] shadow-[0_36px_100px_rgba(0,0,0,.42)]">
              <Image
                src="/product/venue-dashboard-v2.png"
                alt="Outly venue dashboard for a fictional Toronto venue"
                width={1440}
                height={1000}
                priority
                sizes="(max-width: 1023px) 100vw, 58vw"
                className="h-auto w-full"
              />
            </div>
            <p className="mt-4 text-xs leading-5 text-white/52">
              Product interface shown with fictional sample data.
            </p>
          </div>
        </div>
      </section>

      <section className="border-b border-white/10 py-24 sm:py-32">
        <div className="mx-auto grid max-w-[90rem] items-center gap-14 px-5 sm:px-8 lg:grid-cols-[.76fr_1.24fr] lg:px-12">
          <div className="max-w-xl">
            <p className="font-mono text-[11px] font-medium uppercase tracking-[0.18em] text-primary">
              Attendance patterns
            </p>
            <h2 className="mt-6 text-4xl font-medium leading-[1.02] tracking-[-0.045em] sm:text-6xl">
              See when guests arrive—and whether they come back.
            </h2>
            <p className="mt-5 text-lg leading-8 text-white/62">
              Check-in-time and repeat-visitor trends show what is working, while guest data stays aggregated.
            </p>
          </div>

          <figure>
            <div className="overflow-hidden rounded-xl border border-white/14 bg-[#080b10] shadow-[0_30px_90px_rgba(0,0,0,.36)]">
              <Image
                src="/product/venue-analytics-v2.png"
                alt="Outly attendance analytics for a fictional Toronto venue"
                width={1440}
                height={1000}
                sizes="(max-width: 1023px) 100vw, 58vw"
                className="h-auto w-full"
              />
            </div>
            <figcaption className="mt-4 text-xs leading-5 text-white/48">
              Sample data is aggregated; venues do not receive guest names, contact details, or individual timelines.
            </figcaption>
          </figure>
        </div>
      </section>

      <section id="product" className="border-b border-white/10 py-24 sm:py-32">
        <div className="mx-auto max-w-[90rem] px-5 sm:px-8 lg:px-12">
          <div className="max-w-3xl">
            <h2 className="text-4xl font-medium leading-[1.02] tracking-[-0.045em] sm:text-6xl">
              Be there when the decision is made.
            </h2>
            <p className="mt-5 max-w-xl text-lg leading-8 text-white/62">
              Outly connects venue discovery, one committed plan, a verified arrival, and an offer claim—so you can measure the path from interest to foot traffic.
            </p>
          </div>

          <div className="mt-14 grid gap-10 md:grid-cols-3 md:gap-8">
            {outcomes.map((outcome) => (
              <article key={outcome.title} className="border-t border-white/18 pt-6">
                <h3 className="text-2xl font-medium leading-tight tracking-[-0.025em]">{outcome.title}</h3>
                <p className="mt-3 max-w-sm leading-7 text-white/60">{outcome.copy}</p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="border-b border-white/10 bg-[#0b0e13] py-24 sm:py-32">
        <div className="mx-auto grid max-w-[90rem] items-center gap-16 px-5 sm:px-8 lg:grid-cols-[.72fr_1.28fr] lg:px-12">
          <DevicePreview
            src="/product/offer-active-v2.png"
            alt="Free cover offer for a fictional venue that staff can verify"
            className="mx-auto w-full max-w-[20rem]"
            sizes="(max-width: 1023px) 70vw, 320px"
          />

          <div className="max-w-2xl">
            <h2 className="text-4xl font-medium leading-[1.02] tracking-[-0.045em] sm:text-6xl">
              Fill the hours you choose.
            </h2>
            <p className="mt-5 max-w-xl text-lg leading-8 text-white/62">
              Create an exclusive Outly offer for a slower night, an early-arrival window, or any moment you want more traffic. It appears while people are deciding and unlocks only after a verified check-in.
            </p>
            <ul className="mt-9 space-y-4">
              {[
                "Choose the value, schedule, and claim limit",
                "Reach people actively deciding where to go",
                "Give staff a clear live proof screen",
              ].map((item) => (
                <li key={item} className="flex items-start gap-3 text-white/76">
                  <Check className="mt-1 size-4 shrink-0 text-primary" />
                  {item}
                </li>
              ))}
            </ul>
          </div>
        </div>
      </section>

      <section className="border-b border-white/10 py-24 sm:py-32">
        <div className="mx-auto grid max-w-[90rem] items-center gap-14 px-5 sm:px-8 lg:grid-cols-[.8fr_1.2fr] lg:gap-20 lg:px-12">
          <div className="max-w-xl">
            <p className="font-mono text-[11px] font-medium uppercase tracking-[0.18em] text-primary">
              Outly Pro · Partner campaigns
            </p>
            <h2 className="mt-6 text-4xl font-medium leading-[1.02] tracking-[-0.045em] sm:text-6xl">
              Bring brand-funded value to your guests.
            </h2>
            <p className="mt-5 text-lg leading-8 text-white/62">
              Pro venues can be considered for selected campaigns from Outly partners. Campaigns may include ride-home rewards, complimentary items, or other guest benefits—matched to the venue and offered only with your approval.
            </p>
            <Link
              href="#pricing"
              className={cn(
                buttonVariants({ variant: "outline", size: "lg" }),
                "mt-8 h-13 border-white/18 bg-transparent px-6 text-base",
              )}
            >
              See what Pro includes <ArrowRight className="size-4" />
            </Link>
          </div>

          <div className="border border-white/14 bg-[#0b0f15] px-6 py-3 sm:px-8">
            <div className="flex min-h-20 items-center justify-between gap-6 border-b border-white/12">
              <div>
                <p className="font-mono text-[10px] uppercase tracking-[0.18em] text-white/42">Campaign access</p>
                <p className="mt-1 text-lg font-medium">A considered match, not an open marketplace.</p>
              </div>
              <span className="shrink-0 text-xs font-medium text-primary">PRO</span>
            </div>

            <ol>
              {partnerCampaignSteps.map((step) => (
                <li key={step.number} className="grid gap-3 border-b border-white/10 py-6 sm:grid-cols-[3rem_1fr] sm:gap-5">
                  <span className="font-mono text-xs text-primary" aria-hidden="true">{step.number}</span>
                  <div>
                    <h3 className="text-lg font-medium tracking-[-0.015em]">{step.title}</h3>
                    <p className="mt-2 max-w-xl text-sm leading-6 text-white/56">{step.copy}</p>
                  </div>
                </li>
              ))}
            </ol>

            <p className="py-5 text-xs leading-5 text-white/42">
              Campaign access depends on availability, venue fit, timing, budget, and partner approval.
            </p>
          </div>
        </div>
      </section>

      <section id="pricing" className="border-b border-white/10 py-24 sm:py-32">
        <div className="mx-auto max-w-[90rem] px-5 sm:px-8 lg:px-12">
          <div className="max-w-3xl">
            <h2 className="text-4xl font-medium leading-[1.02] tracking-[-0.045em] sm:text-6xl">
              Start free. Add more reach when you need it.
            </h2>
            <p className="mt-5 max-w-xl text-lg leading-8 text-white/62">
              Use the free plan for a current listing and basic offers. Outly Pro adds promoted placement, deeper reporting, more campaign control, and partner-funded opportunities.
            </p>
          </div>

          <div className="mt-14 grid gap-12 lg:grid-cols-2 lg:gap-0">
            <Plan
              title="Free"
              price="C$0"
              copy="The essentials for turning interest into verified visits."
              features={freeFeatures}
            />
            <Plan
              title="Outly Pro"
              price="Pricing soon"
              copy="More reach, control, and measurement for venues using Outly as a growth channel."
              features={paidFeatures}
              className="lg:border-l lg:border-white/14 lg:pl-12"
            />
          </div>
        </div>
      </section>

      <section id="faq" className="py-24 sm:py-32">
        <div className="mx-auto grid max-w-[90rem] gap-12 px-5 sm:px-8 lg:grid-cols-[.72fr_1.28fr] lg:px-12">
          <div className="max-w-md">
            <h2 className="text-4xl font-medium tracking-[-0.045em] sm:text-5xl">What venues need to know.</h2>
            <p className="mt-5 text-lg leading-8 text-white/62">Straight answers before you get started.</p>
          </div>
          <div className="border-b border-white/14">
            {questions.map((item) => (
              <details key={item.question} className="group border-t border-white/14 py-6">
                <summary className="flex min-h-11 list-none items-center justify-between gap-5 text-lg font-medium marker:content-none">
                  {item.question}
                  <span aria-hidden="true" className="text-primary transition-transform duration-200 group-open:rotate-45">+</span>
                </summary>
                <p className="max-w-2xl pb-1 pr-10 pt-3 text-sm leading-6 text-white/60">{item.answer}</p>
              </details>
            ))}
          </div>
        </div>

      </section>

      <SiteFooter audience="venue" />
    </main>
  );
}

function Plan({
  title,
  price,
  copy,
  features,
  className,
}: {
  title: string;
  price: string;
  copy: string;
  features: string[];
  className?: string;
}) {
  return (
    <article className={cn("border-t border-white/18 pt-7", className)}>
      <p className="text-sm font-medium text-white/66">{title}</p>
      <p className="mt-5 text-4xl font-medium tracking-[-0.045em]">{price}</p>
      <p className="mt-3 max-w-md text-sm leading-6 text-white/58">{copy}</p>
      <ul className="mt-8 space-y-3">
        {features.map((feature) => (
          <li key={feature} className="flex items-start gap-3 text-sm leading-6 text-white/72">
            <Check className="mt-1 size-4 shrink-0 text-primary" />
            {feature}
          </li>
        ))}
      </ul>
    </article>
  );
}
