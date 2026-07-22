import AuthenticationServices
import Foundation
import Supabase
import UIKit

struct EmailAuthCredentials: Sendable {
    let email: String
    let password: String
}

enum AuthenticationRequest: Sendable {
    case oauth(AuthProvider)
    case email(intent: AuthIntent, credentials: EmailAuthCredentials)
}

struct AuthenticationResult: Sendable {
    let userID: String
}

struct ConsumerOnboardingSubmission: Sendable {
    let firstName: String
    let dateOfBirth: DateComponents
    let gender: UserGender
}

enum OutlyLegal {
    static let termsVersion = "2026-07-21"
    static let privacyVersion = "2026-07-21"
    static let termsURL = URL(string: "https://getoutly.app/terms")!
    static let privacyURL = URL(string: "https://getoutly.app/privacy")!
}

enum ConsumerDateOfBirthFormatter {
    static func string(from components: DateComponents) -> String? {
        guard let year = components.year,
              let month = components.month,
              let day = components.day,
              (1 ... 12).contains(month),
              (1 ... 31).contains(day)
        else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        var validation = DateComponents()
        validation.calendar = calendar
        validation.timeZone = .gmt
        validation.year = year
        validation.month = month
        validation.day = day
        guard let date = calendar.date(from: validation) else { return nil }
        let roundTrip = calendar.dateComponents([.year, .month, .day], from: date)
        guard roundTrip.year == year, roundTrip.month == month, roundTrip.day == day else {
            return nil
        }
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}

struct ServerCheckInResult: Sendable {
    let checkInID: String
    let venueID: String
    let checkedInAt: Date
    let offer: VenueOffer?
    let offerWindow: TimedOfferWindow?
    let entitlementEndsAt: Date?
}

struct ServerVerifiedCheckIn: Sendable, Equatable {
    let id: String
    let venueID: String
    let checkedInAt: Date
}

enum SupabaseBackendError: LocalizedError, Sendable {
    case missingConfiguration
    case unsupportedProvider
    case emailConfirmationRequired
    case invalidResponse
    case server(code: String, message: String, verifiedCheckIn: ServerVerifiedCheckIn?)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            "Add your Supabase project URL and publishable key to SupabaseConfig.plist."
        case .unsupportedProvider:
            "This sign-in provider is not available."
        case .emailConfirmationRequired:
            "Check your email to confirm your account, then return to Outly."
        case .invalidResponse:
            "Outly received an unexpected response. Try again."
        case let .server(_, message, _):
            message
        }
    }

    var serverCode: String? {
        guard case let .server(code, _, _) = self else { return nil }
        return code
    }

    var verifiedCheckIn: ServerVerifiedCheckIn? {
        guard case let .server(_, _, verifiedCheckIn) = self else { return nil }
        return verifiedCheckIn
    }

    /// An HTTP response with no verified check-in is a completed server-side
    /// rejection only when it carries one of the check-in decision codes. Auth,
    /// infrastructure, and transport failures keep the same idempotency keys
    /// because the client cannot know whether the original write committed.
    var shouldRotateCheckInAttempt: Bool {
        guard case let .server(code, _, verifiedCheckIn) = self,
              verifiedCheckIn == nil
        else {
            return false
        }

        return Self.explicitCheckInRejectionCodes.contains(code)
    }

    private static let explicitCheckInRejectionCodes: Set<String> = [
        "PERMISSION_DENIED",
        "REDUCED_ACCURACY",
        "INSUFFICIENT_ACCURACY",
        "STALE_SAMPLE",
        "FUTURE_SAMPLE",
        "OUTSIDE_GEOFENCE",
        "AMBIGUOUS_NEAREST_VENUE",
        "VENUE_UNAVAILABLE",
        "ACCOUNT_INELIGIBLE",
        "RATE_LIMITED",
        "ALREADY_CHECKED_IN",
        "INVALID_REQUEST",
    ]
}

enum SupabaseClientKeyValidator {
    static func isAllowed(_ key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercase = trimmed.lowercased()
        guard !trimmed.isEmpty,
              !lowercase.hasPrefix("sb_secret_"),
              !lowercase.contains("service_role"),
              jwtRole(in: trimmed) != "service_role",
              jwtRole(in: trimmed) != "supabase_admin"
        else {
            return false
        }
        return true
    }

