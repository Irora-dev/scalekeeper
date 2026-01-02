import SwiftUI

// MARK: - Scale Primary Button

/// Primary call-to-action button with gradient background and glow effect
public struct ScalePrimaryButton: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    // MARK: - Properties
    let title: String
    let icon: String?
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    // MARK: - Init
    public init(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    // MARK: - Body
    public var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                action()
            }
        }) {
            HStack(spacing: ScaleSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }

                Text(isLoading ? "Loading..." : title)
                    .font(.scaleButton)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: ScaleSizes.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: ScaleRadius.sm)
                    .fill(
                        LinearGradient(
                            colors: [themeManager.currentTheme.secondaryAccent, themeManager.currentTheme.primaryAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .opacity(isDisabled ? 0.5 : 1)
            .shadow(color: themeManager.currentTheme.primaryAccent.opacity(0.4), radius: isDisabled ? 0 : 8)
            .shadow(color: themeManager.currentTheme.tertiaryAccent.opacity(0.2), radius: isDisabled ? 0 : 16)
        }
        .disabled(isDisabled || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }
}

// MARK: - Scale Secondary Button

/// Secondary button with border or ghost styling
public struct ScaleSecondaryButton: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    // MARK: - Style
    public enum Style {
        case outlined
        case ghost
        case tinted
    }

    // MARK: - Properties
    let title: String
    let icon: String?
    let style: Style
    let action: () -> Void

    // MARK: - Init
    public init(
        _ title: String,
        icon: String? = nil,
        style: Style = .outlined,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    // MARK: - Body
    public var body: some View {
        Button(action: action) {
            HStack(spacing: ScaleSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }

                Text(title)
                    .font(.scaleButtonSmall)
            }
            .foregroundColor(foregroundColor)
            .frame(height: ScaleSizes.buttonHeightSmall)
            .padding(.horizontal, ScaleSpacing.lg)
            .background(background)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .outlined, .ghost:
            return themeManager.currentTheme.textSecondary
        case .tinted:
            return themeManager.currentTheme.primaryAccent
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .outlined:
            RoundedRectangle(cornerRadius: ScaleRadius.sm)
                .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
        case .ghost:
            Color.clear
        case .tinted:
            RoundedRectangle(cornerRadius: ScaleRadius.sm)
                .fill(themeManager.currentTheme.primaryAccent.opacity(0.15))
        }
    }
}

// MARK: - Scale Icon Button

/// Circular icon-only button for compact actions
public struct ScaleIconButton: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    // MARK: - Size
    public enum Size {
        case small  // 32pt
        case medium // 44pt
        case large  // 56pt

        var dimension: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 44
            case .large: return 56
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 18
            case .large: return 24
            }
        }
    }

    // MARK: - Style
    public enum Style {
        case primary
        case secondary
        case ghost
        case destructive
    }

    // MARK: - Properties
    let icon: String
    let size: Size
    let style: Style
    let action: () -> Void

    // MARK: - Init
    public init(
        icon: String,
        size: Size = .medium,
        style: Style = .secondary,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.style = style
        self.action = action
    }

    // MARK: - Body
    public var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size.iconSize, weight: .semibold))
                .foregroundColor(foregroundColor)
                .frame(width: size.dimension, height: size.dimension)
                .background(background)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return .scaleTextPrimary
        case .ghost:
            return themeManager.currentTheme.textSecondary
        case .destructive:
            return .scaleError
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            Circle()
                .fill(
                    LinearGradient(
                        colors: [themeManager.currentTheme.secondaryAccent, themeManager.currentTheme.primaryAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: themeManager.currentTheme.primaryAccent.opacity(0.4), radius: 8)
        case .secondary:
            Circle()
                .fill(themeManager.currentTheme.cardBackground)
        case .ghost:
            Circle()
                .fill(Color.clear)
        case .destructive:
            Circle()
                .fill(Color.scaleError.opacity(0.15))
        }
    }
}

// MARK: - Previews

#Preview("Primary Button") {
    VStack(spacing: 16) {
        ScalePrimaryButton("Get Started", icon: "arrow.right") {}
        ScalePrimaryButton("Loading...", isLoading: true) {}
        ScalePrimaryButton("Disabled", isDisabled: true) {}
    }
    .padding()
    .background(Color.cosmicBlack)
}

#Preview("Secondary Buttons") {
    VStack(spacing: 16) {
        ScaleSecondaryButton("Outlined", icon: "plus", style: .outlined) {}
        ScaleSecondaryButton("Ghost", style: .ghost) {}
        ScaleSecondaryButton("Tinted", icon: "checkmark", style: .tinted) {}
    }
    .padding()
    .background(Color.cosmicBlack)
}

#Preview("Icon Buttons") {
    HStack(spacing: 16) {
        ScaleIconButton(icon: "plus", size: .small, style: .primary) {}
        ScaleIconButton(icon: "pencil", size: .medium, style: .secondary) {}
        ScaleIconButton(icon: "gearshape", size: .large, style: .ghost) {}
        ScaleIconButton(icon: "trash", size: .medium, style: .destructive) {}
    }
    .padding()
    .background(Color.cosmicBlack)
}
