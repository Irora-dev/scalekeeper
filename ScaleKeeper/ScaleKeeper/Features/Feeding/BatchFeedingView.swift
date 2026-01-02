import SwiftUI
import ScaleCore
import ScaleUI

// MARK: - Batch Feeding View (Animal Selection)

struct BatchFeedingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var themeManager = ThemeManager.shared
    @StateObject private var viewModel = BatchFeedingViewModel()
    @State private var showingSession = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                VStack(spacing: 0) {
                    // Quick Filters
                    filterBar

                    // Animal Selection List
                    ScrollView {
                        LazyVStack(spacing: ScaleSpacing.sm) {
                            ForEach(viewModel.filteredAnimals, id: \.id) { animal in
                                AnimalSelectionRow(
                                    animal: animal,
                                    isSelected: viewModel.selectedAnimals.contains(animal.id)
                                ) {
                                    viewModel.toggleSelection(animal)
                                }
                            }
                        }
                        .padding(ScaleSpacing.lg)
                    }

                    // Bottom Action Bar
                    if !viewModel.selectedAnimals.isEmpty {
                        bottomActionBar
                    }
                }
            }
            .navigationTitle("Batch Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(viewModel.selectedAnimals.count == viewModel.filteredAnimals.count ? "Deselect All" : "Select All") {
                        viewModel.toggleSelectAll()
                    }
                    .foregroundColor(themeManager.currentTheme.primaryAccent)
                }
            }
            .task {
                await viewModel.load()
            }
            .fullScreenCover(isPresented: $showingSession) {
                BatchFeedingSessionView(
                    animals: viewModel.animalsToFeed,
                    onComplete: {
                        dismiss()
                        appState.triggerDataRefresh()
                    }
                )
            }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ScaleSpacing.sm) {
                FilterChip(
                    title: "Due Today",
                    count: viewModel.dueTodayCount,
                    isSelected: viewModel.filter == .dueToday
                ) {
                    viewModel.filter = .dueToday
                }

                FilterChip(
                    title: "Overdue",
                    count: viewModel.overdueCount,
                    isSelected: viewModel.filter == .overdue
                ) {
                    viewModel.filter = .overdue
                }

                FilterChip(
                    title: "All Animals",
                    count: viewModel.allAnimals.count,
                    isSelected: viewModel.filter == .all
                ) {
                    viewModel.filter = .all
                }
            }
            .padding(.horizontal, ScaleSpacing.lg)
            .padding(.vertical, ScaleSpacing.md)
        }
        .background(themeManager.currentTheme.cardBackground.opacity(0.5))
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(themeManager.currentTheme.borderColor)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.selectedAnimals.count) selected")
                        .font(.scaleHeadline)
                        .foregroundColor(.scaleTextPrimary)

                    Text("Tap to start feeding session")
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }

                Spacer()

                Button {
                    showingSession = true
                } label: {
                    HStack(spacing: ScaleSpacing.sm) {
                        Image(systemName: "play.fill")
                        Text("Start Session")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, ScaleSpacing.lg)
                    .padding(.vertical, ScaleSpacing.md)
                    .background(
                        Capsule()
                            .fill(themeManager.currentTheme.primaryAccent)
                    )
                }
            }
            .padding(ScaleSpacing.lg)
            .background(themeManager.currentTheme.backgroundPrimary)
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: ScaleSpacing.xs) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : themeManager.currentTheme.primaryAccent.opacity(0.3))
                        )
                }
            }
            .foregroundColor(isSelected ? .white : themeManager.currentTheme.textSecondary)
            .padding(.horizontal, ScaleSpacing.md)
            .padding(.vertical, ScaleSpacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? themeManager.currentTheme.primaryAccent : themeManager.currentTheme.cardBackground)
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? themeManager.currentTheme.primaryAccent : themeManager.currentTheme.borderColor, lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Animal Selection Row