    private static func jwtRole(in token: String) -> String? {
        let segments = token.split(separator: ".", omittingEmptySubsequences: false)
        guard segments.count == 3 else { return nil }

        var payload = String(segments[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        payload.append(String(repeating: "=", count: (4 - payload.count % 4) % 4))
        guard let data = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }
        return (json["role"] as? String)?.lowercased()
    }
}

private struct SupabaseAppConfiguration: Sendable {
    let projectURL: URL
    let publishableKey: String
    let callbackURL: URL

    static func load(bundle: Bundle = .main) throws -> Self {
        guard let fileURL = bundle.url(forResource: "SupabaseConfig", withExtension: "plist"),
              let data = try? Data(contentsOf: fileURL),
              let values = try? PropertyListSerialization.propertyList(
                  from: data,
                  options: [],
                  format: nil
              ) as? [String: Any],
              let rawURL = values["SupabaseURL"] as? String,
              let projectURL = URL(string: rawURL),
              projectURL.scheme == "https",
              !rawURL.contains("YOUR_PROJECT_REF"),
              let publishableKey = values["SupabasePublishableKey"] as? String,
              SupabaseClientKeyValidator.isAllowed(publishableKey),
              !publishableKey.contains("YOUR_SUPABASE")
        else {
            throw SupabaseBackendError.missingConfiguration
        }

        return Self(
            projectURL: projectURL,
            publishableKey: publishableKey,
            callbackURL: URL(string: "outly://auth-callback")!
        )
    }
}

struct ServerClockTranslation: Sendable, Equatable {
    let clientMinusServer: TimeInterval

    init(serverTime: Date, clientReferenceTime: Date) {
        clientMinusServer = clientReferenceTime.timeIntervalSince(serverTime)
    }

    func clientDate(for serverDate: Date) -> Date {
        serverDate.addingTimeInterval(clientMinusServer)
    }

    func serverDate(for clientDate: Date) -> Date {
        clientDate.addingTimeInterval(-clientMinusServer)
    }
}

private actor ServerClockStore {
    private var translation: ServerClockTranslation?

    func update(serverTime: Date, clientReferenceTime: Date) -> ServerClockTranslation {
        let value = ServerClockTranslation(
            serverTime: serverTime,
            clientReferenceTime: clientReferenceTime
        )
        translation = value
        return value
    }

    func current() -> ServerClockTranslation? {
        translation
    }
}

enum SupabasePublicStorageURL {
    static func make(projectURL: URL, bucket: String, objectPath: String?) -> URL? {
        guard let objectPath else { return nil }
        var components = objectPath.split(separator: "/", omittingEmptySubsequences: false)
        guard !components.isEmpty,
              !objectPath.hasPrefix("/"),
              !objectPath.contains("://"),
              !objectPath.contains("?"),
              !objectPath.contains("#"),
              components.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." })
        else {
            return nil
        }

        if components.first == Substring(bucket) {
            components.removeFirst()
        }
        guard !components.isEmpty else { return nil }

        return components.reduce(
            projectURL
                .appending(path: "storage/v1/object/public")
                .appending(path: bucket)
        ) { url, component in
            url.appending(path: String(component))
        }
    }
}

final class SupabaseBackend: @unchecked Sendable {
    private let configuration: SupabaseAppConfiguration
    private let client: SupabaseClient
    private let clockStore = ServerClockStore()

    init(bundle: Bundle = .main) throws {
        let configuration = try SupabaseAppConfiguration.load(bundle: bundle)
        self.configuration = configuration
        client = SupabaseClient(
            supabaseURL: configuration.projectURL,
            supabaseKey: configuration.publishableKey,
            options: SupabaseClientOptions(
                auth: .init(flowType: .pkce)
            )
        )
    }

    func authenticate(_ request: AuthenticationRequest) async throws -> AuthenticationResult {
        switch request {
        case let .oauth(provider):
            guard provider != .email else { throw SupabaseBackendError.unsupportedProvider }
            return try await authenticateWithOAuth(provider)
        case let .email(intent, credentials):
            return try await authenticateWithEmail(intent: intent, credentials: credentials)
        }
    }

