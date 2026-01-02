import SwiftUI
import SwiftData
import Charts
import ScaleCore
import ScaleUI

// MARK: - Add Weight View

struct AddWeightView: View {
    let animalID: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var animal: Animal?
    @State private var weightGrams: Double = 0
    @State private var recordedDate: Date = Date()
    @State private var notes: String = ""
    @State private var lastWeight: WeightRecord?

    @State private var isLoading = true
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                if isLoading {
                    ScaleLoadingState(message: "Loading...")
                } else {
                    ScrollView {
                        VStack(spacing: ScaleSpacing.lg) {
                            // Previous weight comparison
                            if let last = lastWeight {
                                weightComparisonCard(last)
                            }

                            // Weight input
                            weightInputSection

                            // Date
                            ScaleDatePicker(
                                "Date Recorded",
                                date: $recordedDate,
                                
                            )

                            // Notes
                            ScaleTextEditor(
                                "Notes",
                                text: $notes,
                                placeholder: "Any observations...",
                                helpText: "Optional notes about this weight"
                            )

                            Color.clear.frame(height: 100)
                        }
                        .padding(.horizontal, ScaleSpacing.md)
                        .padding(.top, ScaleSpacing.md)
                    }
                }
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveWeight()
                    }
                    .font(.headline)
                    .foregroundStyle(weightGrams > 0 ? themeManager.currentTheme.primaryAccent : themeManager.currentTheme.textDisabled)
                    .disabled(weightGrams <= 0 || isSaving)
                }
            }
            .onAppear {
                loadAnimal()
            }
            .scaleToastContainer()
        }
    }

    private func weightComparisonCard(_ last: WeightRecord) -> some View {
        VStack(spacing: ScaleSpacing.sm) {
            Text("Previous Weight")
                .font(.scaleCaption)
                .foregroundStyle(themeManager.currentTheme.textTertiary)

            Text(last.formattedWeight)
                .font(.scaleStatMedium)
                .foregroundStyle(Color.scaleTextPrimary)

            Text(last.recordedAt.formatted(date: .abbreviated, time: .omitted))
                .font(.scaleCaption)
                .foregroundStyle(themeManager.currentTheme.textTertiary)

            if weightGrams > 0 {
                let change = weightGrams - Double(last.weightGrams)
                let percentChange = (change / Double(last.weightGrams)) * 100

                HStack(spacing: ScaleSpacing.xs) {
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 12))
                    Text(String(format: "%.1f g (%.1f%%)", change, percentChange))
                        .font(.scaleSubheadline)
                }
                .foregroundStyle(change >= 0 ? Color.scaleSuccess : Color.scaleWarning)
                .padding(.top, ScaleSpacing.xs)
            }
        }
        .padding(ScaleSpacing.md)
        .frame(maxWidth: .infinity)
        .background(themeManager.currentTheme.cardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
    }

    private var weightInputSection: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.md) {
            ScaleSectionHeader("Weight")

            ScaleNumberField(
                "Weight",
                value: $weightGrams,
                unit: "g",
                icon: "scalemass.fill",
                isRequired: true,
                helpText: "Enter weight in grams",
                range: 0...100000,
                step: 1
            )

            // Conversion display
            if weightGrams > 0 {
                HStack(spacing: ScaleSpacing.lg) {
                    conversionLabel("oz", value: weightGrams / 28.3495)
                    conversionLabel("lb", value: weightGrams / 453.592)
                    if weightGrams >= 1000 {
                        conversionLabel("kg", value: weightGrams / 1000)
                    }
                }
            }
        }
    }

    private func conversionLabel(_ unit: String, value: Double) -> some View {
        VStack(spacing: 2) {
            Text(String(format: "%.2f", value))
                .font(.scaleSubheadline)
                .foregroundStyle(themeManager.currentTheme.textSecondary)
            Text(unit)
                .font(.scaleCaption)
                .foregroundStyle(themeManager.currentTheme.textTertiary)
        }
        .padding(.horizontal, ScaleSpacing.md)
        .padding(.vertical, ScaleSpacing.sm)
        .background(themeManager.currentTheme.cardBackground.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.sm))
    }

    private func loadAnimal() {
        isLoading = true

        let predicate = #Predicate<Animal> { $0.id == animalID }
        let descriptor = FetchDescriptor<Animal>(predicate: predicate)

        if let fetchedAnimal = try? modelContext.fetch(descriptor).first {
            animal = fetchedAnimal

            // Get last weight
            if let weights = fetchedAnimal.weights?.sorted(by: { $0.recordedAt > $1.recordedAt }) {
                lastWeight = weights.first
                if let last = lastWeight {
                    weightGrams = Double(last.weightGrams)
                }
            }
        }

        isLoading = false
    }

    private func saveWeight() {
        guard let animal = animal, weightGrams > 0 else { return }

        isSaving = true

        let weight = WeightRecord(weightGrams: weightGrams)
        weight.recordedAt = recordedDate
        weight.animal = animal

        if !notes.isEmpty {
            weight.notes = notes
        }

        animal.weights?.append(weight)
        animal.currentWeightGrams = weightGrams

        do {
            try modelContext.save()
            ScaleToastManager.shared.success("Weight logged!")
            ScaleHaptics.success()
            dismiss()
        } catch {
            ScaleToastManager.shared.error("Failed to save weight")
            isSaving = false
        }
    }
}

