import SwiftUI

struct WingedOMarkView: View {
    var compact = false

    var body: some View {
        Image("WingedOMark")
            .resizable()
            .scaledToFit()
            .frame(width: compact ? 58 : 108, height: compact ? 29 : 54)
            .accessibilityHidden(true)
    }
}

struct StandardActionButtonStyle: ButtonStyle {
    @Environment(OutlyTheme.self) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(minHeight: OutlyMetrics.controlHeight)
            .foregroundStyle(isEnabled ? theme.primaryText : theme.mutedText)
            .background(
                theme.elevatedSurface.opacity(configuration.isPressed ? 0.76 : 1),
                in: RoundedRectangle(cornerRadius: OutlyMetrics.buttonRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: OutlyMetrics.buttonRadius, style: .continuous)
                    .stroke(theme.border, lineWidth: 0.8)
            }
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .opacity(isEnabled ? 1 : 0.58)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct MetalSilverActionButtonStyle: ButtonStyle {
    @Environment(OutlyTheme.self) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(minHeight: OutlyMetrics.controlHeight)
            .foregroundStyle(isEnabled ? theme.sunkenSurface : theme.mutedText)
            .background {
                ZStack {
                    // This remains visible if Metal or the shader pipeline is unavailable.
                    LinearGradient(
                        colors: [
                            theme.chromeLight,
                            theme.chromeMid,
                            theme.chromeLight.opacity(0.92),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    if MetalSilverSurface.isSupported {
                        MetalSilverSurface(
                            isPressed: configuration.isPressed,
                            isEnabled: isEnabled,
                            reduceMotion: reduceMotion
                        )
                    }
                }
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: OutlyMetrics.buttonRadius,
                        style: .continuous
                    )
                )
            }
            .overlay {
                RoundedRectangle(cornerRadius: OutlyMetrics.buttonRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                theme.chromeLight.opacity(0.94),
                                theme.chromeDark.opacity(0.82),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.8
                    )
            }
            .shadow(color: .black.opacity(configuration.isPressed ? 0.16 : 0.34), radius: 8, y: 4)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .opacity(isEnabled ? 1 : 0.62)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(OutlyTheme.self) private var theme
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(minHeight: OutlyMetrics.controlHeight)
            .foregroundStyle(isEnabled ? theme.primaryText : theme.mutedText)
            .background(
                theme.primaryText.opacity(configuration.isPressed ? 0.08 : 0.025),
                in: RoundedRectangle(cornerRadius: OutlyMetrics.buttonRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: OutlyMetrics.buttonRadius, style: .continuous)
                    .stroke(isEnabled ? theme.border : theme.border.opacity(0.55), lineWidth: 1)
            }
    }
}

struct GhostButtonStyle: ButtonStyle {
    @Environment(OutlyTheme.self) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .frame(minHeight: OutlyMetrics.minimumTouchTarget)
            .foregroundStyle(theme.secondaryText.opacity(configuration.isPressed ? 0.65 : 1))
    }
}

struct IconCircleButtonStyle: ButtonStyle {
    @Environment(OutlyTheme.self) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .frame(width: OutlyMetrics.minimumTouchTarget, height: OutlyMetrics.minimumTouchTarget)
            .foregroundStyle(theme.primaryText)
            .background(theme.surface.opacity(configuration.isPressed ? 0.68 : 0.88), in: Circle())
            .overlay { Circle().stroke(theme.border, lineWidth: 1) }
    }
}

struct OutlyCard<Content: View>: View {
    @Environment(OutlyTheme.self) private var theme
    private let padding: CGFloat
    private let accent: Bool
    private let content: Content

    init(padding: CGFloat = 16, accent: Bool = false, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(theme.surface, in: RoundedRectangle(cornerRadius: OutlyMetrics.surfaceRadius, style: .continuous))
            .overlay {
                if accent {
                    RoundedRectangle(cornerRadius: OutlyMetrics.surfaceRadius, style: .continuous)
                        .stroke(theme.accent.opacity(0.24), lineWidth: 1)
                }
            }
    }
}

struct StatusPill: View {
    @Environment(OutlyTheme.self) private var theme
    let text: String
    var tone: Tone = .neutral

    enum Tone {
        case neutral
        case accent
        case success
        case warning
    }

