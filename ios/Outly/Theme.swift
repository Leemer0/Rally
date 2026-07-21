import Observation
import SwiftUI
import UIKit

@MainActor
@Observable
final class OutlyTheme {
    var background = Color(hex: 0x080B10)
    var secondaryBackground = Color(hex: 0x10141B)
    var surface = Color(hex: 0x151A21)
    var elevatedSurface = Color(hex: 0x202630)
    var sunkenSurface = Color(hex: 0x0B1016)
    var primaryText = Color(hex: 0xF5F7F8)
    var secondaryText = Color(hex: 0xB1B8C2)
    var mutedText = Color(hex: 0x85919F)
    var accent = Color(hex: 0xC7FF3D)
    var accentForeground = Color(hex: 0x101507)
    var success = Color(hex: 0x63E681)
    var warning = Color(hex: 0xF2B84B)
    var error = Color(hex: 0xFF6767)
    var border = Color.white.opacity(0.11)
    var chromeLight = Color(hex: 0xF4F5F3)
    var chromeMid = Color(hex: 0xA7ABB0)
    var chromeDark = Color(hex: 0x454A51)
    var mapMarker = Color(hex: 0x4E6070)
    var mapMarkerBusy = Color(hex: 0x6A7F91)
    var crowdCool = Color(hex: 0x5C9DFF)
    var crowdWarm = Color(hex: 0xFF76B8)
    var partnerAccent = Color(hex: 0x7FA8F5)
}

enum OutlyMetrics {
    static let edge: CGFloat = 20
    static let compactEdge: CGFloat = 16

    static let spacing4: CGFloat = 4
    static let spacing8: CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32

    static let controlHeight: CGFloat = 54
    static let minimumTouchTarget: CGFloat = 44
    static let buttonRadius: CGFloat = 12
    static let surfaceRadius: CGFloat = 14
    static let mapSurfaceRadius: CGFloat = 24
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

@MainActor
final class HapticManager {
    static let shared = HapticManager()

    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()

    private init() {
        selection.prepare()
    }

    func selected(enabled: Bool) {
        guard enabled else { return }
        selection.selectionChanged()
    }

    func success(enabled: Bool) {
        guard enabled else { return }
        notification.notificationOccurred(.success)
    }

    func error(enabled: Bool) {
        guard enabled else { return }
        notification.notificationOccurred(.error)
    }
}