    func currentUserID() -> String? {
        client.auth.currentUser?.id.uuidString.lowercased()
    }

    func handleAuthCallback(_ url: URL) async throws {
        _ = try await client.auth.session(from: url)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func completeOnboarding(_ submission: ConsumerOnboardingSubmission) async throws {
        guard let dateOfBirth = ConsumerDateOfBirthFormatter.string(
            from: submission.dateOfBirth
        ) else {
            throw SupabaseBackendError.invalidResponse
        }
        let body = CompleteOnboardingBody(
            firstName: submission.firstName,
            dateOfBirth: dateOfBirth,
            gender: submission.gender.rawValue,
            termsVersion: OutlyLegal.termsVersion,
            privacyVersion: OutlyLegal.privacyVersion
        )
        let _: CompleteOnboardingData = try await invoke(
            "complete-consumer-onboarding",
            body: body
        )
    }

    func consumerBootstrap() async throws -> ConsumerBootstrap {
        let requestStartedAt = Date()
        let response: EdgeEnvelope<API.ConsumerBootstrapPayload> = try await invokeGET(
            "consumer-bootstrap"
        )
        let responseReceivedAt = Date()
        let clientReferenceTime = requestStartedAt.addingTimeInterval(
            responseReceivedAt.timeIntervalSince(requestStartedAt) / 2
        )
        guard let serverTime = API.date(response.data.serverTime) else {
            throw SupabaseBackendError.invalidResponse
        }
        let translation = await clockStore.update(
            serverTime: serverTime,
            clientReferenceTime: clientReferenceTime
        )
        return try response.data.model(
            projectURL: configuration.projectURL,
            clockTranslation: translation
        )
    }

    func setNightPlan(venueID: String, idempotencyKey: UUID) async throws -> NightPlan {
        let response: SetPlanData = try await invoke(
            "set-night-plan",
            body: SetPlanBody(
                venueID: venueID,
                idempotencyKey: idempotencyKey.uuidString.lowercased()
            )
        )
        return response.plan.model
    }

    func cancelNightPlan(planID: String) async throws {
        let _: SetPlanData = try await invoke(
            "cancel-night-plan",
            body: CancelPlanBody(planID: planID)
        )
    }

    func checkIn(
        venue: Venue,
        planID: String?,
        evidence: VenueLocationEvidence,
        checkInIdempotencyKey: UUID,
        claimIdempotencyKey: UUID
    ) async throws -> ServerCheckInResult {
        let clockTranslation = await clockStore.current()
        let body = CheckInBody(
            venueID: venue.id,
            planID: planID,
            offerID: venue.offer?.id,
            checkInIdempotencyKey: checkInIdempotencyKey.uuidString.lowercased(),
            claimIdempotencyKey: venue.offer == nil
                ? nil
                : claimIdempotencyKey.uuidString.lowercased(),
            location: .init(
                evidence: evidence,
                capturedAt: clockTranslation?.serverDate(for: evidence.capturedAt)
                    ?? evidence.capturedAt
            )
        )
        let response: CheckInData
        do {
            response = try await invoke("check-in", body: body)
        } catch let error as SupabaseBackendError {
            guard let verifiedCheckIn = error.verifiedCheckIn else { throw error }
            let translatedCheckIn = ServerVerifiedCheckIn(
                id: verifiedCheckIn.id,
                venueID: verifiedCheckIn.venueID,
                checkedInAt: clockTranslation?.clientDate(for: verifiedCheckIn.checkedInAt)
                    ?? verifiedCheckIn.checkedInAt
            )
            throw SupabaseBackendError.server(
                code: error.serverCode ?? "OFFER_UNLOCK_FAILED",
                message: error.errorDescription ?? "Your offer isn’t ready yet.",
                verifiedCheckIn: translatedCheckIn
            )
        }
        guard response.checkIn.outcome == "verified",
              let rawVerifiedAt = response.checkIn.serverVerifiedAt,
              let serverVerifiedAt = API.date(rawVerifiedAt)
        else {
            throw SupabaseBackendError.invalidResponse
        }

        let offer = try response.claim?.offer.model(projectURL: configuration.projectURL)
        let verifiedAt = clockTranslation?.clientDate(for: serverVerifiedAt) ?? serverVerifiedAt
        let unlockedAt = response.claim
            .flatMap { API.date($0.unlockedAt) }
            .map { clockTranslation?.clientDate(for: $0) ?? $0 }
        let countdownEndsAt = response.claim?.countdownEndsAt
            .flatMap(API.date)
            .map { clockTranslation?.clientDate(for: $0) ?? $0 }
        let entitlementEndsAt = response.claim?.entitlementExpiresAt
            .flatMap(API.date)
            .map { clockTranslation?.clientDate(for: $0) ?? $0 }

        return ServerCheckInResult(
            checkInID: response.checkIn.id,
            venueID: response.checkIn.venueID,
            checkedInAt: verifiedAt,
            offer: offer,
            offerWindow: unlockedAt.map {
                TimedOfferWindow(unlockedAt: $0, expiresAt: countdownEndsAt)
            },
            entitlementEndsAt: entitlementEndsAt
        )
    }

    func deleteConsumerAccount(idempotencyKey: UUID) async throws {
        let _: AccountDeletionData = try await invoke(
            "request-account-deletion",
            body: AccountDeletionBody(
                subjectType: "consumer",
                idempotencyKey: idempotencyKey.uuidString.lowercased()
            )
        )
    }

    private func authenticateWithOAuth(_ provider: AuthProvider) async throws -> AuthenticationResult {
        let userID = try await OAuthWebSession.shared.authenticate(
            client: client,
            provider: provider,
            callbackURL: configuration.callbackURL
        )
        return AuthenticationResult(userID: userID)
    }

    private func authenticateWithEmail(
        intent: AuthIntent,
        credentials: EmailAuthCredentials
    ) async throws -> AuthenticationResult {
        switch intent {
        case .signUp:
            let response = try await client.auth.signUp(
                email: credentials.email,
                password: credentials.password,
                redirectTo: configuration.callbackURL
            )
            guard response.session != nil else {
                throw SupabaseBackendError.emailConfirmationRequired
            }
            return AuthenticationResult(userID: response.user.id.uuidString.lowercased())
        case .logIn:
            let session = try await client.auth.signIn(
                email: credentials.email,
                password: credentials.password
            )
            return AuthenticationResult(userID: session.user.id.uuidString.lowercased())
        }
    }

    private func invoke<Response: Decodable, Body: Encodable & Sendable>(
        _ name: String,
        body: Body
    ) async throws -> Response {
        do {
            let envelope: EdgeEnvelope<Response> = try await client.functions.invoke(
                name,
                options: FunctionInvokeOptions(body: body)
            )
            return envelope.data
        } catch {
            throw Self.present(error)
        }
    }

    private func invokeGET<Response: Decodable>(_ name: String) async throws -> Response {
        do {
            return try await client.functions.invoke(
                name,
                options: FunctionInvokeOptions(method: .get)
            )
        } catch {
            throw Self.present(error)
        }
    }

    private static func present(_ error: Error) -> Error {
        guard case let FunctionsError.httpError(_, data) = error,
              let payload = try? JSONDecoder().decode(EdgeErrorEnvelope.self, from: data)
        else {
            return error
        }
        let verifiedCheckIn: ServerVerifiedCheckIn?
        if let checkIn = payload.error.details?.checkIn,
           checkIn.outcome == "verified",
           let rawVerifiedAt = checkIn.serverVerifiedAt,
           let verifiedAt = API.date(rawVerifiedAt)
        {
            verifiedCheckIn = ServerVerifiedCheckIn(
                id: checkIn.id,
                venueID: checkIn.venueID,
                checkedInAt: verifiedAt
            )
        } else {
            verifiedCheckIn = nil
        }
        return SupabaseBackendError.server(
            code: payload.error.code,
            message: payload.error.message,
            verifiedCheckIn: verifiedCheckIn
        )
    }
}

private enum SupabaseBackendProvider {
    static let backend: Result<SupabaseBackend, Error> = Result {
        try SupabaseBackend()
    }

