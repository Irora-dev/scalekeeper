import SwiftUI
import SwiftData
import ScaleCore
import ScaleUI

// MARK: - Care View (Feeding, Medications, Enclosures)

struct CareView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = CareViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedSection: CareSection = .feeding
    @State private var showingNewSchedule = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                VStack(spacing: 0) {
                    // Section Selector
                    sectionSelector
                        .padding(.horizontal, ScaleSpacing.lg)
                        .padding(.top, ScaleSpacing.md)

                    // Content
                    ScrollView {
                        VStack(spacing: ScaleSpacing.lg) {
                            switch selectedSection {
                            case .feeding:
                                feedingContent
                            case .medications:
                                medicationsContent
                            case .enclosures:
                                enclosuresContent
                            }
                        }
                        .padding(ScaleSpacing.lg)
                    }
                }
            }
            .navigationTitle("Care")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            appState.presentSheet(.quickNote)
                        } label: {
                            Label("Add Note", systemImage: "note.text.badge.plus")
                        }

                        Button {
                            showingNewSchedule = true
                        } label: {
                            Label("New Schedule", systemImage: "calendar.badge.plus")
                        }
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
                NewFeedingScheduleView {
                    Task { await viewModel.load() }
                }
            }
        }
    }

    // MARK: - Section Selector

    private var sectionSelector: some View {
        HStack(spacing: ScaleSpacing.sm) {
            ForEach(CareSection.allCases, id: \.self) { section in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedSection = section
                    }
                    ScaleHaptics.light()
                } label: {
                    VStack(spacing: ScaleSpacing.xs) {
                        Image(systemName: section.icon)
                            .font(.system(size: 20, weight: .medium))

                        Text(section.title)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(selectedSection == section ? .white : themeManager.currentTheme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ScaleSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: ScaleRadius.md)
                            .fill(selectedSection == section ? section.accentColor : themeManager.currentTheme.cardBackground.opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: ScaleRadius.md)
                            .stroke(selectedSection == section ? section.accentColor : themeManager.currentTheme.borderColor, lineWidth: 1)
                    )
                }
            }
        }
        .padding(.bottom, ScaleSpacing.sm)
    }

    // MARK: - Feeding Content

    private var feedingContent: some View {
        VStack(spacing: ScaleSpacing.lg) {
            // Quick Actions
            HStack(spacing: ScaleSpacing.md) {
                QuickCareButton(
                    title: "Setup Schedule",
                    icon: "calendar.badge.plus",
                    color: .nebulaGold
                ) {
                    showingNewSchedule = true
                }

                QuickCareButton(
                    title: "Add Note",
                    icon: "note.text.badge.plus",
                    color: .nebulaCyan
                ) {
                    appState.presentSheet(.quickNote)
                }
            }

            // Upcoming Feedings
            if !viewModel.upcomingFeedings.isEmpty {
                ScaleCard(
                    header: .init(
                        title: "Upcoming Week",
                        subtitle: "\(viewModel.upcomingFeedings.count) scheduled",
                        icon: "calendar.badge.clock",
                        iconColor: .nebulaCyan
                    )
                ) {
                    VStack(spacing: ScaleSpacing.sm) {
                        ForEach(viewModel.upcomingFeedings.prefix(7)) { feeding in
                            UpcomingFeedingRow(feeding: feeding) {
                                if let firstID = feeding.animalIDs.first {
                                    appState.presentSheet(.logFeeding(animalID: firstID))
                                }
                            }
                        }
                    }
                }
            }

            // Active Schedules
            if !viewModel.feedingRoutines.isEmpty {
                ScaleCard(
                    header: .init(
                        title: "Feeding Schedules",
                        subtitle: "\(viewModel.feedingRoutines.count) active",
                        icon: "repeat",
                        iconColor: .nebulaLavender
                    )
                ) {
                    VStack(spacing: ScaleSpacing.sm) {
                        ForEach(viewModel.feedingRoutines, id: \.id) { routine in
                            NavigationLink {
                                FeedingRoutineDetailView(routine: routine) {
                                    Task { await viewModel.load() }
                                }
                            } label: {
                                FeedingRoutineRow(routine: routine)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }

            // Due Today
            if !viewModel.dueToday.isEmpty {
                ScaleCard(
                    header: .init(
                        title: "Due Today",
                        subtitle: "\(viewModel.dueToday.count) animals",
                        icon: "fork.knife",
                        iconColor: .heatLampAmber
                    )
                ) {
                    VStack(spacing: ScaleSpacing.sm) {
                        ForEach(viewModel.dueToday, id: \.id) { animal in
                            DueTodayRow(animal: animal) {
                                appState.presentSheet(.quickFeed(animalID: animal.id))
                            }
                        }
                    }
                }
            }

            // Fed Today (completed feedings)
            if !viewModel.fedToday.isEmpty {
                ScaleCard(
                    header: .init(
                        title: "Fed Today",
                        subtitle: "\(viewModel.fedToday.count) completed",
                        icon: "checkmark.circle.fill",
                        iconColor: .scaleSuccess
                    )
                ) {
                    VStack(spacing: ScaleSpacing.sm) {
                        ForEach(viewModel.fedToday, id: \.id) { animal in
                            FedTodayRow(animal: animal)
                        }
                    }
                }
            }

            // Empty State
            if viewModel.upcomingFeedings.isEmpty && viewModel.feedingRoutines.isEmpty && viewModel.dueToday.isEmpty && viewModel.fedToday.isEmpty {
                emptyFeedingState
            }
        }
    }

    private var emptyFeedingState: some View {
        VStack(spacing: ScaleSpacing.lg) {
            Image(systemName: "fork.knife")
                .font(.system(size: 50))
                .foregroundColor(themeManager.currentTheme.primaryAccent.opacity(0.5))

            Text("No Feeding Schedules")
                .font(.scaleHeadline)
                .foregroundColor(.scaleTextPrimary)

            Text("Set up feeding schedules to track when your animals need to eat.")
                .font(.scaleSubheadline)
                .foregroundColor(.scaleTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, ScaleSpacing.xxl)
    }

    // MARK: - Medications Content

    private var medicationsContent: some View {
        VStack(spacing: ScaleSpacing.lg) {
            // Quick Actions
            HStack(spacing: ScaleSpacing.md) {
                NavigationLink {
                    MedicationView()
                } label: {
                    VStack(spacing: ScaleSpacing.xs) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                        Text("Add Treatment")
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundColor(.nebulaMagenta)
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .background(
                        RoundedRectangle(cornerRadius: ScaleRadius.md)
                            .fill(Color.nebulaMagenta.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: ScaleRadius.md)
                                    .stroke(Color.nebulaMagenta.opacity(0.3), lineWidth: 1)
                            )
                    )
                }

                NavigationLink {
                    MedicationView()
                } label: {
                    VStack(spacing: ScaleSpacing.xs) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 20, weight: .medium))
                        Text("Med Library")
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundColor(.nebulaLavender)
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .background(
                        RoundedRectangle(cornerRadius: ScaleRadius.md)
                            .fill(Color.nebulaLavender.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: ScaleRadius.md)
                                    .stroke(Color.nebulaLavender.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }

            // Active Treatments
            if !viewModel.activeTreatments.isEmpty {
                ScaleCard(
                    header: .init(
                        title: "Active Treatments",
                        subtitle: "\(viewModel.activeTreatments.count) ongoing",
                        icon: "pills.fill",
                        iconColor: .nebulaMagenta
                    )
                ) {
                    VStack(spacing: ScaleSpacing.sm) {
                        ForEach(viewModel.activeTreatments, id: \.id) { treatment in
                            CareTreatmentRow(treatment: treatment)
                        }
                    }
                }
            }

            // Empty State
            if viewModel.activeTreatments.isEmpty {
                emptyMedicationsState
            }
        }
    }

    private var emptyMedicationsState: some View {
        VStack(spacing: ScaleSpacing.lg) {
            Image(systemName: "pills")
                .font(.system(size: 50))
                .foregroundColor(themeManager.currentTheme.secondaryAccent.opacity(0.5))

            Text("No Active Treatments")
                .font(.scaleHeadline)
                .foregroundColor(.scaleTextPrimary)

            Text("When your animals need medication, track treatments here.")
                .font(.scaleSubheadline)
                .foregroundColor(.scaleTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, ScaleSpacing.xxl)
    }

    // MARK: - Enclosures Content

    private var enclosuresContent: some View {
        VStack(spacing: ScaleSpacing.lg) {
            // Quick Actions
            HStack(spacing: ScaleSpacing.md) {
                NavigationLink {
                    EnclosureView()
                } label: {
                    VStack(spacing: ScaleSpacing.xs) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                        Text("Add Enclosure")
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundColor(.nebulaPurple)
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .background(
                        RoundedRectangle(cornerRadius: ScaleRadius.md)
                            .fill(Color.nebulaPurple.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: ScaleRadius.md)
                                    .stroke(Color.nebulaPurple.opacity(0.3), lineWidth: 1)
                            )
                    )
                }

                NavigationLink {
                    EnclosureView()
                } label: {
                    VStack(spacing: ScaleSpacing.xs) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .medium))
                        Text("Log Cleaning")
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundColor(.nebulaCyan)
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .background(
                        RoundedRectangle(cornerRadius: ScaleRadius.md)
                            .fill(Color.nebulaCyan.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: ScaleRadius.md)
                                    .stroke(Color.nebulaCyan.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }

            // Cleaning Due
            if !viewModel.cleaningAlerts.isEmpty {
                ScaleCard(
                    header: .init(
                        title: "Cleaning Due",
                        subtitle: "\(viewModel.cleaningAlerts.count) tasks",
                        icon: "sparkles",
                        iconColor: .nebulaCyan
                    )
                ) {
                    VStack(spacing: ScaleSpacing.sm) {
                        ForEach(viewModel.cleaningAlerts, id: \.enclosureName) { alert in
                            CareCleaningAlertRow(alert: alert)
                        }
                    }
                }
            }

            // Empty State
            if viewModel.cleaningAlerts.isEmpty && viewModel.enclosureCount == 0 {
                emptyEnclosuresState
            }
        }
    }

    private var emptyEnclosuresState: some View {
        VStack(spacing: ScaleSpacing.lg) {
            Image(systemName: "square.3.layers.3d")
                .font(.system(size: 50))
                .foregroundColor(themeManager.currentTheme.primaryAccent.opacity(0.5))

            Text("No Enclosures")
                .font(.scaleHeadline)
                .foregroundColor(.scaleTextPrimary)

            Text("Add enclosures to track cleaning schedules and conditions.")
                .font(.scaleSubheadline)
                .foregroundColor(.scaleTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, ScaleSpacing.xxl)
    }
}

// MARK: - Care Section

enum CareSection: String, CaseIterable {
    case feeding
    case medications
    case enclosures

    var title: String {
        switch self {
        case .feeding: return "Feeding"
        case .medications: return "Meds"
        case .enclosures: return "Enclosures"
        }
    }

    var icon: String {
        switch self {
        case .feeding: return "fork.knife"
        case .medications: return "pills.fill"
        case .enclosures: return "square.3.layers.3d"
        }
    }

    var accentColor: Color {
        switch self {
        case .feeding: return .heatLampAmber
        case .medications: return .nebulaMagenta
        case .enclosures: return .nebulaPurple
        }
    }
}

// MARK: - Quick Care Button

struct QuickCareButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: ScaleSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                RoundedRectangle(cornerRadius: ScaleRadius.md)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: ScaleRadius.md)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Row Views

struct UpcomingFeedingRow: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let feeding: ScheduledFeeding
    let onFeed: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: ScaleSpacing.sm) {
                    Text(feeding.isToday ? "Today" : (feeding.isTomorrow ? "Tomorrow" : feeding.dayOfWeek))
                        .font(.scaleSubheadline)
                        .foregroundColor(feeding.isToday ? themeManager.currentTheme.primaryAccent : .scaleTextPrimary)
                    Text(feeding.formattedTime)
                        .font(.scaleCaption)
                        .foregroundColor(.scaleTextTertiary)
                }
                Text("\(feeding.animalCount) animals - \(feeding.timeLabel)")
                    .font(.scaleCaption)
                    .foregroundColor(.scaleTextTertiary)
            }

            Spacer()

            if feeding.isToday {
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
            } else {
                Text(feeding.formattedDate)
                    .font(.scaleCaption)
                    .foregroundColor(.scaleTextTertiary)
            }
        }
        .padding(.vertical, ScaleSpacing.xs)
    }
}

