// ScaleUI - Design system and UI components for ScaleKeeper
// Part of the ScaleKeeper iOS Application

import SwiftUI

// MARK: - Public Exports

// This file serves as the main entry point for the ScaleUI package
// All public types are exported through their respective files

// MARK: - Background View

/// Standard cosmic background for all screens - theme aware
public struct ScaleBackground: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let showOrbs: Bool

    public init(showOrbs: Bool = true) {
        self.showOrbs = showOrbs
    }

    public var body: some View {
        ZStack {
            // Theme-aware background gradient
            LinearGradient(
                stops: [
                    .init(color: themeManager.currentTheme.backgroundPrimary, location: 0),
                    .init(color: themeManager.currentTheme.backgroundSecondary, location: 0.3),
                    .init(color: themeManager.currentTheme.backgroundSecondary, location: 0.7),
                    .init(color: themeManager.currentTheme.backgroundPrimary, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if showOrbs {
                decorativeOrbs
            }
        }
        .animation(.easeInOut(duration: 0.3), value: themeManager.currentTheme)
    }

    private var decorativeOrbs: some View {
        GeometryReader { geometry in
            ZStack {
                // Primary accent orb
                Circle()
                    .fill(themeManager.currentTheme.secondaryAccent.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: -geometry.size.width * 0.3, y: -geometry.size.height * 0.2)

                // Secondary accent orb
                Circle()
                    .fill(themeManager.currentTheme.primaryAccent.opacity(0.12))
                    .frame(width: 250, height: 250)
                    .blur(radius: 60)
                    .offset(x: geometry.size.width * 0.3, y: geometry.size.height * 0.3)

                // Tertiary accent orb
                Circle()
                    .fill(themeManager.currentTheme.tertiaryAccent.opacity(0.08))
                    .frame(width: 200, height: 200)
                    .blur(radius: 50)
                    .offset(x: geometry.size.width * 0.2, y: -geometry.size.height * 0.3)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Theme-Aware Card Background

/// A view that provides theme-aware card background
public struct ThemeCardBackground: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    public init() {}

    public var body: some View {
        themeManager.currentTheme.cardBackground.opacity(0.7)
    }
}

// MARK: - View Modifiers

public extension View {
    /// Apply standard card styling (theme-aware)
    func scaleCardStyle() -> some View {
        self.modifier(ThemeCardStyleModifier())
    }

    /// Apply standard input field styling (theme-aware)
    func scaleInputStyle() -> some View {
        self.modifier(ThemeInputStyleModifier())
    }
}

struct ThemeCardStyleModifier: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared

    func body(content: Content) -> some View {
        content
            .padding(ScaleSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: ScaleRadius.lg)
                    .fill(themeManager.currentTheme.cardBackground.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: ScaleRadius.lg)
                            .stroke(Color.scaleBorder, lineWidth: 1)
                    )
            )
    }
}

struct ThemeInputStyleModifier: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared

    func body(content: Content) -> some View {
        content
            .padding(ScaleSpacing.md)
            .background(themeManager.currentTheme.cardBackground.opacity(0.7))
            .cornerRadius(ScaleRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: ScaleRadius.md)
                    .stroke(Color.scaleBorder, lineWidth: 1)
            )
    }
}

// MARK: - Animation Constants

public enum ScaleAnimation {
    /// Fast micro-interactions - 0.2s
    public static let fast = Animation.easeInOut(duration: 0.2)

    /// Medium state changes - 0.25s
    public static let medium = Animation.easeInOut(duration: 0.25)

    /// Normal transitions - 0.3s
    public static let normal = Animation.easeInOut(duration: 0.3)

    /// Slow entrance animations - 0.5s
    public static let slow = Animation.easeOut(duration: 0.5)

    /// Spring animation for bouncy effects
    public static let spring = Animation.spring(response: 0.4, dampingFraction: 0.7)
}

// MARK: - Haptic Feedback

public enum ScaleHaptics {
    public static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    public static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    public static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    public static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    public static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    public static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    public static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Preview

#Preview("Scale Background") {
    ScaleBackground()
}
