import XCTest

final class OutlyUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--reset-demo", "--use-demo-services"]
        app.launch()
    }

    func testCompleteNightOutJourney() {
        app.buttons["sign-up"].tap()
        app.buttons["auth-email"].tap()

        let nameField = app.textFields["first-name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Liam")
        app.buttons["onboarding-next"].tap()
        app.buttons["onboarding-next"].tap()
        app.buttons["explore-toronto"].tap()

        let planButton = app.buttons["im-going"]
        XCTAssertTrue(planButton.waitForExistence(timeout: 6))
        planButton.tap()
        XCTAssertTrue(app.buttons["confirm-plan"].waitForExistence(timeout: 3))
        app.buttons["confirm-plan"].tap()

        XCTAssertTrue(app.staticTexts["plan-confirmed"].waitForExistence(timeout: 3))
        app.buttons["at-venue"].tap()

        XCTAssertTrue(app.staticTexts["offer-countdown"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["back-to-explore"].waitForExistence(timeout: 3))
        app.buttons["back-to-explore"].tap()
        let pinnedCheckIn = app.buttons["map-active-checkin"]
        XCTAssertTrue(pinnedCheckIn.waitForExistence(timeout: 6), app.debugDescription)
        XCTAssertTrue(app.staticTexts["map-offer-countdown"].exists)

        app.tabBars.buttons["Venues"].tap()
        XCTAssertTrue(app.staticTexts["venue-list-title"].waitForExistence(timeout: 3))
        app.buttons["open-filters"].tap()
        app.buttons["Has offer"].tap()
        app.buttons["show-filtered-venues"].tap()

        app.tabBars.buttons["Profile"].tap()
        let latestCheckIn = app.descendants(matching: .any)["latest-check-in"]
        XCTAssertTrue(latestCheckIn.waitForExistence(timeout: 3))
        XCTAssertTrue(latestCheckIn.label.contains("Checked in"))
        XCTAssertTrue(app.staticTexts["Track & Field"].exists)
    }

    func testActiveOfferFixture() {
        relaunch(screen: "offer")

        XCTAssertTrue(app.otherElements["active-offer-pass"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Track & Field"].exists)
        XCTAssertTrue(app.staticTexts["50% off your first drink"].exists)

        let countdown = app.staticTexts["offer-countdown"]
        XCTAssertTrue(countdown.waitForExistence(timeout: 3))
        XCTAssertTrue(countdown.label.contains("remaining"))
        XCTAssertTrue(app.buttons["back-to-explore"].exists)
        XCTAssertFalse(app.otherElements["expired-offer-pass"].exists)
    }

    func testVenueDetailShowsAddressLink() {
        relaunch(screen: "venue-detail")

        let addressLink = app.descendants(matching: .any)["venue-address"]
        XCTAssertTrue(addressLink.waitForExistence(timeout: 3))
        XCTAssertTrue(addressLink.label.contains("860 College St"))
        XCTAssertTrue(addressLink.label.contains("open in Maps"))
        XCTAssertTrue(app.staticTexts["Ossington"].exists)
        XCTAssertTrue(app.staticTexts["Open 5:00 PM–2:00 AM"].exists)
        XCTAssertTrue(app.staticTexts["Tonight’s crowd"].exists)
        XCTAssertTrue(app.staticTexts["46 going"].exists)
        XCTAssertFalse(app.staticTexts["Peak"].exists)
        XCTAssertFalse(app.staticTexts["1.2 km"].exists)
        XCTAssertFalse(app.staticTexts["Games Bar"].exists)
        XCTAssertFalse(app.staticTexts["Live estimate"].exists)
    }

    func testLocationConfirmedFixture() {
        relaunch(screen: "checkin-confirmed")

        let confirmed = app.descendants(matching: .any)["location-confirmed"]
        XCTAssertTrue(confirmed.waitForExistence(timeout: 3))
        XCTAssertTrue(confirmed.label.contains("Track & Field"))
    }

    func testLocationVerifyingFixture() {
        relaunch(screen: "checkin-verifying")

        let confirming = app.descendants(matching: .any)["location-confirming"]
        XCTAssertTrue(confirming.waitForExistence(timeout: 3))
        XCTAssertTrue(confirming.label.contains("Track & Field"))
        XCTAssertFalse(app.descendants(matching: .any)["checkin-verifying-inline"].exists)
    }

    func testExpiredOfferFixture() {
        relaunch(screen: "offer-expired")

        XCTAssertTrue(app.otherElements["expired-offer-pass"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Offer expired"].exists)
        XCTAssertFalse(app.staticTexts["offer-countdown"].exists)
        XCTAssertTrue(app.buttons["back-to-explore"].exists)
        XCTAssertFalse(app.otherElements["active-offer-pass"].exists)
    }

    func testInlineCheckInFailureFixture() {
        relaunch(screen: "checkin-failed")

        let failureTitle = app.descendants(matching: .any)["location-failed"]
        XCTAssertTrue(failureTitle.waitForExistence(timeout: 3))
        XCTAssertEqual(
            failureTitle.frame.midX,
            app.windows.firstMatch.frame.midX,
            accuracy: 2,
            "The failed-location status should remain horizontally centered."
        )
        XCTAssertTrue(app.descendants(matching: .any)["checkin-error"].exists)
        XCTAssertTrue(app.buttons["retry-checkin"].exists)
        XCTAssertFalse(app.otherElements["active-offer-pass"].exists)
    }

    func testMapKeepsActiveCheckInPinned() {
        relaunch(screen: "explore-offer")

        let preview = app.descendants(matching: .any)["venue-preview-card"]
        XCTAssertTrue(preview.waitForExistence(timeout: 3))
        tapBareMap()
        XCTAssertTrue(preview.waitForNonExistence(timeout: 3))

        XCTAssertTrue(app.buttons["map-active-checkin"].exists)
        XCTAssertTrue(app.staticTexts["map-offer-countdown"].exists)
    }

    func testMapBackgroundDismissesVenuePreviewAndMarkerRestoresIt() {
        relaunch(screen: "explore")

        let preview = app.descendants(matching: .any)["venue-preview-card"]
        XCTAssertTrue(preview.waitForExistence(timeout: 3))

        tapBareMap()
        XCTAssertTrue(preview.waitForNonExistence(timeout: 3))

        let marker = app.buttons["venue-marker-track-field"]
        XCTAssertTrue(marker.waitForExistence(timeout: 3))
        marker.tap()
        XCTAssertTrue(preview.waitForExistence(timeout: 3))
    }

    private func tapBareMap() {
        let map = app.descendants(matching: .any)["toronto-map"]
        XCTAssertTrue(map.waitForExistence(timeout: 3))
        map.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.52)).tap()
    }

    private func relaunch(screen: String) {
        app.terminate()
        app = XCUIApplication()
        app.launchArguments = ["--reset-demo", "--use-demo-services", "--screen=\(screen)"]
        app.launch()
    }
}
