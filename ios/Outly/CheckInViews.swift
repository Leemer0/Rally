import SwiftUI
import UIKit

private enum CheckInPhase: Equatable {
    case locating
    case confirmed
    case failed
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
    @State private var shouldAutoVerify: Bool

    private var venue: Venue { VenueCatalog.venue(id: venueID) }

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
                                Image(systemName: "location.slash")
                                    .font(.title2.weight(.medium))
                                    .foregroundStyle(theme.mutedText)
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
                Button("Try again", action: beginLocationVerification)
                    .buttonStyle(MetalSilverActionButtonStyle())
                    .accessibilityHint("Checks your current location again")
                    .accessibilityIdentifier("retry-checkin")
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
        switch locationError {
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
        phase = .locating
        verificationTask = Task { await verifyLocation() }
    }

    private func verifyLocation() async {
        do {
            async let minimumPresentation: Void = Task.sleep(for: .milliseconds(1_300))
            let verified = try await services.verifyApproximateLocation(venue)
            try await minimumPresentation
            guard !Task.isCancelled else { return }

            guard verified else {
                verificationTask = nil
                presentFailure("Move closer and try again.")
                return
            }

            phase = .confirmed
            UIAccessibility.post(
                notification: .announcement,
                argument: "Location confirmed at \(venue.name)"
            )

            try await Task.sleep(for: .milliseconds(reduceMotion ? 300 : 650))
            guard !Task.isCancelled else { return }

            // The stored check-in, offer countdown, map card, and Live Activity
            // all share this exact timestamp.
            let checkedInAt = Date()
            store.checkIn(to: venueID, now: checkedInAt)
            let offerExpiresAt = store.offerWindow(at: venueID)?.expiresAt
            Task {
                _ = try? await CheckInLiveActivityManager.shared.start(
                    venueID: venue.id,
                    venueName: venue.name,
                    checkedInAt: checkedInAt,
                    offerTitle: venue.offer,
                    offerExpiresAt: offerExpiresAt
                )
            }
            verificationTask = nil

            if venue.offer != nil {
                router.replaceCurrent(with: .offer(venueID))
            } else {
                router.returnToExplore()
                store.selectVenue(venueID)
            }
        } catch is CancellationError {
            verificationTask = nil
        } catch {
            verificationTask = nil
            let resolvedError = error as? LocationVerificationError
            presentFailure(
                failureMessage(for: resolvedError)
                    ?? (error as? LocalizedError)?.errorDescription
                    ?? "Wait a moment and try again.",
                locationError: resolvedError
            )
        }
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
