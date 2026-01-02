import SwiftUI
import ScaleCore
import ScaleUI

// MARK: - Animal Detail View

struct AnimalDetailView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: AnimalDetailViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedTab = 0

    init(animal: Animal) {
        _viewModel = StateObject(wrappedValue: AnimalDetailViewModel(animal: animal))
    }

    var body: some View {
        ZStack {
            ScaleBackground()

            ScrollView {
                VStack(spacing: ScaleSpacing.lg) {
                    // Header with photo and basic info
                    headerSection

                    // Tab selector
                    tabSelector

                    // Tab content
                    tabContent
                }
                .padding(ScaleSpacing.lg)
            }
        }
        .navigationTitle(viewModel.animal.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        appState.presentSheet(.editAnimal(animalID: viewModel.animal.id))
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button {
                        appState.presentSheet(.logFeeding(animalID: viewModel.animal.id))
                    } label: {
                        Label("Log Feeding", systemImage: "fork.knife")
                    }

                    Button {
                        appState.presentSheet(.addWeight(animalID: viewModel.animal.id))
                    } label: {
                        Label("Log Weight", systemImage: "scalemass")
                    }

                    Button {
                        appState.presentSheet(.addLength(animalID: viewModel.animal.id))
                    } label: {
                        Label("Log Length", systemImage: "ruler")
                    }

                    Button {
                        appState.presentSheet(.addHealthNote(animalID: viewModel.animal.id))
                    } label: {
                        Label("Add Health Note", systemImage: "cross.case")
                    }

                    Divider()

                    Button(role: .destructive) {
                        // Archive animal
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: ScaleSpacing.lg) {
            // Photo
            Circle()
                .fill(themeManager.currentTheme.primaryAccent.opacity(0.2))
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(themeManager.currentTheme.primaryAccent.opacity(0.5))
                )

            // Basic info
            VStack(spacing: ScaleSpacing.xs) {
                Text(viewModel.animal.name)
                    .font(.scaleTitle2)
                    .foregroundColor(.scaleTextPrimary)

                if let morph = viewModel.animal.morph {
                    Text(morph)
                        .font(.scaleSubheadline)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }

                HStack(spacing: ScaleSpacing.md) {
                    // Sex
                    Label(viewModel.animal.sex.displayName, systemImage: "person.fill")
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textTertiary)

                    // Age
                    if let age = viewModel.animal.ageDescription {
                        Label(age, systemImage: "calendar")
                            .font(.scaleCaption)
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                    }

                    // Weight
                    if let weight = viewModel.animal.currentWeightGrams {
                        Label("\(Int(weight))g", systemImage: "scalemass")
                            .font(.scaleCaption)
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                    }
                }
            }

            // Quick actions
            HStack(spacing: ScaleSpacing.md) {
                QuickActionButton(title: "Feed", icon: "fork.knife", color: .heatLampAmber) {
                    appState.presentSheet(.logFeeding(animalID: viewModel.animal.id))
                }

                QuickActionButton(title: "Weight", icon: "scalemass", color: .scaleTeal) {
                    appState.presentSheet(.addWeight(animalID: viewModel.animal.id))
                }

                QuickActionButton(title: "Photo", icon: "camera", color: .shedPink) {
                    // Add photo
                }
            }
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(Array(DetailTab.allCases.enumerated()), id: \.element) { index, tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: ScaleSpacing.xs) {
                        Text(tab.title)
                            .font(.scaleCaption)
                            .foregroundColor(selectedTab == index ? themeManager.currentTheme.primaryAccent : .scaleTextTertiary)

                        Rectangle()
                            .fill(selectedTab == index ? themeManager.currentTheme.primaryAccent : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch DetailTab.allCases[selectedTab] {
        case .overview:
            overviewTab
        case .feeding:
            feedingTab
        case .health:
            healthTab
        case .photos:
            photosTab
        }
    }

    // MARK: - Overview Tab

    private var overviewTab: some View {
        VStack(spacing: ScaleSpacing.lg) {
            // Stats
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: ScaleSpacing.md) {
                ScaleStatCard(
                    title: "Total Feedings",
                    value: "\(viewModel.totalFeedings)",
                    icon: "fork.knife"
                )

                ScaleStatCard(
                    title: "Feeding Rate",
                    value: "\(viewModel.feedingSuccessRate)%",
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .scaleSuccess
                )
            }

            // Recent Activity
            ScaleCard(header: .init(title: "Recent Activity", icon: "clock")) {
                if viewModel.recentFeedings.isEmpty {
                    Text("No activity yet")
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ScaleSpacing.lg)
                } else {
                    VStack(spacing: ScaleSpacing.sm) {
                        ForEach(viewModel.recentFeedings.prefix(3), id: \.id) { feeding in
                            HStack {
                                Circle()
                                    .fill(feeding.feedingResponse.isSuccessful ? Color.scaleSuccess.opacity(0.2) : Color.scaleWarning.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: feeding.feedingResponse.iconName)
                                            .font(.system(size: 14))
                                            .foregroundColor(feeding.feedingResponse.isSuccessful ? .scaleSuccess : .scaleWarning)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(feeding.preySize.displayName) \(feeding.preyType.displayName)")
                                        .font(.scaleCaption)
                                        .foregroundColor(.scaleTextPrimary)

                                    Text(feeding.feedingDate, style: .relative)
                                        .font(.scaleCaption2)
                                        .foregroundColor(themeManager.currentTheme.textTertiary)
                                }

                                Spacer()
                            }
                        }
                    }
                }
            }

            // Growth & Biometrics link
            NavigationLink {
                BiometricsView(animal: viewModel.animal)
            } label: {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.nebulaCyan.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 20))
                            .foregroundColor(.nebulaCyan)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Growth & Biometrics")
                            .font(.scaleSubheadline)
                            .foregroundColor(.scaleTextPrimary)

                        Text("Track weight, length & body condition")
                            .font(.scaleCaption)
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }
                .padding(ScaleSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: ScaleRadius.md)
                        .fill(themeManager.currentTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: ScaleRadius.md)
                                .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Feeding Tab

    private var feedingTab: some View {
        VStack(spacing: ScaleSpacing.lg) {
            // Feeding history
            ScaleCard(header: .init(title: "Feeding History", subtitle: "Long press for options", icon: "list.bullet")) {
                if viewModel.recentFeedings.isEmpty {
                    Text("No feedings recorded")
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ScaleSpacing.lg)
                } else {
                    VStack(spacing: ScaleSpacing.sm) {
                        ForEach(viewModel.recentFeedings, id: \.id) { feeding in
                            FeedingHistoryRow(feeding: feeding) {
                                appState.presentSheet(.markRegurgitation(feedingID: feeding.id))
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Health Tab

    private var healthTab: some View {
        VStack(spacing: ScaleSpacing.lg) {
            // Biometrics summary with link to full view
            NavigationLink {
                BiometricsView(animal: viewModel.animal)
            } label: {
                ScaleCard {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.nebulaCyan.opacity(0.15))
                                .frame(width: 48, height: 48)

                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 22))
                                .foregroundColor(.nebulaCyan)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Growth & Biometrics")
                                .font(.scaleHeadline)
                                .foregroundColor(.scaleTextPrimary)

                            Text("Track weight, length & body condition")
                                .font(.scaleCaption)
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Quick Stats
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: ScaleSpacing.md) {
                ScaleStatCard(
                    title: "Current Weight",
                    value: viewModel.currentWeightText,
                    icon: "scalemass",
                    iconColor: .nebulaCyan
                )

                ScaleStatCard(
                    title: "Current Length",
                    value: viewModel.currentLengthText,
                    icon: "ruler",
                    iconColor: themeManager.currentTheme.primaryAccent
                )
            }

            // Recent Weights
            ScaleCard(header: .init(title: "Recent Weights", icon: "scalemass", iconColor: .nebulaCyan)) {
                if viewModel.recentWeights.isEmpty {
                    Text("No weight records")
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ScaleSpacing.lg)
                } else {
                    VStack(spacing: ScaleSpacing.sm) {
                        ForEach(viewModel.recentWeights.prefix(5), id: \.id) { weight in
                            HStack {
                                Text(weight.formattedWeight)
                                    .font(.scaleSubheadline)
                                    .foregroundColor(.scaleTextPrimary)

                                Spacer()

                                Text(weight.recordedAt, style: .date)
                                    .font(.scaleCaption)
                                    .foregroundColor(themeManager.currentTheme.textTertiary)
                            }
                            .padding(.vertical, ScaleSpacing.xs)
                        }
                    }
                }
            }

            // Health notes
            ScaleCard(header: .init(title: "Health Notes", icon: "cross.case")) {
                Text("No health notes")
                    .font(.scaleCaption)
                    .foregroundColor(themeManager.currentTheme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ScaleSpacing.lg)
            }
        }
    }

    // MARK: - Photos Tab

    private var photosTab: some View {
        VStack(spacing: ScaleSpacing.lg) {
            ScaleCard(header: .init(title: "Photo Gallery", icon: "photo.on.rectangle")) {
                Text("No photos yet")
                    .font(.scaleCaption)
                    .foregroundColor(themeManager.currentTheme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ScaleSpacing.xxxl)
            }
        }
    }
}

// MARK: - Detail Tab

enum DetailTab: CaseIterable {
    case overview
    case feeding
    case health
    case photos

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .feeding: return "Feeding"
        case .health: return "Health"
        case .photos: return "Photos"
        }
    }
}

