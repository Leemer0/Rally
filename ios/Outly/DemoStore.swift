import Foundation
import Observation

enum AuthIntent: Equatable, Identifiable, Sendable {
    case signUp
    case logIn

    var id: String {
        switch self {
        case .signUp: "sign-up"
        case .logIn: "log-in"
        }
    }
}

@MainActor
@Observable
final class DemoStore {
    nonisolated static let activePresenceDuration: TimeInterval = 12 * 60 * 60

    private(set) var state: DemoState {
        didSet { persist() }
    }

    var authIntent: AuthIntent = .signUp
    private(set) var venues: [Venue]

    private let defaults: UserDefaults
    private let storageKey: String
    private let allowsFixtures: Bool

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = "outly.demo.state.v1",
        resetOnLaunch: Bool = false,
        allowsFixtures: Bool = true
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.allowsFixtures = allowsFixtures
        venues = allowsFixtures ? VenueCatalog.venues : []

        if resetOnLaunch {
            defaults.removeObject(forKey: storageKey)
        }

        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(DemoState.self, from: data)
        {
            state = decoded
        } else {
            state = DemoState()
        }
    }

    init(previewState: DemoState) {
        defaults = UserDefaults(suiteName: "outly.preview.\(UUID().uuidString)") ?? .standard
        storageKey = "preview"
        allowsFixtures = true
        state = previewState
        venues = VenueCatalog.venues
    }

    var profile: UserProfile { state.profile }
    var plan: NightPlan? { state.plan }
    var selectedVenue: Venue { venue(id: state.selectedVenueID) }
    var checkedInAt: Date? { state.checkedInAt }
    var lastCheckedInVenue: Venue? { state.checkedInVenueID.map(venue(id:)) }
    var checkedInVenue: Venue? { activeCheckedInVenue() }

    func activeCheckedInVenue(at now: Date = Date()) -> Venue? {
        guard isCheckedIn(to: state.checkedInVenueID, at: now) else { return nil }
        return lastCheckedInVenue
    }

    func isCheckedIn(to venueID: String?, at now: Date = Date()) -> Bool {
        guard let venueID,
              state.checkedInVenueID == venueID,
              let checkedInAt = state.checkedInAt
        else {
            return false
        }

        let elapsed = now.timeIntervalSince(checkedInAt)
        return elapsed >= 0 && elapsed < Self.activePresenceDuration
    }

    func checkInStatusText(at now: Date = Date()) -> String? {
        guard let checkedInAt = state.checkedInAt else { return nil }

        let elapsed = max(0, now.timeIntervalSince(checkedInAt))
        switch elapsed {
        case ..<60:
            return "Checked in just now"
        case ..<3600:
            let minutes = max(1, Int(elapsed / 60))
            return "Checked in \(minutes) \(minutes == 1 ? "minute" : "minutes") ago"
        case ..<86400:
            let hours = max(1, Int(elapsed / 3600))
            return "Checked in \(hours) \(hours == 1 ? "hour" : "hours") ago"
        default:
            let days = max(1, Int(elapsed / 86400))
            return "Checked in \(days) \(days == 1 ? "day" : "days") ago"
        }
    }

    func go(to stage: OnboardingStage) {
        state.onboardingStage = stage
    }

    func beginAuthentication(_ intent: AuthIntent) {
        authIntent = intent
        state.onboardingStage = .auth
    }

    func completeLogin() {
        if state.profile.firstName.isEmpty {
            state.profile.firstName = "Liam"
        }
        state.onboardingStage = .main
    }

    func setFirstName(_ value: String) {
        state.profile.firstName = String(value.prefix(40))
    }

    @discardableResult
    func submitName() -> Bool {
        let trimmed = state.profile.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        state.profile.firstName = trimmed
        state.onboardingStage = .age
        return true
    }

    func setAge(_ age: Int) {
        state.profile.age = max(19, age)
    }

    func setDateOfBirth(_ date: Date) {
        state.profile.dateOfBirth = date
        state.profile.age = max(
            0,
            Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0
        )
    }

    func setGender(_ gender: UserGender) {
        state.profile.gender = gender
    }

    func finishOnboarding() {
        state.onboardingStage = .main
    }

    func selectVenue(_ venueID: String) {
        state.selectedVenueID = venueID
    }

    func hasVenue(id: String) -> Bool {
        venues.contains(where: { $0.id == id })
    }

    func venue(id: String) -> Venue {
        venues.first(where: { $0.id == id })
            ?? (allowsFixtures ? VenueCatalog.venues.first(where: { $0.id == id }) : nil)
            ?? Venue.unavailable(id: id)
    }

    func applyConsumerBootstrap(_ bootstrap: ConsumerBootstrap) {
        venues = bootstrap.venues
        state.profile.firstName = bootstrap.profileFirstName
        state.plan = bootstrap.plan
        state.checkedInID = bootstrap.checkedInID
        state.checkedInVenueID = bootstrap.checkedInVenueID
        state.checkedInAt = bootstrap.checkedInAt
        state.offerWindows.removeAll()
        state.offerEntitlementEndsAt.removeAll()
        state.claimedOffers.removeAll()

        if let venueID = bootstrap.activeOfferVenueID,
           let window = bootstrap.activeOfferWindow,
           let offer = bootstrap.activeOffer
        {
            state.offerWindows[venueID] = window
            state.claimedOffers[venueID] = offer
            if let entitlementEndsAt = bootstrap.offerEntitlementEndsAt {
                state.offerEntitlementEndsAt[venueID] = entitlementEndsAt
            }
        }

        if let checkedInVenueID = bootstrap.checkedInVenueID {
            state.selectedVenueID = checkedInVenueID
        } else if !venues.contains(where: { $0.id == state.selectedVenueID }) {
            state.selectedVenueID = bootstrap.plan?.venueID ?? venues.first?.id ?? state.selectedVenueID
        }
        state.onboardingStage = .main
    }

    func applyServerPlan(_ plan: NightPlan) {
        state.selectedVenueID = plan.venueID
        state.plan = plan
        HapticManager.shared.success(enabled: state.hapticsEnabled)
    }

    func applyServerCheckIn(_ result: ServerCheckInResult) {
        state.selectedVenueID = result.venueID
        state.checkedInID = result.checkInID
        state.checkedInVenueID = result.venueID
        state.checkedInAt = result.checkedInAt
        state.offerWindows.removeAll()
        state.offerEntitlementEndsAt.removeAll()
        state.claimedOffers.removeAll()
        if let offer = result.offer, let window = result.offerWindow {
            state.claimedOffers[result.venueID] = offer
            state.offerWindows[result.venueID] = window
        }
        if let entitlementEndsAt = result.entitlementEndsAt {
            state.offerEntitlementEndsAt[result.venueID] = entitlementEndsAt
        }
        HapticManager.shared.success(enabled: state.hapticsEnabled)
    }

    func signOutLocally() {
        state = DemoState()
        venues = allowsFixtures ? VenueCatalog.venues : []
    }

    func preparePlan(for venueID: String) {
        state.selectedVenueID = venueID
    }

    func confirmPlan(for venueID: String, now: Date = Date()) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_CA")
        formatter.dateFormat = "MMMM d"
        state.selectedVenueID = venueID
        state.plan = NightPlan(
            venueID: venueID,
            dateLabel: "Tonight · \(formatter.string(from: now))"
        )
        HapticManager.shared.success(enabled: state.hapticsEnabled)
    }

    func cancelPlan() {
        state.plan = nil
    }

    func checkIn(to venueID: String, now: Date = Date()) {
        let venue = venue(id: venueID)
        state.selectedVenueID = venueID
        state.checkedInID = "demo-\(UUID().uuidString.lowercased())"
        state.checkedInVenueID = venueID
        state.checkedInAt = now
        state.offerWindows.removeAll()
        state.offerEntitlementEndsAt.removeAll()
        state.claimedOffers.removeAll()
        if let offer = venue.offer {
            state.offerWindows[venueID] = TimedOfferWindow(
                unlockedAt: now,
                duration: offer.claimDurationSeconds.map(TimeInterval.init)
            )
            state.claimedOffers[venueID] = offer
        }
        HapticManager.shared.success(enabled: state.hapticsEnabled)
    }

    func offerWindow(at venueID: String) -> TimedOfferWindow? {
        state.offerWindows[venueID]
    }

    /// Timed offers never advertise more time than the verified venue presence.
    /// An offer with no countdown stays visually open-ended while its internal
    /// entitlement still ends with that presence.
    func offerPresentationWindow(at venueID: String) -> TimedOfferWindow? {
        guard let window = state.offerWindows[venueID] else { return nil }
        guard window.hasCountdown,
              let effectiveEnd = offerPresentationEndsAt(venueID)
        else {
            return window
        }

        return TimedOfferWindow(
            unlockedAt: window.unlockedAt,
            duration: max(0, effectiveEnd.timeIntervalSince(window.unlockedAt))
        )
    }

    func claimedOffer(at venueID: String) -> VenueOffer? {
        if let snapshot = state.claimedOffers[venueID] { return snapshot }
        guard state.offerWindows[venueID] != nil else { return nil }
        return venue(id: venueID).offer
    }

    /// The local prototype keeps a verified venue presence for twelve hours.
    /// A claim may expire sooner, but no offer surface should outlive that
    /// presence. The server will ultimately return this effective end state.
    func offerPresentationEndsAt(_ venueID: String) -> Date? {
        guard state.checkedInVenueID == venueID,
              let checkedInAt = state.checkedInAt,
              let window = state.offerWindows[venueID]
        else {
            return nil
        }

        let presenceEndsAt = state.offerEntitlementEndsAt[venueID]
            ?? checkedInAt.addingTimeInterval(Self.activePresenceDuration)
        guard let claimExpiresAt = window.expiresAt else { return presenceEndsAt }
        return min(claimExpiresAt, presenceEndsAt)
    }

    func isOfferActive(at venueID: String, now: Date = Date()) -> Bool {
        guard isCheckedIn(to: venueID, at: now),
              state.offerWindows[venueID]?.isActive(at: now) == true,
              let effectiveEnd = offerPresentationEndsAt(venueID)
        else {
            return false
        }

        return now < effectiveEnd
    }

    func setHapticsEnabled(_ enabled: Bool) {
        state.hapticsEnabled = enabled
    }

    func resetDemo() {
        defaults.removeObject(forKey: storageKey)
        state = DemoState()
        venues = allowsFixtures ? VenueCatalog.venues : []
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
