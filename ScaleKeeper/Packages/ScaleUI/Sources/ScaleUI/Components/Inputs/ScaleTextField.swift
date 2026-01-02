import SwiftUI

// MARK: - Scale Text Field

public struct ScaleTextField: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var icon: String? = nil
    var isRequired: Bool = false
    var errorMessage: String? = nil
    var helpText: String? = nil
    var autocapitalization: TextInputAutocapitalization = .sentences
    var keyboardType: UIKeyboardType = .default
    var submitLabel: SubmitLabel = .done
    var onSubmit: (() -> Void)? = nil

    @FocusState private var isFocused: Bool

    public init(
        _ title: String,
        text: Binding<String>,
        placeholder: String = "",
        icon: String? = nil,
        isRequired: Bool = false,
        errorMessage: String? = nil,
        helpText: String? = nil
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
        self.isRequired = isRequired
        self.errorMessage = errorMessage
        self.helpText = helpText
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

            // Input field
            HStack(spacing: ScaleSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(isFocused ? themeManager.currentTheme.primaryAccent : themeManager.currentTheme.textTertiary)
                }

                TextField(placeholder, text: $text)
                    .font(Font.scaleBody)
                    .foregroundStyle(Color.scaleTextPrimary)
                    .textInputAutocapitalization(autocapitalization)
                    .keyboardType(keyboardType)
                    .submitLabel(submitLabel)
                    .focused($isFocused)
                    .onSubmit {
                        onSubmit?()
                    }

                if !text.isEmpty {
                    Button {
                        text = ""
                        ScaleHaptics.light()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(themeManager.currentTheme.textTertiary)
                    }
                }
            }
            .padding(.horizontal, ScaleSpacing.md)
            .padding(.vertical, ScaleSpacing.sm)
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

// MARK: - Modifiers

extension ScaleTextField {
    public func autocapitalization(_ type: TextInputAutocapitalization) -> ScaleTextField {
        var copy = self
        copy.autocapitalization = type
        return copy
    }

    public func keyboardType(_ type: UIKeyboardType) -> ScaleTextField {
        var copy = self
        copy.keyboardType = type
        return copy
    }

    public func submitLabel(_ label: SubmitLabel) -> ScaleTextField {
        var copy = self
        copy.submitLabel = label
        return copy
    }

    public func onSubmit(_ action: @escaping () -> Void) -> ScaleTextField {
        var copy = self
        copy.onSubmit = action
        return copy
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        ScaleBackground()

        VStack(spacing: ScaleSpacing.lg) {
            ScaleTextField(
                "Animal Name",
                text: .constant(""),
                placeholder: "Enter name",
                icon: "pawprint.fill",
                isRequired: true
            )

            ScaleTextField(
                "Morph",
                text: .constant("Pastel Banana"),
                placeholder: "Enter morph",
                helpText: "Genetic traits of your animal"
            )

            ScaleTextField(
                "Breeder",
                text: .constant(""),
                placeholder: "Enter breeder name",
                errorMessage: "This field is required"
            )
        }
        .padding()
    }
}
