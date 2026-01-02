import SwiftUI
import ScaleCore
import ScaleUI

// MARK: - New Brumation Cycle View

struct NewBrumationCycleView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NewBrumationCycleViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                ScrollView {
                    VStack(spacing: ScaleSpacing.lg) {
                        // Animal Selection
                        animalSelectionSection

                        // Season Info
                        seasonSection

                        // Phase Dates
                        phaseDatesSection

                        // Temperature Targets
                        temperatureSection

                        // Pre-Brumation Data
                        preBrumationSection

                        // Notes
                        notesSection
                    }
                    .padding(ScaleSpacing.lg)
                }
            }
            .navigationTitle("Plan Brumation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.save()
                            onSave()
                            dismiss()
                        }
                    }
                    .foregroundColor(.nebulaLavender)
                    .disabled(!viewModel.canSave)
                }
            }
            .task {
                await viewModel.loadAnimals()
            }
        }
    }

    // MARK: - Animal Selection Section

    private var animalSelectionSection: some View {
        ScaleCard(header: .init(title: "Select Animal", icon: "leaf.fill", iconColor: .terrariumGreen)) {
            VStack(spacing: ScaleSpacing.sm) {
                if viewModel.availableAnimals.isEmpty {
                    Text("No animals available")
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ScaleSpacing.lg)
                } else {
                    ForEach(viewModel.availableAnimals, id: \.id) { animal in
                        Button {
                            viewModel.selectedAnimal = animal
                        } label: {
                            HStack {
                                Circle()
                                    .fill(Color.terrariumGreen.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "leaf.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.terrariumGreen)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(animal.name)
                                        .font(.scaleSubheadline)
                                        .foregroundColor(.scaleTextPrimary)

                                    if let morph = animal.morph {
                                        Text(morph)
                                            .font(.scaleCaption)
                                            .foregroundColor(themeManager.currentTheme.textTertiary)
                                    }
                                }

                                Spacer()

                                if viewModel.selectedAnimal?.id == animal.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.nebulaLavender)
                                }
                            }
                            .padding(.vertical, ScaleSpacing.xs)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Season Section

    private var seasonSection: some View {
        ScaleCard(header: .init(title: "Season", icon: "calendar", iconColor: .nebulaGold)) {
            VStack(spacing: ScaleSpacing.md) {
                HStack {
                    Text("Year")
                        .font(.scaleSubheadline)
                        .foregroundColor(themeManager.currentTheme.textSecondary)

                    Spacer()

                    Picker("Year", selection: $viewModel.year) {
                        ForEach(viewModel.availableYears, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.nebulaLavender)
                }

                TextField("Season Name (e.g., 2024-2025 Winter)", text: $viewModel.seasonName)
                    .font(.scaleSubheadline)
                    .foregroundColor(.scaleTextPrimary)
                    .textFieldStyle(.plain)
                    .padding(ScaleSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: ScaleRadius.sm)
                            .fill(Color.cosmicDeep)
                    )
            }
        }
    }

    // MARK: - Phase Dates Section

    private var phaseDatesSection: some View {
        ScaleCard(header: .init(title: "Phase Schedule", icon: "clock.fill", iconColor: .nebulaLavender)) {
            VStack(spacing: ScaleSpacing.md) {
                // Cooldown Start
                DateRow(
                    title: "Cooldown Starts",
                    date: $viewModel.cooldownStartDate,
                    phase: .cooldown
                )

                Divider()
                    .background(themeManager.currentTheme.borderColor)

                // Full Brumation Start
                DateRow(
                    title: "Full Brumation Starts",
                    date: $viewModel.fullBrumationStartDate,
                    phase: .active
                )

                Divider()
                    .background(themeManager.currentTheme.borderColor)

                // Warmup Start
                DateRow(
                    title: "Warmup Starts",
                    date: $viewModel.warmupStartDate,
                    phase: .warmup
                )

                Divider()
                    .background(themeManager.currentTheme.borderColor)

                // End Date
                DateRow(
                    title: "Brumation Ends",
                    date: $viewModel.brumationEndDate,
                    phase: .complete
                )
            }
        }
    }

    // MARK: - Temperature Section

    private var temperatureSection: some View {
        ScaleCard(header: .init(title: "Temperature Targets", icon: "thermometer", iconColor: .nebulaCyan)) {
            VStack(spacing: ScaleSpacing.md) {
                HStack {
                    Text("Low Temp")
                        .font(.scaleSubheadline)
                        .foregroundColor(themeManager.currentTheme.textSecondary)

                    Spacer()

                    TextField("°F", text: $viewModel.targetTempLow)
                        .keyboardType(.decimalPad)
                        .font(.scaleSubheadline)
                        .foregroundColor(.scaleTextPrimary)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .padding(ScaleSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: ScaleRadius.sm)
                                .fill(Color.cosmicDeep)
                        )
                }

                HStack {
                    Text("High Temp")
                        .font(.scaleSubheadline)
                        .foregroundColor(themeManager.currentTheme.textSecondary)

                    Spacer()

                    TextField("°F", text: $viewModel.targetTempHigh)
                        .keyboardType(.decimalPad)
                        .font(.scaleSubheadline)
                        .foregroundColor(.scaleTextPrimary)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .padding(ScaleSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: ScaleRadius.sm)
                                .fill(Color.cosmicDeep)
                        )
                }

                Text("Typical ball python brumation temps: 50-65°F")
                    .font(.scaleCaption)
                    .foregroundColor(themeManager.currentTheme.textTertiary)
            }
        }
    }

    // MARK: - Pre-Brumation Section

    private var preBrumationSection: some View {
        ScaleCard(header: .init(title: "Pre-Brumation Data", icon: "scalemass", iconColor: .shedPink)) {
            VStack(spacing: ScaleSpacing.md) {
                HStack {
                    Text("Current Weight")
                        .font(.scaleSubheadline)
                        .foregroundColor(themeManager.currentTheme.textSecondary)

                    Spacer()

                    HStack(spacing: 4) {
                        TextField("0", text: $viewModel.preBrumationWeight)
                            .keyboardType(.decimalPad)
                            .font(.scaleSubheadline)
                            .foregroundColor(.scaleTextPrimary)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)

                        Text("g")
                            .font(.scaleSubheadline)
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                    }
                    .padding(ScaleSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: ScaleRadius.sm)
                            .fill(Color.cosmicDeep)
                    )
                }

                DatePicker(
                    "Last Feeding",
                    selection: $viewModel.lastFeedingDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .font(.scaleSubheadline)
                .foregroundColor(themeManager.currentTheme.textSecondary)
            }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        ScaleCard(header: .init(title: "Notes", icon: "note.text", iconColor: .scaleMuted)) {
            TextField("Add notes about this brumation cycle...", text: $viewModel.notes, axis: .vertical)
                .font(.scaleSubheadline)
                .foregroundColor(.scaleTextPrimary)
                .lineLimit(3...6)
        }
    }
}