struct AnimalSelectionRow: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let animal: Animal
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ScaleSpacing.md) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? themeManager.currentTheme.primaryAccent : themeManager.currentTheme.borderColor, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(themeManager.currentTheme.primaryAccent)
                            .frame(width: 16, height: 16)
                    }
                }

                // Animal info
                VStack(alignment: .leading, spacing: 2) {
                    Text(animal.name)
                        .font(.scaleHeadline)
                        .foregroundColor(.scaleTextPrimary)

                    if let morph = animal.morph {
                        Text(morph)
                            .font(.scaleCaption)
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                    }
                }

                Spacer()

                // Status badge
                if let weight = animal.currentWeightGrams {
                    Text("\(Int(weight))g")
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }
            }
            .padding(ScaleSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: ScaleRadius.md)
                    .fill(isSelected ? themeManager.currentTheme.primaryAccent.opacity(0.1) : themeManager.currentTheme.cardBackground.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: ScaleRadius.md)
                            .stroke(isSelected ? themeManager.currentTheme.primaryAccent.opacity(0.5) : themeManager.currentTheme.borderColor, lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Batch Feeding Session View (Sequential Logging)

struct BatchFeedingSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @StateObject private var viewModel: BatchFeedingSessionViewModel
    let onComplete: () -> Void

    init(animals: [Animal], onComplete: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: BatchFeedingSessionViewModel(animals: animals))
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            ScaleBackground()

            if viewModel.isComplete {
                sessionSummary
            } else {
                feedingCard
            }
        }
    }

    // MARK: - Feeding Card

    private var feedingCard: some View {
        VStack(spacing: ScaleSpacing.xl) {
            // Progress header
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18))
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }

                Spacer()

                Text("\(viewModel.currentIndex + 1) of \(viewModel.animals.count)")
                    .font(.scaleHeadline)
                    .foregroundColor(.scaleTextPrimary)

                Spacer()

                // Skip button
                Button("Skip") {
                    viewModel.skipCurrent()
                }
                .font(.scaleButtonSmall)
                .foregroundColor(themeManager.currentTheme.textTertiary)
            }
            .padding(.horizontal, ScaleSpacing.lg)
            .padding(.top, ScaleSpacing.lg)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeManager.currentTheme.cardBackground)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeManager.currentTheme.primaryAccent)
                        .frame(width: geometry.size.width * viewModel.progress, height: 8)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, ScaleSpacing.lg)

            Spacer()

            // Animal info
            VStack(spacing: ScaleSpacing.md) {
                Circle()
                    .fill(themeManager.currentTheme.primaryAccent.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(themeManager.currentTheme.primaryAccent.opacity(0.5))
                    )

                Text(viewModel.currentAnimal.name)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.scaleTextPrimary)

                if let morph = viewModel.currentAnimal.morph {
                    Text(morph)
                        .font(.scaleSubheadline)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }

                // Last feeding info
                if let lastFeeding = viewModel.lastFeedingText {
                    Text("Last fed: \(lastFeeding)")
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                        .padding(.top, ScaleSpacing.sm)
                }
            }

            Spacer()

            // Large action buttons
            VStack(spacing: ScaleSpacing.md) {
                // ATE button (large, green)
                Button {
                    viewModel.logFeeding(response: .struckImmediately)
                } label: {
                    HStack(spacing: ScaleSpacing.md) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                        Text("ATE")
                            .font(.system(size: 24, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: ScaleRadius.lg)
                            .fill(Color.scaleSuccess)
                    )
                }

                HStack(spacing: ScaleSpacing.md) {
                    // REFUSED button
                    Button {
                        viewModel.logFeeding(response: .refused)
                    } label: {
                        HStack(spacing: ScaleSpacing.sm) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22))
                            Text("REFUSED")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: ScaleRadius.md)
                                .fill(Color.scaleError)
                        )
                    }

                    // RELUCTANT button
                    Button {
                        viewModel.logFeeding(response: .reluctant)
                    } label: {
                        HStack(spacing: ScaleSpacing.sm) {
                            Image(systemName: "circle.lefthalf.filled")
                                .font(.system(size: 22))
                            Text("RELUCTANT")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: ScaleRadius.md)
                                .fill(Color.heatLampAmber)
                        )
                    }
                }

                // Same as last button
                if viewModel.hasLastFeeding {
                    Button {
                        viewModel.logSameAsLast()
                    } label: {
                        HStack(spacing: ScaleSpacing.sm) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Same as Last (\(viewModel.lastPreyDescription))")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .padding(.vertical, ScaleSpacing.md)
                    }
                }
            }
            .padding(.horizontal, ScaleSpacing.lg)
            .padding(.bottom, ScaleSpacing.xxl)
        }
    }

    // MARK: - Session Summary

    private var sessionSummary: some View {
        VStack(spacing: ScaleSpacing.xl) {
            Spacer()

            // Success icon
            ZStack {
                Circle()
                    .fill(Color.scaleSuccess.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.scaleSuccess)
            }

            Text("Feeding Session Complete!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.scaleTextPrimary)

            // Stats
            HStack(spacing: ScaleSpacing.xxl) {
                StatBubble(
                    value: "\(viewModel.ateCount)",
                    label: "Ate",
                    color: .scaleSuccess
                )

                StatBubble(
                    value: "\(viewModel.refusedCount)",
                    label: "Refused",
                    color: .scaleError
                )

                StatBubble(
                    value: "\(viewModel.partialCount)",
                    label: "Reluctant",
                    color: .heatLampAmber
                )

                if viewModel.skippedCount > 0 {
                    StatBubble(
                        value: "\(viewModel.skippedCount)",
                        label: "Skipped",
                        color: .scaleMuted
                    )
                }
            }

            Spacer()

            // Done button
            Button {
                onComplete()
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: ScaleRadius.lg)
                            .fill(themeManager.currentTheme.primaryAccent)
                    )
            }
            .padding(.horizontal, ScaleSpacing.lg)
            .padding(.bottom, ScaleSpacing.xxl)
        }
    }
}

// MARK: - Stat Bubble

