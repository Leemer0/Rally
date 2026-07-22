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
                    if offer.kind == .partner {
                        Image("SponsoredOfferStar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: compact ? 14 : 16, height: compact ? 14 : 16)
                            .shadow(color: .black.opacity(0.28), radius: 1, y: 1)
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

/// A small uncontained chrome star for sponsored map/list placements. Regular
/// offers intentionally have no discovery icon to keep venue surfaces quiet.
struct OfferDiscoveryIcon: View {
    let offer: VenueOffer
    var size: CGFloat = 26

    @ViewBuilder
    var body: some View {
        if offer.kind == .partner {
            Image("SponsoredOfferStar")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(offer.accessibilitySummary)
        }
    }
}
