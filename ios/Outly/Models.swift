import CoreLocation
import Foundation

enum AuthProvider: String, Codable, Sendable {
    case email
    case google

    var title: String {
        switch self {
        case .email: "Email"
        case .google: "Google"
        }
    }
}

enum GenderIdentity: String, Codable, CaseIterable, Identifiable, Sendable {
    case woman
    case man
    case nonBinary
    case selfDescribe
    case preferNotToSay

    var id: Self { self }

    var title: String {
        switch self {
        case .woman: "Woman"
        case .man: "Man"
        case .nonBinary: "Non-binary"
        case .selfDescribe: "Prefer to self-describe"
        case .preferNotToSay: "Prefer not to say"
        }
    }
}

enum InterestedIn: String, Codable, CaseIterable, Identifiable, Sendable {
    case women
    case men
    case everyone

    var id: Self { self }

    var title: String {
        switch self {
        case .women: "Women"
        case .men: "Men"
        case .everyone: "Everyone"
        }
    }
}

enum OnboardingStage: String, Codable, Sendable {
    case welcome
    case auth
    case name
    case age
    case gender
    case interested
    case complete
    case main
}

enum VenueActivity: String, Codable, Sendable {
    case low
    case building
    case busy
    case peak
}

struct AgeDistributionPoint: Codable, Hashable, Sendable {
    let age: Int
    let intensity: Double
}

struct AgeDistribution: Codable, Hashable, Sendable {
    let peakAge: Int?
    let points: [AgeDistributionPoint]

    var hasEnoughData: Bool { peakAge != nil && !points.isEmpty }

    var averageAge: Int? {
        guard hasEnoughData else { return nil }
        let totalWeight = points.reduce(0) { $0 + max($1.intensity, 0) }
        guard totalWeight > 0 else { return nil }

        let weightedAge = points.reduce(0) { partialResult, point in
            partialResult + (Double(point.age) * max(point.intensity, 0))
        }
        return Int((weightedAge / totalWeight).rounded())
    }
}

struct GenderMix: Codable, Hashable, Sendable {
    let menPercentage: Int
    let womenPercentage: Int

    var accessibilitySummary: String {
        "Gender mix: \(menPercentage) percent men and \(womenPercentage) percent women"
    }
}

/// A venue's anonymized historical check-in time, normalized against a
/// nightlife day that begins at 6 PM. Keeping the offset across midnight
/// prevents 11:30 PM and 12:30 AM from incorrectly averaging to noon.
struct NightCheckInSample: Codable, Hashable, Sendable {
    let minutesAfterSixPM: Int

    init(hour: Int, minute: Int) {
        let minuteOfDay = (hour * 60) + minute
        let sixPM = 18 * 60
        minutesAfterSixPM = minuteOfDay >= sixPM
            ? minuteOfDay - sixPM
            : minuteOfDay + (24 * 60) - sixPM
    }
}

enum AverageCheckInTime {
    private static let sixPM = 18 * 60

    static func minuteOfDay(for samples: [NightCheckInSample]) -> Int? {
        guard !samples.isEmpty else { return nil }

        let mean = Double(samples.reduce(0) { $0 + $1.minutesAfterSixPM })
            / Double(samples.count)
        let roundedToFiveMinutes = Int((mean / 5).rounded()) * 5
        return (sixPM + roundedToFiveMinutes) % (24 * 60)
    }

    static func displayTime(for samples: [NightCheckInSample]) -> String? {
        guard let minuteOfDay = minuteOfDay(for: samples) else { return nil }

        let hour24 = minuteOfDay / 60
        let minute = minuteOfDay % 60
        let hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12
        return String(format: "%d:%02d %@", hour12, minute, hour24 < 12 ? "AM" : "PM")
    }
}