    static func live() throws -> SupabaseBackend {
        try backend.get()
    }
}

@MainActor
private final class OAuthWebSession: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = OAuthWebSession()

    private var session: ASWebAuthenticationSession?

    func authenticate(
        client: SupabaseClient,
        provider: AuthProvider,
        callbackURL: URL
    ) async throws -> String {
        let resolvedProvider: Provider
        switch provider {
        case .apple: resolvedProvider = .apple
        case .google: resolvedProvider = .google
        case .facebook: resolvedProvider = .facebook
        case .email: throw SupabaseBackendError.unsupportedProvider
        }

        let signInURL = try client.auth.getOAuthSignInURL(
            provider: resolvedProvider,
            redirectTo: callbackURL
        )
        let callback = try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<URL, Error>) in
            let session = ASWebAuthenticationSession(
                url: signInURL,
                callbackURLScheme: callbackURL.scheme
            ) { [weak self] url, error in
                self?.session = nil
                if let url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: error ?? CancellationError())
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.session = session
            guard session.start() else {
                self.session = nil
                continuation.resume(throwing: SupabaseBackendError.unsupportedProvider)
                return
            }
        }

        _ = try await client.auth.session(from: callback)
        return try await client.auth.user().id.uuidString.lowercased()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
}

struct ConsumerBootstrap: Sendable {
    let profileFirstName: String
    let venues: [Venue]
    let plan: NightPlan?
    let checkedInID: String?
    let checkedInVenueID: String?
    let checkedInAt: Date?
    let activeOfferVenueID: String?
    let activeOffer: VenueOffer?
    let activeOfferWindow: TimedOfferWindow?
    let offerEntitlementEndsAt: Date?
}

