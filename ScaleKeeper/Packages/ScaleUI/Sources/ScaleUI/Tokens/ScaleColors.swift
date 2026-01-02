import SwiftUI

// MARK: - App Theme

public enum AppTheme: String, CaseIterable, Codable {
    case purple = "irora_purple"
    case green = "reptile_green"

    public var displayName: String {
        switch self {
        case .purple: return "Irora Purple"
        case .green: return "Reptile Green"
        }
    }

    public var description: String {
        switch self {
        case .purple: return "Cosmic purple and magenta tones"
        case .green: return "Natural greens and warm amber"
        }
    }

    public var primaryAccent: Color {
        switch self {
        case .purple: return Color(red: 0.55, green: 0.30, blue: 0.85) // nebulaPurple
        case .green: return Color(red: 0.18, green: 0.80, blue: 0.44)  // vibrant emerald #2ECC70
        }
    }

    public var secondaryAccent: Color {
        switch self {
        case .purple: return Color(red: 0.95, green: 0.35, blue: 0.75) // nebulaMagenta
        case .green: return Color(red: 0.95, green: 0.75, blue: 0.30)  // golden honey #F2BF4D
        }
    }

    public var tertiaryAccent: Color {
        switch self {
        case .purple: return Color(red: 0.70, green: 0.55, blue: 0.95) // nebulaLavender
        case .green: return Color(red: 0.30, green: 0.85, blue: 0.75)  // aqua teal #4DD9BF
        }
    }

    // MARK: - Background Colors

    /// Primary background - darkest layer
    public var backgroundPrimary: Color {
        switch self {
        case .purple: return Color(red: 0.04, green: 0.04, blue: 0.08)  // cosmicBlack
        case .green: return Color(red: 0.03, green: 0.06, blue: 0.04)   // forest black
        }
    }

    /// Secondary background - gradient middle
    public var backgroundSecondary: Color {
        switch self {
        case .purple: return Color(red: 0.08, green: 0.06, blue: 0.14)  // cosmicDeep
        case .green: return Color(red: 0.05, green: 0.10, blue: 0.06)   // forest deep
        }
    }

    /// Card/elevated surface background
    public var cardBackground: Color {
        switch self {
        case .purple: return Color(red: 0.12, green: 0.10, blue: 0.20)  // purple card
        case .green: return Color(red: 0.08, green: 0.14, blue: 0.09)   // green card
        }
    }

    /// Muted/tertiary color for text
    public var mutedColor: Color {
        switch self {
        case .purple: return Color(red: 0.70, green: 0.55, blue: 0.95)  // nebulaLavender
        case .green: return Color(red: 0.55, green: 0.75, blue: 0.55)   // muted sage
        }
    }

    // MARK: - Text Colors

    /// Secondary text color - theme aware
    public var textSecondary: Color {
        switch self {
        case .purple: return Color(red: 0.75, green: 0.60, blue: 0.98)  // brighter lavender
        case .green: return Color(red: 0.70, green: 0.85, blue: 0.70)   // brighter sage
        }
    }

    /// Tertiary text color - theme aware
    public var textTertiary: Color {
        switch self {
        case .purple: return Color(red: 0.70, green: 0.55, blue: 0.95).opacity(0.8)  // nebulaLavender
        case .green: return Color(red: 0.60, green: 0.75, blue: 0.60).opacity(0.85)  // muted sage
        }
    }

    /// Disabled text color - theme aware
    public var textDisabled: Color {
        switch self {
        case .purple: return Color(red: 0.70, green: 0.55, blue: 0.95).opacity(0.5)  // nebulaLavender
        case .green: return Color(red: 0.55, green: 0.70, blue: 0.55).opacity(0.6)   // dim sage
        }
    }

    /// Border color - theme aware
    public var borderColor: Color {
        switch self {
        case .purple: return Color(red: 0.70, green: 0.55, blue: 0.95).opacity(0.1)  // nebulaLavender
        case .green: return Color(red: 0.40, green: 0.60, blue: 0.40).opacity(0.15)  // forest border
        }
    }
}

// MARK: - Theme Manager

