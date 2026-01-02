import SwiftUI
import ScaleCore
import ScaleUI

// MARK: - Dashboard View

struct DashboardView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = DashboardViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingNewSchedule = false

    var body: some View {
        NavigationStack(path: $appState.navigationPath) {
            ZStack {
                ScaleBackground()

                ScrollView {
                    VStack(spacing: ScaleSpacing.lg) {
                        // Header with icon
                        headerSection

                        // Quick Stats
                        statsSection

                        // Quick Actions (below stats)
                        quickActionsSection

                        // Feeding Due Today
                        if !viewModel.feedingsDue.isEmpty {
                            feedingSection
                        }

                        // Enclosure/Cleaning Alerts
                        if !viewModel.cleaningAlerts.isEmpty {
                            cleaningAlertsSection
                        }

                        // Management Sections (logical order)
                        managementSection

                        // Recent Activity
                        recentActivitySection
                    }
                    .padding(ScaleSpacing.lg)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        appState.presentSheet(.addAnimal)
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(themeManager.currentTheme.primaryAccent)
                    }
                }
            }
            .task {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load()
            }
            .onChange(of: appState.dataRefreshTrigger) { _, _ in
                Task {
                    await viewModel.load()
                }
            }
            .sheet(isPresented: $showingNewSchedule) {
                NewFeedingScheduleView()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: ScaleSpacing.sm) {
            Image(systemName: "lizard.fill")
                .font(.system(size: 28))
                .foregroundColor(themeManager.currentTheme.primaryAccent)

            HStack(spacing: 0) {
                Text("Scale")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.scaleTextPrimary)
                Text("Keeper")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.nebulaCyan)
            }

            Spacer()
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: ScaleSpacing.md) {
            ScaleStatCard(
                title: "Total Animals",
                value: "\(viewModel.totalAnimals)",
                icon: "leaf.fill",
                iconColor: themeManager.currentTheme.primaryAccent
            )

            ScaleStatCard(
                title: "Due Today",
                value: "\(viewModel.feedingsDue.count)",
                icon: "fork.knife",
                iconColor: viewModel.feedingsDue.isEmpty ? .scaleTextTertiary : .heatLampAmber
            )

            ScaleStatCard(
                title: "Fed Today",
                value: "\(viewModel.fedToday)",
                icon: "checkmark.circle.fill",
                iconColor: .scaleSuccess
            )

            ScaleStatCard(
                title: "Overdue",
                value: "\(viewModel.overdueCount)",
                icon: "exclamationmark.triangle.fill",
                iconColor: viewModel.overdueCount > 0 ? .scaleError : themeManager.currentTheme.textTertiary
            )
        }
    }

    // MARK: - Feeding Section

    private var feedingSection: some View {
        ScaleCard(
            header: .init(
                title: "Due for Feeding",
                subtitle: "\(viewModel.feedingsDue.count) animals",
                icon: "fork.knife",
                iconColor: .heatLampAmber
            )
        ) {
            VStack(spacing: ScaleSpacing.sm) {
                ForEach(viewModel.feedingsDue.prefix(3), id: \.id) { animal in
                    FeedingDueRow(animal: animal) {
                        appState.presentSheet(.quickFeed(animalID: animal.id))
                    }
                }

                if viewModel.feedingsDue.count > 3 {
                    Button {
                        appState.selectedTab = .care
                    } label: {
                        Text("View all \(viewModel.feedingsDue.count) animals")
                            .font(.scaleCaption)
                            .foregroundColor(themeManager.currentTheme.primaryAccent)
                    }
                    .padding(.top, ScaleSpacing.xs)
                }
            }
        }
    }

    // MARK: - Recent Activity Section

    private var recentActivitySection: some View {
        ScaleCard(
            header: .init(
                title: "Recent Activity",
                icon: "clock.fill",
                iconColor: .scaleMuted
            )
        ) {
            if viewModel.recentActivity.isEmpty {
                Text("No recent activity")
                    .font(.scaleSubheadline)
                    .foregroundColor(themeManager.currentTheme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, ScaleSpacing.lg)
            } else {
                VStack(spacing: ScaleSpacing.sm) {
                    ForEach(viewModel.recentActivity.prefix(5), id: \.id) { activity in
                        ActivityRow(activity: activity)
                    }
                }
            }
        }
    }

    // MARK: - Cleaning Alerts Section

    private var cleaningAlertsSection: some View {
        ScaleCard(
            header: .init(
                title: "Cleaning Due",
                subtitle: "\(viewModel.cleaningAlerts.count) tasks",
                icon: "sparkles",
                iconColor: .nebulaMagenta
            )
        ) {
            VStack(spacing: ScaleSpacing.sm) {
                ForEach(viewModel.cleaningAlerts.prefix(3), id: \.enclosureName) { status in
                    HStack {
                        ZStack {
                            Circle()
                                .fill(cleaningUrgencyColor(status.urgency).opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: status.cleaningType.iconName)
                                .font(.system(size: 14))
                                .foregroundColor(cleaningUrgencyColor(status.urgency))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(status.cleaningType.displayName)
                                .font(.scaleSubheadline)
                                .foregroundColor(.scaleTextPrimary)
                            Text(status.enclosureName)
                                .font(.scaleCaption)
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                        }

                        Spacer()

                        if status.urgency == .overdue {
                            Text("\(abs(status.daysUntilDue))d overdue")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.scaleError)
                        } else {
                            Text("Due in \(status.daysUntilDue)d")
                                .font(.system(size: 11))
                                .foregroundColor(.nebulaGold)
                        }
                    }
                    .padding(.vertical, ScaleSpacing.xs)
                }

                if viewModel.cleaningAlerts.count > 3 {
                    NavigationLink {
                        EnclosureView()
                    } label: {
                        Text("View all \(viewModel.cleaningAlerts.count) tasks")
                            .font(.scaleCaption)
                            .foregroundColor(.nebulaMagenta)
                    }
                    .padding(.top, ScaleSpacing.xs)
                }
            }
        }
    }

    private func cleaningUrgencyColor(_ urgency: CleaningUrgency) -> Color {
        switch urgency {
        case .onTrack: return .nebulaCyan
        case .dueSoon: return .nebulaGold
        case .overdue: return .scaleError
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(spacing: ScaleSpacing.md) {
            Text("Quick Actions")
                .font(.scaleHeadline)
                .foregroundColor(.scaleTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: ScaleSpacing.md) {
                QuickActionButton(
                    title: "Add Animal",
                    icon: "plus.circle.fill",
                    color: themeManager.currentTheme.primaryAccent
                ) {
                    appState.presentSheet(.addAnimal)
                }

                QuickActionButton(
                    title: "Add Note",
                    icon: "note.text.badge.plus",
                    color: .nebulaCyan
                ) {
                    appState.presentSheet(.quickNote)
                }

                QuickActionButton(
                    title: "Log Feeding",
                    icon: "fork.knife",
                    color: themeManager.currentTheme.secondaryAccent
                ) {
                    appState.selectedTab = .care
                }

                QuickActionButton(
                    title: "Quick Log",
                    icon: "plus.circle",
                    color: .nebulaGold
                ) {
                    appState.isShowingQuickActionsHub = true
                }
            }

            // View Calendar button
            NavigationLink {
                CalendarView()
            } label: {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(.nebulaPurple)

                    Text("View Calendar")
                        .font(.scaleSubheadline)
                        .foregroundColor(.scaleTextPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.currentTheme.textTertiary)
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
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Management Section

    private var managementSection: some View {
        VStack(spacing: ScaleSpacing.md) {
            Text("Manage")
                .font(.scaleHeadline)
                .foregroundColor(.scaleTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Add Animal
            ManagementRow(
                title: "Add An Animal",
                subtitle: "Add a new pet to your collection",
                icon: "plus.circle.fill",
                iconColor: themeManager.currentTheme.primaryAccent
            ) {
                appState.presentSheet(.addAnimal)
            }

            // Setup Feeding Schedule
            ManagementRow(
                title: "Setup Feeding Schedule",
                subtitle: "Create routine feeding schedules",
                icon: "calendar.badge.plus",
                iconColor: .nebulaGold
            ) {
                showingNewSchedule = true
            }

            // Enclosures
            NavigationLink {
                EnclosureView()
            } label: {
                ManagementRowContent(
                    title: "Setup & Manage Enclosures",
                    subtitle: "Habitats & cleaning schedules",
                    icon: "square.3.layers.3d",
                    iconColor: themeManager.currentTheme.primaryAccent,
                    badge: viewModel.enclosureCount > 0 ? "\(viewModel.enclosureCount)" : nil
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Medications
            NavigationLink {
                MedicationView()
            } label: {
                ManagementRowContent(
                    title: "Setup & Manage Medications",
                    subtitle: "Track treatments & dose schedules",
                    icon: "pills.fill",
                    iconColor: .nebulaMagenta,
                    badge: viewModel.activeTreatmentCount > 0 ? "\(viewModel.activeTreatmentCount)" : nil
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Management Row

struct ManagementRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ManagementRowContent(
                title: title,
                subtitle: subtitle,
                icon: icon,
                iconColor: iconColor,
                badge: nil
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ManagementRowContent: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let badge: String?

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.scaleSubheadline)
                    .foregroundColor(.scaleTextPrimary)

                Text(subtitle)
                    .font(.scaleCaption)
                    .foregroundColor(themeManager.currentTheme.textTertiary)
            }

            Spacer()

            HStack(spacing: 4) {
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.currentTheme.textTertiary)
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
}

// MARK: - Feeding Due Row

struct FeedingDueRow: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let animal: Animal
    let onFeed: () -> Void

    var body: some View {
        HStack {
            Circle()
                .fill(Color.heatLampAmber.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "fork.knife")
                        .font(.system(size: 16))
                        .foregroundColor(.heatLampAmber)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(animal.name)
                    .font(.scaleSubheadline)
                    .foregroundColor(.scaleTextPrimary)

                Text(animal.morph ?? "")
                    .font(.scaleCaption)
                    .foregroundColor(themeManager.currentTheme.textTertiary)
            }

            Spacer()

            Button(action: onFeed) {
                Text("Feed")
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
        .padding(.vertical, ScaleSpacing.xs)
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let activity: ActivityItem

    var body: some View {
        HStack {
            Circle()
                .fill(activity.color.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: activity.icon)
                        .font(.system(size: 14))
                        .foregroundColor(activity.color)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.scaleCaption)
                    .foregroundColor(.scaleTextPrimary)

                Text(activity.timeAgo)
                    .font(.scaleCaption2)
                    .foregroundColor(themeManager.currentTheme.textTertiary)
            }

            Spacer()
        }
        .padding(.vertical, ScaleSpacing.xs)
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: ScaleSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)

                Text(title)
                    .font(.scaleCaption)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ScaleSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: ScaleRadius.md)
                    .fill(themeManager.currentTheme.cardBackground.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: ScaleRadius.md)
                            .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Activity Item

struct ActivityItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let timestamp: Date

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environmentObject(AppState())
}