private struct EdgeEnvelope<Value: Decodable>: Decodable {
    let data: Value
}

private struct EdgeErrorEnvelope: Decodable {
    struct Payload: Decodable {
        struct Details: Decodable {
            let checkIn: API.CheckIn?

            enum CodingKeys: String, CodingKey {
                case checkIn = "check_in"
            }
        }

        let code: String
        let message: String
        let details: Details?
    }

    let error: Payload
}

private struct CompleteOnboardingBody: Encodable, Sendable {
    let firstName: String
    let dateOfBirth: String
    let gender: String
    let termsVersion: String
    let privacyVersion: String

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case dateOfBirth = "date_of_birth"
        case gender
        case termsVersion = "terms_version"
        case privacyVersion = "privacy_version"
    }
}

private struct CompleteOnboardingData: Decodable {
    let profile: API.Profile
}

private struct SetPlanBody: Encodable, Sendable {
    let venueID: String
    let idempotencyKey: String

    enum CodingKeys: String, CodingKey {
        case venueID = "venue_id"
        case idempotencyKey = "idempotency_key"
    }
}

private struct CancelPlanBody: Encodable, Sendable {
    let planID: String

    enum CodingKeys: String, CodingKey {
        case planID = "plan_id"
    }
}

private struct SetPlanData: Decodable {
    let plan: API.Plan
}

private struct CheckInBody: Encodable, Sendable {
    let venueID: String
    let planID: String?
    let offerID: String?
    let checkInIdempotencyKey: String
    let claimIdempotencyKey: String?
    let location: Location

    enum CodingKeys: String, CodingKey {
        case venueID = "venue_id"
        case planID = "plan_id"
        case offerID = "offer_id"
        case checkInIdempotencyKey = "check_in_idempotency_key"
        case claimIdempotencyKey = "claim_idempotency_key"
        case location
    }

    struct Location: Encodable, Sendable {
        let latitude: Double
        let longitude: Double
        let horizontalAccuracyMetres: Double
        let capturedAt: String
        let accuracyAuthorization: String
        let locationAuthorization: String

        init(evidence: VenueLocationEvidence, capturedAt: Date) {
            latitude = evidence.latitude
            longitude = evidence.longitude
            horizontalAccuracyMetres = evidence.horizontalAccuracyMetres
            self.capturedAt = API.timestamp(capturedAt)
            accuracyAuthorization = evidence.accuracyAuthorization
            locationAuthorization = evidence.locationAuthorization
        }

