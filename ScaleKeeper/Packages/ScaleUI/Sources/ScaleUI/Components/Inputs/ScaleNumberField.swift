import SwiftUI

// MARK: - Scale Number Field

public struct ScaleNumberField: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    let title: String
    @Binding var value: Double
    var placeholder: String = "0"
    var unit: String? = nil
    var icon: String? = nil
    var isRequired: Bool = false
    var errorMessage: String? = nil
    var helpText: String? = nil
    var range: ClosedRange<Double>? = nil
    var step: Double = 1
    var decimalPlaces: Int = 0

    @FocusState private var isFocused: Bool
    @State private var textValue: String = ""

    public init(
        _ title: String,
        value: Binding<Double>,
        placeholder: String = "0",
        unit: String? = nil,
        icon: String? = nil,
        isRequired: Bool = false,
        errorMessage: String? = nil,
        helpText: String? = nil,
        range: ClosedRange<Double>? = nil,
        step: Double = 1,
        decimalPlaces: Int = 0
    ) {
        self.title = title
        self._value = value
        self.placeholder = placeholder
        self.unit = unit
        self.icon = icon
        self.isRequired = isRequired
        self.errorMessage = errorMessage
        self.helpText = helpText
        self.range = range
        self.step = step
        self.decimalPlaces = decimalPlaces
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

            // Input field with stepper
            HStack(spacing: ScaleSpacing.sm) {
                // Decrease button
                Button {
                    decreaseValue()
                    ScaleHaptics.light()
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(canDecrease ? Color.scaleTextPrimary : themeManager.currentTheme.textDisabled)
                        .frame(width: 40, height: 40)
                        .background(themeManager.currentTheme.backgroundSecondary)
                        .clipShape(Circle())
                }
                .disabled(!canDecrease)

                // Value display/input
                HStack(spacing: ScaleSpacing.xs) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundStyle(isFocused ? themeManager.currentTheme.primaryAccent : themeManager.currentTheme.textTertiary)
                    }

                    TextField(placeholder, text: $textValue)
                        .font(Font.scaleStatMedium)
                        .foregroundStyle(Color.scaleTextPrimary)
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .focused($isFocused)
                        .onChange(of: textValue) { _, newValue in
                            updateValueFromText(newValue)
                        }
                        .onChange(of: value) { _, newValue in
                            updateTextFromValue(newValue)
                        }

                    if let unit = unit {
                        Text(unit)
                            .font(Font.scaleSubheadline)
                            .foregroundStyle(themeManager.currentTheme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)

                // Increase button
                Button {
                    increaseValue()
                    ScaleHaptics.light()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(canIncrease ? Color.scaleTextPrimary : themeManager.currentTheme.textDisabled)
                        .frame(width: 40, height: 40)
                        .background(themeManager.currentTheme.backgroundSecondary)
                        .clipShape(Circle())
                }
                .disabled(!canIncrease)
            }
            .padding(.horizontal, ScaleSpacing.sm)
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
        .onAppear {
            updateTextFromValue(value)
        }
    }

    private var canDecrease: Bool {
        if let range = range {
            return value - step >= range.lowerBound
        }
        return true
    }

    private var canIncrease: Bool {
        if let range = range {
            return value + step <= range.upperBound
        }
        return true
    }

    private func decreaseValue() {
        let newValue = value - step
        if let range = range {
            value = max(range.lowerBound, newValue)
        } else {
            value = newValue
        }
    }

    private func increaseValue() {
        let newValue = value + step
        if let range = range {
            value = min(range.upperBound, newValue)
        } else {
            value = newValue
        }
    }

    private func updateValueFromText(_ text: String) {
        if let newValue = Double(text) {
            if let range = range {
                value = min(max(newValue, range.lowerBound), range.upperBound)
            } else {
                value = newValue
            }
        }
    }

    private func updateTextFromValue(_ newValue: Double) {
        if decimalPlaces == 0 {
            textValue = String(format: "%.0f", newValue)
        } else {
            textValue = String(format: "%.\(decimalPlaces)f", newValue)
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

// MARK: - Scale Stepper (Simple Integer Stepper)

public struct ScaleStepper: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    let title: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 0...100
    var icon: String? = nil

    public init(
        _ title: String,
        value: Binding<Int>,
        range: ClosedRange<Int> = 0...100,
        icon: String? = nil
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.icon = icon
    }

    public var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.scaleTextSecondary)
            }

            Text(title)
                .font(Font.scaleBody)
                .foregroundStyle(Color.scaleTextPrimary)

            Spacer()

            HStack(spacing: ScaleSpacing.sm) {
                Button {
                    if value > range.lowerBound {
                        value -= 1
                        ScaleHaptics.light()
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(value > range.lowerBound ? themeManager.currentTheme.primaryAccent : themeManager.currentTheme.textDisabled)
                }
                .disabled(value <= range.lowerBound)

                Text("\(value)")
                    .font(Font.scaleStatSmall)
                    .foregroundStyle(Color.scaleTextPrimary)
                    .frame(minWidth: 40)

                Button {
                    if value < range.upperBound {
                        value += 1
                        ScaleHaptics.light()
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(value < range.upperBound ? themeManager.currentTheme.primaryAccent : themeManager.currentTheme.textDisabled)
                }
                .disabled(value >= range.upperBound)
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
            ScaleNumberField(
                "Weight",
                value: .constant(450),
                unit: "g",
                icon: "scalemass.fill",
                isRequired: true,
                helpText: "Current weight in grams",
                range: 0...50000
            )

            ScaleNumberField(
                "Temperature",
                value: .constant(88.5),
                unit: "°F",
                range: 60...120,
                step: 0.5,
                decimalPlaces: 1
            )

            ScaleStepper(
                "Quantity",
                value: .constant(2),
                range: 1...10,
                icon: "number"
            )
        }
        .padding()
    }
}
