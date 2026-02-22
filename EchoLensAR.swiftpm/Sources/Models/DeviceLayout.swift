import SwiftUI

struct DeviceLayout: Equatable {

    let screenWidth: CGFloat
    let screenHeight: CGFloat

    enum DeviceClass: String {
        case iPhone
        case iPadSmall
        case iPadLarge
        case iPadExtraLarge
    }

    var deviceClass: DeviceClass {
        if screenWidth < 500 { return .iPhone }
        else if screenWidth < 900 { return .iPadSmall }
        else if screenWidth < 1100 { return .iPadLarge }
        else { return .iPadExtraLarge }
    }

    var scale: CGFloat {
        switch deviceClass {
        case .iPhone:         return 1.0
        case .iPadSmall:      return 1.65
        case .iPadLarge:      return 2.0
        case .iPadExtraLarge: return 2.3
        }
    }

    var heroTitle: CGFloat { round(34 * scale) }

    var title: CGFloat { round(24 * scale) }

    var heroIcon: CGFloat { round(48 * scale) }

    var permissionIcon: CGFloat { round(72 * scale) }

    var body: CGFloat { round(16 * scale) }

    var subtitle: CGFloat { round(14 * scale) }

    var caption: CGFloat { round(12 * scale) }

    var tiny: CGFloat { round(11 * scale) }

    var pillLabel: CGFloat { round(14 * scale) }

    var pillIcon: CGFloat { round(16 * scale) }

    var tabIcon: CGFloat { round(20 * scale) }

    var tabLabel: CGFloat { round(10 * scale) }

    var buttonText: CGFloat { round(17 * scale) }

    var notifTitle: CGFloat { round(13 * scale) }

    var notifBody: CGFloat { round(12 * scale) }

    var hudStatus: CGFloat { round(12 * scale) }

    var listIcon: CGFloat { round(22 * scale) }

    var settingIcon: CGFloat { round(20 * scale) }

    var settingIconBG: CGFloat { round(36 * scale) }

    var featureIcon: CGFloat { round(40 * scale) }

    var pagePadding: CGFloat { round(screenWidth < 500 ? 24 : min(screenWidth * 0.06, 60)) }

    var cardPadding: CGFloat { round(16 * scale) }

    var sectionSpacing: CGFloat { round(20 * scale) }

    var cardRadius: CGFloat { round(20 * scale) }

    var confidenceBarWidth: CGFloat { round(40 * scale) }

    var notifAppIcon: CGFloat { round(36 * scale) }

    func onboardingRing(index: Int) -> CGFloat {
        round(CGFloat(80 + index * 30) * scale)
    }

    var maxContentWidth: CGFloat {
        switch deviceClass {
        case .iPhone:         return .infinity
        case .iPadSmall:      return 680
        case .iPadLarge:      return 820
        case .iPadExtraLarge: return 920
        }
    }

    var tabBarBottomPadding: CGFloat { round(100 * scale) }

    var entitySize: CGFloat { round(56 * scale) }
    var entityGlow: CGFloat { round(80 * scale) }

    var pillHPadding: CGFloat { round(14 * scale) }
    var pillVPadding: CGFloat { round(8 * scale) }

    @MainActor
    static var `default`: DeviceLayout {
        DeviceLayout(
            screenWidth: UIScreen.main.bounds.width,
            screenHeight: UIScreen.main.bounds.height
        )
    }
}

private struct DeviceLayoutKey: EnvironmentKey {
    static let defaultValue: DeviceLayout = DeviceLayout(screenWidth: 393, screenHeight: 852)
}

extension EnvironmentValues {
    var deviceLayout: DeviceLayout {
        get { self[DeviceLayoutKey.self] }
        set { self[DeviceLayoutKey.self] = newValue }
    }
}

struct AdaptiveContentWidth: ViewModifier {
    @Environment(\.deviceLayout) var layout

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: layout.maxContentWidth)
    }
}

extension View {
    func adaptiveWidth() -> some View {
        modifier(AdaptiveContentWidth())
    }
}
