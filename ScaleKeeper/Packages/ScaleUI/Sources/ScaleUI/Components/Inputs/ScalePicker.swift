import SwiftUI

// MARK: - Scale Picker

public struct ScalePicker<T: Hashable, Content: View>: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    let title: String
    @Binding var selection: T
    let options: [T]
    var isRequired: Bool = false
    var errorMessage: String? = nil
    var helpText: String? = nil
    let content: (T) -> Content

    public init(
        _ title: String,
        selection: Binding<T>,
        options: [T],
        isRequired: Bool = false,
        errorMessage: String? = nil,
        helpText: String? = nil,
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self.title = title
        self._selection = selection
        self.options = options
        self.isRequired = isRequired
        self.errorMessage = errorMessage
        self.helpText = helpText
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.xs) {
            // Label
            HStack(spacing: ScaleSpacing.xs) {
                Text(title)
                    .font(Font.scaleSubheadline)
                    .foregroundStyle(themeManager.currentTheme.textSecondary)

                if isRequired {
                    Text("*")
                        .font(Font.scaleSubheadline)
                        .foregroundStyle(Color.scaleError)
                }
            }

            // Picker
            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection = option
                        ScaleHaptics.light()
                    } label: {
                        content(option)
                    }
                }
            } label: {
                HStack {
                    content(selection)
                        .font(Font.scaleBody)
                        .foregroundStyle(Color.scaleTextPrimary)

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 14))
                        .foregroundStyle(themeManager.currentTheme.textTertiary)
                }
                .padding(.horizontal, ScaleSpacing.md)
                .padding(.vertical, ScaleSpacing.sm)
                .background(themeManager.currentTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: ScaleRadius.md)
                        .stroke(borderColor, lineWidth: 1)
                )
            }

            // Help or error text
            if let error = errorMessage {
                HStack(spacing: ScaleSpacing.xs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text(error)
                        .font(Font.scaleCaption)
                }
                .foregroundStyle(Color.scaleError)
            } else if let help = helpText {
                Text(help)
                    .font(Font.scaleCaption)
                    .foregroundStyle(themeManager.currentTheme.textTertiary)
            }
        }
    }

    private var borderColor: Color {
        if errorMessage != nil {
            return Color.scaleError
        } else {
            return themeManager.currentTheme.borderColor
        }
    }
}

// MARK: - Scale Picker Row (for use in lists)

public struct ScalePickerRow<T: Hashable, Content: View>: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    let title: String
    @Binding var selection: T
    let options: [T]
    let content: (T) -> Content

    public init(
        _ title: String,
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
        HStack {
            Text(title)
                .font(Font.scaleBody)
                .foregroundStyle(Color.scaleTextPrimary)

            Spacer()

            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection = option
                        ScaleHaptics.light()
                    } label: {
                        content(option)
                    }
                }
            } label: {
                HStack(spacing: ScaleSpacing.xs) {
                    content(selection)
                        .font(Font.scaleBody)
                        .foregroundStyle(themeManager.currentTheme.primaryAccent)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(themeManager.currentTheme.textTertiary)
                }
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

        VStack(spacing: ScaleSpacing.lg) {
            ScalePicker(
                "Sex",
                selection: .constant("Male"),
                options: ["Male", "Female", "Unknown"],
                isRequired: true
            ) { option in
                Text(option)
            }

            ScalePickerRow(
                "Prey Size",
                selection: .constant("Medium"),
                options: ["Small", "Medium", "Large", "XL"]
            ) { option in
                Text(option)
            }
        }
        .padding()
    }
}