@MainActor
public final class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()

    @Published public var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "app_theme")
        }
    }

    @Published public var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "has_completed_theme_onboarding")
        }
    }

    private init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "app_theme"),
           let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .purple
        }
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "has_completed_theme_onboarding")
    }

    public func setTheme(_ theme: AppTheme) {
        currentTheme = theme
    }

    public func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}

// MARK: - Scale Colors (Cosmic Theme)

/// Color palette for ScaleKeeper following the Cosmos suite design system
/// Uses cosmic/nebula aesthetic with dark backgrounds and luminous accents
public extension Color {
    // MARK: - Base Colors (Backgrounds)

    /// Primary background - darkest layer (Cosmic Black)
    /// Hex: #0A0A14 | RGB: (0.04, 0.04, 0.08)
    static let cosmicBlack = Color(red: 0.04, green: 0.04, blue: 0.08)

    /// Secondary background - gradient stops (Cosmic Deep)
    /// Hex: #140F24 | RGB: (0.08, 0.06, 0.14)
    static let cosmicDeep = Color(red: 0.08, green: 0.06, blue: 0.14)

    /// Cards, containers, elevated surfaces
    /// Hex: #1F1A33 | RGB: (0.12, 0.10, 0.20)
    static let cardBackground = Color(red: 0.12, green: 0.10, blue: 0.20)

    // MARK: - Accent Colors (Nebula Palette)

    /// Primary accent - main actions, buttons (Nebula Purple)
    /// Hex: #8C4DD9 | RGB: (0.55, 0.30, 0.85)
    static let nebulaPurple = Color(red: 0.55, green: 0.30, blue: 0.85)

    /// Success, completion, highlights (Nebula Cyan)
    /// Hex: #40D9F2 | RGB: (0.25, 0.85, 0.95)
    static let nebulaCyan = Color(red: 0.25, green: 0.85, blue: 0.95)

    /// Warnings, feeding time, morning theme (Nebula Gold)
    /// Hex: #FFCC66 | RGB: (1.0, 0.80, 0.40)
    static let nebulaGold = Color(red: 1.0, green: 0.80, blue: 0.40)

    /// Alerts, breeding, evening theme (Nebula Magenta)
    /// Hex: #F259BF | RGB: (0.95, 0.35, 0.75)
    static let nebulaMagenta = Color(red: 0.95, green: 0.35, blue: 0.75)

    /// Secondary text, muted elements (Nebula Lavender)
    /// Hex: #B38CF2 | RGB: (0.70, 0.55, 0.95)
    static let nebulaLavender = Color(red: 0.70, green: 0.55, blue: 0.95)

    // MARK: - Legacy Aliases (for compatibility)

    static let substrateDark = cosmicBlack
    static let substrateDeep = cosmicDeep
    static let terrariumGreen = nebulaPurple
    static let scaleTeal = nebulaCyan
    static let heatLampAmber = nebulaGold
    static let shedPink = nebulaMagenta
    static let scaleMuted = nebulaLavender

    // MARK: - Semantic Colors

    /// Success - fed, healthy, complete
    static let scaleSuccess = nebulaCyan

    /// Warning - overdue, attention needed
    static let scaleWarning = nebulaGold

    /// Error - critical alerts, health issues
    static let scaleError = Color(red: 0.95, green: 0.30, blue: 0.30)

    /// Info - general information
    static let scaleInfo = nebulaLavender

    // MARK: - Species Category Colors (Cosmic Variants)

    static let snakeColor = nebulaPurple
    static let lizardColor = nebulaGold
    static let geckoColor = Color(red: 0.85, green: 0.65, blue: 0.40)
    static let tortoiseColor = nebulaLavender.opacity(0.8)
    static let frogColor = nebulaCyan
    static let invertebrateColor = nebulaMagenta.opacity(0.8)

    // MARK: - Text Colors

    /// Primary text - white
    static let scaleTextPrimary = Color.white

    /// Secondary text - slightly muted
    static let scaleTextSecondary = Color(red: 0.75, green: 0.60, blue: 0.98)

    /// Tertiary text - more muted
    static let scaleTextTertiary = nebulaLavender.opacity(0.8)

    /// Disabled text
    static let scaleTextDisabled = nebulaLavender.opacity(0.5)

    // MARK: - Border Colors

