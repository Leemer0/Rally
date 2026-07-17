# Outly

Outly is an iPhone nightlife discovery app for deciding where to go based on
aggregated social momentum. The product currently consists of the native SwiftUI
app only; the venue-facing web application will be designed separately later.

## Requirements

- iOS 17 or later
- Xcode with the shared `Outly` scheme
- A public Mapbox access token beginning with `pk.`

Save the Mapbox token in `~/.mapbox`. The build copies it into the app bundle
without committing it to the repository.

## Run the app

Open `ios/Outly.xcodeproj` in Xcode, select the `Outly` scheme, and run it on an
iPhone simulator. To build and test from the command line:

```bash
xcodebuild -project ios/Outly.xcodeproj \
  -scheme Outly \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

To test the live Track & Field check-in in Simulator, choose **Features →
Location → Custom Location** and enter latitude `43.6549`, longitude `-79.4238`.

## Current implementation

The app uses SwiftUI, Mapbox for venue discovery, Core Location for one-time
venue-radius verification, and a Live Activity for active offers. Authentication,
venue data, plans, check-ins, and offer persistence currently use deterministic
local adapters so the complete mobile journey works without a backend.

Use **Reset Demo** in Profile or Settings to return the app to first launch.

## Repository structure

- `ios/Outly/` — iPhone application source
- `ios/OutlyLiveActivity/` — Live Activity extension
- `ios/Shared/` — models shared by the app and extension
- `ios/OutlyTests/` and `ios/OutlyUITests/` — automated tests
- `ios/Screenshots/` and `ios/DemoVideos/` — current product references
- `contracts/` — backend OpenAPI contract and portable examples
- `design-system/` and `design-concepts/` — product design guidance

## Backend boundary

`contracts/openapi.yaml` is the starting point for the versioned API. Before
connecting the app, define canonical onboarding and venue DTOs there. The server
must be authoritative for authentication, attendance aggregation, check-in
eligibility, and offer issuance or redemption; client location checks are a UX
aid, not a security boundary.

No web application is currently included. The future venue portal should be
introduced as a separate target once its product and API requirements are ready.
