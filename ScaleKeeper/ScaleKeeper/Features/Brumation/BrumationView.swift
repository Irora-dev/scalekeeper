import SwiftUI
import ScaleCore
import ScaleUI

// MARK: - Brumation View

struct BrumationView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = BrumationViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingNewCycle = false

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
                            // Active Cycles
                            if !viewModel.activeCycles.isEmpty {
                                activeCyclesSection
                            }

                            // Upcoming Cycles
                            if !viewModel.plannedCycles.isEmpty {
                                plannedCyclesSection
                            }

                            // Past Cycles
                            if !viewModel.completedCycles.isEmpty {
                                completedCyclesSection
                            }

                            // Empty State
                            if viewModel.isEmpty {
                                emptyState
                            }
                        }
                        .padding(ScaleSpacing.lg)
                    }
                }
            }
            .navigationTitle("Brumation")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewCycle = true
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
            .sheet(isPresented: $showingNewCycle) {
                NewBrumationCycleView {
                    Task { await viewModel.load() }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: ScaleSpacing.lg) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 60))
                .foregroundColor(themeManager.currentTheme.primaryAccent.opacity(0.5))
                .shadow(color: themeManager.currentTheme.primaryAccent.opacity(0.3), radius: 10)

            Text("No Brumation Cycles")
                .font(.scaleTitle2)
                .foregroundColor(.scaleTextPrimary)

            Text("Track brumation cycles for your breeding animals. Monitor temperatures, weight changes, and phase transitions.")
                .font(.scaleSubheadline)
                .foregroundColor(.scaleTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, ScaleSpacing.xxl)

            ScalePrimaryButton("Plan Brumation", icon: "plus") {
                showingNewCycle = true
            }
            .padding(.horizontal, ScaleSpacing.xxl)
        }
        .padding(.vertical, ScaleSpacing.xxxl)
    }

    // MARK: - Active Cycles Section

    private var activeCyclesSection: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.md) {
            Text("Active Cycles")
                .font(.scaleHeadline)
                .foregroundColor(.scaleTextPrimary)

            ForEach(viewModel.activeCycles, id: \.id) { cycle in
                NavigationLink {
                    BrumationDetailView(cycle: cycle) {
                        Task { await viewModel.load() }
                    }
                } label: {
                    ActiveBrumationCard(cycle: cycle)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: - Planned Cycles Section

    private var plannedCyclesSection: some View {
        ScaleCard(
            header: .init(
                title: "Planned",
                subtitle: "\(viewModel.plannedCycles.count) cycles",
                icon: "calendar",
                iconColor: .nebulaGold
            )
        ) {
            VStack(spacing: ScaleSpacing.sm) {
                ForEach(viewModel.plannedCycles, id: \.id) { cycle in
                    NavigationLink {
                        BrumationDetailView(cycle: cycle) {
                            Task { await viewModel.load() }
                        }
                    } label: {
                        BrumationCycleRow(cycle: cycle)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - Completed Cycles Section

    private var completedCyclesSection: some View {
        ScaleCard(
            header: .init(
                title: "History",
                subtitle: "\(viewModel.completedCycles.count) completed",
                icon: "clock.arrow.circlepath",
                iconColor: .scaleMuted
            )
        ) {
            VStack(spacing: ScaleSpacing.sm) {
                ForEach(viewModel.completedCycles.prefix(5), id: \.id) { cycle in
                    NavigationLink {
                        BrumationDetailView(cycle: cycle) {
                            Task { await viewModel.load() }
                        }
                    } label: {
                        CompletedBrumationRow(cycle: cycle)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Active Brumation Card

struct ActiveBrumationCard: View {
    let cycle: BrumationCycle

    var body: some View {
        ScaleCard {
            VStack(spacing: ScaleSpacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(cycle.animal?.name ?? "Unknown")
                            .font(.scaleHeadline)
                            .foregroundColor(.scaleTextPrimary)

                        Text(cycle.seasonName ?? "\(cycle.year)")
                            .font(.scaleCaption)
                            .foregroundColor(.scaleTextTertiary)
                    }

                    Spacer()

                    // Phase Badge
                    if let phase = cycle.currentPhase {
                        HStack(spacing: 4) {
                            Image(systemName: phaseIcon(phase))
                                .font(.system(size: 12))
                            Text(phase.displayName)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(phaseColor(phase))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(phaseColor(phase).opacity(0.15))
                        )
                    }
                }

                // Phase Progress
                PhaseProgressView(cycle: cycle)

                // Stats
                HStack(spacing: ScaleSpacing.lg) {
                    if let days = cycle.daysInCurrentPhase {
                        VStack(spacing: 2) {
                            Text("\(days)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(ThemeManager.shared.currentTheme.primaryAccent)
                            Text("days in phase")
                                .font(.scaleCaption2)
                                .foregroundColor(.scaleTextTertiary)
                        }
                    }

                    if let daysUntil = cycle.daysUntilNextPhase, daysUntil > 0 {
                        VStack(spacing: 2) {
                            Text("\(daysUntil)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.nebulaGold)
                            Text("days until next")
                                .font(.scaleCaption2)
                                .foregroundColor(.scaleTextTertiary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.scaleTextTertiary)
                }
            }
        }
    }

    private func phaseIcon(_ phase: BrumationPhase) -> String {
        switch phase {
        case .planned: return "calendar"
        case .cooldown: return "thermometer.snowflake"
        case .active: return "moon.zzz.fill"
        case .warmup: return "thermometer.sun.fill"
        case .complete: return "checkmark.circle.fill"
        }
    }

    private func phaseColor(_ phase: BrumationPhase) -> Color {
        switch phase {
        case .planned: return .nebulaGold
        case .cooldown: return .nebulaCyan
        case .active: return .nebulaLavender
        case .warmup: return .shedPink
        case .complete: return .scaleSuccess
        }
    }
}

// MARK: - Phase Progress View

struct PhaseProgressView: View {
    let cycle: BrumationCycle

    private let phases: [BrumationPhase] = [.cooldown, .active, .warmup, .complete]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(phases, id: \.self) { phase in
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(backgroundColor(for: phase))
                        .frame(height: 8)

                    if isCurrentPhase(phase), let progress = progressInPhase(phase) {
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(foregroundColor(for: phase))
                                .frame(width: geo.size.width * progress)
                        }
                        .frame(height: 8)
                    } else if isPastPhase(phase) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(foregroundColor(for: phase))
                            .frame(height: 8)
                    }
                }
            }
        }
    }

    private func isCurrentPhase(_ phase: BrumationPhase) -> Bool {
        cycle.currentPhase == phase
    }

    private func isPastPhase(_ phase: BrumationPhase) -> Bool {
        guard let currentPhase = cycle.currentPhase,
              let currentIndex = phases.firstIndex(of: currentPhase),
              let phaseIndex = phases.firstIndex(of: phase) else { return false }
        return phaseIndex < currentIndex
    }

    private func progressInPhase(_ phase: BrumationPhase) -> Double? {
        guard let days = cycle.daysInCurrentPhase else { return nil }
        let estimatedDuration: Int
        switch phase {
        case .cooldown: estimatedDuration = 14
        case .active: estimatedDuration = 60
        case .warmup: estimatedDuration = 14
        default: return nil
        }
        return min(Double(days) / Double(estimatedDuration), 1.0)
    }

    private func backgroundColor(for phase: BrumationPhase) -> Color {
        foregroundColor(for: phase).opacity(0.2)
    }

    private func foregroundColor(for phase: BrumationPhase) -> Color {
        switch phase {
        case .cooldown: return .nebulaCyan
        case .active: return .nebulaLavender
        case .warmup: return .shedPink
        case .complete: return .scaleSuccess
        default: return .scaleMuted
        }
    }
}

// MARK: - Brumation Cycle Row

struct BrumationCycleRow: View {
    let cycle: BrumationCycle

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.nebulaGold.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "calendar")
                    .font(.system(size: 18))
                    .foregroundColor(.nebulaGold)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(cycle.animal?.name ?? "Unknown")
                    .font(.scaleSubheadline)
                    .foregroundColor(.scaleTextPrimary)

                if let cooldown = cycle.cooldownStartDate {
                    Text("Starts \(cooldown.formatted(date: .abbreviated, time: .omitted))")
                        .font(.scaleCaption)
                        .foregroundColor(.scaleTextTertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.scaleTextTertiary)
        }
        .padding(.vertical, ScaleSpacing.xs)
    }
}

// MARK: - Completed Brumation Row

struct CompletedBrumationRow: View {
    let cycle: BrumationCycle

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.scaleSuccess.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.scaleSuccess)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(cycle.animal?.name ?? "Unknown")
                    .font(.scaleSubheadline)
                    .foregroundColor(.scaleTextPrimary)

                HStack(spacing: ScaleSpacing.md) {
                    Text(cycle.seasonName ?? "\(cycle.year)")
                        .font(.scaleCaption)
                        .foregroundColor(.scaleTextTertiary)

                    if let totalDays = cycle.totalBrumationDays {
                        Text("\(totalDays) days")
                            .font(.scaleCaption)
                            .foregroundColor(.scaleTextTertiary)
                    }

                    if let change = cycle.weightChangePercentage {
                        Text(String(format: "%+.1f%%", change))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(change >= 0 ? .scaleSuccess : .scaleWarning)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.scaleTextTertiary)
        }
        .padding(.vertical, ScaleSpacing.xs)
    }
}

// MARK: - Brumation View Model

@MainActor
@Observable
final class BrumationViewModel: ObservableObject {
    private let dataService: DataService

    var allCycles: [BrumationCycle] = []
    var isLoading = false
    var error: Error?

    var activeCycles: [BrumationCycle] {
        allCycles.filter { cycle in
            guard let phase = cycle.currentPhase else { return false }
            return phase == .cooldown || phase == .active || phase == .warmup
        }
    }

    var plannedCycles: [BrumationCycle] {
        allCycles.filter { $0.status == .planned && $0.currentPhase == .planned }
    }

    var completedCycles: [BrumationCycle] {
        allCycles.filter { $0.status == .complete || $0.status == .cancelled }
    }

    var isEmpty: Bool {
        allCycles.isEmpty
    }

    init(dataService: DataService = .shared) {
        self.dataService = dataService
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            allCycles = try dataService.fetchBrumationCycles()
        } catch {
            self.error = error
        }
    }
}

// MARK: - Preview

#Preview {
    BrumationView()
        .environmentObject(AppState())
}
