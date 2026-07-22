import SwiftUI

struct OfferView: View {
    @Environment(DemoStore.self) private var store
    @Environment(AppRouter.self) private var router
    let venueID: String

    private var venue: Venue { store.venue(id: venueID) }

    var body: some View {
        let window = store.offerPresentationWindow(at: venueID)
        let effectiveExpiration = store.offerPresentationEndsAt(venueID)

        ExpiryAwareView(expiration: effectiveExpiration) { now in
            Group {
                if let offer = store.claimedOffer(at: venueID),
                   let window,
                   store.isOfferActive(at: venueID, now: now)
                {
                    ActiveVenuePass(venue: venue, offer: offer, window: window) {
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
    let venue: Venue
    let offer: VenueOffer
    let window: TimedOfferWindow
    let onDone: () -> Void

    @State private var isPresented = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                livePass
            }
            .scrollIndicators(.hidden)

            OfferBottomActionBar {
                if offer.redemptionMode == .externalLink,
                   let destinationURL = offer.destinationURL
                {
                    VStack(spacing: 4) {
                        Link(destination: destinationURL) {
                            HStack(spacing: 8) {
                                Text(offer.ctaLabel)
                                Image(systemName: "arrow.up.right")
                                    .font(.subheadline.weight(.semibold))
                                    .accessibilityHidden(true)
                            }
                        }
                        .buttonStyle(MetalSilverActionButtonStyle())
                        .accessibilityHint("Opens \(offer.sponsor?.displayName ?? "the partner") to sign up and claim this offer")
                        .accessibilityIdentifier("partner-offer-action")

                        Button("Back to Explore", action: onDone)
                            .buttonStyle(GhostButtonStyle())
                            .accessibilityIdentifier("back-to-explore")
                    }
                } else {
                    Button("Back to Explore", action: onDone)
                        .buttonStyle(SecondaryButtonStyle())
                        .accessibilityIdentifier("back-to-explore")
                }
            }
        }
        .background {
            if offer.kind == .partner {
                PartnerOfferAtmosphere()
            } else {
                Color.black.ignoresSafeArea()
            }
        }
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
        Group {
            if offer.kind == .partner {
                PartnerVenuePassSurface(venue: venue, offer: offer, window: window)
            } else {
                LiveVenuePassSurface(venue: venue, offer: offer, window: window)
            }
        }
            .padding(.horizontal, OutlyMetrics.edge)
            .padding(.top, offer.kind == .partner ? 28 : 44)
            .padding(.bottom, OutlyMetrics.spacing16)
            .opacity(isPresented ? 1 : 0)
            .scaleEffect(reduceMotion || isPresented ? 1 : 0.985)
    }
}

private struct LiveVenuePassSurface: View {
    @Environment(OutlyTheme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let venue: Venue
    let offer: VenueOffer
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

                Text(offer.redemptionMode == .staffDisplay ? (offer.staffDisplayTitle ?? offer.title) : offer.title)
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

                if window.hasCountdown {
                    CountdownOrbit(
                        seconds: remaining,
                        progress: window.remainingFraction(at: context.date),
                        duration: window.totalDuration,
                        reduceMotion: reduceMotion
                    )
                } else {
                    OpenEndedOfferProof()
                }

                DimensionalWingedOMark()
                    .padding(.top, 16)

                if let staffInstruction = offer.staffInstruction {
                    Text(staffInstruction)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct PartnerVenuePassSurface: View {
    @Environment(OutlyTheme.self) private var theme
    let venue: Venue
    let offer: VenueOffer
    let window: TimedOfferWindow

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 0) {
                Text(offer.sponsor?.disclosure.uppercased() ?? "OUTLY PARTNER")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.7)
                    .foregroundStyle(theme.secondaryText)

                PartnerSponsorMark(sponsor: offer.sponsor)
                    .padding(.top, 16)

                PartnerRule()
                    .padding(.vertical, 20)

                Text("UNLOCKED AT")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.25)
                    .foregroundStyle(theme.mutedText)

                Text(venue.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(theme.primaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 5)
                    .accessibilityAddTraits(.isHeader)

                Text(
                    offer.redemptionMode == .staffDisplay
                        ? (offer.staffDisplayTitle ?? offer.title)
                        : offer.title
                )
                    .font(.system(.largeTitle, design: .default, weight: .semibold))
                    .tracking(-0.7)
                    .foregroundStyle(theme.primaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 30)

                if let explanation = offer.explanation {
                    Text(explanation)
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }

                if window.hasCountdown {
                    PartnerTimeProof(
                        seconds: window.remainingSeconds(at: context.date),
                        progress: window.remainingFraction(at: context.date)
                    )
                    .padding(.top, 28)
                } else {
                    ValidityBadge()
                        .padding(.top, 32)
                }

                Image("WingedOMark")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 108, height: 54)
                    .padding(.top, 32)
                    .accessibilityHidden(true)

                if offer.redemptionMode == .staffDisplay,
                   let staffInstruction = offer.staffInstruction
                {
                    Text(staffInstruction)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .contain)
        }
    }
}

private struct PartnerSponsorMark: View {
    @Environment(OutlyTheme.self) private var theme
    let sponsor: OfferSponsor?

