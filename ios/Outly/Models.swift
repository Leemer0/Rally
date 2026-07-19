import CoreLocation
import Foundation

enum AuthProvider: String, Codable, Sendable {
    case apple
    case email
    case google
    case facebook

    var title: String {
        switch self {
        case .apple: "Apple"
        case .email: "Email"
        case .google: "Google"
        case .facebook: "Facebook"
        }
    }
}

enum OnboardingStage: String, Codable, Sendable {
    case welcome
    case auth
    case name
    case age
    // Retained so installs with the former four-step onboarding state migrate
    // forward instead of losing their locally persisted demo state.
    case gender
    case interested
    case complete
    case main
}

struct AgeDistributionPoint: Codable, Hashable, Sendable {
    let age: Int
    let intensity: Double
}

struct AgeDistribution: Codable, Hashable, Sendable {
    let points: [AgeDistributionPoint]

    var hasEnoughData: Bool { !points.isEmpty }

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

struct Venue: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let neighbourhood: String
    let hours: String
    let address: String
    let goingCount: Int
    let offer: String?
    let latitude: Double
    let longitude: Double
    let ageDistribution: AgeDistribution
    let genderMix: GenderMix

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var appleMapsURL: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "maps.apple.com"
        components.path = "/"
        components.queryItems = [
            URLQueryItem(name: "q", value: name),
            URLQueryItem(name: "ll", value: "\(latitude),\(longitude)"),
        ]
        return components.url ?? URL(string: "https://maps.apple.com")!
    }
}

enum VenueCatalog {
    static let venues: [Venue] = [
        Venue(
            id: "track-field",
            name: "Track & Field",
            neighbourhood: "Ossington",
            hours: "Open 5:00 PM–2:00 AM",
            address: "860 College St, Toronto",
            goingCount: 46,
            offer: "50% off your first drink",
            latitude: 43.6549,
            longitude: -79.4238,
            ageDistribution: distribution(averageAge: 27, spread: 3.4),
            genderMix: GenderMix(menPercentage: 44, womenPercentage: 56)
        ),
        Venue(
            id: "lavelle",
            name: "Lavelle",
            neighbourhood: "King West",
            hours: "Open until 2:00 AM",
            address: "627 King St W, Toronto",
            goingCount: 38,
            offer: "Welcome drink before 10:30 PM",
            latitude: 43.6447,
            longitude: -79.3997,
            ageDistribution: distribution(averageAge: 29, spread: 4.2),
            genderMix: GenderMix(menPercentage: 48, womenPercentage: 52)
        ),
        Venue(
            id: "baro",
            name: "Baro",
            neighbourhood: "King West",
            hours: "Open 5:00 PM–2:00 AM",
            address: "485 King St W, Toronto",
            goingCount: 24,
            offer: nil,
            latitude: 43.6442,
            longitude: -79.3963,
            ageDistribution: distribution(averageAge: 31, spread: 4.8),
            genderMix: GenderMix(menPercentage: 52, womenPercentage: 48)
        ),
        Venue(
            id: "paris-texas",
            name: "Paris Texas",
            neighbourhood: "King West",
            hours: "Opening at 8:00 PM",
            address: "461 King St W, Toronto",
            goingCount: 17,
            offer: "Free coat check",
            latitude: 43.6441,
            longitude: -79.3955,
            ageDistribution: AgeDistribution(points: []),
            genderMix: GenderMix(menPercentage: 55, womenPercentage: 45)
        ),
    ]

    static func venue(id: String) -> Venue {
        venues.first(where: { $0.id == id }) ?? venues[0]
    }

    private static func distribution(averageAge: Int, spread: Double) -> AgeDistribution {
        let points = (19 ... 40).map { age in
            let distance = Double(age - averageAge)
            let intensity = exp(-(distance * distance) / (2 * spread * spread))
            return AgeDistributionPoint(age: age, intensity: intensity)
        }
        return AgeDistribution(points: points)
    }
}

struct UserProfile: Codable, Hashable, Sendable {
    var firstName = ""
    var age = 25
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