struct FeedingRoutineRow: View {
    let routine: FeedingRoutine

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(routine.name)
                    .font(.scaleSubheadline)
                    .foregroundColor(.scaleTextPrimary)
                Text("\(routine.getAnimalIDs().count) animals - \(routine.routineType.displayName)")
                    .font(.scaleCaption)
                    .foregroundColor(.scaleTextTertiary)
            }

            Spacer()

            Circle()
                .fill(routine.isActive ? Color.scaleSuccess : Color.scaleMuted)
                .frame(width: 8, height: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.scaleTextTertiary)
        }
        .padding(.vertical, ScaleSpacing.xs)
    }
}

struct DueTodayRow: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let animal: Animal
    let onFeed: () -> Void

    var body: some View {
        HStack {
            Circle()
                .fill(Color.heatLampAmber.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "fork.knife")
                        .font(.system(size: 14))
                        .foregroundColor(.heatLampAmber)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(animal.name)
                    .font(.scaleSubheadline)
                    .foregroundColor(.scaleTextPrimary)
                if let morph = animal.morph {
                    Text(morph)
                        .font(.scaleCaption)
                        .foregroundColor(.scaleTextTertiary)
                }
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

struct FedTodayRow: View {
    let animal: Animal

    var body: some View {
        HStack {
            // Checkmark circle
            Circle()
                .fill(Color.scaleSuccess.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.scaleSuccess)
                )

            VStack(alignment: .leading, spacing: 2) {
                // Name with strikethrough
                Text(animal.name)
                    .font(.scaleSubheadline)
                    .foregroundColor(.scaleTextTertiary)
                    .strikethrough(true, color: .scaleTextTertiary)
                if let morph = animal.morph {
                    Text(morph)
                        .font(.scaleCaption)
                        .foregroundColor(.scaleTextDisabled)
                }
            }

            Spacer()

            // "Done" badge
            Text("Done")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.scaleSuccess)
                .padding(.horizontal, ScaleSpacing.sm)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.scaleSuccess.opacity(0.15))
                )
        }
        .padding(.vertical, ScaleSpacing.xs)
        .opacity(0.8)
    }
}