        enum CodingKeys: String, CodingKey {
            case latitude
            case longitude
            case horizontalAccuracyMetres = "horizontal_accuracy_metres"
            case capturedAt = "captured_at"
            case accuracyAuthorization = "accuracy_authorization"
            case locationAuthorization = "location_authorization"
        }
    }
}

private struct CheckInData: Decodable {
    let checkIn: API.CheckIn
    let claim: API.Claim?

    enum CodingKeys: String, CodingKey {
        case checkIn = "check_in"
        case claim
    }
}

private struct AccountDeletionBody: Encodable, Sendable {
    let subjectType: String
    let idempotencyKey: String

    enum CodingKeys: String, CodingKey {
        case subjectType = "subject_type"
        case idempotencyKey = "idempotency_key"
    }
}

private struct AccountDeletionData: Decodable {
    let deletion: Deletion

    struct Deletion: Decodable {
        let deletionState: String

        enum CodingKeys: String, CodingKey {
            case deletionState = "deletion_state"
        }
    }
}

private enum API {
    struct Profile: Decodable {
        let userID: String
        let firstName: String
        let onboardingStatus: String
        let accountStatus: String

        enum CodingKeys: String, CodingKey {
            case userID = "user_id"
            case firstName = "first_name"
            case onboardingStatus = "onboarding_status"
            case accountStatus = "account_status"
        }
    }

    struct ConsumerBootstrapPayload: Decodable {
        let serverTime: String
        let profile: Profile
        let currentPlan: Plan?
        let currentCheckIn: CheckIn?
        let activeClaim: Claim?
        let venues: [VenuePayload]

        enum CodingKeys: String, CodingKey {
            case serverTime = "server_time"
            case profile
            case currentPlan = "current_plan"
            case currentCheckIn = "current_check_in"
            case activeClaim = "active_claim"
            case venues
        }

        func model(
            projectURL: URL,
            clockTranslation: ServerClockTranslation
        ) throws -> ConsumerBootstrap {
            let mappedVenues = try venues.map { try $0.model(projectURL: projectURL) }
            let claimOffer = try activeClaim?.offer.model(projectURL: projectURL)
            let claimUnlockedAt = activeClaim
                .flatMap { date($0.unlockedAt) }
                .map { clockTranslation.clientDate(for: $0) }
            let countdownEndsAt = activeClaim?.countdownEndsAt
                .flatMap(date)
                .map { clockTranslation.clientDate(for: $0) }
            let entitlementEndsAt = activeClaim?.entitlementExpiresAt
                .flatMap(date)
                .map { clockTranslation.clientDate(for: $0) }

            let verifiedCheckIn = currentCheckIn.flatMap { checkIn -> CheckIn? in
                checkIn.outcome == "verified" ? checkIn : nil
            }
            let verifiedAt = verifiedCheckIn?.serverVerifiedAt
                .flatMap(date)
                .map { clockTranslation.clientDate(for: $0) }

            return ConsumerBootstrap(
                profileFirstName: profile.firstName,
                venues: mappedVenues,
                plan: currentPlan?.model,
                checkedInID: verifiedAt == nil ? nil : verifiedCheckIn?.id,
                checkedInVenueID: verifiedAt == nil ? nil : verifiedCheckIn?.venueID,
                checkedInAt: verifiedAt,
                activeOfferVenueID: activeClaim?.venueID,
                activeOffer: claimOffer,
                activeOfferWindow: claimUnlockedAt.map {
                    TimedOfferWindow(unlockedAt: $0, expiresAt: countdownEndsAt)
                },
                offerEntitlementEndsAt: entitlementEndsAt
            )
        }
    }

    struct Plan: Decodable {
        let id: String
        let venueID: String
        let nightlifeDate: String
        let status: String

        enum CodingKeys: String, CodingKey {
            case id
            case venueID = "venue_id"
            case nightlifeDate = "nightlife_date"
            case status
        }

        var model: NightPlan {
            NightPlan(id: id, venueID: venueID, dateLabel: "Tonight")
        }
    }

    struct CheckIn: Decodable {
        let id: String
        let venueID: String
        let outcome: String
        let serverVerifiedAt: String?

