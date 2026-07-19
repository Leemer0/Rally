# Outly web

The consumer marketing site and venue portal live together in this Next.js App Router project.

## Routes

- `/` — consumer landing page
- `/venues` — venue SaaS landing page and proposed pilot pricing
- `/venue/login` and `/venue/register` — venue authentication UI
- `/dashboard` — venue overview
- `/dashboard/analytics` — aggregated attendance analytics
- `/dashboard/offers` — offer management
- `/dashboard/offers/new` — offer creation flow
- `/dashboard/venue` — venue profile and hours
- `/dashboard/billing` — plan and billing UI

The dashboard currently uses clearly labelled demo data. Forms navigate through the prototype but do not yet create records. Supabase Auth, database reads/writes, founder approval, and Stripe are intentionally deferred to the backend phase.

## Local development

```bash
pnpm install
pnpm dev
```

## Vercel

Create a Vercel project from the Rally repository and set its **Root Directory** to `web`. The detected framework should be Next.js. No environment variables are required for the current frontend-only build.

## Launch decisions still represented as provisional

- The paid venue tier displays **C$129/month** as proposed pilot pricing.
- The official App Store badge is intentionally withheld until Outly has a public App Store listing or pre-order URL.
- Testimonials are not fabricated; the consumer page presents paraphrased research themes instead.
