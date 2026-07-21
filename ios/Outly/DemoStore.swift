import Foundation
import Observation

enum AuthIntent: Equatable {
    case signUp
    case logIn
}

@MainActor
@Observable
final class DemoStore {
    nonisolated static let activePresenceDuration: TimeInterval = 12 * 60 * 60

    private(set) var state: DemoState {
        didSet { persist() }
    }

    var authIntent: AuthIntent = .signUp

    private let defaults: UserDefaults
    private let storageKey: String

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = "outly.demo.state.v1",
        resetOnLaunch: Bool = false
    ) {
        self.defaults = defaults
        self.storageKey = storageKey

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
        state = previewState
    }

    var profile: UserProfile { state.profile }
    var plan: NightPlan? { state.plan }
    var selectedVenue: Venue { VenueCatalog.venue(id: state.selectedVenueID) }
    var checkedInAt: Date? { state.checkedInAt }
    var lastCheckedInVenue: Venue? { state.checkedInVenueID.map(VenueCatalog.venue(id:)) }
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

    func finishOnboarding() {
        state.onboardingStage = .main
    }

    func selectVenue(_ venueID: String) {
        state.selectedVenueID = venueID
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
        let venue = VenueCatalog.venue(id: venueID)
        state.selectedVenueID = venueID
        state.checkedInVenueID = venueID
        state.checkedInAt = now
        state.offerWindows.removeAll()
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
        return VenueCatalog.venue(id: venueID).offer
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

        let presenceEndsAt = checkedInAt.addingTimeInterval(Self.activePresenceDuration)
        guard let claimExpiresAt = window.expiresAt else { return presenceEndsAt }
        return min(claimExpiresAt, presenceEndsAt)
    }

    func isOfferActive(at venueID: String, now: Date = Date()) -> Bool {
        isCheckedIn(to: venueID, at: now)
            && state.offerWindows[venueID]?.isActive(at: now) == true
    }

    func setHapticsEnabled(_ enabled: Bool) {
        state.hapticsEnabled = enabled
    }

    func resetDemo() {
        defaults.removeObject(forKey: storageKey)
        state = DemoState()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