        enum CodingKeys: String, CodingKey {
            case id
            case venueID = "venue_id"
            case outcome
            case serverVerifiedAt = "server_verified_at"
        }
    }

    struct Claim: Decodable {
        let claimID: String
        let venueID: String
        let unlockedAt: String
        let countdownEndsAt: String?
        let entitlementExpiresAt: String?
        let status: String
        let offer: Offer

        enum CodingKeys: String, CodingKey {
            case claimID = "claim_id"
            case venueID = "venue_id"
            case unlockedAt = "unlocked_at"
            case countdownEndsAt = "countdown_ends_at"
            case entitlementExpiresAt = "entitlement_expires_at"
            case status
            case offer
        }
    }

    struct Offer: Decodable {
        let offerID: String
        let offerVersionID: String
        let kind: String
        let title: String
        let explanation: String?
        let ctaLabel: String
        let redemptionMode: String?
        let destinationURL: String?
        let staffDisplayTitle: String?
        let staffInstruction: String?
        let claimDurationSeconds: Int?
        let sponsorDisplayName: String?
        let sponsorLogoStoragePath: String?
        let sponsorDisclosure: String?
        let discoveryTreatment: String
        let discoveryBadgeLabel: String?

        enum CodingKeys: String, CodingKey {
            case offerID = "offer_id"
            case offerVersionID = "offer_version_id"
            case kind
            case title
            case explanation
            case ctaLabel = "cta_label"
            case redemptionMode = "redemption_mode"
            case destinationURL = "destination_url"
            case staffDisplayTitle = "staff_display_title"
            case staffInstruction = "staff_instruction"
            case claimDurationSeconds = "claim_duration_seconds"
            case sponsorDisplayName = "sponsor_display_name"
            case sponsorLogoStoragePath = "sponsor_logo_storage_path"
            case sponsorDisclosure = "sponsor_disclosure"
            case discoveryTreatment = "discovery_treatment"
            case discoveryBadgeLabel = "discovery_badge_label"
        }

        func model(projectURL: URL) throws -> VenueOffer {
            guard let resolvedKind = OfferKind(rawValue: kind) else {
                throw SupabaseBackendError.invalidResponse
            }
            let resolvedRedemptionMode: OfferRedemptionMode
            switch redemptionMode {
            case "external_link": resolvedRedemptionMode = .externalLink
            case "staff_display", nil: resolvedRedemptionMode = .staffDisplay
            default: throw SupabaseBackendError.invalidResponse
            }
            let treatment: OfferDiscoveryTreatment
            switch discoveryTreatment {
            case "none": treatment = .none
            case "outly_exclusive": treatment = .outlyExclusive
            case "partner_featured": treatment = .partnerFeatured
            default: throw SupabaseBackendError.invalidResponse
            }
            let destination: URL?
            if let destinationURL {
                guard let candidate = URL(string: destinationURL), candidate.scheme == "https" else {
                    throw SupabaseBackendError.invalidResponse
                }
                destination = candidate
            } else {
                destination = nil
            }
            let logoURL = SupabasePublicStorageURL.make(
                projectURL: projectURL,
                bucket: "partner-media",
                objectPath: sponsorLogoStoragePath
            )
            let sponsor = sponsorDisplayName.map {
                OfferSponsor(
                    displayName: $0,
                    disclosure: sponsorDisclosure ?? "Outly partner",
                    logoAssetName: nil,
                    logoURL: logoURL
                )
            }

            return VenueOffer(
                id: offerID,
                versionID: offerVersionID,
                kind: resolvedKind,
                title: title,
                explanation: explanation,
                ctaLabel: ctaLabel,
                redemptionMode: resolvedRedemptionMode,
                destinationURL: destination,
                staffDisplayTitle: staffDisplayTitle,
                staffInstruction: staffInstruction,
                claimDurationSeconds: claimDurationSeconds,
                sponsor: sponsor,
                discoveryTreatment: treatment,
                discoveryBadgeLabel: discoveryBadgeLabel
            )
        }
    }