struct StatBubble: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: ScaleSpacing.xs) {
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(color)

            Text(label)
                .font(.scaleCaption)
                .foregroundColor(.scaleTextTertiary)
        }
    }
}

// MARK: - Batch Feeding View Model

@MainActor
@Observable
final class BatchFeedingViewModel: ObservableObject {
    private let feedingService = FeedingService.shared
    private let dataService = DataService.shared

    var allAnimals: [Animal] = []
    var selectedAnimals: Set<UUID> = []
    var filter: BatchFilter = .dueToday

    enum BatchFilter {
        case dueToday
        case overdue
        case all
    }

    var filteredAnimals: [Animal] {
        switch filter {
        case .dueToday:
            return feedingService.dueToday
        case .overdue:
            return feedingService.overdue
        case .all:
            return allAnimals
        }
    }

    var dueTodayCount: Int { feedingService.dueToday.count }
    var overdueCount: Int { feedingService.overdue.count }

    var animalsToFeed: [Animal] {
        allAnimals.filter { selectedAnimals.contains($0.id) }
    }

    func load() async {
        await feedingService.refresh()
        do {
            allAnimals = try dataService.fetchAllAnimals()
            // Pre-select due today animals
            selectedAnimals = Set(feedingService.dueToday.map { $0.id })
        } catch {
            print("Error loading animals: \(error)")
        }
    }

    func toggleSelection(_ animal: Animal) {
        if selectedAnimals.contains(animal.id) {
            selectedAnimals.remove(animal.id)
        } else {
            selectedAnimals.insert(animal.id)
        }
    }

    func toggleSelectAll() {
        if selectedAnimals.count == filteredAnimals.count {
            selectedAnimals.removeAll()
        } else {
            selectedAnimals = Set(filteredAnimals.map { $0.id })
        }
    }
}

// MARK: - Batch Feeding Session View Model

@MainActor
@Observable
final class BatchFeedingSessionViewModel: ObservableObject {
    private let feedingService = FeedingService.shared
    private let dataService = DataService.shared

    let animals: [Animal]
    var currentIndex = 0
    var results: [UUID: FeedingResponse] = [:]
    var skipped: Set<UUID> = []

    var isComplete: Bool { currentIndex >= animals.count }
    var progress: Double { Double(currentIndex) / Double(animals.count) }

    var currentAnimal: Animal { animals[currentIndex] }

    var ateCount: Int { results.values.filter { $0.isSuccessful }.count }
    var refusedCount: Int { results.values.filter { $0 == .refused }.count }
    var partialCount: Int { results.values.filter { $0 == .reluctant }.count }
    var skippedCount: Int { skipped.count }

    // Last feeding info
    var lastFeedingText: String? {
        guard let lastFeeding = try? dataService.lastFeeding(for: currentAnimal) else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastFeeding.feedingDate, relativeTo: Date())
    }

    var hasLastFeeding: Bool {
        (try? dataService.lastFeeding(for: currentAnimal)) != nil
    }

    var lastPreyDescription: String {
        guard let last = try? dataService.lastFeeding(for: currentAnimal) else { return "" }
        return "\(last.preySize.displayName) \(last.preyType.displayName)"
    }

    init(animals: [Animal]) {
        self.animals = animals
    }

    func logFeeding(response: FeedingResponse) {
        let animal = currentAnimal

        // Get last feeding defaults or use standard defaults
        let preyType: PreyType
        let preySize: PreySize
        let preyState: PreyState

        if let lastFeeding = try? dataService.lastFeeding(for: animal) {
            preyType = lastFeeding.preyType
            preySize = lastFeeding.preySize
            preyState = lastFeeding.preyState
        } else {
            preyType = .rat
            preySize = .small
            preyState = .frozenThawed
        }

        do {
            try feedingService.logFeeding(
                for: animal,
                preyType: preyType,
                preySize: preySize,
                preyState: preyState,
                quantity: 1,
                response: response
            )
            results[animal.id] = response
        } catch {
            print("Error logging feeding: \(error)")
        }

        advanceToNext()
    }

    func logSameAsLast() {
        guard let lastFeeding = try? dataService.lastFeeding(for: currentAnimal) else { return }

        do {
            try feedingService.logFeeding(
                for: currentAnimal,
                preyType: lastFeeding.preyType,
                preySize: lastFeeding.preySize,
                preyState: lastFeeding.preyState,
                quantity: lastFeeding.quantity,
                response: .struckImmediately
            )
            results[currentAnimal.id] = .struckImmediately
        } catch {
            print("Error logging feeding: \(error)")
        }

        advanceToNext()
    }

    func skipCurrent() {
        skipped.insert(currentAnimal.id)
        advanceToNext()
    }

    private func advanceToNext() {
        if currentIndex < animals.count - 1 {
            currentIndex += 1
        } else {
            currentIndex = animals.count // Mark as complete
        }
    }
}

// MARK: - Preview

#Preview {
    BatchFeedingView()
        .environmentObject(AppState())
}
