import SwiftUI
import ScaleCore
import ScaleUI

// MARK: - Feeding View

struct FeedingView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = FeedingViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingNewSchedule = false
    @State private var showingScheduleList = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.primaryAccent))
                } else {
                    ScrollView {
                        VStack(spacing: ScaleSpacing.lg) {
                            // Quick Actions
                            quickActionsSection

                            // Upcoming Week Schedule
                            if !viewModel.upcomingScheduledFeedings.isEmpty {
                                upcomingWeekSection
                            }

                            // Picky Eaters Alert (NEW - "Udon Feature")
                            if !viewModel.pickyEaters.isEmpty {
                                pickyEatersSection
                            }

                            // Overdue Section
                            if !viewModel.overdue.isEmpty {
                                feedingSection(
                                    title: "Overdue",
                                    subtitle: "\(viewModel.overdue.count) animals",
                                    icon: "exclamationmark.triangle.fill",
                                    iconColor: .scaleError,
                                    animals: viewModel.overdue
                                )
                            }

                            // Due Today Section
                            if !viewModel.dueToday.isEmpty {
                                feedingSection(
                                    title: "Due Today",
                                    subtitle: "\(viewModel.dueToday.count) animals",
                                    icon: "clock.fill",
                                    iconColor: .nebulaGold,
                                    animals: viewModel.dueToday
                                )
                            }

                            // Fed Today Section
                            if !viewModel.fedToday.isEmpty {
                                feedingSection(
                                    title: "Fed Today",
                                    subtitle: "\(viewModel.fedToday.count) animals",
                                    icon: "checkmark.circle.fill",
                                    iconColor: .nebulaCyan,
                                    animals: viewModel.fedToday,
                                    showFeedButton: false
                                )
                            }

                            // Upcoming Section
                            if !viewModel.upcoming.isEmpty {
                                feedingSection(
                                    title: "Upcoming",
                                    subtitle: "\(viewModel.upcoming.count) animals",
                                    icon: "calendar",
                                    iconColor: .nebulaLavender,
                                    animals: viewModel.upcoming,
                                    showFeedButton: false
                                )
                            }

                            // Schedules Section
                            if !viewModel.feedingRoutines.isEmpty {
                                schedulesSection
                            }

                            // Empty State
                            if viewModel.isEmpty && viewModel.feedingRoutines.isEmpty {
                                emptyState
                            }
                        }
                        .padding(ScaleSpacing.lg)
                    }
                }
            }
            .navigationTitle("Feeding")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingNewSchedule = true
                        } label: {
                            Label("New Schedule", systemImage: "calendar.badge.plus")
                        }

                        Button {
                            appState.presentSheet(.batchFeed)
                        } label: {
                            Label("Batch Feed", systemImage: "square.stack.fill")
                        }

                        Button {
                            // Export schedule
                        } label: {
                            Label("Export Schedule", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
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

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        HStack(spacing: ScaleSpacing.md) {
            Button {
                showingNewSchedule = true
            } label: {
                HStack(spacing: ScaleSpacing.sm) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 16))
                    Text("Setup Schedule")
                        .font(.scaleButtonSmall)
                }
                .foregroundColor(themeManager.currentTheme.primaryAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, ScaleSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: ScaleRadius.md)
                        .fill(themeManager.currentTheme.primaryAccent.opacity(0.15))
                )
            }
        }
    }

    // MARK: - Upcoming Week Section

    private var upcomingWeekSection: some View {
        ScaleCard(
            header: .init(
                title: "Upcoming Week",
                subtitle: "\(viewModel.upcomingScheduledFeedings.count) scheduled",
                icon: "calendar.badge.clock",
                iconColor: .nebulaCyan
            )
        ) {
            VStack(spacing: ScaleSpacing.sm) {
                ForEach(viewModel.upcomingScheduledFeedings.prefix(7)) { feeding in
                    ScheduledFeedingRow(feeding: feeding) {
                        // Navigate to log feeding for all animals in schedule
                        if let firstAnimalID = feeding.animalIDs.first {
                            appState.presentSheet(.logFeeding(animalID: firstAnimalID))
                        }
                    }
                }

                if viewModel.upcomingScheduledFeedings.count > 7 {
                    Text("+ \(viewModel.upcomingScheduledFeedings.count - 7) more this week")
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                        .padding(.top, ScaleSpacing.xs)
                }
            }
        }
    }

    // MARK: - Schedules Section

    private var schedulesSection: some View {
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
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(routine.name)
                                    .font(.scaleSubheadline)
                                    .foregroundColor(.scaleTextPrimary)
                                Text("\(routine.getAnimalIDs().count) animals - \(routine.routineType.displayName)")
                                    .font(.scaleCaption)
                                    .foregroundColor(themeManager.currentTheme.textTertiary)
                            }

                            Spacer()

                            Circle()
                                .fill(routine.isActive ? Color.scaleSuccess : Color.scaleMuted)
                                .frame(width: 8, height: 8)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.currentTheme.textTertiary)
                        }
                        .padding(.vertical, ScaleSpacing.xs)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - Picky Eaters Section (NEW)

    private var pickyEatersSection: some View {
        ScaleCard(
            header: .init(
                title: "Picky Eaters",
                subtitle: "Extended hunger alert",
                icon: "exclamationmark.bubble.fill",
                iconColor: .nebulaMagenta
            )
        ) {
            VStack(spacing: ScaleSpacing.md) {
                ForEach(viewModel.pickyEaters, id: \.0.id) { animal, hunger in
                    PickyEaterRow(
                        animal: animal,
                        hunger: hunger
                    ) {
                        appState.presentSheet(.logFeeding(animalID: animal.id))
                    }
                }
            }
        }
    }

    // MARK: - Feeding Section

    @ViewBuilder
    private func feedingSection(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        animals: [Animal],
        showFeedButton: Bool = true
    ) -> some View {
        ScaleCard(
            header: .init(
                title: title,
                subtitle: subtitle,
                icon: icon,
                iconColor: iconColor
            )
        ) {
            VStack(spacing: ScaleSpacing.sm) {
                ForEach(animals, id: \.id) { animal in
                    FeedingAnimalRow(
                        animal: animal,
                        hungerDuration: viewModel.hungerForAnimal(animal),
                        showFeedButton: showFeedButton
                    ) {
                        appState.presentSheet(.logFeeding(animalID: animal.id))
                    } onQuickFeed: {
                        Task {
                            await viewModel.quickFeed(animal)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: ScaleSpacing.lg) {
            Image(systemName: "fork.knife")
                .font(.system(size: 60))
                .foregroundColor(themeManager.currentTheme.primaryAccent.opacity(0.5))
                .shadow(color: themeManager.currentTheme.primaryAccent.opacity(0.3), radius: 10)

            Text("No Feedings Scheduled")
                .font(.scaleTitle2)
                .foregroundColor(.scaleTextPrimary)

            Text("Add animals to your collection to see their feeding schedules here.")
                .font(.scaleSubheadline)
                .foregroundColor(themeManager.currentTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, ScaleSpacing.xxl)
        }
        .padding(.vertical, ScaleSpacing.xxxl)
    }
}

// MARK: - Picky Eater Row (NEW)

struct PickyEaterRow: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let animal: Animal
    let hunger: HungerDuration
    let onLogFeeding: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(animal.name)
                        .font(.scaleHeadline)
                        .foregroundColor(.scaleTextPrimary)

                    // Hunger duration badge
                    HStack(spacing: ScaleSpacing.xs) {
                        Circle()
                            .fill(urgencyColor)
                            .frame(width: 8, height: 8)

                        Text(hunger.displayText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(urgencyColor)
                    }
                }

                Spacer()

                // Refusal count badge
                if hunger.refusalCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                        Text("\(hunger.refusalCount) refused")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.scaleError)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.scaleError.opacity(0.15))
                    )
                }

                Button(action: onLogFeeding) {
                    Text("Try Feeding")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.nebulaMagenta)
                        .padding(.horizontal, ScaleSpacing.md)
                        .padding(.vertical, ScaleSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: ScaleRadius.sm)
                                .fill(Color.nebulaMagenta.opacity(0.15))
                        )
                }
            }

            // Insight message
            Text(hunger.urgencyLevel.advice)
                .font(.system(size: 12))
                .foregroundColor(themeManager.currentTheme.textTertiary)
                .padding(.top, 2)
        }
        .padding(.vertical, ScaleSpacing.sm)
    }

    private var urgencyColor: Color {
        switch hunger.urgencyLevel {
        case .unknown: return .nebulaLavender
        case .normal: return .nebulaCyan
        case .extended: return .nebulaGold
        case .concerning: return .nebulaMagenta
        case .critical: return .scaleError
        }
    }
}