    private var foreground: Color {
        switch tone {
        case .neutral: theme.secondaryText
        case .accent: theme.accent
        case .success: theme.success
        case .warning: theme.warning
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(foreground)
                .frame(width: 6, height: 6)
                .accessibilityHidden(true)
            Text(text)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(foreground)
        .accessibilityElement(children: .combine)
    }
}

struct ChoiceRow: View {
    @Environment(OutlyTheme.self) private var theme
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(selected ? theme.primaryText : theme.secondaryText)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? theme.accent : theme.mutedText)
            }
            .padding(.horizontal, 4)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(theme.border)
                    .frame(height: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct FlowHeader: View {
    @Environment(OutlyTheme.self) private var theme
    var title: String?
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .foregroundStyle(theme.primaryText)
            .accessibilityLabel("Go back")

            if let title {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(theme.primaryText)
                    .lineLimit(1)
            }

            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 6)
    }
}

struct BottomActionBar<Content: View>: View {
    @Environment(OutlyTheme.self) private var theme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, OutlyMetrics.compactEdge)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(theme.background)
            .overlay(alignment: .top) {
                Rectangle().fill(theme.border).frame(height: 1)
            }
    }
}

struct SectionEyebrow: View {
    @Environment(OutlyTheme.self) private var theme
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.footnote.weight(.semibold))
            .tracking(0.75)
            .foregroundStyle(theme.mutedText)
    }
}

struct AgeBarPill: View {
    @Environment(OutlyTheme.self) private var theme
    let distribution: AgeDistribution
    var compact = false
    var showsContainer = true

    private var averageAge: Int? { distribution.averageAge }

    var body: some View {
        if distribution.hasEnoughData, let averageAge {
            VStack(alignment: .leading, spacing: compact ? 7 : 10) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Average age")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                    Spacer(minLength: 8)
                    Text("\(averageAge)")
                        .font(compact ? .subheadline.weight(.bold) : .title3.weight(.bold))
                        .foregroundStyle(theme.primaryText)
                }

                GeometryReader { proxy in
                    let width = proxy.size.width
                    let height = proxy.size.height
                    let points = distribution.points
                    let spacing: CGFloat = compact ? 1.5 : 2
                    let availableWidth = width - (spacing * CGFloat(max(points.count - 1, 0)))
                    let barWidth = max(2, availableWidth / CGFloat(max(points.count, 1)))

                    HStack(alignment: .bottom, spacing: spacing) {
                        ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                            RoundedRectangle(cornerRadius: compact ? 1 : 1.5, style: .continuous)
                                .fill(
                                    point.age == averageAge
                                        ? theme.accent
                                        : theme.primaryText.opacity(0.13 + (0.23 * point.intensity))
                                )
                                .frame(
                                    width: barWidth,
                                    height: max(3, height * CGFloat(point.intensity))
                                )
                        }
                    }
                }
                .frame(height: compact ? 23 : 42)

                if !compact {
                    HStack {
                        Text(distribution.points.first.map { "\($0.age)" } ?? "")
                        Spacer()
                        if let peakAge = distribution.peakAge {
                            Text("Peak \(peakAge)")
                        }
                        Spacer()
                        Text(distribution.points.last.map { "\($0.age)+" } ?? "")
                    }
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(theme.mutedText)
                }
            }
            .padding(compact ? 10 : 12)
            .background(
                showsContainer ? theme.primaryText.opacity(0.035) : .clear,
                in: RoundedRectangle(cornerRadius: 11, style: .continuous)
            )
            .overlay {
                if showsContainer {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(theme.border, lineWidth: 0.75)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Age distribution")
            .accessibilityValue(
                "Average age \(averageAge), peak age \(distribution.peakAge ?? averageAge), range \(distribution.points.first?.age ?? 0) to \(distribution.points.last?.age ?? 0)"
            )
        } else {
            Text("Crowd data pending")
            .font(.caption)
            .foregroundStyle(theme.mutedText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, compact ? 8 : 12)
        }
    }
}

struct GenderMixLine: View {
    @Environment(OutlyTheme.self) private var theme
    let mix: GenderMix
    var compact = false

    private var menFraction: CGFloat {
        let total = max(mix.menPercentage + mix.womenPercentage, 1)
        return CGFloat(mix.menPercentage) / CGFloat(total)
    }