// MARK: - Feeding History Row

struct FeedingHistoryRow: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let feeding: FeedingEvent
    let onMarkRegurgitation: () -> Void

    init(feeding: FeedingEvent, onMarkRegurgitation: @escaping () -> Void = {}) {
        self.feeding = feeding
        self.onMarkRegurgitation = onMarkRegurgitation
    }

    var body: some View {
        HStack {
            // Regurgitation indicator
            if feeding.feedingResponse == .regurgitated {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.scaleError)
                    .font(.system(size: 12))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(feeding.quantity)x \(feeding.preySize.displayName) \(feeding.preyType.displayName)")
                    .font(.scaleSubheadline)
                    .foregroundColor(.scaleTextPrimary)

                HStack(spacing: 4) {
                    Text(feeding.feedingResponse.displayName)
                        .foregroundColor(feeding.feedingResponse == .regurgitated ? .scaleError : themeManager.currentTheme.textTertiary)
                    Text("•")
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                    Text(feeding.preyState.displayName)
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }
                .font(.scaleCaption)

                // Show regurgitation date if applicable
                if let regurgDate = feeding.regurgitationDate {
                    Text("Regurgitated: \(regurgDate, style: .date)")
                        .font(.system(size: 10))
                        .foregroundColor(.scaleError.opacity(0.8))
                }
            }

            Spacer()

            Text(feeding.feedingDate, style: .date)
                .font(.scaleCaption)
                .foregroundColor(themeManager.currentTheme.textTertiary)
        }
        .padding(.vertical, ScaleSpacing.xs)
        .contentShape(Rectangle())
        .contextMenu {
            // Only show mark regurgitation option if not already regurgitated
            if feeding.feedingResponse != .regurgitated && feeding.feedingResponse != .refused {
                Button {
                    onMarkRegurgitation()
                } label: {
                    Label("Mark as Regurgitated", systemImage: "exclamationmark.triangle")
                }
            }

            if feeding.feedingResponse == .regurgitated {
                Button(role: .destructive) {
                    // Could add undo functionality here
                } label: {
                    Label("View Regurgitation Details", systemImage: "info.circle")
                }
            }
        }
    }
}