    var body: some View {
        Group {
            if let assetName = sponsor?.logoAssetName {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 168, maxHeight: 38)
            } else if let logoURL = sponsor?.logoURL {
                AsyncImage(url: logoURL) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else {
                        sponsorWordmark
                    }
                }
                .frame(maxWidth: 168, maxHeight: 38)
            } else {
                sponsorWordmark
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(sponsor?.displayName ?? "Offer partner")
    }

    private var sponsorWordmark: some View {
        Text(sponsor?.displayName.uppercased() ?? "PARTNER")
            .font(.title2.weight(.semibold))
            .fontWidth(.expanded)
            .tracking(3.2)
            .foregroundStyle(theme.partnerAccent)
    }
}

private struct PartnerRule: View {
    @Environment(OutlyTheme.self) private var theme

    var body: some View {
        HStack(spacing: 10) {
            Rectangle().fill(theme.primaryText.opacity(0.18)).frame(height: 0.5)
            Circle().fill(theme.partnerAccent).frame(width: 4, height: 4)
            Rectangle().fill(theme.primaryText.opacity(0.18)).frame(height: 0.5)
        }
        .frame(maxWidth: 250)
        .accessibilityHidden(true)
    }
}

private struct PartnerTimeProof: View {
    @Environment(OutlyTheme.self) private var theme
    @ScaledMetric(relativeTo: .largeTitle) private var countdownSize: CGFloat = 58
    let seconds: Int
    let progress: Double

    var body: some View {
        VStack(spacing: 12) {
            Text("VALID FOR")
                .font(.caption2.weight(.bold))
                .tracking(1.15)
                .foregroundStyle(theme.partnerAccent)

            CountdownText(seconds: seconds, preferredSize: countdownSize)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(theme.primaryText.opacity(0.12))
                    Capsule()
                        .fill(theme.partnerAccent)
                        .frame(width: geometry.size.width * max(0, min(1, progress)))
                }
            }
            .frame(width: 190, height: 2)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct PartnerOfferAtmosphere: View {
    @Environment(OutlyTheme.self) private var theme

    var body: some View {
        ZStack {
            Color.black
            RadialGradient(
                colors: [theme.partnerAccent.opacity(0.13), .clear],
                center: .top,
                startRadius: 10,
                endRadius: 430
            )
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.72)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

private struct OpenEndedOfferProof: View {
    @Environment(OutlyTheme.self) private var theme

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 62, weight: .light))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(theme.accent)
                .accessibilityHidden(true)
            ValidityBadge()
        }
        .frame(width: 300, height: 210)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
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
    var preferredSize: CGFloat? = nil

    private var text: String {
        if seconds >= 3600 {
            return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
        }
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private var spokenTime: String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        if hours > 0 {
            return "\(hours) hours, \(minutes) minutes, \(remainingSeconds) seconds remaining"
        }
        return "\(minutes) minutes, \(remainingSeconds) seconds remaining"
    }

    var body: some View {
        Text(text)
            .font(.system(size: min(100, preferredSize ?? scaledSize), weight: .medium, design: .default))
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
