# Outly web

The consumer marketing site and venue portal live together in this Next.js App Router project.

## Routes

- `/` — consumer landing page
- `/venues` — venue SaaS landing page, product value, and pricing
- `/venue/login`, `/venue/register`, and `/venue/status` — Supabase venue access
- `/dashboard` — authenticated venue overview backed by the server-only analytics snapshot
- `/dashboard/analytics` — aggregated attendance analytics
- `/dashboard/offers` — offer management
- `/dashboard/offers/new` — offer creation flow
- `/dashboard/venue` — venue profile and hours
- `/dashboard/billing` — plan and billing UI
- `/admin` — founder-only live network operations
- `/admin/venues` — venue creation, approval, publication, and manual MVP plan controls
- `/admin/users` — privacy-reduced consumer account list
- `/admin/partners` — partner records and location-verified campaign creation
- `/admin/assignments` — venue-offer approval queue

The venue dashboard is protected by a verified Supabase Auth session plus the venue-account mapping in Postgres. Registration and analytics call service-only database RPCs from the Next.js server runtime. The Supabase secret key is never shipped to the browser.

## Local development

```bash
pnpm install
cp .env.example .env.local
pnpm dev
```

Fill in `.env.local` with the project URL, publishable key, server-only secret key, site URL, and current venue-agreement version. Keep `.env.local` out of Git.

## Vercel

Create a Vercel project from the Rally repository and set its **Root Directory** to `web`. The detected framework should be Next.js. Add each variable from `.env.example` in Vercel. `SUPABASE_SECRET_KEY` must remain server-only.

Also configure Supabase Auth with `https://getoutly.app/auth/callback` as an allowed redirect URL. Deploy the authenticated functions named by `SUPABASE_FOUNDER_ACCESS_FUNCTION` and `SUPABASE_FOUNDER_DASHBOARD_FUNCTION`, plus the founder mutation functions in `supabase/functions`. Founder authorization is checked on every read and mutation; `/admin` fails closed when access or live data cannot be verified.

## Launch decisions still represented as provisional

- The paid venue tier displays **C$129/month** as provisional launch pricing.
- The official App Store badge is intentionally withheld until Outly has a public App Store listing or pre-order URL.
- Testimonials are not fabricated; the consumer page presents paraphrased research themes instead.