struct CareTreatmentRow: View {
    let treatment: TreatmentPlan

    var body: some View {
        HStack {
            Circle()
                .fill(Color.nebulaMagenta.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "pills.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.nebulaMagenta)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(treatment.medication?.name ?? "Treatment")
                    .font(.scaleSubheadline)
                    .foregroundColor(.scaleTextPrimary)
                Text(treatment.animal?.name ?? "")
                    .font(.scaleCaption)
                    .foregroundColor(.scaleTextTertiary)
            }

            Spacer()

            Text(treatment.status.displayName)
                .font(.scaleCaption)
                .foregroundColor(.nebulaMagenta)
        }
        .padding(.vertical, ScaleSpacing.xs)
    }
}

struct CareCleaningAlertRow: View {
    let alert: CleaningStatus

    var body: some View {
        HStack {
            Circle()
                .fill(urgencyColor.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: alert.cleaningType.iconName)
                        .font(.system(size: 14))
                        .foregroundColor(urgencyColor)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(alert.cleaningType.displayName)
                    .font(.scaleSubheadline)
                    .foregroundColor(.scaleTextPrimary)
                Text(alert.enclosureName)
                    .font(.scaleCaption)
                    .foregroundColor(.scaleTextTertiary)
            }

            Spacer()

            if alert.urgency == .overdue {
                Text("\(abs(alert.daysUntilDue))d overdue")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.scaleError)
            } else {
                Text("Due in \(alert.daysUntilDue)d")
                    .font(.system(size: 11))
                    .foregroundColor(.nebulaGold)
            }
        }
        .padding(.vertical, ScaleSpacing.xs)
    }

    private var urgencyColor: Color {
        switch alert.urgency {
        case .onTrack: return .nebulaCyan
        case .dueSoon: return .nebulaGold
        case .overdue: return .scaleError
        }
    }
}

