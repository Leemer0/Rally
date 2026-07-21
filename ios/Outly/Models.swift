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

enum OfferKind: String, Codable, Hashable, Sendable {
    case standard
    case partner
}

enum OfferRedemptionMode: String, Codable, Hashable, Sendable {
    case staffDisplay
    case externalLink
}

enum OfferDiscoveryTreatment: String, Codable, Hashable, Sendable {
    case none
    case outlyExclusive
    case partnerFeatured
}

struct OfferSponsor: Codable, Hashable, Sendable {
    let displayName: String
    let disclosure: String
    let logoAssetName: String?
    let logoURL: URL?
}

/// Client snapshot of one approved offer version. Standard and partner offers
/// deliberately share this model and the same verified check-in claim path.
struct VenueOffer: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let versionID: String
    let kind: OfferKind
    let title: String
    let explanation: String?
    let ctaLabel: String
    let redemptionMode: OfferRedemptionMode
    let destinationURL: URL?
    let staffDisplayTitle: String?
    let staffInstruction: String?
    let claimDurationSeconds: Int?
    let sponsor: OfferSponsor?
    let discoveryTreatment: OfferDiscoveryTreatment
    let discoveryBadgeLabel: String?

    var hasCountdown: Bool { claimDurationSeconds != nil }

    var accessibilitySummary: String {
        [
            sponsor.map { "\($0.displayName) partner offer" } ?? discoveryBadgeLabel,
            title,
        ]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}

