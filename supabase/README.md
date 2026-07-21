# Outly local Supabase development

This directory contains the versioned local database definition and automated security tests. Nothing here deploys to the hosted Supabase project automatically.

## Domains currently implemented

- PostGIS extension
- Non-exposed `private` schema
- Opt-in Data API grants
- Consumer profile shell with own-row read policy
- Protected DOB, gender, and server-calculated 19+ eligibility
- Founder authorization allowlist
- Versioned legal acceptances
- Private APNs token storage
- Resumable account-deletion requests
- One-to-one MVP venue accounts
- Venue self-registration and founder approval/publication state
- Public venue profiles with PostGIS points and constrained geofence radii
- Weekly hours, date-specific exceptions, and venue events
- Reviewable critical profile changes
- Moderated venue media with private-submission and public-approved buckets
- Founder-only venue business details and review history
- One active consumer plan per 4:00 AM-bounded nightlife date
- Atomic plan creation, replacement, cancellation, and idempotent retries
- Server-side PostGIS check-in verification using the prototype's 30-second, 75-metre-accuracy, and 1-metre tie rules
- One verified check-in per consumer night for the MVP
- Derived check-in evidence without retained latitude or longitude
- Configurable rapid-attempt protection and versioned verification thresholds
- One approved eligible offer per venue across standard and founder-managed partner campaigns
- Versioned offer copy, schedules, capacity, premium discovery metadata, and approved HTTPS partner destinations
- Location-verified offer claims with configurable positive countdowns or no countdown; every entitlement still has a server-enforced maximum lifetime
- Private partner contacts, commercial campaign terms, venue targeting, and service-only eligibility/unlock operations
- pgTAP structure, privilege, constraint, and RLS tests

Billing, aggregate analytics, and production Edge Function adapters belong in later migrations.

## Local verification

Docker Desktop must be running.

```sh
supabase start
supabase db reset --local
supabase test db
supabase db lint --local --schema public,private --level warning --fail-on warning
```

Stop the local services when finished:

```sh
supabase stop
```

## Migration rules

- Create every migration with `supabase migration new <descriptive_name>`.
- Keep grants, RLS enablement, and policies in the same migration as each exposed table.
- Never add `private` to the Data API exposed schemas.
- Do not use Auth user metadata for authorization.
- Test a clean reset and the full pgTAP suite before linking or pushing remotely.
- Hosted deployment requires a separate review and explicit approval.