    struct VenuePayload: Decodable {
        let id: String
        let name: String
        let neighbourhood: String
        let address: String
        let latitude: Double
        let longitude: Double
        let timezone: String
        let heroStoragePath: String?
        let markerStoragePath: String?
        let hours: [Hours]
        let crowd: Crowd
        let offer: Offer?

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case neighbourhood
            case address
            case latitude
            case longitude
            case timezone
            case heroStoragePath = "hero_storage_path"
            case markerStoragePath = "marker_storage_path"
            case hours
            case crowd = "tonights_crowd"
            case offer
        }

        func model(projectURL: URL) throws -> Venue {
            Venue(
                id: id,
                name: name,
                neighbourhood: neighbourhood,
                hours: hoursDescription,
                address: address,
                goingCount: crowd.goingCount,
                offer: try offer?.model(projectURL: projectURL),
                latitude: latitude,
                longitude: longitude,
                ageDistribution: crowd.ageDistributionModel,
                genderMix: crowd.genderModel,
                markerURL: SupabasePublicStorageURL.make(
                    projectURL: projectURL,
                    bucket: "venue-media",
                    objectPath: markerStoragePath
                ),
                heroURL: SupabasePublicStorageURL.make(
                    projectURL: projectURL,
                    bucket: "venue-media",
                    objectPath: heroStoragePath
                )
            )
        }

        private var hoursDescription: String {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: timezone) ?? .current
            let weekday = calendar.component(.weekday, from: Date()) - 1
            guard let interval = hours.first(where: { $0.weekday == weekday && !$0.isClosed }) else {
                return "Hours unavailable"
            }
            return "Open \(Self.time(interval.opensAt))–\(Self.time(interval.closesAt))"
        }

        private static func time(_ value: String?) -> String {
            guard let value else { return "late" }
            let parser = DateFormatter()
            parser.locale = Locale(identifier: "en_US_POSIX")
            parser.dateFormat = "HH:mm:ss"
            guard let parsed = parser.date(from: String(value.prefix(8))) else { return value }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_CA")
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: parsed)
        }
    }

    struct Hours: Decodable {
        let weekday: Int
        let opensAt: String?
        let closesAt: String?
        let isClosed: Bool

        enum CodingKeys: String, CodingKey {
            case weekday
            case opensAt = "opens_at"
            case closesAt = "closes_at"
            case isClosed = "is_closed"
        }
    }

    struct Crowd: Decodable {
        let goingCount: Int
        let demographicsAvailable: Bool
        let averageAge: Int?
        let ageDistribution: [AgeBucket]?
        let gender: GenderCounts?

        enum CodingKeys: String, CodingKey {
            case goingCount = "going_count"
            case demographicsAvailable = "demographics_available"
            case averageAge = "average_age"
            case ageDistribution = "age_distribution"
            case gender
        }

        var ageDistributionModel: AgeDistribution {
            guard demographicsAvailable,
                  let ageDistribution,
                  let maximum = ageDistribution.map(\.percentage).max(),
                  maximum > 0
            else {
                return AgeDistribution(points: [])
            }
            return AgeDistribution(
                points: ageDistribution.map {
                    AgeDistributionPoint(
                        age: $0.representativeAge,
                        intensity: Double($0.percentage) / Double(maximum)
                    )
                },
                averageAge: averageAge
            )
        }

        var genderModel: GenderMix {
            guard demographicsAvailable, let gender else {
                return GenderMix(menPercentage: 0, womenPercentage: 0)
            }
            return GenderMix(
                menPercentage: gender.man,
                womenPercentage: gender.woman,
                otherPercentage: gender.other
            )
        }
    }

    struct AgeBucket: Decodable {
        let label: String
        let percentage: Int

        var representativeAge: Int {
            switch label {
            case "19–21": 20
            case "22–24": 23
            case "25–27": 26
            case "28–30": 29
            case "31–34": 32
            case "35–39": 37
            default: 40
            }
        }
    }

    struct GenderCounts: Decodable {
        let man: Int
        let woman: Int
        let other: Int
    }

    static func date(_ value: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: value) { return date }
        return ISO8601DateFormatter().date(from: value)
    }

    static func timestamp(_ value: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: value)
    }

}

extension AppServices {
    static var configuredLiveBackend: SupabaseBackend {
        get throws { try SupabaseBackendProvider.live() }
    }
}
