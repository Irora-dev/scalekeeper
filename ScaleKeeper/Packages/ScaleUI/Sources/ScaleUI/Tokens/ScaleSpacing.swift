import SwiftUI

// MARK: - Scale Spacing

/// Spacing system for ScaleKeeper following the suite design system
public enum ScaleSpacing {
    /// Extra small - 4pt
    public static let xs: CGFloat = 4

    /// Small - 8pt
    public static let sm: CGFloat = 8

    /// Medium - 12pt
    public static let md: CGFloat = 12

    /// Large - 16pt
    public static let lg: CGFloat = 16

    /// Extra large - 24pt
    public static let xl: CGFloat = 24

    /// Double extra large - 32pt
    public static let xxl: CGFloat = 32

    /// Triple extra large - 48pt
    public static let xxxl: CGFloat = 48
}

// MARK: - Scale Radius

/// Corner radius system for ScaleKeeper
public enum ScaleRadius {
    /// Small - 8pt (buttons, small elements)
    public static let sm: CGFloat = 8

    /// Medium - 12pt (input fields, tags)
    public static let md: CGFloat = 12

    /// Large - 16pt (cards, containers)
    public static let lg: CGFloat = 16

    /// Extra large - 20pt (large cards, sheets)
    public static let xl: CGFloat = 20

    /// Full - for circular elements
    public static func full(size: CGFloat) -> CGFloat {
        size / 2
    }
}

// MARK: - Scale Elevation

/// Shadow/elevation system for ScaleKeeper
public enum ScaleElevation {
    /// Subtle elevation
    public static let subtle = Shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)

    /// Medium elevation
    public static let medium = Shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)

    /// High elevation
    public static let high = Shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 8)

    public struct Shadow {
        public let color: Color
        public let radius: CGFloat
        public let x: CGFloat
        public let y: CGFloat

        public init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            self.color = color
            self.radius = radius
            self.x = x
            self.y = y
        }
    }
}

// MARK: - Elevation Modifier

public struct ScaleElevationModifier: ViewModifier {
    let elevation: ScaleElevation.Shadow

    public func body(content: Content) -> some View {
        content
            .shadow(
                color: elevation.color,
                radius: elevation.radius,
                x: elevation.x,
                y: elevation.y
            )
    }
}

public extension View {
    func scaleElevation(_ elevation: ScaleElevation.Shadow) -> some View {
        modifier(ScaleElevationModifier(elevation: elevation))
    }
}

// MARK: - Glow Modifier

public struct ScaleGlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    public func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.4), radius: radius)
    }
}

public extension View {
    func scaleGlow(color: Color = .terrariumGreen, radius: CGFloat = 8) -> some View {
        modifier(ScaleGlowModifier(color: color, radius: radius))
    }
}

// MARK: - Standard Sizes

public enum ScaleSizes {
    /// Minimum touch target - 44pt
    public static let minTouchTarget: CGFloat = 44

    /// Standard button height - 50pt
    public static let buttonHeight: CGFloat = 50

    /// Small button height - 40pt
    public static let buttonHeightSmall: CGFloat = 40

    /// Input field height - 50pt
    public static let inputHeight: CGFloat = 50

    /// Tab bar height - 80pt (includes safe area padding)
    public static let tabBarHeight: CGFloat = 80

    /// Card minimum height - 80pt
    public static let cardMinHeight: CGFloat = 80

    /// Avatar sizes
    public static let avatarSmall: CGFloat = 32
    public static let avatarMedium: CGFloat = 48
    public static let avatarLarge: CGFloat = 64
    public static let avatarXLarge: CGFloat = 100

    /// Icon sizes
    public static let iconSmall: CGFloat = 16
    public static let iconMedium: CGFloat = 24
    public static let iconLarge: CGFloat = 32
}
