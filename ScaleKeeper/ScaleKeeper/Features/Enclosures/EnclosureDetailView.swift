import SwiftUI
import ScaleCore
import ScaleUI

// MARK: - Enclosure Detail View

struct EnclosureDetailView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var themeManager = ThemeManager.shared
    @StateObject private var viewModel: EnclosureDetailViewModel
    @State private var showingEditSheet = false
    @State private var showingCleaningSheet = false
    @State private var selectedCleaningType: CleaningType?

    init(enclosure: Enclosure) {
        _viewModel = StateObject(wrappedValue: EnclosureDetailViewModel(enclosure: enclosure))
    }

    var body: some View {
        ZStack {
            ScaleBackground()

            ScrollView {
                VStack(spacing: ScaleSpacing.lg) {
                    // Header Card
                    enclosureHeaderCard

                    // Environment Card
                    environmentCard

                    // Cleaning Status Card
                    cleaningStatusCard

                    // Cleaning History Card
                    if !viewModel.recentCleanings.isEmpty {
                        cleaningHistoryCard
                    }

                    // Animals in Enclosure
                    if !viewModel.animals.isEmpty {
                        animalsCard
                    }
                }
                .padding(ScaleSpacing.lg)
            }
        }
        .navigationTitle(viewModel.enclosure.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Enclosure", systemImage: "pencil")
                    }

                    Button {
                        showingCleaningSheet = true
                    } label: {
                        Label("Log Cleaning", systemImage: "sparkles")
                    }

                    Divider()

                    Button(role: .destructive) {
                        // Delete enclosure
                    } label: {
                        Label("Delete Enclosure", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.nebulaLavender)
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .sheet(isPresented: $showingEditSheet) {
            EditEnclosureView(enclosure: viewModel.enclosure) {
                Task { await viewModel.load() }
            }
        }
        .sheet(isPresented: $showingCleaningSheet) {
            LogCleaningView(enclosure: viewModel.enclosure) {
                Task { await viewModel.load() }
            }
        }
    }

    // MARK: - Header Card

    private var enclosureHeaderCard: some View {
        ScaleCard {
            VStack(spacing: ScaleSpacing.md) {
                // Icon and Type
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.nebulaPurple.opacity(0.15))
                            .frame(width: 60, height: 60)

                        Image(systemName: viewModel.enclosure.enclosureType.iconName)
                            .font(.system(size: 28))
                            .foregroundColor(.nebulaPurple)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.enclosure.enclosureType.displayName)
                            .font(.scaleTitle3)
                            .foregroundColor(.scaleTextPrimary)

                        if let location = viewModel.enclosure.location {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 10))
                                Text(location)
                                    .font(.scaleCaption)
                            }
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                        }
                    }

                    Spacer()

                    if viewModel.enclosure.isBioactive {
                        VStack(spacing: 4) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.nebulaCyan)
                            Text("Bioactive")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.nebulaCyan)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.nebulaCyan.opacity(0.15))
                        )
                    }
                }

                Divider()
                    .background(themeManager.currentTheme.borderColor)

                // Dimensions
                if let l = viewModel.enclosure.lengthInches,
                   let w = viewModel.enclosure.widthInches,
                   let h = viewModel.enclosure.heightInches {
                    HStack {
                        dimensionItem(label: "Length", value: "\(Int(l))\"")
                        dimensionItem(label: "Width", value: "\(Int(w))\"")
                        dimensionItem(label: "Height", value: "\(Int(h))\"")

                        if let gallons = viewModel.enclosure.volumeGallons {
                            dimensionItem(label: "Volume", value: "\(Int(gallons)) gal")
                        }
                    }
                }

                // Substrate
                if let substrate = viewModel.enclosure.substrateType {
                    HStack {
                        Image(systemName: "square.3.layers.3d.down.left")
                            .font(.system(size: 14))
                            .foregroundColor(.nebulaLavender)

                        Text("Substrate:")
                            .font(.scaleCaption)
                            .foregroundColor(themeManager.currentTheme.textSecondary)

                        Text(substrate.displayName)
                            .font(.scaleSubheadline)
                            .foregroundColor(.scaleTextPrimary)

                        Spacer()
                    }
                }
            }
        }
    }

    private func dimensionItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.scaleTextPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(themeManager.currentTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Environment Card

    private var environmentCard: some View {
        ScaleCard(
            header: .init(
                title: "Environment",
                subtitle: "Target conditions",
                icon: "thermometer",
                iconColor: .nebulaGold
            )
        ) {
            HStack(spacing: ScaleSpacing.lg) {
                // Temperature
                if let hotTemp = viewModel.enclosure.targetTempHotF {
                    environmentGauge(
                        icon: "thermometer.high",
                        label: "Hot Side",
                        value: "\(Int(hotTemp))°F",
                        color: .scaleError
                    )
                }

                if let coolTemp = viewModel.enclosure.targetTempCoolF {
                    environmentGauge(
                        icon: "thermometer.low",
                        label: "Cool Side",
                        value: "\(Int(coolTemp))°F",
                        color: .nebulaCyan
                    )
                }

                // Humidity
                if let humidity = viewModel.enclosure.targetHumidity {
                    environmentGauge(
                        icon: "humidity",
                        label: "Humidity",
                        value: "\(humidity)%",
                        color: .nebulaLavender
                    )
                }
            }

            // No targets set message
            if viewModel.enclosure.targetTempHotF == nil &&
               viewModel.enclosure.targetTempCoolF == nil &&
               viewModel.enclosure.targetHumidity == nil {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                    Text("No environment targets configured")
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }
                .padding(.vertical, ScaleSpacing.sm)
            }
        }
    }

    private func environmentGauge(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: ScaleSpacing.sm) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)

                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.scaleTextPrimary)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(themeManager.currentTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Cleaning Status Card

    private var cleaningStatusCard: some View {
        ScaleCard(
            header: .init(
                title: "Cleaning Schedule",
                subtitle: "\(viewModel.cleaningStatuses.count) tasks configured",
                icon: "sparkles",
                iconColor: .nebulaMagenta
            )
        ) {
            if viewModel.cleaningStatuses.isEmpty {
                VStack(spacing: ScaleSpacing.md) {
                    Text("No cleaning schedules set up")
                        .font(.scaleSubheadline)
                        .foregroundColor(themeManager.currentTheme.textSecondary)

                    Button {
                        Task {
                            await viewModel.setupDefaultSchedules()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("Setup Default Schedules")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.nebulaMagenta)
                        .padding(.horizontal, ScaleSpacing.md)
                        .padding(.vertical, ScaleSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: ScaleRadius.sm)
                                .fill(Color.nebulaMagenta.opacity(0.15))
                        )
                    }
                }
                .padding(.vertical, ScaleSpacing.md)
            } else {
                VStack(spacing: ScaleSpacing.sm) {
                    ForEach(viewModel.cleaningStatuses, id: \.cleaningType) { status in
                        CleaningStatusRow(status: status) {
                            selectedCleaningType = status.cleaningType
                            showingCleaningSheet = true
                        }
                    }
                }
            }
        }
    }

    // MARK: - Cleaning History Card

    private var cleaningHistoryCard: some View {
        ScaleCard(
            header: .init(
                title: "Recent Cleanings",
                subtitle: "Last \(viewModel.recentCleanings.count) events",
                icon: "clock.arrow.circlepath",
                iconColor: .nebulaLavender
            )
        ) {
            VStack(spacing: ScaleSpacing.sm) {
                ForEach(viewModel.recentCleanings, id: \.id) { event in
                    CleaningEventRow(event: event)
                }
            }
        }
    }

    // MARK: - Animals Card

    private var animalsCard: some View {
        ScaleCard(
            header: .init(
                title: "Animals",
                subtitle: "\(viewModel.animals.count) housed here",
                icon: "leaf.fill",
                iconColor: .nebulaCyan
            )
        ) {
            VStack(spacing: ScaleSpacing.sm) {
                ForEach(viewModel.animals, id: \.id) { animal in
                    HStack {
                        Text(animal.name)
                            .font(.scaleSubheadline)
                            .foregroundColor(.scaleTextPrimary)

                        if let morph = animal.morph {
                            Text(morph)
                                .font(.scaleCaption)
                                .foregroundColor(themeManager.currentTheme.textTertiary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                    }
                    .padding(.vertical, ScaleSpacing.xs)
                }
            }
        }
    }
}

// MARK: - Cleaning Status Row

struct CleaningStatusRow: View {
    let status: CleaningStatus
    let onLogCleaning: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        HStack {
            // Icon
            ZStack {
                Circle()
                    .fill(urgencyColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: status.cleaningType.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(urgencyColor)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(status.cleaningType.displayName)
                    .font(.scaleSubheadline)
                    .foregroundColor(.scaleTextPrimary)

                if let days = status.daysSinceLastClean {
                    Text("Last cleaned \(days) days ago")
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                } else {
                    Text("Never cleaned")
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }
            }

            Spacer()

            // Status & Action
            VStack(alignment: .trailing, spacing: 4) {
                statusBadge

                Button(action: onLogCleaning) {
                    Text("Log")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.nebulaMagenta)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.nebulaMagenta.opacity(0.15))
                        )
                }
            }
        }
        .padding(.vertical, ScaleSpacing.xs)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch status.urgency {
        case .overdue:
            Text("\(abs(status.daysUntilDue))d overdue")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.scaleError)
        case .dueSoon:
            Text("Due in \(status.daysUntilDue)d")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.nebulaGold)
        case .onTrack:
            Text("Due in \(status.daysUntilDue)d")
                .font(.system(size: 11))
                .foregroundColor(themeManager.currentTheme.textTertiary)
        }
    }

    private var urgencyColor: Color {
        switch status.urgency {
        case .onTrack: return .nebulaCyan
        case .dueSoon: return .nebulaGold
        case .overdue: return .scaleError
        }
    }
}

