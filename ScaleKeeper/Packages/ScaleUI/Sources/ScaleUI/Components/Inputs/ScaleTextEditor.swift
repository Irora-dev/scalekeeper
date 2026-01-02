import SwiftUI

// MARK: - Scale Text Editor

public struct ScaleTextEditor: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var isRequired: Bool = false
    var errorMessage: String? = nil
    var helpText: String? = nil
    var minHeight: CGFloat = 100
    var maxHeight: CGFloat = 200
    var characterLimit: Int? = nil

    @FocusState private var isFocused: Bool

    public init(
        _ title: String,
        text: Binding<String>,
        placeholder: String = "",
        isRequired: Bool = false,
        errorMessage: String? = nil,
        helpText: String? = nil,
        minHeight: CGFloat = 100,
        maxHeight: CGFloat = 200,
        characterLimit: Int? = nil
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.errorMessage = errorMessage
        self.helpText = helpText
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.characterLimit = characterLimit
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

                Spacer()

                if let limit = characterLimit {
                    Text("\(text.count)/\(limit)")
                        .font(Font.scaleCaption)
                        .foregroundStyle(text.count > limit ? Color.scaleError : themeManager.currentTheme.textTertiary)
                }
            }

            // Text editor
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(Font.scaleBody)
                        .foregroundStyle(themeManager.currentTheme.textTertiary)
                        .padding(.horizontal, ScaleSpacing.sm)
                        .padding(.vertical, ScaleSpacing.sm + 8)
                }

                TextEditor(text: $text)
                    .font(Font.scaleBody)
                    .foregroundStyle(Color.scaleTextPrimary)
                    .scrollContentBackground(.hidden)
                    .focused($isFocused)
                    .frame(minHeight: minHeight, maxHeight: maxHeight)
                    .onChange(of: text) { _, newValue in
                        if let limit = characterLimit, newValue.count > limit {
                            text = String(newValue.prefix(limit))
                        }
                    }
            }
            .padding(.horizontal, ScaleSpacing.sm)
            .padding(.vertical, ScaleSpacing.xs)
            .background(themeManager.currentTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: ScaleRadius.md)
                    .stroke(borderColor, lineWidth: 1)
            )

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
        } else if isFocused {
            return themeManager.currentTheme.primaryAccent
        } else {
            return themeManager.currentTheme.borderColor
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        ScaleBackground()

        VStack(spacing: ScaleSpacing.lg) {
            ScaleTextEditor(
                "Notes",
                text: .constant(""),
                placeholder: "Add notes about your animal...",
                helpText: "Optional notes for your records"
            )

            ScaleTextEditor(
                "Care Notes",
                text: .constant("This snake prefers to eat at night and likes a warm hide."),
                placeholder: "Enter care notes",
                characterLimit: 500
            )
        }
        .padding()
    }
}
