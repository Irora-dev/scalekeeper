import SwiftUI
import SwiftData
import ScaleCore
import ScaleUI

// MARK: - Add Animal View

struct AddAnimalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var themeManager = ThemeManager.shared

    // Form state
    @State private var name: String = ""
    @State private var selectedSpecies: Species? = nil
    @State private var sex: AnimalSex = .unknown
    @State private var morph: String = ""
    @State private var hatchDate: Date? = nil
    @State private var acquisitionDate: Date = Date()
    @State private var acquisitionSource: String = ""
    @State private var acquisitionPrice: String = ""
    @State private var notes: String = ""
    @State private var selectedImage: UIImage? = nil

    // UI state
    @State private var showingSpeciesPicker = false
    @State private var isSaving = false
    @State private var showValidationError = false
    @State private var validationMessage = ""

    @FocusState private var focusedField: Field?

    enum Field {
        case name, morph, source, price, notes
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                ScrollView {
                    VStack(spacing: ScaleSpacing.lg) {
                        // Photo section
                        photoSection

                        // Basic info section
                        basicInfoSection

                        // Details section
                        detailsSection

                        // Acquisition section
                        acquisitionSection

                        // Notes section
                        notesSection

                        // Save button at bottom
                        VStack(spacing: ScaleSpacing.md) {
                            ScalePrimaryButton(
                                "Save Animal",
                                icon: "checkmark.circle.fill",
                                isLoading: isSaving,
                                isDisabled: !canSave
                            ) {
                                saveAnimal()
                            }
                        }
                        .padding(.top, ScaleSpacing.lg)

                        // Spacer for keyboard
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, ScaleSpacing.md)
                    .padding(.top, ScaleSpacing.md)
                }
            }
            .navigationTitle("Add Animal")
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
                        saveAnimal()
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
            .sheet(isPresented: $showingSpeciesPicker) {
                SpeciesPickerView(selectedSpecies: $selectedSpecies)
            }
            .alert("Validation Error", isPresented: $showValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
            .scaleToastContainer()
        }
    }

    // MARK: - Sections

    private var photoSection: some View {
        ScalePhotoPicker(
            "Photo",
            selectedImage: $selectedImage,
            placeholder: "Add a photo of your animal"
        )
    }

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.md) {
            ScaleSectionHeader("Basic Information")

            ScaleTextField(
                "Name",
                text: $name,
                placeholder: "Enter animal name",
                icon: "pawprint.fill",
                isRequired: true
            )
            .focused($focusedField, equals: .name)
            .autocapitalization(.words)

            // Species picker button
            VStack(alignment: .leading, spacing: ScaleSpacing.xs) {
                HStack(spacing: ScaleSpacing.xs) {
                    Text("Species")
                        .font(Font.scaleSubheadline)
                        .foregroundStyle(themeManager.currentTheme.textSecondary)

                    Text("*")
                        .font(Font.scaleSubheadline)
                        .foregroundStyle(Color.scaleError)
                }

                Button {
                    showingSpeciesPicker = true
                    ScaleHaptics.light()
                } label: {
                    HStack {
                        Image(systemName: selectedSpecies?.category.iconName ?? "questionmark.circle")
                            .font(.system(size: 16))
                            .foregroundStyle(selectedSpecies != nil ? themeManager.currentTheme.primaryAccent : Color.scaleTextTertiary)

                        if let species = selectedSpecies {
                            Text(species.commonName)
                                .font(Font.scaleBody)
                                .foregroundStyle(Color.scaleTextPrimary)
                        } else {
                            Text("Select species")
                                .font(Font.scaleBody)
                                .foregroundStyle(themeManager.currentTheme.textTertiary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundStyle(themeManager.currentTheme.textTertiary)
                    }
                    .padding(.horizontal, ScaleSpacing.md)
                    .padding(.vertical, ScaleSpacing.sm)
                    .background(themeManager.currentTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: ScaleRadius.md)
                            .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
                    )
                }
            }

            ScalePicker(
                "Sex",
                selection: $sex,
                options: AnimalSex.allCases,
                isRequired: false,
                helpText: "You can update this later if unsure"
            ) { sex in
                HStack(spacing: ScaleSpacing.sm) {
                    Text(sex.symbol)
                        .font(.system(size: 16))
                    Text(sex.displayName)
                        .font(Font.scaleBody)
                }
            }
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.md) {
            ScaleSectionHeader("Details")

            ScaleTextField(
                "Morph/Genetics",
                text: $morph,
                placeholder: "e.g., Pastel Banana, Normal, etc.",
                icon: "paintpalette.fill"
            )
            .focused($focusedField, equals: .morph)
            .autocapitalization(.words)

            ScaleOptionalDatePicker(
                "Hatch/Birth Date",
                date: $hatchDate,
                placeholder: "Select date if known",
                helpText: "Used to calculate age"
            )
        }
    }

    private var acquisitionSection: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.md) {
            ScaleSectionHeader("Acquisition")

            ScaleDatePicker(
                "Acquisition Date",
                date: $acquisitionDate,
                helpText: "When did you acquire this animal?"
            )

            ScaleTextField(
                "Source/Breeder",
                text: $acquisitionSource,
                placeholder: "Where did you get this animal?",
                icon: "person.fill"
            )
            .focused($focusedField, equals: .source)
            .autocapitalization(.words)

            ScaleTextField(
                "Price Paid",
                text: $acquisitionPrice,
                placeholder: "Optional",
                icon: "dollarsign.circle.fill"
            )
            .focused($focusedField, equals: .price)
            .keyboardType(.decimalPad)
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.md) {
            ScaleSectionHeader("Notes")

            ScaleTextEditor(
                "Notes",
                text: $notes,
                placeholder: "Any additional information about this animal...",
                helpText: "Care preferences, temperament, history, etc."
            )
        }
    }

    // MARK: - Validation

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && selectedSpecies != nil
    }

    // MARK: - Save

    private func saveAnimal() {
        guard canSave else {
            validationMessage = "Please enter a name and select a species."
            showValidationError = true
            return
        }

        isSaving = true

        let animal = Animal(
            name: name.trimmingCharacters(in: .whitespaces),
            speciesID: selectedSpecies!.id,
            sex: sex
        )

        animal.morph = morph.isEmpty ? nil : morph
        animal.hatchDate = hatchDate
        animal.acquisitionDate = acquisitionDate
        animal.acquisitionSource = acquisitionSource.isEmpty ? nil : acquisitionSource

        if let price = Decimal(string: acquisitionPrice) {
            animal.acquisitionPrice = price
        }

        animal.notes = notes.isEmpty ? nil : notes

        // TODO: Save photo if selected

        modelContext.insert(animal)

        do {
            try modelContext.save()
            ScaleToastManager.shared.success("Animal added successfully!")
            ScaleHaptics.success()
            appState.triggerDataRefresh()
            dismiss()
        } catch {
            ScaleToastManager.shared.error("Failed to save animal")
            isSaving = false
        }
    }
}

