# Outly Supabase backend

This directory is the versioned backend for the consumer iOS app, venue portal,
and founder operations dashboard. Database migrations are the source of truth;
the hosted project should be changed by pushing these migrations, not by
manually creating production tables in Studio.

## Implemented MVP domains

- Supabase Auth identity shells for consumers, one-login venue accounts, and a
  private founder allowlist
- Immutable consumer DOB and required gender with server-calculated 19+
  eligibility
- Venue self-registration, founder approval, business records, weekly hours,
  map coordinates, and constrained geofences
- One plan per consumer per 4:00 AM-bounded nightlife date
- server-side PostGIS check-in decisions using fresh, precise iOS location
  evidence; raw coordinates are not retained in the check-in record
- standard and partner offers on one location-verified claim path
- configurable claim countdowns from one second to 24 hours, plus open-ended
  display offers with a server-enforced entitlement expiry
- Pro-only partner campaigns, premium discovery metadata, HTTPS destinations,
  approved public partner artwork, campaign capacity, and per-user limits
- privacy-thresholded, coarsened crowd demographics and aggregate venue
  analytics
- Free/Pro entitlements with Stripe Checkout, signed webhook synchronization,
  configurable recurring Prices, and self-service Customer Portal management
- resumable account deletion, including durable completion when Auth is removed
- authenticated Edge Functions for every consumer, venue, and founder action
- an OpenAPI contract in `../contracts/openapi.yaml`

The `private` schema is never exposed through the Data API. Privileged RPCs are
service-role-only and are called by authenticated Edge Functions. Never put the
Supabase secret/service key in the iOS app or browser JavaScript.

## Local verification

With Docker Desktop running:

```sh
supabase start
supabase db reset --local
supabase test db
supabase db lint --local --schema public,private --level warning --fail-on warning
supabase functions serve
```

The database suite covers structure, RLS, plans, location verification, offers,
arbitrary countdowns, privacy rules, deletion, and primary API workflows.

## Hosted project setup

1. Sign in and link this repository:

   ```sh
   supabase login
   supabase link --project-ref YOUR_PROJECT_REF
   ```

2. Review the pending production migration, then deploy schema and functions:

   ```sh
   supabase db push --dry-run
   supabase db push
   supabase functions deploy
   ```

3. In Supabase Auth, set the site URL to `https://www.getoutly.app` and allow:

   - `https://getoutly.app/auth/callback`
   - `https://www.getoutly.app/auth/callback`
   - `outly://auth-callback`
   - the localhost callback while developing

4. Configure the chosen OAuth providers with their production app credentials.
   Configure Resend custom SMTP and publish the branded confirmation/recovery
   templates in `templates/` before requiring email confirmation.

5. Add one founder after that person has an Auth user. Run this once in the SQL
   editor with the real Auth UUID:

   ```sql
   insert into private.internal_admins (user_id, role, active, revoked_at)
   values ('FOUNDER_AUTH_USER_UUID', 'founder_admin', true, null)
   on conflict (user_id) do update
   set role = excluded.role,
       active = excluded.active,
       revoked_at = null;
   ```

6. Add the project URL, publishable key, and server-only secret key to Vercel as
   documented in `../web/.env.example`. The iOS app receives only the project URL
   and publishable key.

7. Add `RESEND_API_KEY`, `OUTLY_EMAIL_FROM`, `OUTLY_EMAIL_REPLY_TO`, and
   `OUTLY_SITE_URL` as Supabase Edge Function secrets. Consumer welcome email is
   sent only after successful 19+ onboarding; Auth confirmation and recovery
   email continues through Supabase Auth using Resend SMTP.

Approved partner logos belong in the public `partner-media` bucket with paths
such as `partner-media/northline/logo.webp`. There is intentionally no direct
browser upload policy; founders upload approved artwork through trusted server
operations.

## Not yet production-complete

- Stripe Checkout and webhook code is implemented, but the live Stripe Product,
  recurring Price, Customer Portal, webhook destination, branding, and Vercel
  secrets must be configured and exercised in a Stripe sandbox before live mode.
- Core Location evidence is mathematically verified but still originates on the
  client. Before attaching material cash value to partner rewards, add App
  Attest, one-time challenges, fraud monitoring, and conservative claim caps.
- Production legal copy/version identifiers, SMTP, OAuth credentials, APNs, and
  retention periods still need final configuration.

## Migration rules

- Keep grants, RLS, constraints, and policies beside the object they protect.
- Do not add `private` to the exposed Data API schemas.
- Do not use mutable Auth metadata for authorization.
- Create a new migration for deployed-schema changes; never rewrite a migration
  that has already reached production.
- Run a clean reset, the complete pgTAP suite, and database lint before pushing.
