import SwiftUI
import SwiftData
import ScaleCore
import ScaleUI

// MARK: - New Pairing View

struct NewPairingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var males: [Animal] = []
    @State private var females: [Animal] = []
    @State private var selectedMale: Animal? = nil
    @State private var selectedFemale: Animal? = nil
    @State private var introductionDate: Date = Date()
    @State private var breedingSeason: String = ""
    @State private var notes: String = ""

    @State private var isLoading = true
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                if isLoading {
                    ScaleLoadingState(message: "Loading animals...")
                } else {
                    ScrollView {
                        VStack(spacing: ScaleSpacing.lg) {
                            // Male selection
                            animalSelectionSection(
                                title: "Male",
                                animals: males,
                                selection: $selectedMale
                            )

                            // Female selection
                            animalSelectionSection(
                                title: "Female",
                                animals: females,
                                selection: $selectedFemale
                            )

                            // Introduction date
                            ScaleDatePicker(
                                "Introduction Date",
                                date: $introductionDate
                            )

                            // Season
                            ScaleTextField(
                                "Breeding Season",
                                text: $breedingSeason,
                                placeholder: "e.g., 2024-2025",
                                icon: "calendar"
                            )

                            // Notes
                            ScaleTextEditor(
                                "Notes",
                                text: $notes,
                                placeholder: "Observations about this pairing..."
                            )

                            Color.clear.frame(height: 100)
                        }
                        .padding(.horizontal, ScaleSpacing.md)
                        .padding(.top, ScaleSpacing.md)
                    }
                }
            }
            .navigationTitle("New Pairing")
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
                        savePairing()
                    }
                    .font(.headline)
                    .foregroundStyle(canSave ? themeManager.currentTheme.primaryAccent : themeManager.currentTheme.textDisabled)
                    .disabled(!canSave || isSaving)
                }
            }
            .onAppear {
                loadAnimals()
            }
            .scaleToastContainer()
        }
    }

    private var canSave: Bool {
        selectedMale != nil && selectedFemale != nil
    }

    private func animalSelectionSection(title: String, animals: [Animal], selection: Binding<Animal?>) -> some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.sm) {
            ScaleSectionHeader(title)

            if animals.isEmpty {
                Text("No \(title.lowercased())s available")
                    .font(.scaleBody)
                    .foregroundStyle(themeManager.currentTheme.textTertiary)
                    .padding(ScaleSpacing.md)
                    .frame(maxWidth: .infinity)
                    .background(Color.cardBackground.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ScaleSpacing.sm) {
                        ForEach(animals) { animal in
                            Button {
                                selection.wrappedValue = animal
                                ScaleHaptics.light()
                            } label: {
                                VStack(spacing: ScaleSpacing.xs) {
                                    Circle()
                                        .fill(selection.wrappedValue?.id == animal.id ? ThemeManager.shared.currentTheme.primaryAccent : ThemeManager.shared.currentTheme.cardBackground)
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            Image(systemName: "pawprint.fill")
                                                .foregroundStyle(selection.wrappedValue?.id == animal.id ? Color.substrateDark : themeManager.currentTheme.textTertiary)
                                        )

                                    Text(animal.name)
                                        .font(.scaleCaption)
                                        .foregroundStyle(Color.scaleTextPrimary)
                                        .lineLimit(1)

                                    if let morph = animal.morph {
                                        Text(morph)
                                            .font(.scaleCaption2)
                                            .foregroundStyle(themeManager.currentTheme.textTertiary)
                                            .lineLimit(1)
                                    }
                                }
                                .frame(width: 80)
                            }
                        }
                    }
                    .padding(.horizontal, ScaleSpacing.xs)
                }
            }
        }
    }

    private func loadAnimals() {
        isLoading = true

        let descriptor = FetchDescriptor<Animal>()

        if let allAnimals = try? modelContext.fetch(descriptor) {
            males = allAnimals.filter { $0.sex == .male || $0.sex == .suspectedMale }
            females = allAnimals.filter { $0.sex == .female || $0.sex == .suspectedFemale }
        }

        isLoading = false
    }

    private func savePairing() {
        guard let male = selectedMale, let female = selectedFemale else { return }

        isSaving = true

        let pairing = Pairing(maleID: male.id, femaleID: female.id)
        pairing.introductionDate = introductionDate
        pairing.breedingSeason = breedingSeason.isEmpty ? nil : breedingSeason
        pairing.notes = notes.isEmpty ? nil : notes
        pairing.status = .active

        modelContext.insert(pairing)

        do {
            try modelContext.save()
            ScaleToastManager.shared.success("Pairing created!")
            ScaleHaptics.success()
            dismiss()
        } catch {
            ScaleToastManager.shared.error("Failed to save pairing")
            isSaving = false
        }
    }
}

