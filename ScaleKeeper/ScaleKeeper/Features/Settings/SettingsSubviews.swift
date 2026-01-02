import SwiftUI
import ScaleCore
import ScaleUI

// MARK: - Units Preferences View

struct UnitsPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @AppStorage("weightUnit") private var weightUnit: String = "grams"
    @AppStorage("temperatureUnit") private var temperatureUnit: String = "fahrenheit"

    var body: some View {
        ZStack {
            ScaleBackground()

            ScrollView {
                VStack(spacing: ScaleSpacing.lg) {
                    // Weight unit
                    VStack(alignment: .leading, spacing: ScaleSpacing.md) {
                        ScaleSectionHeader("Weight")

                        ScaleSegmentedPicker(
                            selection: $weightUnit,
                            options: ["grams", "ounces"]
                        ) { unit in
                            Text(unit == "grams" ? "Grams (g)" : "Ounces (oz)")
                        }

                        Text("Default unit for weight measurements")
                            .font(.scaleCaption)
                            .foregroundStyle(themeManager.currentTheme.textTertiary)
                    }

                    // Temperature unit
                    VStack(alignment: .leading, spacing: ScaleSpacing.md) {
                        ScaleSectionHeader("Temperature")

                        ScaleSegmentedPicker(
                            selection: $temperatureUnit,
                            options: ["fahrenheit", "celsius"]
                        ) { unit in
                            Text(unit == "fahrenheit" ? "Fahrenheit (F)" : "Celsius (C)")
                        }

                        Text("Used for incubation temperature tracking")
                            .font(.scaleCaption)
                            .foregroundStyle(themeManager.currentTheme.textTertiary)
                    }
                }
                .padding(.horizontal, ScaleSpacing.md)
                .padding(.top, ScaleSpacing.md)
            }
        }
        .navigationTitle("Units")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Notification Settings View

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @AppStorage("feedingReminders") private var feedingReminders: Bool = true
    @AppStorage("feedingReminderTime") private var feedingReminderTime: Double = 32400 // 9 AM in seconds
    @AppStorage("shedReminders") private var shedReminders: Bool = false
    @AppStorage("breedingAlerts") private var breedingAlerts: Bool = false

    var body: some View {
        ZStack {
            ScaleBackground()

            ScrollView {
                VStack(spacing: ScaleSpacing.lg) {
                    // Feeding reminders
                    VStack(alignment: .leading, spacing: ScaleSpacing.md) {
                        ScaleSectionHeader("Feeding Reminders")

                        ScaleToggleRow(
                            "Enable Feeding Reminders",
                            isOn: $feedingReminders,
                            icon: "fork.knife",
                            subtitle: "Get notified when animals are due to eat"
                        )

                        if feedingReminders {
                            VStack(alignment: .leading, spacing: ScaleSpacing.xs) {
                                Text("Default Reminder Time")
                                    .font(.scaleSubheadline)
                                    .foregroundStyle(themeManager.currentTheme.textSecondary)

                                DatePicker(
                                    "",
                                    selection: Binding(
                                        get: { Date(timeIntervalSince1970: feedingReminderTime) },
                                        set: { feedingReminderTime = $0.timeIntervalSince1970 }
                                    ),
                                    displayedComponents: .hourAndMinute
                                )
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .frame(height: 100)
                                .clipped()
                            }
                        }
                    }

                    // Shed reminders
                    VStack(alignment: .leading, spacing: ScaleSpacing.md) {
                        ScaleSectionHeader("Shed Tracking")

                        ScaleToggleRow(
                            "Shed Reminders",
                            isOn: $shedReminders,
                            icon: "leaf.fill",
                            subtitle: "Notify when animals may be entering shed"
                        )
                    }

                    // Breeding alerts
                    VStack(alignment: .leading, spacing: ScaleSpacing.md) {
                        ScaleSectionHeader("Breeding")

                        ScaleToggleRow(
                            "Breeding Alerts",
                            isOn: $breedingAlerts,
                            icon: "heart.fill",
                            subtitle: "Get updates on clutch development"
                        )
                    }
                }
                .padding(.horizontal, ScaleSpacing.md)
                .padding(.top, ScaleSpacing.md)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Appearance Settings View

struct AppearanceSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @AppStorage("appTheme") private var appTheme: String = "system"
    @AppStorage("accentColor") private var accentColor: String = "green"

    var body: some View {
        ZStack {
            ScaleBackground()

            ScrollView {
                VStack(spacing: ScaleSpacing.lg) {
                    // Theme
                    VStack(alignment: .leading, spacing: ScaleSpacing.md) {
                        ScaleSectionHeader("Theme")

                        ScaleSegmentedPicker(
                            selection: $appTheme,
                            options: ["light", "dark", "system"]
                        ) { theme in
                            switch theme {
                            case "light": Text("Light")
                            case "dark": Text("Dark")
                            default: Text("System")
                            }
                        }

                        Text("Choose how ScaleKeeper appears")
                            .font(.scaleCaption)
                            .foregroundStyle(themeManager.currentTheme.textTertiary)
                    }

                    // Accent color
                    VStack(alignment: .leading, spacing: ScaleSpacing.md) {
                        ScaleSectionHeader("Accent Color")

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: ScaleSpacing.md) {
                            ForEach(["green", "blue", "purple", "orange"], id: \.self) { color in
                                Button {
                                    accentColor = color
                                    ScaleHaptics.light()
                                } label: {
                                    Circle()
                                        .fill(colorForName(color))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .stroke(accentColor == color ? Color.white : Color.clear, lineWidth: 3)
                                        )
                                        .overlay(
                                            Image(systemName: accentColor == color ? "checkmark" : "")
                                                .foregroundStyle(.white)
                                                .font(.system(size: 16, weight: .bold))
                                        )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, ScaleSpacing.md)
                .padding(.top, ScaleSpacing.md)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func colorForName(_ name: String) -> Color {
        switch name {
        case "green": return .terrariumGreen
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        default: return .terrariumGreen
        }
    }
}

// MARK: - Data Management View

struct DataManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingExportSheet = false
    @State private var showingDeleteAlert = false
    @State private var isExporting = false

    var body: some View {
        ZStack {
            ScaleBackground()

            ScrollView {
                VStack(spacing: ScaleSpacing.lg) {
                    // Export
                    VStack(alignment: .leading, spacing: ScaleSpacing.md) {
                        ScaleSectionHeader("Export")

                        Button {
                            showingExportSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(Color.terrariumGreen)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Export Data")
                                        .font(.scaleBody)
                                        .foregroundStyle(Color.scaleTextPrimary)
                                    Text("Export your collection as CSV or JSON")
                                        .font(.scaleCaption)
                                        .foregroundStyle(themeManager.currentTheme.textTertiary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(themeManager.currentTheme.textTertiary)
                            }
                            .padding(ScaleSpacing.md)
                            .background(Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
                        }
                    }

                    // Storage info
                    VStack(alignment: .leading, spacing: ScaleSpacing.md) {
                        ScaleSectionHeader("Storage")

                        VStack(spacing: ScaleSpacing.sm) {
                            storageRow(title: "Animals", value: "Calculating...")
                            storageRow(title: "Photos", value: "Calculating...")
                            storageRow(title: "Feeding Records", value: "Calculating...")
                            storageRow(title: "Total", value: "Calculating...")
                        }
                        .padding(ScaleSpacing.md)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
                    }

                    // Danger zone
                    VStack(alignment: .leading, spacing: ScaleSpacing.md) {
                        ScaleSectionHeader("Danger Zone")

                        Button {
                            showingDeleteAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .foregroundStyle(Color.scaleError)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Delete All Data")
                                        .font(.scaleBody)
                                        .foregroundStyle(Color.scaleError)
                                    Text("Permanently remove all animals and records")
                                        .font(.scaleCaption)
                                        .foregroundStyle(themeManager.currentTheme.textTertiary)
                                }

                                Spacer()
                            }
                            .padding(ScaleSpacing.md)
                            .background(Color.scaleError.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: ScaleRadius.md)
                                    .stroke(Color.scaleError.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, ScaleSpacing.md)
                .padding(.top, ScaleSpacing.md)
            }
        }
        .navigationTitle("Data Management")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete All Data?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Everything", role: .destructive) {
                // TODO: Implement delete all
            }
        } message: {
            Text("This will permanently delete all your animals, feeding records, photos, and breeding data. This action cannot be undone.")
        }
    }

    private func storageRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.scaleBody)
                .foregroundStyle(Color.scaleTextPrimary)
            Spacer()
            Text(value)
                .font(.scaleBody)
                .foregroundStyle(themeManager.currentTheme.textSecondary)
        }
    }
}

// MARK: - Help View

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        ZStack {
            ScaleBackground()

            ScrollView {
                VStack(spacing: ScaleSpacing.lg) {
                    // Quick start
                    VStack(alignment: .leading, spacing: ScaleSpacing.md) {
                        ScaleSectionHeader("Quick Start")

                        VStack(spacing: 0) {
                            helpRow(
                                icon: "1.circle.fill",
                                title: "Add Your First Animal",
                                description: "Tap the + button in the Collection tab"
                            )
                            Divider()
                            helpRow(
                                icon: "2.circle.fill",
                                title: "Log Feedings",
                                description: "Track what and when your animals eat"
                            )
                            Divider()
                            helpRow(
                                icon: "3.circle.fill",
                                title: "Monitor Health",
                                description: "Record weights, sheds, and health notes"
                            )
                        }
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
                    }

                    // FAQ
                    VStack(alignment: .leading, spacing: ScaleSpacing.md) {
                        ScaleSectionHeader("FAQ")

                        VStack(spacing: 0) {
                            faqRow(
                                question: "How do I set feeding reminders?",
                                answer: "Feeding schedules are set per-animal. Edit an animal and adjust the feeding interval."
                            )
                            Divider()
                            faqRow(
                                question: "Can I track multiple species?",
                                answer: "Yes! ScaleKeeper supports snakes, lizards, geckos, and more."
                            )
                            Divider()
                            faqRow(
                                question: "Is my data backed up?",
                                answer: "Your data is stored locally. Export regularly to create backups."
                            )
                        }
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
                    }

                    // Contact
                    VStack(alignment: .leading, spacing: ScaleSpacing.md) {
                        ScaleSectionHeader("Contact")

                        Button {
                            // TODO: Open email
                        } label: {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundStyle(Color.terrariumGreen)
                                    .frame(width: 24)

                                Text("Email Support")
                                    .font(.scaleBody)
                                    .foregroundStyle(Color.scaleTextPrimary)

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .foregroundStyle(themeManager.currentTheme.textTertiary)
                            }
                            .padding(ScaleSpacing.md)
                            .background(Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
                        }
                    }
                }
                .padding(.horizontal, ScaleSpacing.md)
                .padding(.top, ScaleSpacing.md)
            }
        }
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func helpRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: ScaleSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(Color.terrariumGreen)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.scaleBody)
                    .foregroundStyle(Color.scaleTextPrimary)
                Text(description)
                    .font(.scaleCaption)
                    .foregroundStyle(themeManager.currentTheme.textTertiary)
            }

            Spacer()
        }
        .padding(ScaleSpacing.md)
    }

    private func faqRow(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.xs) {
            Text(question)
                .font(.scaleBody)
                .foregroundStyle(Color.scaleTextPrimary)
            Text(answer)
                .font(.scaleCaption)
                .foregroundStyle(themeManager.currentTheme.textTertiary)
        }
        .padding(ScaleSpacing.md)
    }
}

// MARK: - Previews

#Preview("Units") {
    NavigationStack {
        UnitsPreferencesView()
    }
}

#Preview("Notifications") {
    NavigationStack {
        NotificationSettingsView()
    }
}

#Preview("Appearance") {
    NavigationStack {
        AppearanceSettingsView()
    }
}

#Preview("Data") {
    NavigationStack {
        DataManagementView()
    }
}

#Preview("Help") {
    NavigationStack {
        HelpView()
    }
}
