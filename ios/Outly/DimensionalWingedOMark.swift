import SwiftUI

enum DimensionalMarkState: Equatable {
    case idle
    case searching
    case confirmed
    case failed
}

/// A layered, animated treatment of the Outly mark. The small offsets create
/// an extruded edge while the verification state controls its spatial motion.
struct DimensionalWingedOMark: View {
    @Environment(OutlyTheme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var state: DimensionalMarkState = .idle
    var width: CGFloat = 148

    var body: some View {
        Group {
            if state == .searching, !reduceMotion {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                    mark(phase: context.date.timeIntervalSinceReferenceDate)
                }
            } else {
                mark(phase: 0)
            }
        }
        .frame(width: width, height: width * 0.48)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Outly authenticity mark")
    }

    private func mark(phase: TimeInterval) -> some View {
        let yaw = state == .searching ? sin(phase * 2.1) * 14 : 0
        let pitch = state == .searching ? cos(phase * 1.55) * 5 : -1.5
        let lift = state == .searching ? sin(phase * 2.6) * 2.5 : 0
        let scale = state == .confirmed ? 1.04 : 1.0

        return ZStack {
            ForEach(0 ..< 5, id: \.self) { layer in
                wingedMark
                    .foregroundStyle(theme.chromeDark.opacity(0.76))
                    .offset(
                        x: CGFloat(4 - layer) * 0.42,
                        y: CGFloat(5 - layer) * 0.72
                    )
            }

            wingedMark
                .foregroundStyle(frontGradient)
        }
        .compositingGroup()
        .shadow(color: glowColor, radius: state == .confirmed ? 11 : 6)
        .shadow(color: .black.opacity(0.42), radius: 4, y: 4)
        .rotation3DEffect(.degrees(pitch), axis: (x: 1, y: 0, z: 0), perspective: 0.7)
        .rotation3DEffect(.degrees(yaw), axis: (x: 0, y: 1, z: 0), perspective: 0.62)
        .offset(y: CGFloat(lift))
        .scaleEffect(CGFloat(scale))
        .opacity(state == .searching ? 0.9 : 1)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.46), value: state)
    }

    private var frontGradient: LinearGradient {
        let colors: [Color]
        switch state {
        case .confirmed:
            colors = [theme.primaryText, theme.chromeLight, theme.accent, theme.chromeMid]
        case .failed:
            colors = [theme.primaryText, theme.error, theme.chromeDark]
        case .idle, .searching:
            colors = [theme.primaryText, theme.chromeMid, theme.chromeLight, theme.chromeDark]
        }

        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    private var glowColor: Color {
        switch state {
        case .confirmed: theme.accent.opacity(0.34)
        case .failed: theme.error.opacity(0.28)
        case .idle, .searching: theme.chromeLight.opacity(0.14)
        }
    }

    private var wingedMark: some View {
        Image("WingedOMark")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: width * 0.95, height: width * 0.48)
    }
}