// MARK: - Cleaning Event Row

struct CleaningEventRow: View {
    let event: CleaningEvent
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        HStack {
            Image(systemName: event.cleaningType.iconName)
                .font(.system(size: 14))
                .foregroundColor(.nebulaLavender)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.cleaningType.displayName)
                    .font(.scaleCaption)
                    .foregroundColor(.scaleTextPrimary)

                Text(event.cleanedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 10))
                    .foregroundColor(themeManager.currentTheme.textTertiary)
            }

            Spacer()

            if let notes = event.notes, !notes.isEmpty {
                Image(systemName: "note.text")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.currentTheme.textTertiary)
            }
        }
        .padding(.vertical, ScaleSpacing.xs)
    }
}

// MARK: - Enclosure Detail View Model

@MainActor
@Observable
final class EnclosureDetailViewModel: ObservableObject {
    // MARK: - Dependencies
    private let dataService: DataService
    private let cleaningService: CleaningService

    // MARK: - State
    let enclosure: Enclosure
    var cleaningStatuses: [CleaningStatus] = []
    var recentCleanings: [CleaningEvent] = []
    var animals: [Animal] = []
    var isLoading = false
    var error: Error?

    // MARK: - Init
    init(
        enclosure: Enclosure,
        dataService: DataService = .shared,
        cleaningService: CleaningService = .shared
    ) {
        self.enclosure = enclosure
        self.dataService = dataService
        self.cleaningService = cleaningService
    }

    // MARK: - Load
    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            cleaningStatuses = try cleaningService.cleaningStatus(for: enclosure)
            recentCleanings = try cleaningService.cleaningHistory(for: enclosure, limit: 5)

            // TODO: Fetch animals assigned to this enclosure
            // This would require an enclosureID field on Animal
            animals = []
        } catch {
            self.error = error
        }
    }

    // MARK: - Setup Default Schedules
    func setupDefaultSchedules() async {
        do {
            try cleaningService.setupDefaultSchedules(for: enclosure)
            await load()
        } catch {
            self.error = error
        }
    }

    // MARK: - Log Cleaning
    func logCleaning(type: CleaningType, notes: String?) async {
        do {
            _ = try cleaningService.logCleaning(for: enclosure, type: type, notes: notes)
            await load()
        } catch {
            self.error = error
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EnclosureDetailView(enclosure: Enclosure(name: "Main Vivarium", enclosureType: .vivarium))
    }
    .environmentObject(AppState())
}