// MARK: - Feeding Animal Row

struct FeedingAnimalRow: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let animal: Animal
    let hungerDuration: HungerDuration?
    let showFeedButton: Bool
    let onLogFeeding: () -> Void
    let onQuickFeed: () -> Void

    var body: some View {
        HStack {
            // Animal Info
            VStack(alignment: .leading, spacing: ScaleSpacing.xs) {
                Text(animal.name)
                    .font(.scaleHeadline)
                    .foregroundColor(.scaleTextPrimary)

                HStack(spacing: ScaleSpacing.sm) {
                    if let morph = animal.morph {
                        Text(morph)
                            .font(.scaleCaption)
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                    }

                    // Hunger duration badge (NEW)
                    if let hunger = hungerDuration,
                       let days = hunger.daysSinceLastMeal,
                       days > 0 {
                        HungerBadge(days: days, urgency: hunger.urgencyLevel)
                    }
                }
            }

            Spacer()

            if showFeedButton {
                HStack(spacing: ScaleSpacing.sm) {
                    // Quick feed
                    Button(action: onQuickFeed) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.nebulaGold)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color.nebulaGold.opacity(0.15))
                            )
                    }

                    // Log feeding
                    Button(action: onLogFeeding) {
                        Text("Feed")
                            .font(.scaleButtonSmall)
                            .foregroundColor(ThemeManager.shared.currentTheme.primaryAccent)
                            .padding(.horizontal, ScaleSpacing.md)
                            .padding(.vertical, ScaleSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: ScaleRadius.sm)
                                    .fill(ThemeManager.shared.currentTheme.primaryAccent.opacity(0.15))
                            )
                    }
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.nebulaCyan)
            }
        }
        .padding(.vertical, ScaleSpacing.sm)
    }
}