// MARK: - Weight Chart View

struct WeightChartView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let animalID: UUID
    @Environment(\.modelContext) private var modelContext

    @State private var weights: [WeightRecord] = []
    @State private var timeRange: TimeRange = .threeMonths

    enum TimeRange: String, CaseIterable {
        case oneMonth = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case oneYear = "1Y"
        case all = "All"

        var days: Int? {
            switch self {
            case .oneMonth: return 30
            case .threeMonths: return 90
            case .sixMonths: return 180
            case .oneYear: return 365
            case .all: return nil
            }
        }
    }

    var filteredWeights: [WeightRecord] {
        guard let days = timeRange.days else { return weights }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return weights.filter { $0.recordedAt >= cutoff }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.md) {
            HStack {
                Text("Weight History")
                    .font(.scaleHeadline)
                    .foregroundStyle(Color.scaleTextPrimary)

                Spacer()

                Picker("Time Range", selection: $timeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            if filteredWeights.isEmpty {
                ScaleEmptyState.noWeights()
            } else {
                Chart(filteredWeights) { weight in
                    LineMark(
                        x: .value("Date", weight.recordedAt),
                        y: .value("Weight", weight.weightGrams)
                    )
                    .foregroundStyle(ThemeManager.shared.currentTheme.primaryAccent)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", weight.recordedAt),
                        y: .value("Weight", weight.weightGrams)
                    )
                    .foregroundStyle(ThemeManager.shared.currentTheme.primaryAccent)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let grams = value.as(Int.self) {
                                Text("\(grams)g")
                                    .font(.scaleCaption)
                                    .foregroundStyle(themeManager.currentTheme.textTertiary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date.formatted(.dateTime.month(.abbreviated).day()))
                                    .font(.scaleCaption)
                                    .foregroundStyle(themeManager.currentTheme.textTertiary)
                            }
                        }
                    }
                }
                .frame(height: 200)
                .padding(ScaleSpacing.md)
                .background(ThemeManager.shared.currentTheme.cardBackground.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))

                // Stats
                weightStatsRow
            }
        }
        .onAppear {
            loadWeights()
        }
    }

    private var weightStatsRow: some View {
        HStack(spacing: ScaleSpacing.md) {
            statCard("Current", value: filteredWeights.first?.formattedWeight ?? "-")
            statCard("Min", value: filteredWeights.min(by: { $0.weightGrams < $1.weightGrams })?.formattedWeight ?? "-")
            statCard("Max", value: filteredWeights.max(by: { $0.weightGrams < $1.weightGrams })?.formattedWeight ?? "-")
        }
    }

    private func statCard(_ title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.scaleCaption)
                .foregroundStyle(themeManager.currentTheme.textTertiary)
            Text(value)
                .font(.scaleSubheadline)
                .foregroundStyle(Color.scaleTextPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(ScaleSpacing.sm)
        .background(ThemeManager.shared.currentTheme.cardBackground.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.sm))
    }

    private func loadWeights() {
        let predicate = #Predicate<Animal> { $0.id == animalID }
        let descriptor = FetchDescriptor<Animal>(predicate: predicate)

        if let animal = try? modelContext.fetch(descriptor).first {
            weights = animal.weights?.sorted(by: { $0.recordedAt > $1.recordedAt }) ?? []
        }
    }
}

