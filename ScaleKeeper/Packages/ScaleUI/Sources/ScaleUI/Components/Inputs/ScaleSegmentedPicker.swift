import SwiftUI

// MARK: - Scale Segmented Picker

public struct ScaleSegmentedPicker<T: Hashable, Content: View>: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    let title: String?
    @Binding var selection: T
    let options: [T]
    let content: (T) -> Content

    public init(
        _ title: String? = nil,
        selection: Binding<T>,
        options: [T],
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self.title = title
        self._selection = selection
        self.options = options
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.xs) {
            if let title = title {
                Text(title)
                    .font(Font.scaleSubheadline)
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
            }

            HStack(spacing: 0) {
                ForEach(options, id: \.self) { option in
                    Button {
                        withAnimation(ScaleAnimation.fast) {
                            selection = option
                        }
                        ScaleHaptics.light()
                    } label: {
                        content(option)
                            .font(Font.scaleButtonSmall)
                            .foregroundStyle(selection == option ? themeManager.currentTheme.backgroundPrimary : Color.scaleTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ScaleSpacing.sm)
                            .background(
                                selection == option ?
                                themeManager.currentTheme.primaryAccent :
                                Color.clear
                            )
                    }
                }
            }
            .background(themeManager.currentTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: ScaleRadius.md)
                    .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
            )
        }
    }
}

// MARK: - Scale Chip Picker (Multi-select chips)

public struct ScaleChipPicker<T: Hashable, Content: View>: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    let title: String?
    @Binding var selection: Set<T>
    let options: [T]
    var allowsMultiple: Bool = true
    let content: (T) -> Content

    public init(
        _ title: String? = nil,
        selection: Binding<Set<T>>,
        options: [T],
        allowsMultiple: Bool = true,
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self.title = title
        self._selection = selection
        self.options = options
        self.allowsMultiple = allowsMultiple
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.sm) {
            if let title = title {
                Text(title)
                    .font(Font.scaleSubheadline)
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
            }

            FlowLayout(spacing: ScaleSpacing.sm) {
                ForEach(options, id: \.self) { option in
                    ChipButton(
                        isSelected: selection.contains(option),
                        themeManager: themeManager,
                        action: {
                            toggleSelection(option)
                        }
                    ) {
                        content(option)
                    }
                }
            }
        }
    }

    private func toggleSelection(_ option: T) {
        ScaleHaptics.light()

        if allowsMultiple {
            if selection.contains(option) {
                selection.remove(option)
            } else {
                selection.insert(option)
            }
        } else {
            selection = [option]
        }
    }
}

// MARK: - Chip Button

private struct ChipButton<Content: View>: View {
    let isSelected: Bool
    @ObservedObject var themeManager: ThemeManager
    let action: () -> Void
    let content: () -> Content

    var body: some View {
        Button(action: action) {
            content()
                .font(Font.scaleButtonSmall)
                .foregroundStyle(isSelected ? themeManager.currentTheme.backgroundPrimary : Color.scaleTextSecondary)
                .padding(.horizontal, ScaleSpacing.md)
                .padding(.vertical, ScaleSpacing.sm)
                .background(isSelected ? themeManager.currentTheme.primaryAccent : themeManager.currentTheme.cardBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? themeManager.currentTheme.primaryAccent : Color.scaleBorder, lineWidth: 1)
                )
        }
    }
}

// MARK: - Flow Layout

public struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    public init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                self.size.width = max(self.size.width, x - spacing)
            }

            self.size.height = y + rowHeight
        }
    }
}

// MARK: - Scale Toggle Row

public struct ScaleToggleRow: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    let title: String
    @Binding var isOn: Bool
    var icon: String? = nil
    var subtitle: String? = nil

    public init(
        _ title: String,
        isOn: Binding<Bool>,
        icon: String? = nil,
        subtitle: String? = nil
    ) {
        self.title = title
        self._isOn = isOn
        self.icon = icon
        self.subtitle = subtitle
    }

    public var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
                    .frame(width: 24)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Font.scaleBody)
                    .foregroundStyle(Color.scaleTextPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Font.scaleCaption)
                        .foregroundStyle(themeManager.currentTheme.textTertiary)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(themeManager.currentTheme.primaryAccent)
                .onChange(of: isOn) { _, _ in
                    ScaleHaptics.light()
                }
        }
        .padding(.horizontal, ScaleSpacing.md)
        .padding(.vertical, ScaleSpacing.sm)
        .background(themeManager.currentTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        ScaleBackground()

        ScrollView {
            VStack(spacing: ScaleSpacing.lg) {
                ScaleSegmentedPicker(
                    "View Mode",
                    selection: .constant("Grid"),
                    options: ["List", "Grid", "Cards"]
                ) { option in
                    Text(option)
                }

                ScaleChipPicker(
                    "Categories",
                    selection: .constant(Set(["Snakes"])),
                    options: ["Snakes", "Lizards", "Geckos", "Tortoises", "Frogs"]
                ) { option in
                    Text(option)
                }

                ScaleToggleRow(
                    "Push Notifications",
                    isOn: .constant(true),
                    icon: "bell.fill",
                    subtitle: "Receive feeding reminders"
                )
            }
            .padding()
        }
    }
}
