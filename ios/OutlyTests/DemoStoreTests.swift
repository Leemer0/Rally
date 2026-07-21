import CoreLocation
import UIKit
import XCTest
@testable import Outly

@MainActor
final class DemoStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "OutlyTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testProfileValidationAndMinimumAge() {
        let store = DemoStore(defaults: defaults, storageKey: "state")

        XCTAssertFalse(store.submitName())
        store.setFirstName("  Liam  ")
        XCTAssertTrue(store.submitName())
        XCTAssertEqual(store.profile.firstName, "Liam")
        XCTAssertEqual(store.state.onboardingStage, .age)

        store.setAge(99)
        XCTAssertEqual(store.profile.age, 99)
        store.setAge(-1)
        XCTAssertEqual(store.profile.age, 19)
    }

    func testPlanCheckInAndTimedOfferPersistAcrossStores() {
        let key = "state"
        let checkInDate = Date(timeIntervalSince1970: 1_721_000_500)
        let firstStore = DemoStore(defaults: defaults, storageKey: key)
        firstStore.go(to: .main)
        firstStore.confirmPlan(
            for: "track-field",
            now: Date(timeIntervalSince1970: 1_721_000_000)
        )
        firstStore.checkIn(to: "track-field", now: checkInDate)

        let restoredStore = DemoStore(defaults: defaults, storageKey: key)
        XCTAssertEqual(restoredStore.state.onboardingStage, .main)
        XCTAssertEqual(restoredStore.plan?.venueID, "track-field")
        XCTAssertEqual(restoredStore.lastCheckedInVenue?.id, "track-field")
        XCTAssertEqual(restoredStore.checkedInAt, checkInDate)
        XCTAssertEqual(restoredStore.activeCheckedInVenue(at: checkInDate.addingTimeInterval(60))?.id, "track-field")
        XCTAssertNil(restoredStore.activeCheckedInVenue(at: checkInDate.addingTimeInterval(DemoStore.activePresenceDuration)))
        XCTAssertEqual(restoredStore.offerWindow(at: "track-field")?.unlockedAt, checkInDate)
        XCTAssertEqual(
            restoredStore.offerWindow(at: "track-field")?.expiresAt,
            checkInDate.addingTimeInterval(TimedOfferWindow.duration)
        )
        XCTAssertTrue(restoredStore.isOfferActive(at: "track-field", now: checkInDate.addingTimeInterval(599)))
        XCTAssertFalse(restoredStore.isOfferActive(at: "track-field", now: checkInDate.addingTimeInterval(600)))
    }

    func testTimedOfferRemainingFractionTracksItsActualDuration() {
        let unlockedAt = Date(timeIntervalSince1970: 1_721_000_000)
        let window = TimedOfferWindow(unlockedAt: unlockedAt, duration: 600)

        XCTAssertEqual(window.remainingFraction(at: unlockedAt), 1, accuracy: 0.0001)
        XCTAssertEqual(
            window.remainingFraction(at: unlockedAt.addingTimeInterval(300)),
            0.5,
            accuracy: 0.0001
        )
        XCTAssertEqual(window.remainingFraction(at: unlockedAt.addingTimeInterval(600)), 0, accuracy: 0.0001)
    }

    func testPartnerOfferUsesConfiguredDurationAndExternalDestination() throws {
        let checkedInAt = Date(timeIntervalSince1970: 1_721_000_500)
        let store = DemoStore(defaults: defaults, storageKey: "state")
        let venue = VenueCatalog.venue(id: "lavelle")
        let offer = try XCTUnwrap(venue.offer)

        store.checkIn(to: venue.id, now: checkedInAt)
        let window = try XCTUnwrap(store.offerWindow(at: venue.id))

        XCTAssertEqual(offer.kind, .partner)
        XCTAssertEqual(offer.sponsor?.displayName, "Northline")
        XCTAssertEqual(offer.redemptionMode, .externalLink)
        XCTAssertEqual(offer.destinationURL?.scheme, "https")
        XCTAssertEqual(store.claimedOffer(at: venue.id)?.versionID, offer.versionID)
        XCTAssertEqual(window.totalDuration, 30 * 60, accuracy: 0.0001)
        XCTAssertTrue(store.isOfferActive(at: venue.id, now: checkedInAt.addingTimeInterval(1_799)))
        XCTAssertFalse(store.isOfferActive(at: venue.id, now: checkedInAt.addingTimeInterval(1_800)))
    }

    func testOpenEndedOfferRemainsActiveOnlyWhileVenuePresenceIsActive() throws {
        let checkedInAt = Date(timeIntervalSince1970: 1_721_000_500)
        let store = DemoStore(defaults: defaults, storageKey: "state")
        let venue = VenueCatalog.venue(id: "paris-texas")

        store.checkIn(to: venue.id, now: checkedInAt)
        let window = try XCTUnwrap(store.offerWindow(at: venue.id))

        XCTAssertFalse(window.hasCountdown)
        XCTAssertNil(window.expiresAt)
        XCTAssertTrue(store.isOfferActive(
            at: venue.id,
            now: checkedInAt.addingTimeInterval(DemoStore.activePresenceDuration - 1)
        ))
        XCTAssertFalse(store.isOfferActive(
            at: venue.id,
            now: checkedInAt.addingTimeInterval(DemoStore.activePresenceDuration)
        ))
        XCTAssertEqual(
            store.offerPresentationEndsAt(venue.id),
            checkedInAt.addingTimeInterval(DemoStore.activePresenceDuration)
        )
    }

    func testLongClaimUsesOneEffectivePresenceEndAcrossSurfaces() {
        let checkedInAt = Date(timeIntervalSince1970: 1_721_000_500)
        let venue = VenueCatalog.venue(id: "lavelle")
        let state = DemoState(
            onboardingStage: .main,
            selectedVenueID: venue.id,
            checkedInVenueID: venue.id,
            checkedInAt: checkedInAt,
            offerWindows: [venue.id: TimedOfferWindow(unlockedAt: checkedInAt, duration: 24 * 60 * 60)],
            claimedOffers: [venue.id: venue.offer!]
        )
        let store = DemoStore(previewState: state)
        let effectiveEnd = checkedInAt.addingTimeInterval(DemoStore.activePresenceDuration)

        XCTAssertEqual(store.offerPresentationEndsAt(venue.id), effectiveEnd)
        XCTAssertEqual(store.offerPresentationWindow(at: venue.id)?.expiresAt, effectiveEnd)
        XCTAssertEqual(
            store.offerPresentationWindow(at: venue.id)?.totalDuration,
            DemoStore.activePresenceDuration
        )
        XCTAssertTrue(store.isOfferActive(at: venue.id, now: effectiveEnd.addingTimeInterval(-1)))
        XCTAssertFalse(store.isOfferActive(at: venue.id, now: effectiveEnd))
    }

    func testPartnerOfferContractDecodesSupabaseSnakeCase() throws {
        let json = #"""
        {
          "offer_id": "d1000000-0000-4000-8000-000000000001",
          "offer_version_id": "e1000000-0000-4000-8000-000000000001",
          "kind": "partner",
          "title": "50% off your ride home",
          "explanation": "For new Northline riders.",
          "cta_label": "Sign up with Northline",
          "redemption_mode": "external_link",
          "destination_url": "https://getoutly.app/partners/northline",
          "claim_duration_seconds": 1800,
          "presentation_kind": "partner",
          "sponsor_display_name": "Northline",
          "sponsor_logo_storage_path": "partners/northline/logo.svg",
          "sponsor_disclosure": "Outly partner",
          "discovery_treatment": "partner_featured",
          "discovery_badge_label": "Partner offer",
          "discovery_icon_key": "northline-mark"
        }
        """#.data(using: .utf8)!

        let payload = try JSONDecoder().decode(OfferContractPayload.self, from: json)
        let offer = try payload.venueOffer()

        XCTAssertEqual(offer.kind, .partner)
        XCTAssertEqual(offer.redemptionMode, .externalLink)
        XCTAssertEqual(offer.claimDurationSeconds, 1_800)
        XCTAssertEqual(offer.discoveryTreatment, .partnerFeatured)
        XCTAssertEqual(offer.sponsor?.displayName, "Northline")
        XCTAssertEqual(offer.destinationURL?.scheme, "https")
    }

    func testResetReturnsToFirstLaunch() {
        let store = DemoStore(defaults: defaults, storageKey: "state")
        store.go(to: .main)
        store.confirmPlan(for: "lavelle")
        store.checkIn(to: "lavelle")

        store.resetDemo()

        XCTAssertEqual(store.state, DemoState())
        XCTAssertNil(store.plan)
        XCTAssertNil(store.checkedInVenue)
    }

    func testAuthenticationIntentSeparatesSignUpAndLogin() {
        let store = DemoStore(defaults: defaults, storageKey: "state")

        store.beginAuthentication(.signUp)
        XCTAssertEqual(store.state.onboardingStage, .auth)
        XCTAssertEqual(store.authIntent, .signUp)

        store.beginAuthentication(.logIn)
        store.completeLogin()
        XCTAssertEqual(store.state.onboardingStage, .main)
        XCTAssertEqual(store.profile.firstName, "Liam")
    }

    func testDemoAuthenticationSupportsFacebook() async throws {
        let userID = try await AppServices.demo.authenticate(.facebook)

        XCTAssertEqual(userID, "demo-facebook-user")
        XCTAssertEqual(AuthProvider.facebook.title, "Facebook")
    }

    func testDemoAuthenticationSupportsApple() async throws {
        let userID = try await AppServices.demo.authenticate(.apple)

        XCTAssertEqual(userID, "demo-apple-user")
        XCTAssertEqual(AuthProvider.apple.title, "Apple")
    }

    func testActivePresenceRequiresTimestampAndExpiresAfterTwelveHours() throws {
        let checkedInAt = Date(timeIntervalSince1970: 1_721_000_500)
        let store = DemoStore(defaults: defaults, storageKey: "state")
        store.checkIn(to: "track-field", now: checkedInAt)

        XCTAssertTrue(store.isCheckedIn(to: "track-field", at: checkedInAt))
        XCTAssertTrue(store.isCheckedIn(
            to: "track-field",
            at: checkedInAt.addingTimeInterval(DemoStore.activePresenceDuration - 1)
        ))
        XCTAssertFalse(store.isCheckedIn(
            to: "track-field",
            at: checkedInAt.addingTimeInterval(DemoStore.activePresenceDuration)
        ))
        XCTAssertFalse(store.isCheckedIn(to: "lavelle", at: checkedInAt))

        let legacyJSON = """
        {
          "onboardingStage": "main",
          "selectedVenueID": "track-field",
          "checkedInVenueID": "track-field"
        }
        """.data(using: .utf8)!
        let legacyState = try JSONDecoder().decode(DemoState.self, from: legacyJSON)
        let legacyStore = DemoStore(previewState: legacyState)

        XCTAssertEqual(legacyStore.lastCheckedInVenue?.id, "track-field")
        XCTAssertNil(legacyStore.checkedInAt)
        XCTAssertNil(legacyStore.activeCheckedInVenue(at: checkedInAt))
    }

    func testReturnToExploreClearsEveryTabPath() {
        let router = AppRouter()
        router.explorePath = [.venueDetail("track-field")]
        router.listPath = [.rsvpReview("lavelle")]
        router.profilePath = [.checkInIntro("baro")]
        router.selectedTab = .profile

        router.returnToExplore()

        XCTAssertEqual(router.selectedTab, .explore)
        XCTAssertTrue(router.explorePath.isEmpty)
        XCTAssertTrue(router.listPath.isEmpty)
        XCTAssertTrue(router.profilePath.isEmpty)
    }

    func testLegacyNightPlanJSONIgnoresRemovedPlanningFields() throws {
        let legacyJSON = """
        {
          "venueID": "track-field",
          "arrivalWindow": "10:00–11:00 PM",
          "groupSize": 3,
          "dateLabel": "Tonight"
        }
        """.data(using: .utf8)!

        let plan = try JSONDecoder().decode(NightPlan.self, from: legacyJSON)

        XCTAssertEqual(plan.venueID, "track-field")
        XCTAssertEqual(plan.dateLabel, "Tonight")
    }

    func testReplacingCurrentRouteDoesNotLeaveCheckInBehind() {
        let router = AppRouter()
        router.explorePath = [.venueDetail("track-field"), .checkInIntro("track-field")]

        router.replaceCurrent(with: .offer("track-field"))

        XCTAssertEqual(
            router.explorePath,
            [.venueDetail("track-field"), .offer("track-field")]
        )
    }

    func testVenueGeofenceAcceptsVenueAndRejectsDistantLocation() {
        let venue = VenueCatalog.venue(id: "track-field")
        let venueCenter = CLLocation(latitude: venue.latitude, longitude: venue.longitude)
        let distantLocation = CLLocation(latitude: 43.6532, longitude: -79.3832)

        XCTAssertTrue(VenueGeofence.contains(venueCenter, venue: venue))
        XCTAssertFalse(VenueGeofence.contains(distantLocation, venue: venue))
    }

    func testVenueGeofenceRejectsAdjacentVenueAndAmbiguousMidpoint() {
        let baro = VenueCatalog.venue(id: "baro")
        let parisTexas = VenueCatalog.venue(id: "paris-texas")
        let baroCenter = CLLocation(latitude: baro.latitude, longitude: baro.longitude)
        let parisTexasCenter = CLLocation(latitude: parisTexas.latitude, longitude: parisTexas.longitude)
        let midpoint = CLLocation(
            latitude: (baro.latitude + parisTexas.latitude) / 2,
            longitude: (baro.longitude + parisTexas.longitude) / 2
        )

        XCTAssertTrue(VenueGeofence.contains(baroCenter, venue: baro))
        XCTAssertFalse(VenueGeofence.contains(baroCenter, venue: parisTexas))
        XCTAssertTrue(VenueGeofence.contains(parisTexasCenter, venue: parisTexas))
        XCTAssertFalse(VenueGeofence.contains(parisTexasCenter, venue: baro))
        XCTAssertFalse(VenueGeofence.contains(midpoint, venue: baro))
        XCTAssertFalse(VenueGeofence.contains(midpoint, venue: parisTexas))
    }

    func testVenueGeofenceRejectsStaleLocationSamples() {
        let venue = VenueCatalog.venue(id: "track-field")
        let now = Date(timeIntervalSince1970: 1_721_000_500)
        let fresh = CLLocation(
            coordinate: venue.coordinate,
            altitude: 0,
            horizontalAccuracy: 20,
            verticalAccuracy: 20,
            timestamp: now.addingTimeInterval(-VenueGeofence.maximumLocationAge)
        )
        let stale = CLLocation(
            coordinate: venue.coordinate,
            altitude: 0,
            horizontalAccuracy: 20,
            verticalAccuracy: 20,
            timestamp: now.addingTimeInterval(-VenueGeofence.maximumLocationAge - 0.1)
        )

        XCTAssertTrue(VenueGeofence.isFresh(fresh, now: now))
        XCTAssertFalse(VenueGeofence.isFresh(stale, now: now))
        XCTAssertEqual(VenueGeofence.maximumAcceptedAccuracy, 75)
    }

    func testVenueGeofenceRejectsFutureLocationSamples() {
        let now = Date(timeIntervalSince1970: 1_721_000_500)
        let futureLocation = CLLocation(
            coordinate: VenueCatalog.venue(id: "track-field").coordinate,
            altitude: 0,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            timestamp: now.addingTimeInterval(1)
        )

        XCTAssertFalse(VenueGeofence.isFresh(futureLocation, now: now))
    }

    func testVenueMapPinAssetsAreBundled() {
        let expectedAssets = [
            "track-field": "VenuePinTrackField",
            "lavelle": "VenuePinLavelle",
            "baro": "VenuePinBaro",
            "paris-texas": "VenuePinParisTexas",
        ]

        for venue in VenueCatalog.venues {
            let assetName = venue.mapMarkerAssetName

            XCTAssertEqual(assetName, expectedAssets[venue.id])
            guard let assetName else { continue }
            XCTAssertNotNil(UIImage(named: assetName), "Missing map marker asset: \(assetName)")
        }
    }

    func testVenueMapLinksContainVenueNameAndCoordinates() throws {
        for venue in VenueCatalog.venues {
            let components = try XCTUnwrap(URLComponents(url: venue.appleMapsURL, resolvingAgainstBaseURL: false))
            let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })

            XCTAssertEqual(components.scheme, "https")
            XCTAssertEqual(components.host, "maps.apple.com")
            XCTAssertEqual(query["q"] ?? nil, venue.name)
            XCTAssertEqual(query["ll"] ?? nil, "\(venue.latitude),\(venue.longitude)")
        }
    }
}