// MARK: - Care View Model

@MainActor
@Observable
final class CareViewModel: ObservableObject {
    private let dataService: DataService
    private let feedingService: FeedingService
    private let cleaningService: CleaningService

    var feedingRoutines: [FeedingRoutine] = []
    var upcomingFeedings: [ScheduledFeeding] = []
    var dueToday: [Animal] = []
    var fedToday: [Animal] = []
    var activeTreatments: [TreatmentPlan] = []
    var cleaningAlerts: [CleaningStatus] = []
    var enclosureCount: Int = 0
    var isLoading = false

    init(
        dataService: DataService = .shared,
        feedingService: FeedingService = .shared,
        cleaningService: CleaningService = .shared
    ) {
        self.dataService = dataService
        self.feedingService = feedingService
        self.cleaningService = cleaningService
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        // Load feeding data
        do {
            feedingRoutines = try dataService.fetchActiveFeedingRoutines()
            upcomingFeedings = try dataService.upcomingWeekFeedings()
        } catch {
            print("Error loading feeding data: \(error)")
        }

        // Load due today and fed today from feeding service
        await feedingService.refresh()
        dueToday = feedingService.dueToday
        fedToday = feedingService.fedToday

        // Load medications
        do {
            activeTreatments = try dataService.fetchActiveTreatments()
        } catch {
            print("Error loading treatments: \(error)")
        }

        // Load enclosures and cleaning alerts
        do {
            let enclosures = try dataService.fetchEnclosures()
            enclosureCount = enclosures.count

            var allStatuses: [CleaningStatus] = []
            for enclosure in enclosures {
                if let statuses = try? cleaningService.cleaningStatus(for: enclosure) {
                    allStatuses.append(contentsOf: statuses)
                }
            }
            let filteredStatuses = allStatuses.filter { $0.urgency == .dueSoon || $0.urgency == .overdue }
            cleaningAlerts = filteredStatuses.sorted { $0.daysUntilDue < $1.daysUntilDue }
        } catch {
            print("Error loading enclosures: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    CareView()
        .environmentObject(AppState())
}