// MARK: - Date Row

struct DateRow: View {
    let title: String
    @Binding var date: Date?
    let phase: BrumationPhase
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: phaseIcon)
                    .font(.system(size: 12))
                    .foregroundColor(phaseColor)

                Text(title)
                    .font(.scaleSubheadline)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            Spacer()

            if let boundDate = Binding($date) {
                DatePicker("", selection: boundDate, displayedComponents: .date)
                    .labelsHidden()
                    .tint(.nebulaLavender)
            } else {
                Button("Set Date") {
                    date = Date()
                }
                .font(.scaleCaption)
                .foregroundColor(.nebulaLavender)
            }
        }
    }

    private var phaseIcon: String {
        switch phase {
        case .cooldown: return "thermometer.snowflake"
        case .active: return "moon.zzz.fill"
        case .warmup: return "thermometer.sun.fill"
        case .complete: return "checkmark.circle.fill"
        default: return "calendar"
        }
    }

    private var phaseColor: Color {
        switch phase {
        case .cooldown: return .nebulaCyan
        case .active: return .nebulaLavender
        case .warmup: return .shedPink
        case .complete: return .scaleSuccess
        default: return .scaleMuted
        }
    }
}

// MARK: - New Brumation Cycle View Model

@MainActor
@Observable
final class NewBrumationCycleViewModel: ObservableObject {
    private let dataService: DataService

