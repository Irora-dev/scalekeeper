import SwiftUI
import ScaleCore
import ScaleUI

// MARK: - New Treatment View

struct NewTreatmentView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NewTreatmentViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                ScrollView {
                    VStack(spacing: ScaleSpacing.lg) {
                        // Select Animal
                        animalSection

                        // Select or Create Medication
                        medicationSection

                        // Treatment Details
                        treatmentDetailsSection

                        // Schedule
                        scheduleSection
                    }
                    .padding(ScaleSpacing.lg)
                }
            }
            .navigationTitle("New Treatment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Start") {
                        if viewModel.createTreatment() {
                            onSave()
                            dismiss()
                        }
                    }
                    .foregroundColor(.nebulaMagenta)
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isValid)
                }
            }
            .task {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Animal Section

    private var animalSection: some View {
        ScaleCard(
            header: .init(
                title: "Patient",
                icon: "leaf.fill",
                iconColor: .nebulaCyan
            )
        ) {
            if viewModel.animals.isEmpty {
                Text("No animals in collection")
                    .font(.scaleSubheadline)
                    .foregroundColor(themeManager.currentTheme.textTertiary)
                    .padding(.vertical, ScaleSpacing.md)
            } else {
                Menu {
                    ForEach(viewModel.animals, id: \.id) { animal in
                        Button(animal.name) {
                            viewModel.selectedAnimal = animal
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.selectedAnimal?.name ?? "Select animal")
                            .foregroundColor(viewModel.selectedAnimal == nil ? themeManager.currentTheme.textTertiary : .scaleTextPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: ScaleRadius.sm)
                            .fill(Color.cosmicDeep)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: ScaleRadius.sm)
                            .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - Medication Section

    private var medicationSection: some View {
        ScaleCard(
            header: .init(
                title: "Medication",
                icon: "pills.fill",
                iconColor: .nebulaMagenta
            )
        ) {
            VStack(spacing: ScaleSpacing.md) {
                // Existing medications dropdown
                if !viewModel.medications.isEmpty {
                    Menu {
                        Button("Create New") {
                            viewModel.selectedMedication = nil
                            viewModel.isCreatingNew = true
                        }
                        Divider()
                        ForEach(viewModel.medications, id: \.id) { med in
                            Button(med.name) {
                                viewModel.selectedMedication = med
                                viewModel.isCreatingNew = false
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.selectedMedication?.name ?? "Select or create medication")
                                .foregroundColor(viewModel.selectedMedication == nil ? .scaleTextTertiary : .scaleTextPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.scaleTextTertiary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: ScaleRadius.sm)
                                .fill(Color.cosmicDeep)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: ScaleRadius.sm)
                                .stroke(Color.scaleBorder, lineWidth: 1)
                        )
                    }
                }

                // New medication fields
                if viewModel.isCreatingNew || viewModel.medications.isEmpty {
                    VStack(spacing: ScaleSpacing.md) {
                        formField("Medication Name", text: $viewModel.newMedicationName)

                        // Type picker
                        VStack(alignment: .leading, spacing: ScaleSpacing.xs) {
                            Text("Type")
                                .font(.scaleCaption)
                                .foregroundColor(themeManager.currentTheme.textSecondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: ScaleSpacing.sm) {
                                    ForEach(MedicationType.allCases, id: \.self) { type in
                                        MedicationTypeChip(
                                            type: type,
                                            isSelected: viewModel.newMedicationType == type
                                        ) {
                                            viewModel.newMedicationType = type
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Treatment Details Section

    private var treatmentDetailsSection: some View {
        ScaleCard(
            header: .init(
                title: "Treatment Details",
                icon: "doc.text.fill",
                iconColor: .nebulaLavender
            )
        ) {
            VStack(spacing: ScaleSpacing.md) {
                formField("Condition Being Treated", text: $viewModel.condition, placeholder: "e.g., Respiratory infection")
                formField("Dosage", text: $viewModel.dosage, placeholder: "e.g., 0.1ml/100g")
                formField("Prescribed By (Optional)", text: $viewModel.prescribedBy, placeholder: "Veterinarian name")

                VStack(alignment: .leading, spacing: ScaleSpacing.xs) {
                    Text("Notes (Optional)")
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)

                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 60)
                        .padding(ScaleSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: ScaleRadius.sm)
                                .fill(Color.cosmicDeep)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: ScaleRadius.sm)
                                .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
                        )
                }
            }
        }
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        ScaleCard(
            header: .init(
                title: "Schedule",
                icon: "calendar",
                iconColor: .nebulaGold
            )
        ) {
            VStack(spacing: ScaleSpacing.md) {
                // Start date
                VStack(alignment: .leading, spacing: ScaleSpacing.xs) {
                    Text("Start Date & Time")
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)

                    DatePicker("", selection: $viewModel.startDate)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }

                HStack(spacing: ScaleSpacing.md) {
                    // Frequency
                    VStack(alignment: .leading, spacing: ScaleSpacing.xs) {
                        Text("Every")
                            .font(.scaleCaption)
                            .foregroundColor(themeManager.currentTheme.textSecondary)

                        HStack {
                            TextField("24", text: $viewModel.frequencyHours)
                                .keyboardType(.numberPad)
                                .textFieldStyle(ScaleTextFieldStyle())
                                .frame(width: 60)

                            Text("hours")
                                .font(.scaleSubheadline)
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                        }
                    }

                    // Total doses
                    VStack(alignment: .leading, spacing: ScaleSpacing.xs) {
                        Text("Total Doses")
                            .font(.scaleCaption)
                            .foregroundColor(themeManager.currentTheme.textSecondary)

                        TextField("7", text: $viewModel.totalDoses)
                            .keyboardType(.numberPad)
                            .textFieldStyle(ScaleTextFieldStyle())
                    }
                }

                // Summary
                if let summary = viewModel.scheduleSummary {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.nebulaLavender)
                        Text(summary)
                            .font(.scaleCaption)
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }
                    .padding(ScaleSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: ScaleRadius.sm)
                            .fill(Color.nebulaLavender.opacity(0.1))
                    )
                }
            }
        }
    }

    // MARK: - Helpers

    private func formField(_ label: String, text: Binding<String>, placeholder: String = "") -> some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.xs) {
            Text(label)
                .font(.scaleCaption)
                .foregroundColor(themeManager.currentTheme.textSecondary)

            TextField(placeholder, text: text)
                .textFieldStyle(ScaleTextFieldStyle())
        }
    }
}

// MARK: - Medication Type Chip

struct MedicationTypeChip: View {
    let type: MedicationType
    let isSelected: Bool
    let onTap: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: type.iconName)
                    .font(.system(size: 18))
                Text(type.displayName)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? .nebulaMagenta : themeManager.currentTheme.textSecondary)
            .frame(width: 70, height: 54)
            .background(
                RoundedRectangle(cornerRadius: ScaleRadius.sm)
                    .fill(isSelected ? Color.nebulaMagenta.opacity(0.15) : Color.cosmicDeep)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ScaleRadius.sm)
                    .stroke(isSelected ? Color.nebulaMagenta : themeManager.currentTheme.borderColor, lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

// MARK: - New Treatment View Model

@MainActor
@Observable
final class NewTreatmentViewModel: ObservableObject {
    private let dataService: DataService
    private let medicationService: MedicationService

    // Data
    var animals: [Animal] = []
    var medications: [Medication] = []

    // Form state
    var selectedAnimal: Animal?
    var selectedMedication: Medication?
    var isCreatingNew = false

    var newMedicationName = ""
    var newMedicationType: MedicationType = .oral

    var condition = ""
    var dosage = ""
    var prescribedBy = ""
    var notes = ""

    var startDate = Date()
    var frequencyHours = "24"
    var totalDoses = "7"

    var isValid: Bool {
        selectedAnimal != nil &&
        (selectedMedication != nil || !newMedicationName.isEmpty) &&
        !condition.isEmpty &&
        !dosage.isEmpty &&
        Int(frequencyHours) != nil &&
        Int(totalDoses) != nil
    }

    var scheduleSummary: String? {
        guard let frequency = Int(frequencyHours),
              let doses = Int(totalDoses),
              frequency > 0, doses > 0 else { return nil }

        let days = (frequency * doses) / 24
        let endDate = Calendar.current.date(byAdding: .hour, value: frequency * doses, to: startDate)!

        return "Treatment will end on \(endDate.formatted(date: .abbreviated, time: .omitted)) (\(days) days)"
    }

    init(dataService: DataService = .shared, medicationService: MedicationService = .shared) {
        self.dataService = dataService
        self.medicationService = medicationService
    }

    func loadData() async {
        do {
            animals = try dataService.fetchActiveAnimals()
            medications = try dataService.fetchMedications()
        } catch {
            print("Failed to load data: \(error)")
        }
    }

    func createTreatment() -> Bool {
        guard let animal = selectedAnimal,
              let frequency = Int(frequencyHours),
              let doses = Int(totalDoses) else { return false }

        do {
            // Create medication if needed
            let medication: Medication
            if let existing = selectedMedication {
                medication = existing
            } else {
                medication = Medication(name: newMedicationName, medicationType: newMedicationType)
                dataService.insert(medication)
                try dataService.save()
            }

            // Create treatment plan
            _ = try medicationService.createTreatmentPlan(
                for: animal,
                medication: medication,
                conditionTreated: condition,
                dosage: dosage,
                frequencyHours: frequency,
                totalDoses: doses,
                startDate: startDate,
                prescribedBy: prescribedBy.isEmpty ? nil : prescribedBy,
                notes: notes.isEmpty ? nil : notes
            )

            return true
        } catch {
            print("Failed to create treatment: \(error)")
            return false
        }
    }
}

// MARK: - Treatment Detail View

struct TreatmentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: TreatmentDetailViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingDiscontinueAlert = false

    init(treatment: TreatmentPlan) {
        _viewModel = StateObject(wrappedValue: TreatmentDetailViewModel(treatment: treatment))
    }

    var body: some View {
        ZStack {
            ScaleBackground()

            ScrollView {
                VStack(spacing: ScaleSpacing.lg) {
                    // Header Card
                    treatmentHeaderCard

                    // Progress Card
                    progressCard

                    // Upcoming Doses
                    if !viewModel.upcomingDoses.isEmpty {
                        upcomingDosesCard
                    }

                    // Completed Doses
                    if !viewModel.completedDoses.isEmpty {
                        completedDosesCard
                    }
                }
                .padding(ScaleSpacing.lg)
            }
        }
        .navigationTitle("Treatment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if viewModel.treatment.status == .active {
                        Button {
                            viewModel.pauseTreatment()
                        } label: {
                            Label("Pause Treatment", systemImage: "pause.circle")
                        }
                    } else if viewModel.treatment.status == .paused {
                        Button {
                            viewModel.resumeTreatment()
                        } label: {
                            Label("Resume Treatment", systemImage: "play.circle")
                        }
                    }

                    Button(role: .destructive) {
                        showingDiscontinueAlert = true
                    } label: {
                        Label("Discontinue Treatment", systemImage: "xmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.nebulaLavender)
                }
            }
        }
        .alert("Discontinue Treatment?", isPresented: $showingDiscontinueAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Discontinue", role: .destructive) {
                viewModel.discontinueTreatment()
                dismiss()
            }
        } message: {
            Text("This will stop all scheduled doses. This action cannot be undone.")
        }
    }

    // MARK: - Header Card

    private var treatmentHeaderCard: some View {
        ScaleCard {
            VStack(spacing: ScaleSpacing.md) {
                HStack {
                    // Medication icon
                    ZStack {
                        Circle()
                            .fill(Color.nebulaMagenta.opacity(0.15))
                            .frame(width: 56, height: 56)

                        Image(systemName: viewModel.treatment.medication?.medicationType.iconName ?? "pills")
                            .font(.system(size: 24))
                            .foregroundColor(.nebulaMagenta)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.treatment.medication?.name ?? "Unknown")
                            .font(.scaleTitle3)
                            .foregroundColor(.scaleTextPrimary)

                        Text("for \(viewModel.treatment.animal?.name ?? "Unknown")")
                            .font(.scaleSubheadline)
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }

                    Spacer()

                    // Status badge
                    statusBadge
                }

                Divider()
                    .background(themeManager.currentTheme.borderColor)

                // Details
                VStack(spacing: ScaleSpacing.sm) {
                    detailRow(icon: "heart.text.square", label: "Condition", value: viewModel.treatment.conditionTreated)
                    detailRow(icon: "eyedropper", label: "Dosage", value: viewModel.treatment.dosage)
                    detailRow(icon: "clock", label: "Frequency", value: "Every \(viewModel.treatment.frequencyHours) hours")

                    if let prescriber = viewModel.treatment.prescribedBy {
                        detailRow(icon: "person.crop.circle", label: "Prescribed By", value: prescriber)
                    }
                }
            }
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: viewModel.treatment.status.iconName)
            Text(viewModel.treatment.status.displayName)
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(statusColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(statusColor.opacity(0.15))
        )
    }

    private var statusColor: Color {
        switch viewModel.treatment.status {
        case .active: return .nebulaCyan
        case .paused: return .nebulaGold
        case .completed: return .nebulaCyan
        case .discontinued: return .scaleError
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.nebulaLavender)
                .frame(width: 24)

            Text(label)
                .font(.scaleCaption)
                .foregroundColor(themeManager.currentTheme.textSecondary)

            Spacer()

            Text(value)
                .font(.scaleSubheadline)
                .foregroundColor(.scaleTextPrimary)
        }
    }

    // MARK: - Progress Card

    private var progressCard: some View {
        ScaleCard(
            header: .init(
                title: "Progress",
                icon: "chart.bar.fill",
                iconColor: .nebulaCyan
            )
        ) {
            VStack(spacing: ScaleSpacing.md) {
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.nebulaMagenta.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.nebulaMagenta)
                            .frame(width: geo.size.width * (viewModel.treatment.progressPercentage / 100), height: 8)
                    }
                }
                .frame(height: 8)

                // Stats
                HStack {
                    statItem(value: "\(viewModel.treatment.completedDoses)", label: "Completed")
                    Spacer()
                    statItem(value: "\(viewModel.remainingDoses)", label: "Remaining")
                    Spacer()
                    statItem(value: "\(Int(viewModel.treatment.progressPercentage))%", label: "Progress")
                }
            }
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.scaleTextPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(themeManager.currentTheme.textTertiary)
        }
    }

    // MARK: - Upcoming Doses Card

    private var upcomingDosesCard: some View {
        ScaleCard(
            header: .init(
                title: "Upcoming Doses",
                subtitle: "\(viewModel.upcomingDoses.count) remaining",
                icon: "clock.fill",
                iconColor: .nebulaGold
            )
        ) {
            VStack(spacing: ScaleSpacing.sm) {
                ForEach(viewModel.upcomingDoses.prefix(5), id: \.id) { dose in
                    doseRow(dose, showActions: true)
                }

                if viewModel.upcomingDoses.count > 5 {
                    Text("+ \(viewModel.upcomingDoses.count - 5) more doses")
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                        .padding(.top, ScaleSpacing.xs)
                }
            }
        }
    }

    // MARK: - Completed Doses Card

    private var completedDosesCard: some View {
        ScaleCard(
            header: .init(
                title: "Completed Doses",
                subtitle: "\(viewModel.completedDoses.count) administered",
                icon: "checkmark.circle.fill",
                iconColor: .nebulaCyan
            )
        ) {
            VStack(spacing: ScaleSpacing.sm) {
                ForEach(viewModel.completedDoses.prefix(5), id: \.id) { dose in
                    doseRow(dose, showActions: false)
                }
            }
        }
    }

    private func doseRow(_ dose: MedicationDose, showActions: Bool) -> some View {
        HStack {
            Image(systemName: dose.status.iconName)
                .font(.system(size: 14))
                .foregroundColor(doseStatusColor(dose.status))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(dose.scheduledTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.scaleSubheadline)
                    .foregroundColor(.scaleTextPrimary)

                Text(dose.status.displayName)
                    .font(.scaleCaption)
                    .foregroundColor(themeManager.currentTheme.textTertiary)
            }

            Spacer()

            if showActions && dose.status == .scheduled {
                Button {
                    viewModel.administerDose(dose)
                } label: {
                    Text("Give")
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

    private func doseStatusColor(_ status: DoseStatus) -> Color {
        switch status {
        case .scheduled: return .nebulaGold
        case .administered: return .nebulaCyan
        case .skipped: return ThemeManager.shared.currentTheme.textTertiary
        case .missed: return .scaleError
        }
    }
}

// MARK: - Treatment Detail View Model

@MainActor
@Observable
final class TreatmentDetailViewModel: ObservableObject {
    private let medicationService: MedicationService

    let treatment: TreatmentPlan

    var upcomingDoses: [MedicationDose] {
        treatment.doses?
            .filter { $0.status == .scheduled }
            .sorted { $0.scheduledTime < $1.scheduledTime } ?? []
    }

    var completedDoses: [MedicationDose] {
        treatment.doses?
            .filter { $0.status == .administered }
            .sorted { $0.administeredTime ?? $0.scheduledTime > $1.administeredTime ?? $1.scheduledTime } ?? []
    }

    var remainingDoses: Int {
        (treatment.totalDoses ?? 0) - treatment.completedDoses
    }

    init(treatment: TreatmentPlan, medicationService: MedicationService = .shared) {
        self.treatment = treatment
        self.medicationService = medicationService
    }

    func administerDose(_ dose: MedicationDose) {
        do {
            try medicationService.administerDose(dose)
        } catch {
            print("Failed to administer dose: \(error)")
        }
    }

    func pauseTreatment() {
        do {
            try medicationService.pauseTreatment(treatment)
        } catch {
            print("Failed to pause treatment: \(error)")
        }
    }

    func resumeTreatment() {
        do {
            try medicationService.resumeTreatment(treatment)
        } catch {
            print("Failed to resume treatment: \(error)")
        }
    }

    func discontinueTreatment() {
        do {
            try medicationService.discontinueTreatment(treatment)
        } catch {
            print("Failed to discontinue treatment: \(error)")
        }
    }
}

// MARK: - Preview

#Preview("New Treatment") {
    NewTreatmentView { }
}

#Preview("Treatment Detail") {
    NavigationStack {
        TreatmentDetailView(treatment: TreatmentPlan(
            conditionTreated: "Respiratory Infection",
            dosage: "0.1ml/100g",
            frequencyHours: 24,
            totalDoses: 7
        ))
    }
}
