import SwiftUI

// MARK: - Scale Card

/// Standard card container with optional header - theme aware
public struct ScaleCard<Content: View>: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    // MARK: - Header
    public struct CardHeader {
        let title: String
        let subtitle: String?
        let icon: String?
        let iconColor: Color
        let action: (() -> Void)?

        public init(
            title: String,
            subtitle: String? = nil,
            icon: String? = nil,
            iconColor: Color = .terrariumGreen,
            action: (() -> Void)? = nil
        ) {
            self.title = title
            self.subtitle = subtitle
            self.icon = icon
            self.iconColor = iconColor
            self.action = action
        }
    }

    // MARK: - Properties
    let header: CardHeader?
    let content: () -> Content

    // MARK: - Init
    public init(
        header: CardHeader? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.header = header
        self.content = content
    }

    // MARK: - Body
    public var body: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.md) {
            if let header = header {
                headerView(header)
            }

            content()
        }
        .padding(ScaleSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ScaleRadius.lg)
                .fill(themeManager.currentTheme.cardBackground.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: ScaleRadius.lg)
                        .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func headerView(_ header: CardHeader) -> some View {
        HStack {
            if let icon = header.icon {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(header.iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(header.title)
                    .font(.scaleHeadline)
                    .foregroundColor(.scaleTextPrimary)

                if let subtitle = header.subtitle {
                    Text(subtitle)
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }
            }

            Spacer()

            if let action = header.action {
                Button(action: action) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }
            }
        }
    }
}

// MARK: - Scale Stat Card

/// Card displaying a single statistic with trend indicator - theme aware
public struct ScaleStatCard: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    // MARK: - Trend
    public enum Trend {
        case up(percentage: Int)
        case down(percentage: Int)
        case neutral

        var color: Color {
            switch self {
            case .up: return .scaleSuccess
            case .down: return .scaleError
            case .neutral: return .scaleTextTertiary
            }
        }

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "arrow.right"
            }
        }
    }

    // MARK: - Properties
    let title: String
    let value: String
    let subtitle: String?
    let trend: Trend?
    let icon: String?
    let iconColor: Color

    // MARK: - Init
    public init(
        title: String,
        value: String,
        subtitle: String? = nil,
        trend: Trend? = nil,
        icon: String? = nil,
        iconColor: Color = .terrariumGreen
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.trend = trend
        self.icon = icon
        self.iconColor = iconColor
    }

    // MARK: - Body
    public var body: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.sm) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)
                }

                Text(title)
                    .font(.scaleCaption)
                    .foregroundColor(themeManager.currentTheme.textTertiary)

                Spacer()

                if let trend = trend {
                    trendView(trend)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: ScaleSpacing.xs) {
                Text(value)
                    .font(.scaleStatMedium)
                    .foregroundColor(.scaleTextPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }
            }
        }
        .padding(ScaleSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ScaleRadius.md)
                .fill(themeManager.currentTheme.cardBackground.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: ScaleRadius.md)
                        .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func trendView(_ trend: Trend) -> some View {
        HStack(spacing: 2) {
            Image(systemName: trend.icon)
                .font(.system(size: 10, weight: .semibold))

            if case .up(let pct) = trend {
                Text("\(pct)%")
                    .font(.scaleCaption2)
            } else if case .down(let pct) = trend {
                Text("\(pct)%")
                    .font(.scaleCaption2)
            }
        }
        .foregroundColor(trend.color)
    }
}

// MARK: - Scale Animal Card

/// Card specifically for displaying animal information - theme aware
public struct ScaleAnimalCard: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    // MARK: - Properties
    let name: String
    let species: String
    let morph: String?
    let status: String
    let statusColor: Color
    let imageData: Data?
    let onTap: (() -> Void)?

    // MARK: - Init
    public init(
        name: String,
        species: String,
        morph: String? = nil,
        status: String,
        statusColor: Color = .scaleSuccess,
        imageData: Data? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.name = name
        self.species = species
        self.morph = morph
        self.status = status
        self.statusColor = statusColor
        self.imageData = imageData
        self.onTap = onTap
    }

    // MARK: - Body
    public var body: some View {
        cardContent
    }

    @ViewBuilder
    private var cardContent: some View {
        if let onTap = onTap {
            Button(action: onTap) {
                cardView
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            cardView
        }
    }

    private var cardView: some View {
        HStack(spacing: ScaleSpacing.md) {
            // Photo or placeholder
            photoView
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))

            // Info
            VStack(alignment: .leading, spacing: ScaleSpacing.xs) {
                Text(name)
                    .font(.scaleHeadline)
                    .foregroundColor(.scaleTextPrimary)

                Text(morph ?? species)
                    .font(.scaleSubheadline)
                    .foregroundColor(themeManager.currentTheme.textSecondary)

                HStack(spacing: ScaleSpacing.xs) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)

                    Text(status)
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeManager.currentTheme.textTertiary)
        }
        .padding(ScaleSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ScaleRadius.lg)
                .fill(themeManager.currentTheme.cardBackground.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: ScaleRadius.lg)
                        .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var photoView: some View {
        if let data = imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle()
                .fill(themeManager.currentTheme.primaryAccent.opacity(0.2))
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.currentTheme.primaryAccent.opacity(0.5))
                )
        }
    }
}

// MARK: - Previews

#Preview("Scale Card") {
    ScaleCard(
        header: .init(title: "Morning Feedings", subtitle: "3 animals due", icon: "sun.max.fill")
    ) {
        Text("Card content goes here")
            .foregroundColor(.nebulaLavender)
    }
    .padding()
    .background(Color.substrateDark)
}

#Preview("Stat Card") {
    HStack(spacing: 12) {
        ScaleStatCard(
            title: "Current Streak",
            value: "12",
            subtitle: "days",
            trend: .up(percentage: 20),
            icon: "flame.fill",
            iconColor: .heatLampAmber
        )

        ScaleStatCard(
            title: "Total Animals",
            value: "23",
            icon: "leaf.fill"
        )
    }
    .padding()
    .background(Color.substrateDark)
}

#Preview("Animal Card") {
    ScaleAnimalCard(
        name: "Monty",
        species: "Ball Python",
        morph: "Piebald het Clown",
        status: "Due for feeding",
        statusColor: .heatLampAmber
    ) {}
    .padding()
    .background(Color.substrateDark)
}
