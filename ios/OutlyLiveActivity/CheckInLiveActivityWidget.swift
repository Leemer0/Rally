import ActivityKit
import SwiftUI
import WidgetKit

@main
struct OutlyLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CheckInActivityAttributes.self) { context in
            CheckInLockScreenView(context: context)
                .activityBackgroundTint(LiveActivityPalette.background)
                .activitySystemActionForegroundColor(LiveActivityPalette.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    OutlyActivityMark(width: 44)
                        .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    ActivityStatusView(
                        state: context.state,
                        isStale: context.isStale,
                        compact: false
                    )
                    .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 1) {
                        Text("VALID AT")
                            .font(.caption2.weight(.semibold))
                            .tracking(1.15)
                            .foregroundStyle(LiveActivityPalette.secondary)

                        Text(context.attributes.venueName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(LiveActivityPalette.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedActivityDetail(context: context)
                }
            } compactLeading: {
                OutlyActivityMark(width: 28)
            } compactTrailing: {
                ActivityStatusView(
                    state: context.state,
                    isStale: context.isStale,
                    compact: true
                )
            } minimal: {
                OutlyActivityMark(
                    width: 20,
                    accessibilityLabel: context.state.offerExpiresAt == nil || context.isStale
                        ? "Outly check-in"
                        : "Outly offer active"
                )
            }
            .keylineTint(LiveActivityPalette.accent)
        }
    }
}

private struct CheckInLockScreenView: View {
    let context: ActivityViewContext<CheckInActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                OutlyActivityMark(width: 58)
                Spacer(minLength: 12)
                ActivityStatusView(
                    state: context.state,
                    isStale: context.isStale,
                    compact: false
                )
            }

            Rectangle()
                .fill(LiveActivityPalette.hairline)
                .frame(height: 0.5)
                .padding(.vertical, 11)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("VALID AT")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.2)
                    .foregroundStyle(LiveActivityPalette.secondary)

                Text(context.attributes.venueName)
                    .font(.headline)
                    .foregroundStyle(LiveActivityPalette.primary)
                    .lineLimit(1)

                Text(detailText)
                    .font(.subheadline)
                    .foregroundStyle(LiveActivityPalette.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }

            if let interval = offerInterval {
                LiveOfferProgress(interval: interval)
                    .padding(.top, 11)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
    }

    private var offerInterval: ClosedRange<Date>? {
        guard !context.isStale else { return nil }
        return context.state.offerInterval
    }

    private var detailText: String {
        guard offerInterval != nil else { return "Venue confirmed" }
        return context.attributes.offerTitle ?? "Venue offer active"
    }
}

private struct ExpandedActivityDetail: View {
    let context: ActivityViewContext<CheckInActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                Circle()
                    .fill(LiveActivityPalette.accent)
                    .frame(width: 5, height: 5)
                    .accessibilityHidden(true)

                Text(detailText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LiveActivityPalette.primary)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }

            if let interval = offerInterval {
                LiveOfferProgress(interval: interval)
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 5)
        .accessibilityElement(children: .combine)
    }

    private var offerInterval: ClosedRange<Date>? {
        guard !context.isStale else { return nil }
        return context.state.offerInterval
    }

    private var detailText: String {
        guard offerInterval != nil else { return "Venue confirmed" }
        return context.attributes.offerTitle ?? "Venue offer active"
    }
}

private struct ActivityStatusView: View {
    let state: CheckInActivityAttributes.ContentState
    let isStale: Bool
    let compact: Bool

    var body: some View {
        Group {
            if let interval = offerInterval, !isStale {
                VStack(alignment: .trailing, spacing: compact ? 0 : 3) {
                    Text(
                        timerInterval: interval,
                        pauseTime: interval.upperBound,
                        countsDown: true,
                        showsHours: false
                    )
                    .font(compact ? .caption.weight(.semibold) : .title2.weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(compact ? LiveActivityPalette.accent : LiveActivityPalette.primary)
                    .contentTransition(.numericText(countsDown: true))

                    if !compact {
                        ValidityIndicator(text: "VALID NOW")
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Offer time remaining")
                .accessibilityValue(
                    Text(
                        timerInterval: interval,
                        pauseTime: interval.upperBound,
                        countsDown: true,
                        showsHours: false
                    )
                )
            } else if compact {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LiveActivityPalette.accent)
                    .accessibilityLabel("Checked in")
            } else {
                ValidityIndicator(text: "CHECKED IN")
                    .accessibilityLabel("Checked in")
            }
        }
    }

    private var offerInterval: ClosedRange<Date>? {
        state.offerInterval
    }
}

private struct OutlyActivityMark: View {
    var width: CGFloat = 54
    var accessibilityLabel = "Outly"

    var body: some View {
        Image("winged-o")
            .renderingMode(.original)
            .resizable()
            .scaledToFit()
            .frame(width: width, height: width / 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct ValidityIndicator: View {
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(LiveActivityPalette.accent)
                .frame(width: 5, height: 5)
                .accessibilityHidden(true)

            Text(text)
                .font(.caption2.weight(.bold))
                .tracking(0.9)
        }
        .foregroundStyle(LiveActivityPalette.accent)
    }
}

private struct LiveOfferProgress: View {
    let interval: ClosedRange<Date>

    var body: some View {
        ProgressView(timerInterval: interval, countsDown: true)
            .progressViewStyle(.linear)
            .tint(LiveActivityPalette.accent)
            .scaleEffect(y: 0.65, anchor: .center)
            .accessibilityHidden(true)
    }
}

private extension CheckInActivityAttributes.ContentState {
    var offerInterval: ClosedRange<Date>? {
        guard let expiration = offerExpiresAt else { return nil }
        return checkedInAt ... max(checkedInAt, expiration)
    }
}

private enum LiveActivityPalette {
    static let background = Color(red: 5 / 255, green: 7 / 255, blue: 10 / 255)
    static let accent = Color(red: 199 / 255, green: 255 / 255, blue: 61 / 255)
    static let primary = Color.white
    static let secondary = Color.white.opacity(0.62)
    static let hairline = Color.white.opacity(0.14)
}