// MARK: - Add Health Note View

struct AddHealthNoteView: View {
    let animalID: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var animal: Animal?
    @State private var noteType: HealthNoteType = .observation
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var recordedDate: Date = Date()

    // Vet visit fields
    @State private var vetName: String = ""
    @State private var vetClinic: String = ""
    @State private var diagnosis: String = ""
    @State private var treatment: String = ""
    @State private var cost: String = ""

    // Medication fields
    @State private var medicationName: String = ""
    @State private var medicationDosage: String = ""
    @State private var medicationStartDate: Date = Date()
    @State private var medicationEndDate: Date? = nil

    @State private var followUpDate: Date? = nil
    @State private var isResolved: Bool = false

    @State private var isLoading = true
    @State private var isSaving = false

    @FocusState private var focusedField: Field?

    enum Field {
        case title, content, vetName, vetClinic, diagnosis, treatment, cost, medName, medDosage
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                if isLoading {
                    ScaleLoadingState(message: "Loading...")
                } else {
                    ScrollView {
                        VStack(spacing: ScaleSpacing.lg) {
                            // Note type
                            noteTypeSection

                            // Basic info
                            basicInfoSection

                            // Type-specific fields
                            if noteType == .vetVisit {
                                vetVisitSection
                            }

                            if noteType == .medication {
                                medicationSection
                            }

                            // Follow-up
                            followUpSection

                            Color.clear.frame(height: 100)
                        }
                        .padding(.horizontal, ScaleSpacing.md)
                        .padding(.top, ScaleSpacing.md)
                    }
                }
            }
            .navigationTitle("Health Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveHealthNote()
                    }
                    .font(.headline)
                    .foregroundStyle(canSave ? themeManager.currentTheme.primaryAccent : themeManager.currentTheme.textDisabled)
                    .disabled(!canSave || isSaving)
                }

                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            focusedField = nil
                        }
                    }
                }
            }
            .onAppear {
                loadAnimal()
            }
            .scaleToastContainer()
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var noteTypeSection: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.md) {
            ScaleSectionHeader("Type")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ScaleSpacing.sm) {
                    ForEach(HealthNoteType.allCases, id: \.self) { type in
                        Button {
                            withAnimation(ScaleAnimation.fast) {
                                noteType = type
                            }
                            ScaleHaptics.light()
                        } label: {
                            VStack(spacing: ScaleSpacing.xs) {
                                Image(systemName: type.iconName)
                                    .font(.system(size: 20))
                                Text(type.displayName)
                                    .font(.scaleCaption)
                            }
                            .foregroundStyle(noteType == type ? themeManager.currentTheme.backgroundPrimary : Color.scaleTextSecondary)
                            .padding(.horizontal, ScaleSpacing.md)
                            .padding(.vertical, ScaleSpacing.sm)
                            .background(noteType == type ? themeManager.currentTheme.primaryAccent : themeManager.currentTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
                        }
                    }
                }
            }
        }
    }

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.md) {
            ScaleSectionHeader("Details")

            ScaleTextField(
                "Title",
                text: $title,
                placeholder: "Brief description",
                isRequired: true
            )
            .focused($focusedField, equals: .title)

            ScaleTextEditor(
                "Notes",
                text: $content,
                placeholder: "Detailed observations..."
            )

            ScaleDatePicker(
                "Date",
                date: $recordedDate,
                
            )
        }
    }

    private var vetVisitSection: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.md) {
            ScaleSectionHeader("Vet Visit Details")

            ScaleTextField(
                "Veterinarian",
                text: $vetName,
                placeholder: "Dr. Name",
                icon: "person.fill"
            )
            .focused($focusedField, equals: .vetName)

            ScaleTextField(
                "Clinic",
                text: $vetClinic,
                placeholder: "Clinic name",
                icon: "building.2.fill"
            )
            .focused($focusedField, equals: .vetClinic)

            ScaleTextField(
                "Diagnosis",
                text: $diagnosis,
                placeholder: "What was diagnosed?"
            )
            .focused($focusedField, equals: .diagnosis)

            ScaleTextEditor(
                "Treatment",
                text: $treatment,
                placeholder: "Treatment plan..."
            )

            ScaleTextField(
                "Cost",
                text: $cost,
                placeholder: "0.00",
                icon: "dollarsign.circle.fill"
            )
            .focused($focusedField, equals: .cost)
            .keyboardType(.decimalPad)
        }
    }

    private var medicationSection: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.md) {
            ScaleSectionHeader("Medication Details")

            ScaleTextField(
                "Medication Name",
                text: $medicationName,
                placeholder: "Name of medication",
                icon: "pills.fill",
                isRequired: true
            )
            .focused($focusedField, equals: .medName)

            ScaleTextField(
                "Dosage",
                text: $medicationDosage,
                placeholder: "e.g., 0.1ml twice daily",
                icon: "drop.fill"
            )
            .focused($focusedField, equals: .medDosage)

            ScaleDatePicker(
                "Start Date",
                date: $medicationStartDate,
                
            )

            ScaleOptionalDatePicker(
                "End Date",
                date: $medicationEndDate,
                placeholder: "Ongoing"
            )
        }
    }

    private var followUpSection: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.md) {
            ScaleSectionHeader("Follow-up")

            ScaleOptionalDatePicker(
                "Follow-up Date",
                date: $followUpDate,
                placeholder: "No follow-up scheduled"
            )

            ScaleToggleRow(
                "Issue Resolved",
                isOn: $isResolved,
                icon: "checkmark.circle.fill"
            )
        }
    }

    private func loadAnimal() {
        isLoading = true

        let predicate = #Predicate<Animal> { $0.id == animalID }
        let descriptor = FetchDescriptor<Animal>(predicate: predicate)

        animal = try? modelContext.fetch(descriptor).first
        isLoading = false
    }

    private func saveHealthNote() {
        guard let animal = animal, canSave else { return }

        isSaving = true

        let note = HealthNote(
            noteType: noteType,
            title: title.trimmingCharacters(in: .whitespaces),
            content: content.isEmpty ? nil : content
        )

        note.recordedAt = recordedDate
        note.animal = animal
        note.isResolved = isResolved
        note.followUpDate = followUpDate

        if noteType == .vetVisit {
            note.vetName = vetName.isEmpty ? nil : vetName
            note.vetClinic = vetClinic.isEmpty ? nil : vetClinic
            note.diagnosis = diagnosis.isEmpty ? nil : diagnosis
            note.treatment = treatment.isEmpty ? nil : treatment
            if let costValue = Decimal(string: cost) {
                note.cost = costValue
            }
        }

        if noteType == .medication {
            note.medicationName = medicationName.isEmpty ? nil : medicationName
            note.medicationDosage = medicationDosage.isEmpty ? nil : medicationDosage
            note.medicationStartDate = medicationStartDate
            note.medicationEndDate = medicationEndDate
        }

        animal.healthNotes?.append(note)

        do {
            try modelContext.save()
            ScaleToastManager.shared.success("Health note saved!")
            ScaleHaptics.success()
            dismiss()
        } catch {
            ScaleToastManager.shared.error("Failed to save health note")
            isSaving = false
        }
    }
}

