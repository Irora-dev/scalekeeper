import SwiftUI
import ScaleCore
import ScaleUI

// MARK: - Collection View

struct CollectionView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = CollectionViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.primaryAccent))
                } else if viewModel.animals.isEmpty {
                    emptyState
                } else {
                    animalList
                }
            }
            .navigationTitle("Collection")
            .searchable(text: $searchText, prompt: "Search animals...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        appState.presentSheet(.addAnimal)
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(themeManager.currentTheme.primaryAccent)
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button("All Animals") {
                            viewModel.filterStatus = nil
                        }
                        Divider()
                        ForEach(AnimalStatus.allCases, id: \.self) { status in
                            Button(status.displayName) {
                                viewModel.filterStatus = status
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }
                }
            }
            .task {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load()
            }
            .onChange(of: searchText) { _, newValue in
                viewModel.searchQuery = newValue
            }
            .onChange(of: appState.dataRefreshTrigger) { _, _ in
                Task {
                    await viewModel.load()
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: ScaleSpacing.lg) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 60))
                .foregroundColor(themeManager.currentTheme.primaryAccent.opacity(0.5))

            Text("No Animals Yet")
                .font(.scaleTitle2)
                .foregroundColor(.scaleTextPrimary)

            Text("Add your first animal to start tracking their care.")
                .font(.scaleSubheadline)
                .foregroundColor(themeManager.currentTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, ScaleSpacing.xxl)

            ScalePrimaryButton("Add Animal", icon: "plus") {
                appState.presentSheet(.addAnimal)
            }
            .padding(.horizontal, ScaleSpacing.xxl)
        }
    }

    // MARK: - Animal List

    private var animalList: some View {
        List {
            // Quick Action Button
            Section {
                Button {
                    appState.presentSheet(.addAnimal)
                } label: {
                    VStack(spacing: ScaleSpacing.xs) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                        Text("Add Animal")
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundColor(themeManager.currentTheme.primaryAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: ScaleRadius.md)
                        .fill(themeManager.currentTheme.primaryAccent.opacity(0.1))
                )
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 24, trailing: 16))

            // Animal Cards with Swipe Actions
            Section {
                ForEach(viewModel.filteredAnimals, id: \.id) { animal in
                    AnimalCardWithSwipe(
                        animal: animal,
                        statusText: feedingStatusText(for: animal),
                        statusColor: feedingStatusColor(for: animal)
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .listSectionSpacing(24)
    }

    // MARK: - Helpers

    private func feedingStatusText(for animal: Animal) -> String {
        // TODO: Implement proper feeding status lookup
        return animal.status.displayName
    }

    private func feedingStatusColor(for animal: Animal) -> Color {
        switch animal.status {
        case .active:
            return .scaleSuccess
        case .breedingHold:
            return .shedPink
        case .forSale:
            return .heatLampAmber
        case .sold:
            return .scaleMuted
        case .deceased:
            return themeManager.currentTheme.textTertiary
        case .quarantine:
            return .scaleWarning
        }
    }
}

// MARK: - Collection View Model

@MainActor
@Observable
final class CollectionViewModel: ObservableObject {
    // MARK: - Dependencies
    private let dataService: DataService

    // MARK: - State
    var animals: [Animal] = []
    var searchQuery = ""
    var filterStatus: AnimalStatus?
    var isLoading = false
    var error: Error?

    // MARK: - Computed
    var filteredAnimals: [Animal] {
        var result = animals

        if let status = filterStatus {
            result = result.filter { $0.status == status }
        }

        if !searchQuery.isEmpty {
            result = result.filter { animal in
                animal.name.localizedCaseInsensitiveContains(searchQuery) ||
                (animal.morph?.localizedCaseInsensitiveContains(searchQuery) ?? false)
            }
        }

        return result
    }

    // MARK: - Init
    init(dataService: DataService = .shared) {
        self.dataService = dataService
    }

    // MARK: - Load
    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            animals = try dataService.fetchAllAnimals()
        } catch {
            self.error = error
        }
    }
}

// MARK: - Animal Card with Swipe Actions

