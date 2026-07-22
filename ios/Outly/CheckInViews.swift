import SwiftUI
import UIKit

private enum CheckInPhase: Equatable {
    case locating
    case confirmed
    case failed
}

struct CheckInAttemptKeys: Equatable, Sendable {
    private(set) var checkIn = UUID()
    private(set) var claim = UUID()

    mutating func prepareForRetry(after error: Error) {
        guard let backendError = error as? SupabaseBackendError,
              backendError.shouldRotateCheckInAttempt
        else {
            return
        }
        checkIn = UUID()
        claim = UUID()
    }
}

/// Check-in is one continuous surface: selecting Check in starts verification,
/// a restrained location pulse resolves in place, and success proceeds directly
/// to the offer. Permission and geofence failures remain inline for recovery.
struct CheckInIntroView: View {
    @Environment(DemoStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(OutlyTheme.self) private var theme
    @Environment(\.appServices) private var services
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let venueID: String

    @State private var phase: CheckInPhase
    @State private var verificationTask: Task<Void, Never>?
    @State private var errorMessage: String?
    @State private var locationError: LocationVerificationError?
    @State private var attemptKeys = CheckInAttemptKeys()
    @State private var checkInWasVerified = false
    @State private var shouldAutoVerify: Bool

    private var venue: Venue { store.venue(id: venueID) }

    init(venueID: String) {
        self.venueID = venueID

#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        let isScreenshotFixture = arguments.contains { $0.hasPrefix("--screen=") }
        if arguments.contains("--screen=checkin-confirmed") {
            _phase = State(initialValue: .confirmed)
            _errorMessage = State(initialValue: nil)
        } else if arguments.contains("--screen=checkin-failed") {
            _phase = State(initialValue: .failed)
            _errorMessage = State(initialValue: "Move closer and try again.")
        } else {
            _phase = State(initialValue: .locating)
            _errorMessage = State(initialValue: nil)
        }
        _shouldAutoVerify = State(initialValue: !isScreenshotFixture)
#else
        _phase = State(initialValue: .locating)
        _errorMessage = State(initialValue: nil)
        _shouldAutoVerify = State(initialValue: true)
#endif
    }

    var body: some View {
        Group {
            switch phase {
            case .locating, .confirmed:
                verificationContent
            case .failed:
                failureContent
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .outlyScreenBackground()
        .onAppear {
            guard shouldAutoVerify else { return }
            shouldAutoVerify = false
            beginLocationVerification()
        }
        .onDisappear {
            verificationTask?.cancel()
            verificationTask = nil
        }
    }

    private var verificationContent: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                venueEyebrow

                Spacer()

                VStack(spacing: 28) {
                    LocationPulseView(confirmed: phase == .confirmed)
                        .frame(width: 88, height: 88)

                    verificationStatus
                }

                Spacer(minLength: 96)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            cancelButton
        }
    }

    private var failureContent: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                ScrollView {
                    ZStack(alignment: .topLeading) {
                        VStack(spacing: 0) {
                            venueEyebrow

                            Spacer(minLength: 64)

                            VStack(spacing: 20) {
                                Image(systemName: checkInWasVerified ? "checkmark.circle.fill" : "location.slash")
                                    .font(.title2.weight(.medium))
                                    .foregroundStyle(checkInWasVerified ? theme.accent : theme.mutedText)
                                    .frame(width: 44, height: 44)
                                    .accessibilityHidden(true)

                                VStack(spacing: 8) {
                                    Text(failureTitle)
                                        .font(.title2.weight(.semibold))
                                        .tracking(-0.35)
                                        .foregroundStyle(theme.primaryText)
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .accessibilityIdentifier("location-failed")

                                    if let errorMessage {
                                        Text(errorMessage)
                                            .font(.subheadline)
                                            .foregroundStyle(theme.secondaryText)
                                            .multilineTextAlignment(.center)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .accessibilityIdentifier("checkin-error")
                                    }
                                }
                                .frame(maxWidth: 280)
                                .accessibilityElement(children: .contain)

                                if shouldOfferSettingsRecovery {
                                    Button("Open Settings", action: openSettings)
                                        .buttonStyle(GhostButtonStyle())
                                        .accessibilityHint("Opens the app’s location permission settings")
                                }
                            }
                            .padding(.horizontal, OutlyMetrics.edge)

                            Spacer(minLength: 48)
                        }
                        .frame(maxWidth: .infinity, minHeight: proxy.size.height)

                        cancelButton
                    }
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
            }

            BottomActionBar {
                if checkInWasVerified {
                    VStack(spacing: 4) {
                        Button("Try offer again", action: beginLocationVerification)
                            .buttonStyle(MetalSilverActionButtonStyle())
                            .accessibilityHint("Retries the offer without creating another check-in")
                            .accessibilityIdentifier("retry-offer")
                        Button("Back to Explore") { router.returnToExplore() }
                            .buttonStyle(GhostButtonStyle())
                    }
                } else {
                    Button("Try again", action: beginLocationVerification)
                        .buttonStyle(MetalSilverActionButtonStyle())
                        .accessibilityHint("Checks your current location again")
                        .accessibilityIdentifier("retry-checkin")
                }
            }
        }
    }

    private var venueEyebrow: some View {
        Text(venue.name.uppercased())
            .font(.caption2.weight(.medium))
            .tracking(2.0)
            .foregroundStyle(theme.mutedText)
            .accessibilityHidden(true)
            .padding(.top, 18)
    }

    private var cancelButton: some View {
        Button(action: cancelVerification) {
            Image(systemName: "chevron.left")
                .font(.body.weight(.semibold))
                .foregroundStyle(theme.secondaryText)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Cancel check-in")
        .accessibilityHint("Returns to the venue")
        .padding(.leading, 4)
        .padding(.top, 1)
    }

    private var verificationStatus: some View {
        Text(statusTitle)
            .font(.title2.weight(.regular))
            .tracking(-0.35)
            .foregroundStyle(theme.primaryText)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .accessibilityLabel(statusAccessibilityLabel)
            .accessibilityIdentifier(statusIdentifier)
    }

    private var statusTitle: String {
        switch phase {
        case .locating: "Confirming location"
        case .confirmed: "Location confirmed"
        case .failed: failureTitle
        }
    }

    private var failureTitle: String {
        if checkInWasVerified { return "You’re checked in" }
        return switch locationError {
        case .permissionDenied:
            "Location access is off"
        case .servicesDisabled:
            "Location Services are off"
        case .locationUnavailable, .staleLocation, .insufficientAccuracy, .requestInProgress:
            "Location unavailable"
        case nil:
            "You’re outside the venue"
        }
    }

    private var statusAccessibilityLabel: String {
        switch phase {
        case .locating: "Confirming location at \(venue.name)"
        case .confirmed: "Location confirmed at \(venue.name)"
        case .failed where checkInWasVerified: "Checked in at \(venue.name), offer unavailable"
        case .failed: "Check-in failed at \(venue.name)"
        }
    }

    private var statusIdentifier: String {
        switch phase {
        case .locating: "location-confirming"
        case .confirmed: "location-confirmed"
        case .failed: "location-failed"
        }
    }

    private func cancelVerification() {
        verificationTask?.cancel()
        verificationTask = nil
        dismiss()
    }

    private func beginLocationVerification() {
        guard verificationTask == nil else { return }
        errorMessage = nil
        locationError = nil
        checkInWasVerified = false
        phase = .locating
        verificationTask = Task { await verifyLocation() }
    }

    private func verifyLocation() async {
        do {
            guard venue.isAvailable else {
                throw SupabaseBackendError.server(
                    code: "VENUE_UNAVAILABLE",
                    message: "This venue is no longer available tonight.",
                    verifiedCheckIn: nil
                )
            }
            async let minimumPresentation: Void = Task.sleep(for: .milliseconds(1_300))
            let evidence = try await services.captureLocationEvidence()
            let result = try await services.checkIn(
                venue,
                store.plan?.venueID == venueID ? store.plan?.id : nil,
                evidence,
                attemptKeys.checkIn,
                attemptKeys.claim
            )
            try await minimumPresentation
            guard !Task.isCancelled else { return }

            phase = .confirmed
            UIAccessibility.post(
                notification: .announcement,
                argument: "Location confirmed at \(venue.name)"
            )

            try await Task.sleep(for: .milliseconds(reduceMotion ? 300 : 650))
            guard !Task.isCancelled else { return }

            // The backend timestamp drives the offer, map card, and Live Activity.
            let checkedInAt = result.checkedInAt
            store.applyServerCheckIn(result)
            let offerWindow = store.offerWindow(at: venueID)
            let claimedOffer = store.claimedOffer(at: venueID)
            let effectiveOfferEnd = store.offerPresentationEndsAt(venueID)
            Task {
                _ = try? await CheckInLiveActivityManager.shared.start(
                    venueID: venue.id,
                    venueName: venue.name,
                    checkedInAt: checkedInAt,
                    offerTitle: claimedOffer?.title,
                    offerKind: claimedOffer?.kind,
                    sponsorDisplayName: claimedOffer?.sponsor?.displayName,
                    offerHasCountdown: offerWindow?.hasCountdown == true,
                    activityStaleAt: effectiveOfferEnd,
                    offerExpiresAt: offerWindow?.hasCountdown == true ? effectiveOfferEnd : nil
                )
            }
            verificationTask = nil

            if claimedOffer != nil {
                router.replaceCurrent(with: .offer(venueID))
            } else {
                router.returnToExplore()
                store.selectVenue(venueID)
            }
        } catch is CancellationError {
            verificationTask = nil
        } catch {
            verificationTask = nil
            if let backendError = error as? SupabaseBackendError,
               let verifiedCheckIn = backendError.verifiedCheckIn
            {
                store.applyServerCheckIn(ServerCheckInResult(
                    checkInID: verifiedCheckIn.id,
                    venueID: verifiedCheckIn.venueID,
                    checkedInAt: verifiedCheckIn.checkedInAt,
                    offer: nil,
                    offerWindow: nil,
                    entitlementEndsAt: nil
                ))
                presentVerifiedCheckInOfferFailure()
                return
            }

            attemptKeys.prepareForRetry(after: error)
            let resolvedError = error as? LocationVerificationError
            presentFailure(
                failureMessage(for: resolvedError)
                    ?? (error as? LocalizedError)?.errorDescription
                    ?? "Wait a moment and try again.",
                locationError: resolvedError
            )
        }
    }

    private func presentVerifiedCheckInOfferFailure() {
        phase = .failed
        checkInWasVerified = true
        locationError = nil
        errorMessage = "Your location was confirmed, but the offer didn’t load."
        HapticManager.shared.success(enabled: store.state.hapticsEnabled)
        UIAccessibility.post(
            notification: .announcement,
            argument: "You’re checked in at \(venue.name). Your offer didn’t load."
        )
    }

    private var shouldOfferSettingsRecovery: Bool {
        locationError == .permissionDenied || locationError == .servicesDisabled
    }

    private func presentFailure(
        _ message: String,
        locationError: LocationVerificationError? = nil
    ) {
        phase = .failed
        errorMessage = message
        self.locationError = locationError
        HapticManager.shared.error(enabled: store.state.hapticsEnabled)
        UIAccessibility.post(notification: .announcement, argument: "Couldn’t check in. \(message)")
    }

    private func failureMessage(for error: LocationVerificationError?) -> String? {
        switch error {
        case .permissionDenied:
            "Allow access in Settings."
        case .servicesDisabled:
            "Turn them on in Settings."
        case .locationUnavailable, .staleLocation, .insufficientAccuracy, .requestInProgress:
            "Wait a moment and try again."
        case nil:
            nil
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

private struct LocationPulseView: View {
    @Environment(OutlyTheme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let confirmed: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion || confirmed)) { context in
            let cycle = context.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: 1.6) / 1.6
            let progress = reduceMotion || confirmed ? 0.0 : cycle

            ZStack {
                if !confirmed {
                    Circle()
                        .fill(theme.accent.opacity((1 - progress) * 0.22))
                        .frame(width: 54, height: 54)
                        .scaleEffect(0.55 + (progress * 0.9))

                    Circle()
                        .fill(theme.accent)
                        .frame(width: 16, height: 16)
                        .shadow(color: theme.accent.opacity(0.28), radius: 5)
                } else {
                    Circle()
                        .fill(theme.accent)
                        .frame(width: 46, height: 46)

                    Image(systemName: "checkmark")
                        .font(.body.weight(.bold))
                        .foregroundStyle(Color.black)
                }
            }
            .animation(
                reduceMotion
                    ? nil
                    : .timingCurve(0.16, 1, 0.3, 1, duration: 0.28),
                value: confirmed
            )
        }
        .accessibilityHidden(true)
    }
}
