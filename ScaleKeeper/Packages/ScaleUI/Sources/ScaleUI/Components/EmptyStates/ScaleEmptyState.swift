import SwiftUI

// MARK: - Scale Empty State

public struct ScaleEmptyState: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    public init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: ScaleSpacing.lg) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(themeManager.currentTheme.textTertiary)

            // Text
            VStack(spacing: ScaleSpacing.xs) {
                Text(title)
                    .font(Font.scaleTitle3)
                    .foregroundStyle(Color.scaleTextPrimary)

                Text(message)
                    .font(Font.scaleBody)
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Action button
            if let actionTitle = actionTitle, let action = action {
                Button {
                    action()
                    ScaleHaptics.light()
                } label: {
                    HStack(spacing: ScaleSpacing.xs) {
                        Image(systemName: "plus")
                        Text(actionTitle)
                    }
                    .font(Font.scaleButton)
                    .foregroundStyle(themeManager.currentTheme.backgroundPrimary)
                    .padding(.horizontal, ScaleSpacing.lg)
                    .padding(.vertical, ScaleSpacing.sm)
                    .background(themeManager.currentTheme.primaryAccent)
                    .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
                }
            }
        }
        .padding(ScaleSpacing.xl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preset Empty States

public extension ScaleEmptyState {
    static func noAnimals(action: @escaping () -> Void) -> ScaleEmptyState {
        ScaleEmptyState(
            icon: "pawprint.fill",
            title: "No Animals Yet",
            message: "Start building your collection by adding your first animal.",
            actionTitle: "Add Animal",
            action: action
        )
    }

    static func noFeedings() -> ScaleEmptyState {
        ScaleEmptyState(
            icon: "fork.knife",
            title: "No Feeding Records",
            message: "Feeding records will appear here once you start logging meals."
        )
    }

    static func noWeights() -> ScaleEmptyState {
        ScaleEmptyState(
            icon: "scalemass.fill",
            title: "No Weight Records",
            message: "Track your animal's growth by recording weight measurements."
        )
    }

    static func noPhotos(action: @escaping () -> Void) -> ScaleEmptyState {
        ScaleEmptyState(
            icon: "photo.fill",
            title: "No Photos",
            message: "Document your animal's appearance by adding photos.",
            actionTitle: "Add Photo",
            action: action
        )
    }

    static func noHealthNotes() -> ScaleEmptyState {
        ScaleEmptyState(
            icon: "heart.text.square.fill",
            title: "No Health Notes",
            message: "Keep track of vet visits, medications, and health observations here."
        )
    }

    static func noSheds() -> ScaleEmptyState {
        ScaleEmptyState(
            icon: "leaf.fill",
            title: "No Shed Records",
            message: "Log shedding events to track your animal's health and growth cycles."
        )
    }

    static func noPairings(action: @escaping () -> Void) -> ScaleEmptyState {
        ScaleEmptyState(
            icon: "heart.fill",
            title: "No Pairings",
            message: "Start a breeding project by creating your first pairing.",
            actionTitle: "New Pairing",
            action: action
        )
    }

    static func noClutches() -> ScaleEmptyState {
        ScaleEmptyState(
            icon: "circle.grid.3x3.fill",
            title: "No Clutches",
            message: "Clutch records will appear here once eggs are laid."
        )
    }

    static func searchNoResults(query: String) -> ScaleEmptyState {
        ScaleEmptyState(
            icon: "magnifyingglass",
            title: "No Results",
            message: "No animals found matching \"\(query)\". Try a different search term."
        )
    }

    static func offline() -> ScaleEmptyState {
        ScaleEmptyState(
            icon: "wifi.slash",
            title: "You're Offline",
            message: "Your data is saved locally. Changes will sync when you reconnect."
        )
    }

    static func error(action: @escaping () -> Void) -> ScaleEmptyState {
        ScaleEmptyState(
            icon: "exclamationmark.triangle.fill",
            title: "Something Went Wrong",
            message: "We couldn't load your data. Please try again.",
            actionTitle: "Retry",
            action: action
        )
    }
}

// MARK: - Loading State

public struct ScaleLoadingState: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    var message: String? = nil

    public init(message: String? = nil) {
        self.message = message
    }

    public var body: some View {
        VStack(spacing: ScaleSpacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.primaryAccent))
                .scaleEffect(1.2)

            if let message = message {
                Text(message)
                    .font(Font.scaleSubheadline)
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Section Header

public struct ScaleSectionHeader: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    let title: String
    var subtitle: String? = nil
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil

    public init(
        _ title: String,
        subtitle: String? = nil,
        action: (() -> Void)? = nil,
        actionLabel: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.actionLabel = actionLabel
    }

    public var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Font.scaleHeadline)
                    .foregroundStyle(Color.scaleTextPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Font.scaleCaption)
                        .foregroundStyle(themeManager.currentTheme.textTertiary)
                }
            }

            Spacer()

            if let action = action {
                Button {
                    action()
                } label: {
                    Text(actionLabel ?? "See All")
                        .font(Font.scaleSubheadline)
                        .foregroundStyle(themeManager.currentTheme.primaryAccent)
                }
            }
        }
    }
}

// MARK: - Divider

public struct ScaleDivider: View {
    var color: Color = .scaleBorder
    var height: CGFloat = 1

    public init(color: Color = .scaleBorder, height: CGFloat = 1) {
        self.color = color
        self.height = height
    }

    public var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: height)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        ScaleBackground()

        ScrollView {
            VStack(spacing: ScaleSpacing.xl) {
                ScaleEmptyState.noAnimals {}

                ScaleDivider()

                ScaleEmptyState.searchNoResults(query: "Python")

                ScaleDivider()

                ScaleLoadingState(message: "Loading your collection...")

                ScaleDivider()

                ScaleSectionHeader(
                    "Recent Activity",
                    subtitle: "Last 7 days",
                    action: {},
                    actionLabel: "View All"
                )
            }
            .padding()
        }
    }
}
