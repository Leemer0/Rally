import ActivityKit
import Foundation

struct CheckInActivityAttributes: ActivityAttributes, Hashable, Sendable {
    struct ContentState: Codable, Hashable, Sendable {
        let checkedInAt: Date
        let offerExpiresAt: Date?

        init(checkedInAt: Date, offerExpiresAt: Date? = nil) {
            self.checkedInAt = checkedInAt
            self.offerExpiresAt = offerExpiresAt
        }
    }

    let venueID: String
    let venueName: String
    let offerTitle: String?
}