    var body: some View {
        VStack(spacing: compact ? 5 : 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(mix.menPercentage)%")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.crowdCool)
                Text("Men")
                    .font(.caption2)
                    .foregroundStyle(theme.secondaryText)
                Spacer()
                Text("Women")
                    .font(.caption2)
                    .foregroundStyle(theme.secondaryText)
                Text("\(mix.womenPercentage)%")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.crowdWarm)
            }

            GeometryReader { proxy in
                let gap: CGFloat = 3
                let usableWidth = max(proxy.size.width - gap, 0)

                HStack(spacing: gap) {
                    Capsule()
                        .fill(theme.crowdCool)
                        .frame(width: usableWidth * menFraction)
                    Capsule()
                        .fill(theme.crowdWarm)
                }
            }
            .frame(height: compact ? 3 : 4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(mix.accessibilitySummary)
    }
}

struct CrowdInsightsSurface: View {
    @Environment(OutlyTheme.self) private var theme
    let venue: Venue

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Tonight’s crowd")
                    .font(.headline)
                Spacer()
                Text("Live estimate")
                    .font(.caption)
                    .foregroundStyle(theme.mutedText)
            }

            AgeBarPill(distribution: venue.ageDistribution, showsContainer: false)

            GenderMixLine(mix: venue.genderMix)
                .padding(.horizontal, 2)
        }
        .padding(14)
        .background(
            theme.surface,
            in: RoundedRectangle(cornerRadius: OutlyMetrics.surfaceRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: OutlyMetrics.surfaceRadius, style: .continuous)
                .stroke(theme.border, lineWidth: 0.75)
        }
    }
}

struct SuccessSymbol: View {
    @Environment(OutlyTheme.self) private var theme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(
                    AngularGradient(
                        colors: [
                            theme.chromeDark,
                            theme.chromeLight,
                            theme.chromeMid,
                            theme.chromeDark,
                            theme.chromeLight,
                        ],
                        center: .center
                    )
                )

            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(theme.background)
                .padding(2.5)

            Image(systemName: "checkmark")
                .font(.system(size: 25, weight: .black))
                .foregroundStyle(theme.accent)
        }
        .frame(width: 62, height: 62)
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(theme.chromeLight.opacity(0.42), lineWidth: 0.7)
        }
        .shadow(color: .black.opacity(0.36), radius: 12, y: 8)
        .accessibilityHidden(true)
    }
}

struct MapGlassSurface<Content: View>: View {
    @Environment(OutlyTheme.self) private var theme
    private let cornerRadius: CGFloat
    private let content: Content

    init(cornerRadius: CGFloat = OutlyMetrics.mapSurfaceRadius, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    @ViewBuilder
    var body: some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(
                    .regular.tint(theme.secondaryBackground.opacity(0.18)),
                    in: .rect(cornerRadius: cornerRadius)
                )
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(theme.primaryText.opacity(0.1), lineWidth: 0.75)
                }
        }
    }
}

struct ExpiryAwareView<Content: View>: View {
    let expiration: Date?
    private let content: (Date) -> Content
    @State private var now = Date()

    init(expiration: Date?, @ViewBuilder content: @escaping (Date) -> Content) {
        self.expiration = expiration
        self.content = content
    }

    var body: some View {
        content(now)
            .task(id: expiration) {
                now = Date()
                guard let expiration else { return }
                let delay = expiration.timeIntervalSince(now)
                guard delay > 0 else { return }

                do {
                    try await Task.sleep(for: .seconds(delay))
                    guard !Task.isCancelled else { return }
                    now = Date()
                } catch is CancellationError {
                    return
                } catch {
                    return
                }
            }
    }
}

extension View {
    func outlyScreenBackground() -> some View {
        modifier(OutlyScreenBackgroundModifier())
    }
}

private struct OutlyScreenBackgroundModifier: ViewModifier {
    @Environment(OutlyTheme.self) private var theme

    func body(content: Content) -> some View {
        content
            .background(theme.background.ignoresSafeArea())
            .foregroundStyle(theme.primaryText)
            .tint(theme.accent)
            .toolbarBackground(theme.secondaryBackground, for: .navigationBar, .tabBar)
            .toolbarColorScheme(.dark, for: .navigationBar, .tabBar)
    }
}

extension View {
    func outlyNavigationTitle(_ title: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}