// MARK: - Add Shed View

struct AddShedView: View {
    let animalID: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var animal: Animal?
    @State private var shedDate: Date = Date()
    @State private var bluePhaseStart: Date? = nil
    @State private var quality: ShedQuality = .complete
    @State private var selectedIssues: Set<ShedIssue> = []
    @State private var notes: String = ""

    @State private var isLoading = true
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                if isLoading {
                    ScaleLoadingState(message: "Loading...")
                } else {
                    ScrollView {
                        VStack(spacing: ScaleSpacing.lg) {
                            // Shed date
                            ScaleSectionHeader("Date")

                            ScaleDatePicker(
                                "Shed Date",
                                date: $shedDate,
                                
                            )

                            ScaleOptionalDatePicker(
                                "Blue Phase Started",
                                date: $bluePhaseStart,
                                placeholder: "Not tracked",
                                helpText: "When did you notice the animal going into blue?",
                                
                            )

                            // Quality
                            ScaleSectionHeader("Shed Quality")

                            ScaleSegmentedPicker(
                                selection: $quality,
                                options: ShedQuality.allCases
                            ) { q in
                                VStack(spacing: 2) {
                                    Image(systemName: q.iconName)
                                        .font(.system(size: 16))
                                    Text(q.displayName)
                                        .font(.scaleCaption)
                                }
                            }

                            // Issues
                            if quality != .complete {
                                ScaleSectionHeader("Problem Areas")

                                ScaleChipPicker(
                                    selection: $selectedIssues,
                                    options: ShedIssue.allCases
                                ) { issue in
                                    Text(issue.displayName)
                                }
                            }

                            // Notes
                            ScaleSectionHeader("Notes")

                            ScaleTextEditor(
                                "Notes",
                                text: $notes,
                                placeholder: "Any observations about this shed..."
                            )

                            Color.clear.frame(height: 100)
                        }
                        .padding(.horizontal, ScaleSpacing.md)
                        .padding(.top, ScaleSpacing.md)
                    }
                }
            }
            .navigationTitle("Log Shed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveShed()
                    }
                    .font(.headline)
                    .foregroundStyle(themeManager.currentTheme.primaryAccent)
                    .disabled(isSaving)
                }
            }
            .onAppear {
                loadAnimal()
            }
            .scaleToastContainer()
        }
    }

    private func loadAnimal() {
        isLoading = true

        let predicate = #Predicate<Animal> { $0.id == animalID }
        let descriptor = FetchDescriptor<Animal>(predicate: predicate)

        animal = try? modelContext.fetch(descriptor).first
        isLoading = false
    }

    private func saveShed() {
        guard let animal = animal else { return }

        isSaving = true

        let shed = ShedRecord(shedDate: shedDate, quality: quality)
        shed.bluePhaseStartDate = bluePhaseStart
        shed.animal = animal

        if !selectedIssues.isEmpty {
            shed.issues = Array(selectedIssues)
        }

        if !notes.isEmpty {
            shed.notes = notes
        }

        animal.sheds?.append(shed)

        do {
            try modelContext.save()
            ScaleToastManager.shared.success("Shed logged!")
            ScaleHaptics.success()
            dismiss()
        } catch {
            ScaleToastManager.shared.error("Failed to save shed")
            isSaving = false
        }
    }
}

