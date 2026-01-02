import SwiftUI
import ScaleCore
import ScaleUI

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground(showOrbs: false)

                List {
                    // Account Section
                    Section {
                        subscriptionRow
                    } header: {
                        Text("Account")
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                    }
                    .listRowBackground(themeManager.currentTheme.cardBackground.opacity(0.7))

                    // Preferences Section
                    Section {
                        NavigationLink {
                            Text("Units Settings")
                        } label: {
                            settingsRow(icon: "ruler", title: "Units", value: "Metric")
                        }

                        NavigationLink {
                            Text("Notifications Settings")
                        } label: {
                            settingsRow(icon: "bell.fill", title: "Notifications")
                        }
                    } header: {
                        Text("Preferences")
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                    }
                    .listRowBackground(themeManager.currentTheme.cardBackground.opacity(0.7))

                    // Data Section
                    Section {
                        NavigationLink {
                            Text("Export Data")
                        } label: {
                            settingsRow(icon: "square.and.arrow.up", title: "Export Data")
                        }

                        NavigationLink {
                            Text("Import Data")
                        } label: {
                            settingsRow(icon: "square.and.arrow.down", title: "Import Data")
                        }

                        NavigationLink {
                            Text("iCloud Sync")
                        } label: {
                            settingsRow(icon: "icloud.fill", title: "iCloud Sync", value: "On")
                        }
                    } header: {
                        Text("Data")
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                    }
                    .listRowBackground(themeManager.currentTheme.cardBackground.opacity(0.7))

                    // Support Section
                    Section {
                        NavigationLink {
                            Text("Help & FAQ")
                        } label: {
                            settingsRow(icon: "questionmark.circle.fill", title: "Help & FAQ")
                        }

                        Button {
                            // Open email
                        } label: {
                            settingsRow(icon: "envelope.fill", title: "Contact Support")
                        }

                        Button {
                            // Open App Store review
                        } label: {
                            settingsRow(icon: "star.fill", title: "Rate ScaleKeeper")
                        }
                    } header: {
                        Text("Support")
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                    }
                    .listRowBackground(themeManager.currentTheme.cardBackground.opacity(0.7))

                    // About Section
                    Section {
                        settingsRow(icon: "info.circle.fill", title: "Version", value: "1.0.0")

                        NavigationLink {
                            Text("Privacy Policy")
                        } label: {
                            settingsRow(icon: "hand.raised.fill", title: "Privacy Policy")
                        }

                        NavigationLink {
                            Text("Terms of Service")
                        } label: {
                            settingsRow(icon: "doc.text.fill", title: "Terms of Service")
                        }
                    } header: {
                        Text("About")
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                    }
                    .listRowBackground(themeManager.currentTheme.cardBackground.opacity(0.7))
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Subscription Row

    private var subscriptionRow: some View {
        Button {
            appState.isShowingPaywall = true
        } label: {
            HStack {
                Circle()
                    .fill(subscriptionColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: subscriptionIcon)
                            .foregroundColor(subscriptionColor)
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.subscriptionService.currentTier.displayName)
                        .font(.scaleHeadline)
                        .foregroundColor(.scaleTextPrimary)

                    Text(subscriptionSubtitle)
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }

                Spacer()

                if !appState.subscriptionService.isPremium {
                    Text("Upgrade")
                        .font(.scaleButtonSmall)
                        .foregroundColor(themeManager.currentTheme.primaryAccent)
                        .padding(.horizontal, ScaleSpacing.md)
                        .padding(.vertical, ScaleSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: ScaleRadius.sm)
                                .fill(themeManager.currentTheme.primaryAccent.opacity(0.15))
                        )
                }
            }
        }
    }

    private var subscriptionColor: Color {
        switch appState.subscriptionService.currentTier {
        case .free:
            return .scaleMuted
        case .keeper:
            return themeManager.currentTheme.primaryAccent
        case .breeder:
            return themeManager.currentTheme.secondaryAccent
        case .professional:
            return .heatLampAmber
        }
    }

    private var subscriptionIcon: String {
        switch appState.subscriptionService.currentTier {
        case .free:
            return "person.fill"
        case .keeper:
            return "leaf.fill"
        case .breeder:
            return "heart.fill"
        case .professional:
            return "star.fill"
        }
    }

    private var subscriptionSubtitle: String {
        switch appState.subscriptionService.currentTier {
        case .free:
            return "Up to 5 animals"
        case .keeper:
            return "Unlimited animals"
        case .breeder:
            return "Full breeding tools"
        case .professional:
            return "All features unlocked"
        }
    }

    // MARK: - Settings Row

    @ViewBuilder
    private func settingsRow(icon: String, title: String, value: String? = nil) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(themeManager.currentTheme.primaryAccent)
                .frame(width: 24)

            Text(title)
                .font(.scaleBody)
                .foregroundColor(.scaleTextPrimary)

            Spacer()

            if let value = value {
                Text(value)
                    .font(.scaleSubheadline)
                    .foregroundColor(themeManager.currentTheme.textTertiary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
