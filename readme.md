# Outly

Outly is a mobile-first nightlife discovery app for deciding where to go based on
aggregated social momentum. The product is being built as a Next.js web MVP around a
versioned API that can later support a separate SwiftUI client.

## Local development

```bash
npm install
cp .env.example .env.local
npm run dev
```

Open `http://localhost:3000` for the interactive mobile prototype. It supports the
complete mocked journey from account choice and onboarding through venue discovery,
RSVP, QR check-in, offer redemption, List, filters, and Profile.

## Native iOS MVP

The SwiftUI prototype lives in `ios/Outly.xcodeproj` and targets iOS 17 or later.
Open the shared `Outly` scheme in Xcode or build it from the command line:

```bash
xcodebuild -project ios/Outly.xcodeproj \
  -scheme Outly \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  test
```

The iOS app uses a native Mapbox discovery surface, Core Location for one-time
venue-radius verification, and a deterministic local authentication adapter.
Onboarding, plans, check-ins, and timed offer windows persist locally. Use **Reset
Demo** in Profile or Settings to return to first launch.

Mapbox and location verification are live. Authentication, venue data, and timed
offer persistence remain prototype adapters or local fixtures. The design-system
lab remains available at `http://localhost:3000/system`.

To test the live Track & Field check-in in Simulator, choose **Features → Location
→ Custom Location** and enter latitude `43.6549`, longitude `-79.4238`.

## Quality checks

```bash
npm run format:check
npm run lint
npm run typecheck
npm run test
npm run test:e2e
npm run build
```

## Architecture boundaries

- `contracts/` — public OpenAPI contract and portable examples
- `src/contracts/` — client-safe DTOs and schemas
- `src/api-client/` — typed access to `/api/v1`
- `src/domain/` — framework-independent business rules
- `src/server/` — server-only orchestration and persistence
- `src/components/` — presentation components; never direct database access

Application routes will live under `/api/v1` and use a consistent data/error envelope.