struct AnimalCardWithSwipe: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var themeManager = ThemeManager.shared
    let animal: Animal
    let statusText: String
    let statusColor: Color

    // Timer for live countdown
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationLink {
            AnimalDetailView(animal: animal)
        } label: {
            enhancedCardView
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                appState.presentSheet(.quickFeed(animalID: animal.id))
            } label: {
                Label("Feed", systemImage: "fork.knife")
            }
            .tint(.heatLampAmber)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                appState.presentSheet(.addWeight(animalID: animal.id))
            } label: {
                Label("Weight", systemImage: "scalemass")
            }
            .tint(.nebulaCyan)

            Button {
                appState.presentSheet(.logFeeding(animalID: animal.id))
            } label: {
                Label("Log", systemImage: "list.bullet.clipboard")
            }
            .tint(.nebulaPurple)
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }

    // MARK: - Enhanced Card View

    private var enhancedCardView: some View {
        VStack(spacing: 0) {
            // Main card content
            HStack(spacing: ScaleSpacing.md) {
                // Photo placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: ScaleRadius.md)
                        .fill(themeManager.currentTheme.primaryAccent.opacity(0.15))
                    Image(systemName: "lizard.fill")
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.currentTheme.primaryAccent)
                }
                .frame(width: 60, height: 60)

                // Info section
                VStack(alignment: .leading, spacing: ScaleSpacing.xs) {
                    Text(animal.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.scaleTextPrimary)

                    if let morph = animal.morph {
                        Text(morph)
                            .font(.scaleSubheadline)
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }

                    // Status indicator
                    HStack(spacing: ScaleSpacing.xs) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 6, height: 6)
                        Text(statusText)
                            .font(.scaleCaption)
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                    }
                }

                Spacer()

                // Chevron to indicate tappable
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.primaryAccent)
            }
            .padding(ScaleSpacing.md)

            // Stats row (weight, length, next feed)
            HStack(spacing: ScaleSpacing.sm) {
                // Weight
                statPill(
                    icon: "scalemass",
                    value: currentWeight,
                    color: .nebulaCyan
                )

                // Length
                statPill(
                    icon: "ruler",
                    value: currentLength,
                    color: .nebulaPurple
                )

                Spacer()

                // Next feed countdown
                feedCountdownPill
            }
            .padding(.horizontal, ScaleSpacing.md)
            .padding(.bottom, ScaleSpacing.md)
        }
        .background(
            RoundedRectangle(cornerRadius: ScaleRadius.lg)
                .fill(themeManager.currentTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: ScaleRadius.lg)
                        .stroke(themeManager.currentTheme.primaryAccent.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - Stat Pill

    private func statPill(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.scaleTextPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.1))
        )
    }

    // MARK: - Feed Countdown Pill

    private var feedCountdownPill: some View {
        HStack(spacing: 4) {
            Image(systemName: countdownIcon)
                .font(.system(size: 10))
                .foregroundColor(countdownColor)
            Text(countdownText)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(countdownColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(countdownColor.opacity(0.15))
        )
    }

    // MARK: - Computed Properties

    private var currentWeight: String {
        // First check the cached current weight
        if let weight = animal.currentWeightGrams, weight > 0 {
            return String(format: "%.0fg", weight)
        }
        // Fallback to weight records
        if let weights = animal.weights?.sorted(by: { $0.recordedAt > $1.recordedAt }),
           let latest = weights.first {
            return String(format: "%.0fg", latest.weightGrams)
        }
        return "—"
    }

    private var currentLength: String {
        // No length records on Animal model, show placeholder
        // TODO: Add length records relationship to Animal model
        return "—"
    }

    private var nextFeedDate: Date? {
        // Estimate based on last feeding + 7 day default interval
        if let feedings = animal.feedings?.sorted(by: { $0.feedingDate > $1.feedingDate }),
           let lastFeeding = feedings.first {
            return Calendar.current.date(byAdding: .day, value: 7, to: lastFeeding.feedingDate)
        }
        return nil
    }

    private var countdownText: String {
        guard let nextFeed = nextFeedDate else {
            return "No schedule"
        }

        let now = currentTime
        let interval = nextFeed.timeIntervalSince(now)

        if interval < 0 {
            // Overdue
            let overdueDays = Int(abs(interval) / 86400)
            if overdueDays == 0 {
                let hours = Int(abs(interval) / 3600)
                return "\(hours)h overdue"
            }
            return "\(overdueDays)d overdue"
        } else if interval < 3600 {
            // Less than 1 hour
            let minutes = Int(interval / 60)
            return "\(minutes)m"
        } else if interval < 86400 {
            // Less than 1 day
            let hours = Int(interval / 3600)
            return "\(hours)h"
        } else {
            // Days
            let days = Int(interval / 86400)
            let hours = Int((interval.truncatingRemainder(dividingBy: 86400)) / 3600)
            if days == 0 {
                return "\(hours)h"
            } else if hours > 0 && days < 3 {
                return "\(days)d \(hours)h"
            }
            return "\(days)d"
        }
    }

    private var countdownColor: Color {
        guard let nextFeed = nextFeedDate else {
            return themeManager.currentTheme.textTertiary
        }

        let interval = nextFeed.timeIntervalSince(currentTime)

        if interval < 0 {
            return .scaleError // Overdue
        } else if interval < 86400 {
            return .heatLampAmber // Due today
        } else if interval < 172800 {
            return .nebulaGold // Due tomorrow
        } else {
            return .scaleSuccess // On track
        }
    }

    private var countdownIcon: String {
        guard let nextFeed = nextFeedDate else {
            return "calendar.badge.clock"
        }

        let interval = nextFeed.timeIntervalSince(currentTime)

        if interval < 0 {
            return "exclamationmark.triangle.fill"
        } else if interval < 86400 {
            return "fork.knife"
        } else {
            return "clock"
        }
    }
}

// MARK: - Preview

#Preview {
    CollectionView()
        .environmentObject(AppState())
}
