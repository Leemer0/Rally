import ActivityKit
import Foundation

struct CheckInActivityAttributes: ActivityAttributes, Hashable, Sendable {
    struct ContentState: Codable, Hashable, Sendable {
        let checkedInAt: Date
        let offerIsActive: Bool
        let offerExpiresAt: Date?

        init(
            checkedInAt: Date,
            offerIsActive: Bool = false,
            offerExpiresAt: Date? = nil
        ) {
            self.checkedInAt = checkedInAt
            self.offerIsActive = offerIsActive
            self.offerExpiresAt = offerExpiresAt
        }

        private enum CodingKeys: String, CodingKey {
            case checkedInAt
            case offerIsActive
            case offerExpiresAt
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            checkedInAt = try container.decode(Date.self, forKey: .checkedInAt)
            offerExpiresAt = try container.decodeIfPresent(Date.self, forKey: .offerExpiresAt)
            offerIsActive = try container.decodeIfPresent(Bool.self, forKey: .offerIsActive)
                ?? (offerExpiresAt != nil)
        }
    }

    let venueID: String
    let venueName: String
    let offerTitle: String?
    let offerKind: String?
    let sponsorDisplayName: String?
}