    static let scaleBorder = nebulaLavender.opacity(0.1)
    static let scaleBorderFocused = nebulaPurple.opacity(0.5)
}

// MARK: - Gradients

public extension LinearGradient {
    /// Main cosmic background gradient
    static let scaleBackground = LinearGradient(
        stops: [
            .init(color: Color.cosmicBlack, location: 0),
            .init(color: Color.cosmicDeep, location: 0.3),
            .init(color: Color.cosmicDeep, location: 0.7),
            .init(color: Color.cosmicBlack, location: 1)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Nebula accent gradient for buttons and highlights
    static let scaleAccent = LinearGradient(
        colors: [Color.nebulaMagenta, Color.nebulaPurple, Color.nebulaCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Warm gradient for warnings/feeding
    static let scaleWarm = LinearGradient(
        colors: [Color.nebulaGold, Color.nebulaMagenta.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Full nebula gradient
    static let nebulaGradient = LinearGradient(
        colors: [Color.nebulaMagenta, Color.nebulaPurple, Color.nebulaCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Color Extensions

public extension Color {
    /// Get species category color
    static func forSpeciesCategory(_ category: String) -> Color {
        switch category.lowercased() {
        case "snake": return .snakeColor
        case "lizard": return .lizardColor
        case "gecko": return .geckoColor
        case "tortoise", "turtle": return .tortoiseColor
        case "frog", "salamander": return .frogColor
        case "invertebrate": return .invertebrateColor
        default: return .nebulaPurple
        }
    }

    /// Hex initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // MARK: - Theme-Aware Colors

    /// Primary accent color based on current theme
    @MainActor
    static var themePrimary: Color {
        ThemeManager.shared.currentTheme.primaryAccent
    }

    /// Secondary accent color based on current theme
    @MainActor
    static var themeSecondary: Color {
        ThemeManager.shared.currentTheme.secondaryAccent
    }

    /// Tertiary accent color based on current theme
    @MainActor
    static var themeTertiary: Color {
        ThemeManager.shared.currentTheme.tertiaryAccent
    }

    /// Theme-aware card background
    @MainActor
    static var themeCardBackground: Color {
        ThemeManager.shared.currentTheme.cardBackground
    }

    /// Theme-aware primary background
    @MainActor
    static var themeBackgroundPrimary: Color {
        ThemeManager.shared.currentTheme.backgroundPrimary
    }

    /// Theme-aware secondary background
    @MainActor
    static var themeBackgroundSecondary: Color {
        ThemeManager.shared.currentTheme.backgroundSecondary
    }

    /// Theme-aware muted color
    @MainActor
    static var themeMuted: Color {
        ThemeManager.shared.currentTheme.mutedColor
    }

    /// Theme-aware secondary text color
    @MainActor
    static var themeTextSecondary: Color {
        ThemeManager.shared.currentTheme.textSecondary
    }

    /// Theme-aware tertiary text color
    @MainActor
    static var themeTextTertiary: Color {
        ThemeManager.shared.currentTheme.textTertiary
    }

    /// Theme-aware disabled text color
    @MainActor
    static var themeTextDisabled: Color {
        ThemeManager.shared.currentTheme.textDisabled
    }

    /// Theme-aware border color
    @MainActor
    static var themeBorder: Color {
        ThemeManager.shared.currentTheme.borderColor
    }

    /// Get primary color for a specific theme
    static func primary(for theme: AppTheme) -> Color {
        theme.primaryAccent
    }

    /// Get secondary color for a specific theme
    static func secondary(for theme: AppTheme) -> Color {
        theme.secondaryAccent
    }

    // MARK: - Green Theme Colors (Static)

    /// Terrarium green - primary for green theme
    static let reptileGreen = Color(red: 0.30, green: 0.70, blue: 0.40)

    /// Warm amber - secondary for green theme
    static let warmAmber = Color(red: 1.0, green: 0.60, blue: 0.20)

    /// Leaf green - tertiary for green theme
    static let leafGreen = Color(red: 0.60, green: 0.80, blue: 0.55)

    /// Forest deep - darker green accent
    static let forestDeep = Color(red: 0.15, green: 0.40, blue: 0.25)
}