// MARK: - Species Picker View

struct SpeciesPickerView: View {
    @Binding var selectedSpecies: Species?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var searchText = ""
    @State private var selectedCategory: SpeciesCategory? = nil
    @State private var species: [Species] = []

    var filteredSpecies: [Species] {
        var result = species

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.commonName.localizedCaseInsensitiveContains(searchText) ||
                $0.scientificName.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result.sorted { $0.commonName < $1.commonName }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                VStack(spacing: 0) {
                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: ScaleSpacing.sm) {
                            categoryChip(nil, label: "All")
                            ForEach(SpeciesCategory.allCases, id: \.self) { category in
                                categoryChip(category, label: category.displayName)
                            }
                        }
                        .padding(.horizontal, ScaleSpacing.md)
                        .padding(.vertical, ScaleSpacing.sm)
                    }

                    ScaleDivider()

                    // Species list
                    if filteredSpecies.isEmpty {
                        ScaleEmptyState(
                            icon: "magnifyingglass",
                            title: "No Species Found",
                            message: "Try adjusting your search or category filter."
                        )
                    } else {
                        List {
                            ForEach(filteredSpecies) { species in
                                Button {
                                    selectedSpecies = species
                                    ScaleHaptics.light()
                                    dismiss()
                                } label: {
                                    HStack(spacing: ScaleSpacing.md) {
                                        Image(systemName: species.category.iconName)
                                            .font(.system(size: 20))
                                            .foregroundStyle(species.category.color)
                                            .frame(width: 32)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(species.commonName)
                                                .font(Font.scaleBody)
                                                .foregroundStyle(Color.scaleTextPrimary)

                                            Text(species.scientificName)
                                                .font(Font.scaleCaption)
                                                .foregroundStyle(themeManager.currentTheme.textTertiary)
                                                .italic()
                                        }

                                        Spacer()

                                        if selectedSpecies?.id == species.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(themeManager.currentTheme.primaryAccent)
                                        }
                                    }
                                    .padding(.vertical, ScaleSpacing.xs)
                                }
                                .listRowBackground(themeManager.currentTheme.cardBackground.opacity(0.5))
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Select Species")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search species")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
                }
            }
            .onAppear {
                loadSpecies()
            }
        }
    }

    private func categoryChip(_ category: SpeciesCategory?, label: String) -> some View {
        Button {
            withAnimation(ScaleAnimation.fast) {
                selectedCategory = category
            }
            ScaleHaptics.light()
        } label: {
            Text(label)
                .font(Font.scaleButtonSmall)
                .foregroundStyle(selectedCategory == category ? themeManager.currentTheme.backgroundPrimary : Color.scaleTextSecondary)
                .padding(.horizontal, ScaleSpacing.md)
                .padding(.vertical, ScaleSpacing.sm)
                .background(selectedCategory == category ? themeManager.currentTheme.primaryAccent : themeManager.currentTheme.cardBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(selectedCategory == category ? themeManager.currentTheme.primaryAccent : themeManager.currentTheme.borderColor, lineWidth: 1)
                )
        }
    }

    private func loadSpecies() {
        let descriptor = FetchDescriptor<Species>(sortBy: [SortDescriptor(\.commonName)])
        species = (try? modelContext.fetch(descriptor)) ?? []

        // If no species exist, seed with defaults
        if species.isEmpty {
            seedDefaultSpecies()
        }
    }

    private func seedDefaultSpecies() {
        // Seed a few common species for now
        // Full database will be added in Phase 8
        let defaultSpecies = [
            Species(commonName: "Ball Python", scientificName: "Python regius", category: .snake),
            Species(commonName: "Corn Snake", scientificName: "Pantherophis guttatus", category: .snake),
            Species(commonName: "Leopard Gecko", scientificName: "Eublepharis macularius", category: .gecko),
            Species(commonName: "Bearded Dragon", scientificName: "Pogona vitticeps", category: .lizard),
            Species(commonName: "Crested Gecko", scientificName: "Correlophus ciliatus", category: .gecko),
            Species(commonName: "Boa Constrictor", scientificName: "Boa constrictor", category: .snake),
            Species(commonName: "Red-Tailed Boa", scientificName: "Boa constrictor constrictor", category: .snake),
            Species(commonName: "Blue Tongue Skink", scientificName: "Tiliqua scincoides", category: .lizard),
            Species(commonName: "Russian Tortoise", scientificName: "Testudo horsfieldii", category: .tortoise),
            Species(commonName: "Red-Eared Slider", scientificName: "Trachemys scripta elegans", category: .turtle)
        ]

        for sp in defaultSpecies {
            modelContext.insert(sp)
        }

        try? modelContext.save()
        species = defaultSpecies.sorted { $0.commonName < $1.commonName }
    }
}

