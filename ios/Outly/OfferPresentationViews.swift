import SwiftUI

/// Compact discovery treatment for an eligible approved offer. It sits inside
/// existing venue surfaces rather than introducing another nested card.
struct OfferDiscoveryRow: View {
    @Environment(OutlyTheme.self) private var theme
    let offer: VenueOffer
    var compact = false

    var body: some View {
        HStack(alignment: .top, spacing: compact ? 9 : 12) {
            Rectangle()
                .fill(offer.kind == .partner ? theme.partnerAccent : theme.accent)
                .frame(
                    width: 2,
                    height: compact ? 38 : (offer.explanation == nil ? 44 : 58)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: compact ? 3 : 5) {
                HStack(spacing: 6) {
                    if offer.discoveryTreatment == .outlyExclusive {
                        Image("WingedOMark")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: compact ? 24 : 29, height: compact ? 12 : 15)
                            .foregroundStyle(theme.primaryText)
                            .accessibilityHidden(true)
                    }

                    Text(eyebrow)
                        .font(.caption2.weight(.bold))
                        .tracking(0.85)
                        .foregroundStyle(offer.kind == .partner ? theme.partnerAccent : theme.accent)
                        .lineLimit(1)
                }

                Text(offer.title)
                    .font(compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                    .foregroundStyle(theme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                if !compact, let explanation = offer.explanation {
                    Text(explanation)
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(offer.accessibilitySummary)
    }

    private var eyebrow: String {
        if let sponsor = offer.sponsor {
            return "OUTLY PARTNER · \(sponsor.displayName.uppercased())"
        }
        return (offer.discoveryBadgeLabel ?? "VENUE OFFER").uppercased()
    }
}

/// Small map/list badge that preserves venue identity. Outly exclusives use
/// the supplied winged-O; partner placements use a restrained sponsor initial.
struct OfferDiscoveryIcon: View {
    @Environment(OutlyTheme.self) private var theme
    let offer: VenueOffer
    var size: CGFloat = 26

    var body: some View {
        Group {
            if offer.discoveryTreatment == .outlyExclusive {
                Image("WingedOMark")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, size * 0.16)
                    .foregroundStyle(theme.primaryText)
            } else if let sponsor = offer.sponsor {
                if let assetName = sponsor.logoAssetName {
                    Image(assetName)
                        .resizable()
                        .scaledToFit()
                        .padding(size * 0.2)
                } else if let logoURL = sponsor.logoURL {
                    AsyncImage(url: logoURL) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFit()
                        } else {
                            fallbackSponsorInitial(sponsor)
                        }
                    }
                    .padding(size * 0.18)
                } else {
                    fallbackSponsorInitial(sponsor)
                }
            }
        }
        .frame(width: size, height: size)
        .background(theme.sunkenSurface.opacity(0.96), in: Circle())
        .overlay {
            Circle()
                .stroke(
                    offer.kind == .partner ? theme.partnerAccent.opacity(0.9) : theme.accent.opacity(0.9),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(0.45), radius: 3, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(offer.accessibilitySummary)
    }

    private func fallbackSponsorInitial(_ sponsor: OfferSponsor) -> some View {
        Text(String(sponsor.displayName.prefix(1)).uppercased())
            .font(.system(size: size * 0.43, weight: .bold, design: .rounded))
            .foregroundStyle(theme.primaryText)
    }
}
