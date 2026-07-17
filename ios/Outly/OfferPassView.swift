import SwiftUI

struct OfferView: View {
    @Environment(DemoStore.self) private var store
    @Environment(AppRouter.self) private var router
    let venueID: String

    private var venue: Venue { VenueCatalog.venue(id: venueID) }

    var body: some View {
        let window = store.offerWindow(at: venueID)

        ExpiryAwareView(expiration: window?.expiresAt) { now in
            Group {
                if let window, window.isActive(at: now) {
                    ActiveVenuePass(venue: venue, window: window) {
                        router.returnToExplore()
                    }
                } else {
                    ExpiredVenuePass(venue: venue) {
                        router.returnToExplore()
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .outlyScreenBackground()
    }
}

private struct ActiveVenuePass: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let venue: Venue
    let window: TimedOfferWindow
    let onDone: () -> Void

    @State private var isPresented = false

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    ScrollView {
                        livePass
                    }
                    .scrollIndicators(.hidden)
                } else {
                    livePass
                        .frame(maxHeight: .infinity, alignment: .top)
                }
            }

            OfferBottomActionBar {
                Button("Back to Explore", action: onDone)
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityIdentifier("back-to-explore")
            }
        }
        .background(Color.black.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("active-offer-pass")
        .task {
            guard !isPresented else { return }

            if reduceMotion {
                isPresented = true
            } else {
                withAnimation(.timingCurve(0.2, 0.85, 0.25, 1, duration: 0.42)) {
                    isPresented = true
                }
            }
        }
    }

    private var livePass: some View {
        LiveVenuePassSurface(venue: venue, window: window)
            .padding(.horizontal, OutlyMetrics.edge)
            .padding(.top, 44)
            .padding(.bottom, OutlyMetrics.spacing16)
            .opacity(isPresented ? 1 : 0)
            .scaleEffect(reduceMotion || isPresented ? 1 : 0.985)
    }
}

private struct LiveVenuePassSurface: View {
    @Environment(OutlyTheme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let venue: Venue
    let window: TimedOfferWindow

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = window.remainingSeconds(at: context.date)

            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    Text("VALID AT")
                        .font(.caption2.weight(.semibold))
                        .tracking(1.4)
                        .foregroundStyle(theme.mutedText)

                    Text(venue.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(theme.primaryText)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                }

                Text(venue.offer ?? "Tonight's venue offer")
                    .font(.system(.title, design: .default, weight: .semibold))
                    .tracking(-0.5)
                    .foregroundStyle(theme.primaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 16)

                Rectangle()
                    .fill(theme.primaryText.opacity(0.12))
                    .frame(height: 1)
                    .padding(.top, 18)
                    .padding(.bottom, 14)
                    .accessibilityHidden(true)

                CountdownOrbit(
                    seconds: remaining,
                    progress: window.remainingFraction(at: context.date),
                    duration: window.totalDuration,
                    reduceMotion: reduceMotion
                )

                DimensionalWingedOMark()
                    .padding(.top, 16)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct CountdownOrbit: View {
    let seconds: Int
    let progress: Double
    let duration: TimeInterval
    let reduceMotion: Bool

    var body: some View {
        ZStack {
            OfferGlassOrbit(
                progress: progress,
                duration: duration,
                reduceMotion: reduceMotion
            )

            VStack(spacing: 18) {
                CountdownText(seconds: seconds)
                ValidityBadge()
            }
        }
        .frame(width: 326, height: 326)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }
}

private struct CountdownText: View {
    @Environment(OutlyTheme.self) private var theme
    @ScaledMetric(relativeTo: .largeTitle) private var scaledSize: CGFloat = 80
    let seconds: Int

    private var text: String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private var spokenTime: String {
        "\(seconds / 60) minutes, \(seconds % 60) seconds remaining"
    }

    var body: some View {
        Text(text)
            .font(.system(size: min(100, scaledSize), weight: .medium, design: .default))
            .monospacedDigit()
            .tracking(-2.2)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .foregroundStyle(theme.primaryText)
            .contentTransition(.numericText(countsDown: true))
            .accessibilityLabel(spokenTime)
            .accessibilityIdentifier("offer-countdown")
            .accessibilityAddTraits(.updatesFrequently)
    }
}

private struct ValidityBadge: View {
    @Environment(OutlyTheme.self) private var theme

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "checkmark.seal.fill")
                .font(.caption.weight(.semibold))
                .accessibilityHidden(true)

            Text("VALID NOW")
                .font(.caption.weight(.bold))
                .tracking(1.15)
        }
        .foregroundStyle(theme.accent)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Offer valid now")
    }
}

private struct ExpiredVenuePass: View {
    @Environment(OutlyTheme.self) private var theme
    let venue: Venue
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 28)

            VStack(spacing: 0) {
                Text(venue.name)
                    .font(.caption.weight(.semibold))
                    .tracking(2.2)
                    .foregroundStyle(theme.mutedText)
                    .multilineTextAlignment(.center)

                Text("Offer expired")
                    .font(.system(.title, design: .default, weight: .semibold))
                    .foregroundStyle(theme.secondaryText)
                    .padding(.top, 28)

                Image("WingedOMark")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 70)
                    .foregroundStyle(theme.mutedText)
                    .opacity(0.42)
                    .padding(.top, 38)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, OutlyMetrics.edge)

            Spacer(minLength: OutlyMetrics.spacing24)

            OfferBottomActionBar {
                Button("Back to Explore", action: onDone)
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityIdentifier("back-to-explore")
            }
        }
        .background(Color.black.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("expired-offer-pass")
    }
}

private struct OfferBottomActionBar<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, OutlyMetrics.edge)
            .padding(.vertical, OutlyMetrics.spacing8)
            .background(Color.black)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 0.5)
            }
    }
}