// MARK: - Animal Detail View Model

@MainActor
@Observable
final class AnimalDetailViewModel: ObservableObject {
    let animal: Animal
    private let dataService: DataService
    private let biometricsService: BiometricsService

    var recentFeedings: [FeedingEvent] = []
    var totalFeedings: Int = 0
    var feedingSuccessRate: Int = 0

    // Biometrics
    var recentWeights: [WeightRecord] = []
    var recentLengths: [LengthRecord] = []

    var currentWeightText: String {
        if let weight = recentWeights.first {
            return weight.formattedWeight
        }
        return "--"
    }

    var currentLengthText: String {
        if let length = recentLengths.first {
            return length.formattedLength
        }
        return "--"
    }

    init(animal: Animal, dataService: DataService = .shared, biometricsService: BiometricsService = .shared) {
        self.animal = animal
        self.dataService = dataService
        self.biometricsService = biometricsService

        Task {
            await load()
        }
    }

    func load() async {
        do {
            // Feedings
            recentFeedings = try dataService.fetchFeedings(for: animal, limit: 10)
            totalFeedings = recentFeedings.count

            let successful = recentFeedings.filter { $0.feedingResponse.isSuccessful }.count
            feedingSuccessRate = totalFeedings > 0 ? (successful * 100 / totalFeedings) : 0

            // Biometrics
            recentWeights = try dataService.fetchWeights(for: animal)
            recentLengths = try biometricsService.lengthHistory(for: animal)
        } catch {
            print("Failed to load animal detail: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AnimalDetailView(animal: Animal(name: "Monty", speciesID: UUID()))
    }
    .environmentObject(AppState())
}