    var availableAnimals: [Animal] = []
    var selectedAnimal: Animal?

    var year: Int = Calendar.current.component(.year, from: Date())
    var seasonName = ""

    var cooldownStartDate: Date? = nil
    var fullBrumationStartDate: Date? = nil
    var warmupStartDate: Date? = nil
    var brumationEndDate: Date? = nil

    var targetTempLow = ""
    var targetTempHigh = ""
    var preBrumationWeight = ""
    var lastFeedingDate = Date()
    var notes = ""

    var error: Error?

    var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 1)...(currentYear + 1))
    }

    var canSave: Bool {
        selectedAnimal != nil
    }

    init(dataService: DataService = .shared) {
        self.dataService = dataService
    }

    func loadAnimals() async {
        do {
            availableAnimals = try dataService.fetchAllAnimals()
                .filter { $0.status == .active || $0.status == .breedingHold }
        } catch {
            self.error = error
        }
    }

    func save() async {
        guard let animal = selectedAnimal else { return }

        let cycle = BrumationCycle(year: year)
        cycle.animal = animal
        cycle.seasonName = seasonName.isEmpty ? nil : seasonName
        cycle.cooldownStartDate = cooldownStartDate
        cycle.fullBrumationStartDate = fullBrumationStartDate
        cycle.warmupStartDate = warmupStartDate
        cycle.brumationEndDate = brumationEndDate

        if let tempLow = Double(targetTempLow) {
            cycle.targetTempLowF = tempLow
        }
        if let tempHigh = Double(targetTempHigh) {
            cycle.targetTempHighF = tempHigh
        }
        if let weight = Double(preBrumationWeight) {
            cycle.preBrumationWeight = weight
        }

        cycle.lastFeedingBefore = lastFeedingDate
        cycle.notes = notes.isEmpty ? nil : notes

        do {
            dataService.insert(cycle)
            try dataService.save()
        } catch {
            self.error = error
        }
    }
}

// MARK: - Brumation Detail View

