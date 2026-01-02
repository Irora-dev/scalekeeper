import SwiftUI

// MARK: - Scale Date Picker

public struct ScaleDatePicker: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    let title: String
    @Binding var date: Date
    var isRequired: Bool = false
    var errorMessage: String? = nil
    var helpText: String? = nil
    var displayedComponents: DatePickerComponents = .date
    var range: ClosedRange<Date>? = nil

    @State private var isExpanded: Bool = false

    public init(
        _ title: String,
        date: Binding<Date>,
        isRequired: Bool = false,
        errorMessage: String? = nil,
        helpText: String? = nil,
        displayedComponents: DatePickerComponents = .date,
        range: ClosedRange<Date>? = nil
    ) {
        self.title = title
        self._date = date
        self.isRequired = isRequired
        self.errorMessage = errorMessage
        self.helpText = helpText
        self.displayedComponents = displayedComponents
        self.range = range
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

            // Date picker button
            Button {
                withAnimation(ScaleAnimation.medium) {
                    isExpanded.toggle()
                }
                ScaleHaptics.light()
            } label: {
                HStack {
                    Image(systemName: iconName)
                        .font(.system(size: 16))
                        .foregroundStyle(themeManager.currentTheme.primaryAccent)

                    Text(formattedDate)
                        .font(Font.scaleBody)
                        .foregroundStyle(Color.scaleTextPrimary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
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

            // Expanded picker
            if isExpanded {
                Group {
                    if let range = range {
                        DatePicker(
                            "",
                            selection: $date,
                            in: range,
                            displayedComponents: displayedComponents
                        )
                    } else {
                        DatePicker(
                            "",
                            selection: $date,
                            displayedComponents: displayedComponents
                        )
                    }
                }
                .datePickerStyle(.graphical)
                .tint(themeManager.currentTheme.primaryAccent)
                .colorScheme(.dark)
                .padding(ScaleSpacing.sm)
                .background(themeManager.currentTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
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

    private var iconName: String {
        if displayedComponents.contains(.hourAndMinute) && !displayedComponents.contains(.date) {
            return "clock.fill"
        } else {
            return "calendar"
        }
    }

    private var formattedDate: String {
        if displayedComponents == .date {
            return date.formatted(date: .long, time: .omitted)
        } else if displayedComponents == .hourAndMinute {
            return date.formatted(date: .omitted, time: .shortened)
        } else {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
    }

    private var borderColor: Color {
        if errorMessage != nil {
            return Color.scaleError
        } else if isExpanded {
            return themeManager.currentTheme.primaryAccent
        } else {
            return themeManager.currentTheme.borderColor
        }
    }
}

// MARK: - Optional Date Picker

public struct ScaleOptionalDatePicker: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    let title: String
    @Binding var date: Date?
    var placeholder: String = "Not set"
    var isRequired: Bool = false
    var errorMessage: String? = nil
    var helpText: String? = nil
    var displayedComponents: DatePickerComponents = .date
    var range: ClosedRange<Date>? = nil

    @State private var isExpanded: Bool = false
    @State private var tempDate: Date = Date()

    public init(
        _ title: String,
        date: Binding<Date?>,
        placeholder: String = "Not set",
        isRequired: Bool = false,
        errorMessage: String? = nil,
        helpText: String? = nil,
        displayedComponents: DatePickerComponents = .date,
        range: ClosedRange<Date>? = nil
    ) {
        self.title = title
        self._date = date
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.errorMessage = errorMessage
        self.helpText = helpText
        self.displayedComponents = displayedComponents
        self.range = range
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

            // Date picker button
            HStack {
                Button {
                    withAnimation(ScaleAnimation.medium) {
                        isExpanded.toggle()
                    }
                    ScaleHaptics.light()
                } label: {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 16))
                            .foregroundStyle(date != nil ? themeManager.currentTheme.primaryAccent : themeManager.currentTheme.textTertiary)

                        if let date = date {
                            Text(formattedDate(date))
                                .font(Font.scaleBody)
                                .foregroundStyle(Color.scaleTextPrimary)
                        } else {
                            Text(placeholder)
                                .font(Font.scaleBody)
                                .foregroundStyle(themeManager.currentTheme.textTertiary)
                        }

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.scaleTextTertiary)
                    }
                }

                if date != nil {
                    Button {
                        date = nil
                        isExpanded = false
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

            // Expanded picker
            if isExpanded {
                VStack(spacing: ScaleSpacing.sm) {
                    Group {
                        if let range = range {
                            DatePicker(
                                "",
                                selection: $tempDate,
                                in: range,
                                displayedComponents: displayedComponents
                            )
                        } else {
                            DatePicker(
                                "",
                                selection: $tempDate,
                                displayedComponents: displayedComponents
                            )
                        }
                    }
                    .datePickerStyle(.graphical)
                    .tint(themeManager.currentTheme.primaryAccent)
                    .colorScheme(.dark)

                    HStack {
                        Button("Clear") {
                            date = nil
                            isExpanded = false
                            ScaleHaptics.light()
                        }
                        .font(Font.scaleButton)
                        .foregroundStyle(themeManager.currentTheme.textSecondary)

                        Spacer()

                        Button("Set Date") {
                            date = tempDate
                            isExpanded = false
                            ScaleHaptics.success()
                        }
                        .font(Font.scaleButton)
                        .foregroundStyle(themeManager.currentTheme.primaryAccent)
                    }
                }
                .padding(ScaleSpacing.sm)
                .background(themeManager.currentTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
                .onAppear {
                    tempDate = date ?? Date()
                }
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

    private func formattedDate(_ date: Date) -> String {
        if displayedComponents == .date {
            return date.formatted(date: .long, time: .omitted)
        } else if displayedComponents == .hourAndMinute {
            return date.formatted(date: .omitted, time: .shortened)
        } else {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
    }

    private var borderColor: Color {
        if errorMessage != nil {
            return Color.scaleError
        } else if isExpanded {
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

        ScrollView {
            VStack(spacing: ScaleSpacing.lg) {
                ScaleDatePicker(
                    "Hatch Date",
                    date: .constant(Date()),
                    isRequired: true,
                    helpText: "When was this animal born?"
                )

                ScaleOptionalDatePicker(
                    "Acquisition Date",
                    date: .constant(nil),
                    placeholder: "Select date",
                    helpText: "When did you acquire this animal?"
                )

                ScaleDatePicker(
                    "Feeding Time",
                    date: .constant(Date()),
                    displayedComponents: [.date, .hourAndMinute]
                )
            }
            .padding()
        }
    }
}
