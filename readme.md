# Outly

Outly is a map-first iPhone app for seeing where people are going tonight,
choosing one venue, checking in on arrival, and unlocking venue or partner
offers. This repository contains the consumer iOS app, the public website,
venue and founder dashboards, and the Supabase backend they share.

## Repository structure

- `ios/Outly/` — SwiftUI consumer app
- `ios/OutlyLiveActivity/` — active-offer Live Activity extension
- `ios/Shared/` — models shared by the app and extension
- `ios/OutlyTests/` and `ios/OutlyUITests/` — automated iOS tests
- `web/` — Next.js public site, venue portal, and founder dashboard
- `supabase/` — migrations, pgTAP tests, and Edge Functions
- `contracts/openapi.yaml` — shared backend contract
- `design-system/` and `design-concepts/` — product design guidance

## iOS app

Requirements:

- iOS 17 or later
- Xcode with the shared `Outly` scheme
- a public Mapbox access token beginning with `pk.` in `~/.mapbox`
- the Supabase project URL and public publishable key in
  `ios/Outly/SupabaseConfig.plist`

Open `ios/Outly.xcodeproj`, select the `Outly` scheme, and run it on an iPhone
simulator. To run the automated suite:

```bash
xcodebuild -project ios/Outly.xcodeproj \
  -scheme Outly \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

The app uses live Supabase Auth and Edge Functions in normal builds. Explicit
demo, preview, screenshot, and UI-test launch arguments remain available for
repeatable design review and testing.

## Website and dashboards

See `web/README.md` for local environment variables and development commands.
The marketing pages can render without Supabase configuration; authenticated
venue and founder routes fail closed until the public and server-only keys are
configured.

## Backend

See `supabase/README.md` for the implemented data model, local verification,
hosted deployment steps, Auth provider setup, and remaining production work.
Database migrations are the source of truth. Supabase is authoritative for age
eligibility, plans, geofence decisions, offer claims, entitlements, analytics,
and account deletion; clients never receive the secret/service-role key.