struct BrumationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    let cycle: BrumationCycle
    let onUpdate: () -> Void
    @State private var showingPhaseTransition = false

    var body: some View {
        ZStack {
            ScaleBackground()

            ScrollView {
                VStack(spacing: ScaleSpacing.lg) {
                    // Header
                    headerSection

                    // Current Phase
                    if let phase = cycle.currentPhase {
                        currentPhaseSection(phase)
                    }

                    // Phase Progress
                    phaseProgressSection

                    // Data Summary
                    dataSummarySection

                    // Tasks
                    if let phase = cycle.currentPhase {
                        tasksSection(phase)
                    }

                    // Notes
                    if let notes = cycle.notes, !notes.isEmpty {
                        notesSection(notes)
                    }

                    // Actions
                    actionsSection
                }
                .padding(ScaleSpacing.lg)
            }
        }
        .navigationTitle(cycle.animal?.name ?? "Brumation")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: ScaleSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.nebulaLavender.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: cycle.status.iconName)
                    .font(.system(size: 36))
                    .foregroundColor(.nebulaLavender)
            }

            // Info
            VStack(spacing: 4) {
                Text(cycle.animal?.name ?? "Unknown")
                    .font(.scaleTitle2)
                    .foregroundColor(.scaleTextPrimary)

                Text(cycle.seasonName ?? "\(cycle.year)")
                    .font(.scaleSubheadline)
                    .foregroundColor(themeManager.currentTheme.textSecondary)

                Text(cycle.status.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.nebulaLavender)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.nebulaLavender.opacity(0.15))
                    )
            }
        }
    }

    // MARK: - Current Phase Section

    private func currentPhaseSection(_ phase: BrumationPhase) -> some View {
        ScaleCard(
            header: .init(
                title: "Current Phase",
                icon: phaseIcon(phase),
                iconColor: phaseColor(phase)
            )
        ) {
            VStack(alignment: .leading, spacing: ScaleSpacing.md) {
                Text(phase.displayName)
                    .font(.scaleHeadline)
                    .foregroundColor(.scaleTextPrimary)

                Text(phase.description)
                    .font(.scaleCaption)
                    .foregroundColor(themeManager.currentTheme.textSecondary)

                HStack(spacing: ScaleSpacing.lg) {
                    if let days = cycle.daysInCurrentPhase {
                        VStack(spacing: 2) {
                            Text("\(days)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(phaseColor(phase))
                            Text("days in phase")
                                .font(.scaleCaption)
                                .foregroundColor(themeManager.currentTheme.textTertiary)
                        }
                    }

                    if let daysUntil = cycle.daysUntilNextPhase, daysUntil > 0 {
                        VStack(spacing: 2) {
                            Text("\(daysUntil)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.nebulaGold)
                            Text("until next phase")
                                .font(.scaleCaption)
                                .foregroundColor(themeManager.currentTheme.textTertiary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Phase Progress Section

    private var phaseProgressSection: some View {
        ScaleCard(header: .init(title: "Timeline", icon: "calendar.badge.clock", iconColor: .scaleMuted)) {
            VStack(spacing: ScaleSpacing.md) {
                PhaseTimelineRow(
                    phase: .cooldown,
                    date: cycle.cooldownStartDate,
                    isActive: cycle.currentPhase == .cooldown,
                    isPast: isPastPhase(.cooldown)
                )

                PhaseTimelineRow(
                    phase: .active,
                    date: cycle.fullBrumationStartDate,
                    isActive: cycle.currentPhase == .active,
                    isPast: isPastPhase(.active)
                )

                PhaseTimelineRow(
                    phase: .warmup,
                    date: cycle.warmupStartDate,
                    isActive: cycle.currentPhase == .warmup,
                    isPast: isPastPhase(.warmup)
                )

                PhaseTimelineRow(
                    phase: .complete,
                    date: cycle.brumationEndDate,
                    isActive: cycle.currentPhase == .complete,
                    isPast: cycle.status == .complete
                )
            }
        }
    }

    // MARK: - Data Summary Section

    private var dataSummarySection: some View {
        ScaleCard(header: .init(title: "Data", icon: "chart.bar.fill", iconColor: .nebulaCyan)) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: ScaleSpacing.md) {
                DataCell(
                    title: "Pre-Weight",
                    value: cycle.preBrumationWeight.map { "\(Int($0))g" } ?? "--",
                    icon: "scalemass"
                )

                DataCell(
                    title: "Post-Weight",
                    value: cycle.postBrumationWeight.map { "\(Int($0))g" } ?? "--",
                    icon: "scalemass"
                )

                DataCell(
                    title: "Total Days",
                    value: cycle.totalBrumationDays.map { "\($0)" } ?? "--",
                    icon: "clock"
                )

                DataCell(
                    title: "Weight Change",
                    value: cycle.weightChangePercentage.map { String(format: "%+.1f%%", $0) } ?? "--",
                    icon: "arrow.up.arrow.down"
                )
            }
        }
    }

    // MARK: - Tasks Section

    private func tasksSection(_ phase: BrumationPhase) -> some View {
        ScaleCard(header: .init(title: "Phase Tasks", icon: "checklist", iconColor: .nebulaGold)) {
            VStack(alignment: .leading, spacing: ScaleSpacing.sm) {
                ForEach(phase.tasks, id: \.self) { task in
                    HStack(alignment: .top, spacing: ScaleSpacing.sm) {
                        Image(systemName: "circle")
                            .font(.system(size: 10))
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                            .padding(.top, 4)

                        Text(task)
                            .font(.scaleCaption)
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Notes Section

    private func notesSection(_ notes: String) -> some View {
        ScaleCard(header: .init(title: "Notes", icon: "note.text", iconColor: .scaleMuted)) {
            Text(notes)
                .font(.scaleSubheadline)
                .foregroundColor(themeManager.currentTheme.textSecondary)
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: ScaleSpacing.md) {
            if cycle.status != .complete && cycle.status != .cancelled {
                ScaleSecondaryButton("Advance Phase", icon: "arrow.forward") {
                    // Advance to next phase
                }

                Button {
                    // Cancel brumation
                } label: {
                    Text("Cancel Brumation")
                        .font(.scaleCaption)
                        .foregroundColor(.scaleError)
                }
            }
        }
    }

    // MARK: - Helpers

    private func isPastPhase(_ phase: BrumationPhase) -> Bool {
        guard let currentPhase = cycle.currentPhase else { return false }
        let phases: [BrumationPhase] = [.cooldown, .active, .warmup, .complete]
        guard let currentIndex = phases.firstIndex(of: currentPhase),
              let phaseIndex = phases.firstIndex(of: phase) else { return false }
        return phaseIndex < currentIndex
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

// MARK: - Phase Timeline Row

struct PhaseTimelineRow: View {
    let phase: BrumationPhase
    let date: Date?
    let isActive: Bool
    let isPast: Bool
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        HStack {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 36, height: 36)

                Image(systemName: phaseIcon)
                    .font(.system(size: 14))
                    .foregroundColor(iconForegroundColor)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(phase.displayName)
                    .font(.scaleSubheadline)
                    .foregroundColor(isActive ? .scaleTextPrimary : themeManager.currentTheme.textSecondary)

                if let date = date {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                } else {
                    Text("Not scheduled")
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }
            }

            Spacer()

            // Status
            if isPast {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.scaleSuccess)
            } else if isActive {
                Text("Active")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(phaseColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(phaseColor.opacity(0.15))
                    )
            }
        }
    }

    private var phaseIcon: String {
        switch phase {
        case .cooldown: return "thermometer.snowflake"
        case .active: return "moon.zzz.fill"
        case .warmup: return "thermometer.sun.fill"
        case .complete: return "checkmark.circle.fill"
        default: return "calendar"
        }
    }

    private var phaseColor: Color {
        switch phase {
        case .cooldown: return .nebulaCyan
        case .active: return .nebulaLavender
        case .warmup: return .shedPink
        case .complete: return .scaleSuccess
        default: return .scaleMuted
        }
    }

    private var iconBackgroundColor: Color {
        if isActive {
            return phaseColor.opacity(0.15)
        } else if isPast {
            return Color.scaleSuccess.opacity(0.15)
        } else {
            return Color.scaleMuted.opacity(0.1)
        }
    }

    private var iconForegroundColor: Color {
        if isActive {
            return phaseColor
        } else if isPast {
            return .scaleSuccess
        } else {
            return .scaleTextTertiary
        }
    }
}

// MARK: - Data Cell

struct DataCell: View {
    let title: String
    let value: String
    let icon: String
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: ScaleSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(themeManager.currentTheme.textTertiary)

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.scaleTextPrimary)

            Text(title)
                .font(.scaleCaption)
                .foregroundColor(themeManager.currentTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ScaleSpacing.md)
    }
}

// MARK: - Preview

#Preview("New Cycle") {
    NewBrumationCycleView {}
}

#Preview("Detail") {
    NavigationStack {
        BrumationDetailView(cycle: BrumationCycle(year: 2024)) {}
    }
}