// MARK: - Species Category Extension

extension SpeciesCategory {
    var displayName: String {
        switch self {
        case .snake: return "Snakes"
        case .lizard: return "Lizards"
        case .gecko: return "Geckos"
        case .tortoise: return "Tortoises"
        case .turtle: return "Turtles"
        case .crocodilian: return "Crocodilians"
        case .frog: return "Frogs"
        case .salamander: return "Salamanders"
        case .invertebrate: return "Invertebrates"
        case .other: return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .snake: return "line.diagonal"
        case .lizard: return "lizard.fill"
        case .gecko: return "pawprint.fill"
        case .tortoise: return "tortoise.fill"
        case .turtle: return "tortoise.fill"
        case .crocodilian: return "water.waves"
        case .frog: return "leaf.fill"
        case .salamander: return "drop.fill"
        case .invertebrate: return "ant.fill"
        case .other: return "questionmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .snake: return .snakeColor
        case .lizard: return .lizardColor
        case .gecko: return .geckoColor
        case .tortoise: return .tortoiseColor
        case .turtle: return .tortoiseColor
        case .crocodilian: return .scaleTeal
        case .frog: return .frogColor
        case .salamander: return .frogColor
        case .invertebrate: return .invertebrateColor
        case .other: return .scaleMuted
        }
    }
}