// MARK: - Edit Pairing View

struct EditPairingView: View {
    let pairingID: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var pairing: Pairing?
    @State private var status: PairingStatus = .active
    @State private var separationDate: Date? = nil
    @State private var notes: String = ""

    @State private var isLoading = true
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                if isLoading {
                    ScaleLoadingState(message: "Loading...")
                } else if let pairing = pairing {
                    ScrollView {
                        VStack(spacing: ScaleSpacing.lg) {
                            // Status
                            ScalePicker(
                                "Status",
                                selection: $status,
                                options: PairingStatus.allCases
                            ) { status in
                                Text(status.displayName)
                            }

                            // Separation date
                            ScaleOptionalDatePicker(
                                "Separation Date",
                                date: $separationDate,
                                placeholder: "Not separated yet"
                            )

                            // Notes
                            ScaleTextEditor(
                                "Notes",
                                text: $notes,
                                placeholder: "Update notes..."
                            )

                            Color.clear.frame(height: 100)
                        }
                        .padding(.horizontal, ScaleSpacing.md)
                        .padding(.top, ScaleSpacing.md)
                    }
                } else {
                    ScaleEmptyState.error {
                        loadPairing()
                    }
                }
            }
            .navigationTitle("Edit Pairing")
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
                        saveChanges()
                    }
                    .font(.headline)
                    .foregroundStyle(themeManager.currentTheme.primaryAccent)
                    .disabled(isSaving)
                }
            }
            .onAppear {
                loadPairing()
            }
            .scaleToastContainer()
        }
    }

    private func loadPairing() {
        isLoading = true

        let predicate = #Predicate<Pairing> { $0.id == pairingID }
        let descriptor = FetchDescriptor<Pairing>(predicate: predicate)

        if let fetchedPairing = try? modelContext.fetch(descriptor).first {
            pairing = fetchedPairing
            status = fetchedPairing.status
            separationDate = fetchedPairing.separationDate
            notes = fetchedPairing.notes ?? ""
        }

        isLoading = false
    }

    private func saveChanges() {
        guard let pairing = pairing else { return }

        isSaving = true

        pairing.status = status
        pairing.separationDate = separationDate
        pairing.notes = notes.isEmpty ? nil : notes
        pairing.updatedAt = Date()

        do {
            try modelContext.save()
            ScaleToastManager.shared.success("Pairing updated!")
            ScaleHaptics.success()
            dismiss()
        } catch {
            ScaleToastManager.shared.error("Failed to save changes")
            isSaving = false
        }
    }
}

// MARK: - Add Clutch View

struct AddClutchView: View {
    let pairingID: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var pairing: Pairing?
    @State private var layDate: Date = Date()
    @State private var totalEggs: Int = 0
    @State private var fertileEggs: Int = 0
    @State private var infertileEggs: Int = 0
    @State private var slugs: Int = 0
    @State private var incubationTemp: Double = 88.0
    @State private var incubationHumidity: Int = 90
    @State private var incubationMethod: IncubationMethod = .incubator
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
                            // Lay date
                            ScaleDatePicker(
                                "Lay Date",
                                date: $layDate,
                                isRequired: true
                            )

