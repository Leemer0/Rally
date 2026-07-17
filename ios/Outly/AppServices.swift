import Foundation
import SwiftUI

struct AppServices: Sendable {
    var authenticate: @Sendable (AuthProvider) async throws -> String
    var verifyApproximateLocation: @Sendable (Venue) async throws -> Bool

    static let demo = AppServices(
        authenticate: { provider in
            try await Task.sleep(for: .milliseconds(450))
            return "demo-\(provider.rawValue)-user"
        },
        verifyApproximateLocation: { _ in
            try await Task.sleep(for: .milliseconds(700))
            return true
        }
    )

    static let live = AppServices(
        authenticate: { provider in
            try await Task.sleep(for: .milliseconds(450))
            return "demo-\(provider.rawValue)-user"
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