// MARK: - Edit Animal View

struct EditAnimalView: View {
    let animalID: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var animal: Animal?
    @State private var name: String = ""
    @State private var selectedSpecies: Species? = nil
    @State private var sex: AnimalSex = .unknown
    @State private var morph: String = ""
    @State private var hatchDate: Date? = nil
    @State private var notes: String = ""

    @State private var showingSpeciesPicker = false
    @State private var isSaving = false
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                if isLoading {
                    ScaleLoadingState(message: "Loading...")
                } else if let animal = animal {
                    ScrollView {
                        VStack(spacing: ScaleSpacing.lg) {
                            ScaleTextField(
                                "Name",
                                text: $name,
                                placeholder: "Enter animal name",
                                icon: "pawprint.fill",
                                isRequired: true
                            )

                            ScalePicker(
                                "Sex",
                                selection: $sex,
                                options: AnimalSex.allCases
                            ) { sex in
                                HStack(spacing: ScaleSpacing.sm) {
                                    Text(sex.symbol)
                                        .font(.system(size: 16))
                                    Text(sex.displayName)
                                        .font(Font.scaleBody)
                                }
                            }

                            ScaleTextField(
                                "Morph/Genetics",
                                text: $morph,
                                placeholder: "e.g., Pastel Banana",
                                icon: "paintpalette.fill"
                            )

                            ScaleOptionalDatePicker(
                                "Hatch/Birth Date",
                                date: $hatchDate,
                                placeholder: "Select date if known"
                            )

                            ScaleTextEditor(
                                "Notes",
                                text: $notes,
                                placeholder: "Any additional information..."
                            )
                        }
                        .padding(.horizontal, ScaleSpacing.md)
                        .padding(.top, ScaleSpacing.md)
                    }
                } else {
                    ScaleEmptyState.error {
                        loadAnimal()
                    }
                }
            }
            .navigationTitle("Edit Animal")
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
                    .foregroundStyle(canSave ? themeManager.currentTheme.primaryAccent : themeManager.currentTheme.textDisabled)
                    .disabled(!canSave || isSaving)
                }
            }
            .onAppear {
                loadAnimal()
            }
            .scaleToastContainer()
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func loadAnimal() {
        isLoading = true

        let predicate = #Predicate<Animal> { $0.id == animalID }
        let descriptor = FetchDescriptor<Animal>(predicate: predicate)

        if let fetchedAnimal = try? modelContext.fetch(descriptor).first {
            animal = fetchedAnimal
            name = fetchedAnimal.name
            sex = fetchedAnimal.sex
            morph = fetchedAnimal.morph ?? ""
            hatchDate = fetchedAnimal.hatchDate
            notes = fetchedAnimal.notes ?? ""
        }

        isLoading = false
    }

    private func saveChanges() {
        guard let animal = animal, canSave else { return }

        isSaving = true

        animal.name = name.trimmingCharacters(in: .whitespaces)
        animal.sex = sex
        animal.morph = morph.isEmpty ? nil : morph
        animal.hatchDate = hatchDate
        animal.notes = notes.isEmpty ? nil : notes
        animal.updatedAt = Date()

        do {
            try modelContext.save()
            ScaleToastManager.shared.success("Changes saved!")
            ScaleHaptics.success()
            dismiss()
        } catch {
            ScaleToastManager.shared.error("Failed to save changes")
            isSaving = false
        }
    }
}

// MARK: - Previews

#Preview("Add Animal") {
    AddAnimalView()
        .modelContainer(for: [Animal.self, Species.self], inMemory: true)
        .environmentObject(AppState())
}

#Preview("Species Picker") {
    SpeciesPickerView(selectedSpecies: .constant(nil))
        .modelContainer(for: Species.self, inMemory: true)
}
