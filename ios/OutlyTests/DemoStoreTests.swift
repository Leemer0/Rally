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

    func testProfileValidationAndBounds() {
        let store = DemoStore(defaults: defaults, storageKey: "state")

        XCTAssertFalse(store.submitName())
        store.setFirstName("  Liam  ")
        XCTAssertTrue(store.submitName())
        XCTAssertEqual(store.profile.firstName, "Liam")
        XCTAssertEqual(store.state.onboardingStage, .age)

        store.setAge(99)
        XCTAssertEqual(store.profile.age, 40)
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

    func testAverageCheckInTimeHandlesMidnightAndEmptyHistory() {
        let aroundMidnight = [
            NightCheckInSample(hour: 23, minute: 30),
            NightCheckInSample(hour: 0, minute: 30),
        ]

        XCTAssertEqual(AverageCheckInTime.minuteOfDay(for: aroundMidnight), 0)
        XCTAssertEqual(AverageCheckInTime.displayTime(for: aroundMidnight), "12:00 AM")
        XCTAssertNil(AverageCheckInTime.minuteOfDay(for: []))
        XCTAssertNil(AverageCheckInTime.displayTime(for: []))
    }

    func testCatalogPeakTimesAreDerivedFromCheckInAverages() {
        let expected = [
            "track-field": "10:30 PM",
            "lavelle": "11:00 PM",
            "baro": "9:30 PM",
            "paris-texas": "11:30 PM",
        ]

        for venue in VenueCatalog.venues {
            XCTAssertFalse(venue.historicalCheckIns.isEmpty)
            XCTAssertEqual(venue.expectedPeakTime, expected[venue.id])
        }
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
}