struct Venue: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let neighbourhood: String
    let category: String
    let hours: String
    let address: String
    let goingCount: Int
    let verifiedCount: Int
    let historicalCheckIns: [NightCheckInSample]
    let offer: String?
    let offerDetails: String?
    let description: String
    let activity: VenueActivity
    let latitude: Double
    let longitude: Double
    let ageDistribution: AgeDistribution
    let genderMix: GenderMix
    let distance: String

    /// The prototype derives this crowd estimate from anonymized fixture
    /// history. Production should supply the equivalent aggregate metric.
    var expectedPeakTime: String {
        AverageCheckInTime.displayTime(for: historicalCheckIns) ?? "Not enough data"
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum VenueCatalog {
    static let venues: [Venue] = [
        Venue(
            id: "track-field",
            name: "Track & Field",
            neighbourhood: "Ossington",
            category: "Games Bar",
            hours: "Open 5:00 PM–2:00 AM",
            address: "860 College St, Toronto",
            goingCount: 46,
            verifiedCount: 14,
            historicalCheckIns: checkIns(
                hours: [22, 22, 22, 22, 23],
                minutes: [0, 15, 30, 45, 0]
            ),
            offer: "50% off your first drink",
            offerDetails: "Valid on one house drink. One offer per verified check-in.",
            description: "Shuffleboard, bocce, and a lively social room.",
            activity: .peak,
            latitude: 43.6549,
            longitude: -79.4238,
            ageDistribution: distribution(peakAge: 27, spread: 3.4),
            genderMix: GenderMix(menPercentage: 44, womenPercentage: 56),
            distance: "1.2 km"
        ),
        Venue(
            id: "lavelle",
            name: "Lavelle",
            neighbourhood: "King West",
            category: "Rooftop Lounge",
            hours: "Open until 2:00 AM",
            address: "627 King St W, Toronto",
            goingCount: 38,
            verifiedCount: 9,
            historicalCheckIns: checkIns(
                hours: [22, 22, 23, 23, 23],
                minutes: [30, 45, 0, 15, 30]
            ),
            offer: "Welcome drink before 10:30 PM",
            offerDetails: "One house welcome drink after a verified check-in.",
            description: "A rooftop escape with a high-energy room, skyline views, and a late-night crowd.",
            activity: .busy,
            latitude: 43.6447,
            longitude: -79.3997,
            ageDistribution: distribution(peakAge: 29, spread: 4.2),
            genderMix: GenderMix(menPercentage: 48, womenPercentage: 52),
            distance: "800 m"
        ),
        Venue(
            id: "baro",
            name: "Baro",
            neighbourhood: "King West",
            category: "Latin Restaurant & Bar",
            hours: "Open 5:00 PM–2:00 AM",
            address: "485 King St W, Toronto",
            goingCount: 24,
            verifiedCount: 6,
            historicalCheckIns: checkIns(
                hours: [21, 21, 21, 21, 22],
                minutes: [0, 15, 30, 45, 0]
            ),
            offer: nil,
            offerDetails: nil,
            description: "A warm multi-level space for dinner that rolls naturally into drinks and dancing.",
            activity: .building,
            latitude: 43.6442,
            longitude: -79.3963,
            ageDistribution: distribution(peakAge: 31, spread: 4.8),
            genderMix: GenderMix(menPercentage: 52, womenPercentage: 48),
            distance: "650 m"
        ),
        Venue(
            id: "paris-texas",
            name: "Paris Texas",
            neighbourhood: "King West",
            category: "Dance Bar",
            hours: "Opening at 8:00 PM",
            address: "461 King St W, Toronto",
            goingCount: 17,
            verifiedCount: 0,
            historicalCheckIns: checkIns(
                hours: [23, 23, 23, 23, 0],
                minutes: [0, 15, 30, 45, 0]
            ),
            offer: "Free coat check",
            offerDetails: "Complimentary coat check with a verified check-in.",
            description: "A western-inspired party bar with DJs, dancing, and a playful late-night atmosphere.",
            activity: .low,
            latitude: 43.6441,
            longitude: -79.3955,
            ageDistribution: AgeDistribution(peakAge: nil, points: []),
            genderMix: GenderMix(menPercentage: 55, womenPercentage: 45),
            distance: "500 m"
        ),
    ]

    static func venue(id: String) -> Venue {
        venues.first(where: { $0.id == id }) ?? venues[0]
    }

    private static func distribution(peakAge: Int, spread: Double) -> AgeDistribution {
        let points = (19 ... 40).map { age in
            let distance = Double(age - peakAge)
            let intensity = exp(-(distance * distance) / (2 * spread * spread))
            return AgeDistributionPoint(age: age, intensity: intensity)
        }
        return AgeDistribution(peakAge: peakAge, points: points)
    }

    private static func checkIns(hours: [Int], minutes: [Int]) -> [NightCheckInSample] {
        zip(hours, minutes).map { NightCheckInSample(hour: $0, minute: $1) }
    }
}

struct UserProfile: Codable, Hashable, Sendable {
    var firstName = ""
    var age = 25
    var genderIdentity: GenderIdentity?
    var genderSelfDescription = ""
    var interestedIn: [InterestedIn] = []
}

struct NightPlan: Codable, Hashable, Sendable {
    let venueID: String
    let dateLabel: String
}

struct TimedOfferWindow: Codable, Hashable, Sendable {
    static let duration: TimeInterval = 10 * 60

    let unlockedAt: Date
    let expiresAt: Date

    init(unlockedAt: Date, duration: TimeInterval = Self.duration) {
        self.unlockedAt = unlockedAt
        expiresAt = unlockedAt.addingTimeInterval(duration)
    }

    func isActive(at date: Date) -> Bool {
        date >= unlockedAt && date < expiresAt
    }

    func remainingSeconds(at date: Date) -> Int {
        max(0, Int(ceil(expiresAt.timeIntervalSince(date))))
    }

    var totalDuration: TimeInterval {
        max(0, expiresAt.timeIntervalSince(unlockedAt))
    }

    func remainingFraction(at date: Date) -> Double {
        guard totalDuration > 0 else { return 0 }

        return min(1, max(0, expiresAt.timeIntervalSince(date) / totalDuration))
    }
}

struct DemoState: Codable, Hashable, Sendable {
    var onboardingStage: OnboardingStage = .welcome
    var profile = UserProfile()
    var plan: NightPlan?
    var selectedVenueID = "track-field"
    var checkedInVenueID: String?
    var checkedInAt: Date?
    var offerWindows: [String: TimedOfferWindow] = [:]
    var hapticsEnabled = true

    init(
        onboardingStage: OnboardingStage = .welcome,
        profile: UserProfile = UserProfile(),
        plan: NightPlan? = nil,
        selectedVenueID: String = "track-field",
        checkedInVenueID: String? = nil,
        checkedInAt: Date? = nil,
        offerWindows: [String: TimedOfferWindow] = [:],
        hapticsEnabled: Bool = true
    ) {
        self.onboardingStage = onboardingStage
        self.profile = profile
        self.plan = plan
        self.selectedVenueID = selectedVenueID
        self.checkedInVenueID = checkedInVenueID
        self.checkedInAt = checkedInAt
        self.offerWindows = offerWindows
        self.hapticsEnabled = hapticsEnabled
    }

    private enum CodingKeys: String, CodingKey {
        case onboardingStage
        case profile
        case plan
        case selectedVenueID
        case checkedInVenueID
        case checkedInAt
        case offerWindows
        case hapticsEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        onboardingStage = try container.decodeIfPresent(OnboardingStage.self, forKey: .onboardingStage) ?? .welcome
        profile = try container.decodeIfPresent(UserProfile.self, forKey: .profile) ?? UserProfile()
        plan = try container.decodeIfPresent(NightPlan.self, forKey: .plan)
        selectedVenueID = try container.decodeIfPresent(String.self, forKey: .selectedVenueID) ?? "track-field"
        checkedInVenueID = try container.decodeIfPresent(String.self, forKey: .checkedInVenueID)
        checkedInAt = try container.decodeIfPresent(Date.self, forKey: .checkedInAt)
        offerWindows = try container.decodeIfPresent([String: TimedOfferWindow].self, forKey: .offerWindows) ?? [:]
        hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
    }
}
