import ActivityKit
import Foundation

enum CheckInLiveActivityStartResult: Equatable, Sendable {
    case started(activityID: String)
    case updated(activityID: String)
    case activitiesDisabled
}

actor CheckInLiveActivityManager {
    static let shared = CheckInLiveActivityManager()

    private init() {}

    var activitiesAreEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    var activeActivityIDs: [String] {
        Activity<CheckInActivityAttributes>.activities.map(\.id)
    }

    func activeActivityID(for venueID: String) -> String? {
        Activity<CheckInActivityAttributes>.activities.first {
            $0.attributes.venueID == venueID
        }?.id
    }

    @discardableResult
    func start(
        venueID: String,
        venueName: String,
        checkedInAt: Date = Date(),
        offerTitle: String? = nil,
        offerExpiresAt: Date? = nil
    ) async throws -> CheckInLiveActivityStartResult {
        guard activitiesAreEnabled else { return .activitiesDisabled }

        let validExpiration = offerExpiresAt.flatMap { expiration in
            expiration > checkedInAt ? expiration : nil
        }
        let attributes = CheckInActivityAttributes(
            venueID: venueID,
            venueName: venueName,
            offerTitle: validExpiration == nil ? nil : normalizedOfferTitle(offerTitle)
        )
        let state = CheckInActivityAttributes.ContentState(
            checkedInAt: checkedInAt,
            offerExpiresAt: validExpiration
        )
        let content = ActivityContent(state: state, staleDate: validExpiration)
        let currentActivities = Activity<CheckInActivityAttributes>.activities

        if let reusableActivity = currentActivities.first(where: { $0.attributes == attributes }) {
            for activity in currentActivities where activity.id != reusableActivity.id {
                await finish(activity, dismissalPolicy: .immediate)
            }
            await reusableActivity.update(content)
            return .updated(activityID: reusableActivity.id)
        }

        for activity in currentActivities {
            await finish(activity, dismissalPolicy: .immediate)
        }

        let activity = try Activity.request(
            attributes: attributes,
            content: content,
            pushType: nil
        )
        return .started(activityID: activity.id)
    }

    func end(
        venueID: String? = nil,
        dismissalPolicy: ActivityUIDismissalPolicy = .immediate
    ) async {
        let activities = Activity<CheckInActivityAttributes>.activities.filter { activity in
            venueID == nil || activity.attributes.venueID == venueID
        }

        for activity in activities {
            await finish(activity, dismissalPolicy: dismissalPolicy)
        }
    }

    func endAll(dismissalPolicy: ActivityUIDismissalPolicy = .immediate) async {
        await end(dismissalPolicy: dismissalPolicy)
    }

    private func finish(
        _ activity: Activity<CheckInActivityAttributes>,
        dismissalPolicy: ActivityUIDismissalPolicy
    ) async {
        let finalState = CheckInActivityAttributes.ContentState(
            checkedInAt: activity.content.state.checkedInAt
        )
        let finalContent = ActivityContent(state: finalState, staleDate: nil)
        await activity.end(finalContent, dismissalPolicy: dismissalPolicy)
    }

    private func normalizedOfferTitle(_ offerTitle: String?) -> String? {
        guard let title = offerTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty
        else {
            return nil
        }

        return title
    }
}