                            // Egg counts
                            ScaleSectionHeader("Egg Count")

                            ScaleStepper(
                                "Total Eggs",
                                value: $totalEggs,
                                range: 0...50,
                                icon: "circle.grid.3x3.fill"
                            )

                            ScaleStepper(
                                "Fertile Eggs",
                                value: $fertileEggs,
                                range: 0...50,
                                icon: "checkmark.circle.fill"
                            )

                            ScaleStepper(
                                "Infertile Eggs",
                                value: $infertileEggs,
                                range: 0...50,
                                icon: "xmark.circle.fill"
                            )

                            ScaleStepper(
                                "Slugs",
                                value: $slugs,
                                range: 0...50,
                                icon: "drop.fill"
                            )

                            // Incubation settings
                            ScaleSectionHeader("Incubation")

                            ScalePicker(
                                "Method",
                                selection: $incubationMethod,
                                options: IncubationMethod.allCases
                            ) { method in
                                Text(method.displayName)
                            }

                            ScaleNumberField(
                                "Temperature",
                                value: $incubationTemp,
                                unit: "°F",
                                icon: "thermometer.medium",
                                range: 70...100,
                                step: 0.5,
                                decimalPlaces: 1
                            )

                            ScaleStepper(
                                "Humidity %",
                                value: $incubationHumidity,
                                range: 50...100,
                                icon: "humidity.fill"
                            )

                            // Notes
                            ScaleTextEditor(
                                "Notes",
                                text: $notes,
                                placeholder: "Any observations about this clutch..."
                            )

                            Color.clear.frame(height: 100)
                        }
                        .padding(.horizontal, ScaleSpacing.md)
                        .padding(.top, ScaleSpacing.md)
                    }
                }
            }
            .navigationTitle("Add Clutch")
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
                        saveClutch()
                    }
                    .font(.headline)
                    .foregroundStyle(totalEggs > 0 ? themeManager.currentTheme.primaryAccent : themeManager.currentTheme.textDisabled)
                    .disabled(totalEggs <= 0 || isSaving)
                }
            }
            .onAppear {
                loadPairing()
            }
            .scaleToastContainer()
        }
    }

    private func loadPairing() {
        isLoading = true

        let predicate = #Predicate<Pairing> { $0.id == pairingID }
        let descriptor = FetchDescriptor<Pairing>(predicate: predicate)

        pairing = try? modelContext.fetch(descriptor).first
        isLoading = false
    }

    private func saveClutch() {
        guard let pairing = pairing, totalEggs > 0 else { return }

        isSaving = true

        let clutch = Clutch(
            layDate: layDate,
            totalEggs: totalEggs
        )

        clutch.fertileEggs = fertileEggs
        clutch.infertileEggs = infertileEggs
        clutch.slugs = slugs
        clutch.incubationTempF = incubationTemp
        clutch.incubationHumidity = incubationHumidity
        clutch.incubationMethod = incubationMethod
        clutch.incubationStartDate = layDate
        clutch.pairing = pairing
        // status is already .incubating from init

        if !notes.isEmpty {
            clutch.notes = notes
        }

        pairing.clutches?.append(clutch)
        pairing.status = .successful

        do {
            try modelContext.save()
            ScaleToastManager.shared.success("Clutch recorded!")
            ScaleHaptics.success()
            dismiss()
        } catch {
            ScaleToastManager.shared.error("Failed to save clutch")
            isSaving = false
        }
    }
}

// MARK: - Previews

#Preview("New Pairing") {
    NewPairingView()
        .modelContainer(for: [Animal.self, Pairing.self], inMemory: true)
}

#Preview("Add Clutch") {
    AddClutchView(pairingID: UUID())
        .modelContainer(for: [Pairing.self, Clutch.self], inMemory: true)
}