// MARK: - Hunger Badge (NEW)

struct HungerBadge: View {
    let days: Int
    let urgency: HungerUrgency

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.system(size: 10))
            Text("\(days)d")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(urgencyColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(urgencyColor.opacity(0.15))
        )
    }

    private var urgencyColor: Color {
        switch urgency {
        case .unknown: return .nebulaLavender
        case .normal: return .nebulaCyan
        case .extended: return .nebulaGold
        case .concerning: return .nebulaMagenta
        case .critical: return .scaleError
        }
    }
}

// MARK: - Scheduled Feeding Row

struct ScheduledFeedingRow: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let feeding: ScheduledFeeding
    let onFeed: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: ScaleSpacing.sm) {
                    Text(feeding.isToday ? "Today" : (feeding.isTomorrow ? "Tomorrow" : feeding.dayOfWeek))
                        .font(.scaleSubheadline)
                        .foregroundColor(feeding.isToday ? ThemeManager.shared.currentTheme.primaryAccent : .scaleTextPrimary)

                    Text(feeding.formattedTime)
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }

                Text("\(feeding.animalCount) animals - \(feeding.timeLabel)")
                    .font(.scaleCaption)
                    .foregroundColor(themeManager.currentTheme.textTertiary)
            }

            Spacer()

            if feeding.isToday {
                Button(action: onFeed) {
                    Text("Feed")
                        .font(.scaleButtonSmall)
                        .foregroundColor(ThemeManager.shared.currentTheme.primaryAccent)
                        .padding(.horizontal, ScaleSpacing.md)
                        .padding(.vertical, ScaleSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: ScaleRadius.sm)
                                .fill(ThemeManager.shared.currentTheme.primaryAccent.opacity(0.15))
                        )
                }
            } else {
                Text(feeding.formattedDate)
                    .font(.scaleCaption)
                    .foregroundColor(themeManager.currentTheme.textTertiary)
            }
        }
        .padding(.vertical, ScaleSpacing.xs)
    }
}

// MARK: - Feeding View Model

@MainActor
@Observable
final class FeedingViewModel: ObservableObject {
    // MARK: - Dependencies
    private let feedingService: FeedingService
    private let dataService: DataService

    // MARK: - State
    var overdue: [Animal] = []
    var dueToday: [Animal] = []
    var fedToday: [Animal] = []
    var upcoming: [Animal] = []
    var pickyEaters: [(Animal, HungerDuration)] = []
    var animalHungerMap: [UUID: HungerDuration] = [:]
    var feedingRoutines: [FeedingRoutine] = []
    var upcomingScheduledFeedings: [ScheduledFeeding] = []
    var isLoading = false
    var error: Error?

    var isEmpty: Bool {
        overdue.isEmpty && dueToday.isEmpty && fedToday.isEmpty && upcoming.isEmpty && pickyEaters.isEmpty
    }

    // MARK: - Init
    init(feedingService: FeedingService = .shared, dataService: DataService = .shared) {
        self.feedingService = feedingService
        self.dataService = dataService
    }

    // MARK: - Load
    func load() async {
        isLoading = true
        defer { isLoading = false }

        await feedingService.refresh()

        overdue = feedingService.overdue
        dueToday = feedingService.dueToday
        fedToday = feedingService.fedToday
        upcoming = feedingService.upcoming

        // Load feeding routines
        do {
            feedingRoutines = try dataService.fetchActiveFeedingRoutines()
            upcomingScheduledFeedings = try dataService.upcomingWeekFeedings()
        } catch {
            self.error = error
        }

        // Load picky eaters (extended hunger)
        do {
            pickyEaters = try await feedingService.animalsWithExtendedHunger()

            // Build hunger map for all animals
            let allAnimals = overdue + dueToday + fedToday + upcoming
            for animal in allAnimals {
                if let hunger = try? feedingService.hungerDuration(for: animal) {
                    animalHungerMap[animal.id] = hunger
                }
            }
        } catch {
            self.error = error
        }
    }

    // MARK: - Get hunger for animal
    func hungerForAnimal(_ animal: Animal) -> HungerDuration? {
        return animalHungerMap[animal.id]
    }

    // MARK: - Quick Feed
    func quickFeed(_ animal: Animal) async {
        do {
            try feedingService.quickFeed(animal: animal)
            await load() // Refresh
        } catch {
            self.error = error
        }
    }
}

// MARK: - Preview

#Preview {
    FeedingView()
        .environmentObject(AppState())
}