struct Venue: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let neighbourhood: String
    let hours: String
    let address: String
    let goingCount: Int
    let offer: VenueOffer?
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
    #if DEBUG
    static let venues: [Venue] = ProcessInfo.processInfo.arguments.contains("--marketing-fixtures")
        ? marketingVenues
        : productionVenues
    #else
    static let venues: [Venue] = productionVenues
    #endif

    private static let productionVenues: [Venue] = [
        Venue(
            id: "track-field",
            name: "Track & Field",
            neighbourhood: "Ossington",
            hours: "Open 5:00 PM–2:00 AM",
            address: "860 College St, Toronto",
            goingCount: 46,
            offer: standardOffer(
                id: "track-field-cover",
                title: "Free cover with Outly before 10 PM",
                staffTitle: "Free cover",
                instruction: "Show this screen at the door.",
                durationSeconds: 10 * 60,
                discoveryTreatment: .outlyExclusive,
                badgeLabel: "Outly exclusive"
            ),
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
            offer: northlineOffer(id: "lavelle-northline"),
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
            offer: standardOffer(
                id: "paris-texas-coat-check",
                title: "Complimentary coat check",
                staffTitle: "Complimentary coat check",
                instruction: "Show this screen to coat-check staff.",
                durationSeconds: nil
            ),
            latitude: 43.6441,
            longitude: -79.3955,
            ageDistribution: AgeDistribution(points: []),
            genderMix: GenderMix(menPercentage: 55, womenPercentage: 45)
        ),
    ]

    #if DEBUG
    /// Anonymous fixtures for product screenshots. The stable IDs preserve routes,
    /// custom map marker art, and deterministic screenshot states without exposing
    /// real venue names or addresses in public marketing assets.
    private static let marketingVenues: [Venue] = [
        Venue(
            id: "track-field",
            name: "Vesper Row",
            neighbourhood: "Ossington",
            hours: "Open until 2:00 AM",
            address: "Toronto, Ontario",
            goingCount: 42,
            offer: standardOffer(
                id: "track-field-cover",
                title: "Free cover with Outly before 10 PM",
                staffTitle: "Free cover",
                instruction: "Show this screen at the door.",
                durationSeconds: 10 * 60,
                discoveryTreatment: .outlyExclusive,
                badgeLabel: "Outly exclusive"
            ),
            latitude: 43.6549,
            longitude: -79.4238,
            ageDistribution: distribution(averageAge: 27, spread: 3.4),
            genderMix: GenderMix(menPercentage: 44, womenPercentage: 56)
        ),
        Venue(
            id: "lavelle",
            name: "Halide House",
            neighbourhood: "King West",
            hours: "Open until 2:00 AM",
            address: "Toronto, Ontario",
            goingCount: 31,
            offer: northlineOffer(id: "lavelle-northline"),
            latitude: 43.6447,
            longitude: -79.3997,
            ageDistribution: distribution(averageAge: 29, spread: 4.2),
            genderMix: GenderMix(menPercentage: 48, womenPercentage: 52)
        ),
        Venue(
            id: "baro",
            name: "Night Archive",
            neighbourhood: "College",
            hours: "Open until 2:00 AM",
            address: "Toronto, Ontario",
            goingCount: 18,
            offer: nil,
            latitude: 43.6442,
            longitude: -79.3963,
            ageDistribution: distribution(averageAge: 31, spread: 4.8),
            genderMix: GenderMix(menPercentage: 52, womenPercentage: 48)
        ),
        Venue(
            id: "paris-texas",
            name: "Sidecar Assembly",
            neighbourhood: "Chinatown",
            hours: "Opening at 8:00 PM",
            address: "Toronto, Ontario",
            goingCount: 12,
            offer: standardOffer(
                id: "paris-texas-coat-check",
                title: "Complimentary coat check",
                staffTitle: "Complimentary coat check",
                instruction: "Show this screen to coat-check staff.",
                durationSeconds: nil
            ),
            latitude: 43.6441,
            longitude: -79.3955,
            ageDistribution: AgeDistribution(points: []),
            genderMix: GenderMix(menPercentage: 55, womenPercentage: 45)
        ),
    ]
    #endif

    static func venue(id: String) -> Venue {
        venues.first(where: { $0.id == id }) ?? venues[0]
    }

    private static func standardOffer(
        id: String,
        title: String,
        staffTitle: String,
        instruction: String,
        durationSeconds: Int?,
        discoveryTreatment: OfferDiscoveryTreatment = .none,
        badgeLabel: String? = nil
    ) -> VenueOffer {
        VenueOffer(
            id: id,
            versionID: "\(id)-v1",
            kind: .standard,
            title: title,
            explanation: nil,
            ctaLabel: "View offer",
            redemptionMode: .staffDisplay,
            destinationURL: nil,
            staffDisplayTitle: staffTitle,
            staffInstruction: instruction,
            claimDurationSeconds: durationSeconds,
            sponsor: nil,
            discoveryTreatment: discoveryTreatment,
            discoveryBadgeLabel: badgeLabel
        )
    }

    private static func northlineOffer(id: String) -> VenueOffer {
        VenueOffer(
            id: id,
            versionID: "\(id)-v1",
            kind: .partner,
            title: "50% off your ride home",
            explanation: "For new Northline riders.",
            ctaLabel: "Sign up with Northline",
            redemptionMode: .externalLink,
            destinationURL: URL(string: "https://getoutly.app/partners/northline"),
            staffDisplayTitle: nil,
            staffInstruction: nil,
            claimDurationSeconds: 30 * 60,
            sponsor: OfferSponsor(
                displayName: "Northline",
                disclosure: "Outly partner",
                logoAssetName: nil,
                logoURL: nil
            ),
            discoveryTreatment: .partnerFeatured,
            discoveryBadgeLabel: "Partner offer"
        )
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
    let expiresAt: Date?

    init(unlockedAt: Date, duration: TimeInterval? = Self.duration) {
        self.unlockedAt = unlockedAt
        expiresAt = duration.map(unlockedAt.addingTimeInterval)
    }

    func isActive(at date: Date) -> Bool {
        guard date >= unlockedAt else { return false }
        guard let expiresAt else { return true }
        return date < expiresAt
    }

    func remainingSeconds(at date: Date) -> Int {
        guard let expiresAt else { return 0 }
        return max(0, Int(ceil(expiresAt.timeIntervalSince(date))))
    }

    var totalDuration: TimeInterval {
        guard let expiresAt else { return 0 }
        return max(0, expiresAt.timeIntervalSince(unlockedAt))
    }

    var hasCountdown: Bool { expiresAt != nil }

    func remainingFraction(at date: Date) -> Double {
        guard let expiresAt, totalDuration > 0 else { return 1 }

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
    var claimedOffers: [String: VenueOffer] = [:]
    var hapticsEnabled = true

    init(
        onboardingStage: OnboardingStage = .welcome,
        profile: UserProfile = UserProfile(),
        plan: NightPlan? = nil,
        selectedVenueID: String = "track-field",
        checkedInVenueID: String? = nil,
        checkedInAt: Date? = nil,
        offerWindows: [String: TimedOfferWindow] = [:],
        claimedOffers: [String: VenueOffer] = [:],
        hapticsEnabled: Bool = true
    ) {
        self.onboardingStage = onboardingStage
        self.profile = profile
        self.plan = plan
        self.selectedVenueID = selectedVenueID
        self.checkedInVenueID = checkedInVenueID
        self.checkedInAt = checkedInAt
        self.offerWindows = offerWindows
        self.claimedOffers = claimedOffers
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
        case claimedOffers
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
        claimedOffers = try container.decodeIfPresent([String: VenueOffer].self, forKey: .claimedOffers) ?? [:]
        hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
    }
}
