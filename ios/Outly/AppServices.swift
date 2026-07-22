import Foundation
import SwiftUI

struct AppServices: Sendable {
    let isDemo: Bool
    var authenticate: @Sendable (AuthenticationRequest) async throws -> AuthenticationResult
    var currentUserID: @Sendable () async -> String?
    var handleAuthCallback: @Sendable (URL) async throws -> Void
    var completeOnboarding: @Sendable (ConsumerOnboardingSubmission) async throws -> Void
    var loadConsumerBootstrap: @Sendable () async throws -> ConsumerBootstrap
    var setNightPlan: @Sendable (String, UUID) async throws -> NightPlan
    var cancelNightPlan: @Sendable (String) async throws -> Void
    var captureLocationEvidence: @Sendable () async throws -> VenueLocationEvidence
    var checkIn: @Sendable (Venue, String?, VenueLocationEvidence, UUID, UUID) async throws -> ServerCheckInResult
    var deleteConsumerAccount: @Sendable (UUID) async throws -> Void
    var signOut: @Sendable () async throws -> Void
    var verifyApproximateLocation: @Sendable (Venue) async throws -> Bool

    static let demo = AppServices(
        isDemo: true,
        authenticate: { request in
            try await Task.sleep(for: .milliseconds(450))
            let provider: AuthProvider
            switch request {
            case let .oauth(value): provider = value
            case .email: provider = .email
            }
            return AuthenticationResult(userID: "demo-\(provider.rawValue)-user")
        },
        currentUserID: { "demo-user" },
        handleAuthCallback: { _ in },
        completeOnboarding: { _ in
            try await Task.sleep(for: .milliseconds(350))
        },
        loadConsumerBootstrap: {
            ConsumerBootstrap(
                profileFirstName: "Liam",
                venues: VenueCatalog.venues,
                plan: nil,
                checkedInID: nil,
                checkedInVenueID: nil,
                checkedInAt: nil,
                activeOfferVenueID: nil,
                activeOffer: nil,
                activeOfferWindow: nil,
                offerEntitlementEndsAt: nil
            )
        },
        setNightPlan: { venueID, _ in
            try await Task.sleep(for: .milliseconds(250))
            return NightPlan(venueID: venueID, dateLabel: "Tonight")
        },
        cancelNightPlan: { _ in
            try await Task.sleep(for: .milliseconds(150))
        },
        captureLocationEvidence: {
            VenueLocationEvidence(
                latitude: 43.6549,
                longitude: -79.4238,
                horizontalAccuracyMetres: 5,
                capturedAt: Date(),
                accuracyAuthorization: "full",
                locationAuthorization: "when_in_use"
            )
        },
        checkIn: { venue, _, _, _, _ in
            try await Task.sleep(for: .milliseconds(700))
            let checkedInAt = Date()
            return ServerCheckInResult(
                checkInID: "demo-\(UUID().uuidString.lowercased())",
                venueID: venue.id,
                checkedInAt: checkedInAt,
                offer: venue.offer,
                offerWindow: venue.offer.map {
                    TimedOfferWindow(
                        unlockedAt: checkedInAt,
                        duration: $0.claimDurationSeconds.map(TimeInterval.init)
                    )
                },
                entitlementEndsAt: checkedInAt.addingTimeInterval(DemoStore.activePresenceDuration)
            )
        },
        deleteConsumerAccount: { _ in },
        signOut: {},
        verifyApproximateLocation: { _ in
            try await Task.sleep(for: .milliseconds(700))
            return true
        }
    )

    static let live = AppServices(
        isDemo: false,
        authenticate: { request in
            try await configuredLiveBackend.authenticate(request)
        },
        currentUserID: {
            try? configuredLiveBackend.currentUserID()
        },
        handleAuthCallback: { url in
            try await configuredLiveBackend.handleAuthCallback(url)
        },
        completeOnboarding: { submission in
            try await configuredLiveBackend.completeOnboarding(submission)
        },
        loadConsumerBootstrap: {
            try await configuredLiveBackend.consumerBootstrap()
        },
        setNightPlan: { venueID, key in
            try await configuredLiveBackend.setNightPlan(venueID: venueID, idempotencyKey: key)
        },
        cancelNightPlan: { planID in
            try await configuredLiveBackend.cancelNightPlan(planID: planID)
        },
        captureLocationEvidence: {
            try await VenueLocationVerifier.shared.captureEvidence()
        },
        checkIn: { venue, planID, evidence, checkInKey, claimKey in
            try await configuredLiveBackend.checkIn(
                venue: venue,
                planID: planID,
                evidence: evidence,
                checkInIdempotencyKey: checkInKey,
                claimIdempotencyKey: claimKey
            )
        },
        deleteConsumerAccount: { key in
            try await configuredLiveBackend.deleteConsumerAccount(idempotencyKey: key)
        },
        signOut: {
            try await configuredLiveBackend.signOut()
        },
        verifyApproximateLocation: { venue in
            try await VenueLocationVerifier.shared.verify(venue)
        }
    )
}

private struct AppServicesKey: EnvironmentKey {
    static let defaultValue = AppServices.demo
}

extension EnvironmentValues {
    var appServices: AppServices {
        get { self[AppServicesKey.self] }
        set { self[AppServicesKey.self] = newValue }
    }
}