// MARK: - Extensions

extension HealthNoteType {
    var displayName: String {
        switch self {
        case .observation: return "Observation"
        case .vetVisit: return "Vet Visit"
        case .medication: return "Medication"
        case .treatment: return "Treatment"
        case .injury: return "Injury"
        case .illness: return "Illness"
        case .parasite: return "Parasite"
        case .respiratoryIssue: return "Respiratory"
        case .scaleRot: return "Scale Rot"
        case .mites: return "Mites"
        case .burnInjury: return "Burn"
        case .mouthRot: return "Mouth Rot"
        case .other: return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .observation: return "eye.fill"
        case .vetVisit: return "stethoscope"
        case .medication: return "pills.fill"
        case .treatment: return "cross.case.fill"
        case .injury: return "bandage.fill"
        case .illness: return "heart.slash.fill"
        case .parasite: return "ant.fill"
        case .respiratoryIssue: return "lungs.fill"
        case .scaleRot: return "exclamationmark.triangle.fill"
        case .mites: return "ladybug.fill"
        case .burnInjury: return "flame.fill"
        case .mouthRot: return "mouth.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
}

extension ShedQuality {
    var displayName: String {
        switch self {
        case .complete: return "Complete"
        case .partial: return "Partial"
        case .stuck: return "Stuck"
        case .assisted: return "Assisted"
        }
    }

    var iconName: String {
        switch self {
        case .complete: return "checkmark.circle.fill"
        case .partial: return "circle.lefthalf.filled"
        case .stuck: return "exclamationmark.circle.fill"
        case .assisted: return "hand.raised.fill"
        }
    }
}

extension ShedIssue {
    var displayName: String {
        switch self {
        case .eyeCaps: return "Eye Caps"
        case .tailTip: return "Tail Tip"
        case .toes: return "Toes"
        case .bodyPatches: return "Body Patches"
        case .headArea: return "Head Area"
        }
    }
}

// MARK: - Previews

#Preview("Add Weight") {
    AddWeightView(animalID: UUID())
        .modelContainer(for: [Animal.self, WeightRecord.self], inMemory: true)
}

#Preview("Add Health Note") {
    AddHealthNoteView(animalID: UUID())
        .modelContainer(for: [Animal.self, HealthNote.self], inMemory: true)
}

#Preview("Add Shed") {
    AddShedView(animalID: UUID())
        .modelContainer(for: [Animal.self, ShedRecord.self], inMemory: true)
}
