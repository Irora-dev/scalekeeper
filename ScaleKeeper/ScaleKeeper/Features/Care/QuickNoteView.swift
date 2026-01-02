import SwiftUI
import SwiftData
import ScaleCore
import ScaleUI

// MARK: - Quick Note View

struct QuickNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var themeManager = ThemeManager.shared

    // Optional pre-selected animal
    let preselectedAnimalID: UUID?

    @State private var selectedAnimal: Animal?
    @State private var noteContent: String = ""
    @State private var noteType: HealthNoteType = .observation
    @State private var animals: [Animal] = []
    @State private var isSaving = false
    @State private var showingAnimalPicker = false

    @FocusState private var isNoteFocused: Bool

    init(animalID: UUID? = nil) {
        self.preselectedAnimalID = animalID
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                ScrollView {
                    VStack(spacing: ScaleSpacing.lg) {
                        // Animal Selector
                        animalSelector

                        // Note Type Selector
                        noteTypeSelector

                        // Note Content
                        noteEditor

                        // Quick Templates
                        quickTemplates

                        // Save Button
                        ScalePrimaryButton(
                            "Save Note",
                            icon: "checkmark.circle.fill",
                            isLoading: isSaving,
                            isDisabled: !canSave
                        ) {
                            saveNote()
                        }
                        .padding(.top, ScaleSpacing.md)
                    }
                    .padding(ScaleSpacing.lg)
                }
            }
            .navigationTitle("Quick Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                }
            }
            .onAppear {
                loadAnimals()
            }
            .sheet(isPresented: $showingAnimalPicker) {
                AnimalPickerSheet(
                    animals: animals,
                    selectedAnimal: $selectedAnimal
                )
            }
        }
    }

    // MARK: - Animal Selector

    private var animalSelector: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.sm) {
            HStack {
                Text("Animal")
                    .font(.scaleSubheadline)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                Text("*")
                    .foregroundColor(.scaleError)
            }

            Button {
                showingAnimalPicker = true
            } label: {
                HStack {
                    if let animal = selectedAnimal {
                        Circle()
                            .fill(ThemeManager.shared.currentTheme.primaryAccent.opacity(0.2))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "pawprint.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(ThemeManager.shared.currentTheme.primaryAccent)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(animal.name)
                                .font(.scaleBody)
                                .foregroundColor(.scaleTextPrimary)
                            if let morph = animal.morph {
                                Text(morph)
                                    .font(.scaleCaption)
                                    .foregroundColor(themeManager.currentTheme.textTertiary)
                            }
                        }
                    } else {
                        Image(systemName: "pawprint")
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                        Text("Select an animal")
                            .font(.scaleBody)
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }
                .padding(ScaleSpacing.md)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: ScaleRadius.md)
                        .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Note Type Selector

    private var noteTypeSelector: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.sm) {
            Text("Type")
                .font(.scaleSubheadline)
                .foregroundColor(themeManager.currentTheme.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ScaleSpacing.sm) {
                    ForEach(quickNoteTypes, id: \.self) { type in
                        NoteTypeChip(
                            type: type,
                            isSelected: noteType == type
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                noteType = type
                            }
                            ScaleHaptics.light()
                        }
                    }
                }
            }
        }
    }

    private var quickNoteTypes: [HealthNoteType] {
        [.observation, .medication, .treatment, .illness, .injury, .vetVisit, .other]
    }

    // MARK: - Note Editor

    private var noteEditor: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.sm) {
            Text("Note")
                .font(.scaleSubheadline)
                .foregroundColor(themeManager.currentTheme.textSecondary)

            TextEditor(text: $noteContent)
                .font(.scaleBody)
                .foregroundColor(.scaleTextPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 150)
                .padding(ScaleSpacing.md)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: ScaleRadius.md)
                        .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
                )
                .focused($isNoteFocused)
                .overlay(
                    Group {
                        if noteContent.isEmpty {
                            Text("Write your note here...")
                                .font(.scaleBody)
                                .foregroundColor(themeManager.currentTheme.textTertiary)
                                .padding(.horizontal, ScaleSpacing.md)
                                .padding(.vertical, ScaleSpacing.md + 8)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
        }
    }

    // MARK: - Quick Templates

    private var quickTemplates: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.sm) {
            Text("Quick Templates")
                .font(.scaleCaption)
                .foregroundColor(themeManager.currentTheme.textTertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ScaleSpacing.sm) {
                    TemplateChip(text: "Looking healthy") { noteContent = "Looking healthy today. Good coloring and activity level." }
                    TemplateChip(text: "In blue") { noteContent = "Eyes are cloudy - entering shed cycle." }
                    TemplateChip(text: "Good appetite") { noteContent = "Feeding response was excellent today." }
                    TemplateChip(text: "Refused food") { noteContent = "Refused food today. Will try again in a few days." }
                    TemplateChip(text: "Active today") { noteContent = "Very active and exploring enclosure." }
                    TemplateChip(text: "Hiding") { noteContent = "Spending more time in hide. Monitoring behavior." }
                }
            }
        }
    }

    // MARK: - Helpers

    private var canSave: Bool {
        selectedAnimal != nil && !noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func loadAnimals() {
        let descriptor = FetchDescriptor<Animal>(sortBy: [SortDescriptor(\.name)])
        animals = (try? modelContext.fetch(descriptor)) ?? []

        // Pre-select animal if provided
        if let preselectedID = preselectedAnimalID {
            selectedAnimal = animals.first { $0.id == preselectedID }
        }
    }

    private func saveNote() {
        guard let animal = selectedAnimal, canSave else { return }

        isSaving = true

        let note = HealthNote(
            recordedAt: Date(),
            noteType: noteType,
            title: noteType.displayName,
            content: noteContent.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        note.animal = animal

        modelContext.insert(note)

        do {
            try modelContext.save()
            ScaleToastManager.shared.success("Note saved!")
            ScaleHaptics.success()
            appState.triggerDataRefresh()
            dismiss()
        } catch {
            ScaleToastManager.shared.error("Failed to save note")
            isSaving = false
        }
    }
}

// MARK: - Note Type Chip

struct NoteTypeChip: View {
    let type: HealthNoteType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: ScaleSpacing.xs) {
                Image(systemName: type.iconName)
                    .font(.system(size: 12))
                Text(type.displayName)
                    .font(.scaleButtonSmall)
            }
            .foregroundColor(isSelected ? .substrateDark : type.color)
            .padding(.horizontal, ScaleSpacing.md)
            .padding(.vertical, ScaleSpacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? type.color : type.color.opacity(0.15))
            )
        }
    }
}

// MARK: - Template Chip

struct TemplateChip: View {
    let text: String
    let action: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.scaleCaption)
                .foregroundColor(themeManager.currentTheme.textSecondary)
                .padding(.horizontal, ScaleSpacing.md)
                .padding(.vertical, ScaleSpacing.sm)
                .background(
                    Capsule()
                        .fill(Color.cardBackground)
                        .overlay(
                            Capsule()
                                .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - Animal Picker Sheet

struct AnimalPickerSheet: View {
    let animals: [Animal]
    @Binding var selectedAnimal: Animal?
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var searchText = ""

    var filteredAnimals: [Animal] {
        if searchText.isEmpty {
            return animals
        }
        return animals.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.morph?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                if filteredAnimals.isEmpty {
                    VStack(spacing: ScaleSpacing.md) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                        Text("No animals found")
                            .font(.scaleSubheadline)
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                    }
                } else {
                    List {
                        ForEach(filteredAnimals) { animal in
                            Button {
                                selectedAnimal = animal
                                ScaleHaptics.light()
                                dismiss()
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(ThemeManager.shared.currentTheme.primaryAccent.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Image(systemName: "pawprint.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(ThemeManager.shared.currentTheme.primaryAccent)
                                        )

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(animal.name)
                                            .font(.scaleBody)
                                            .foregroundColor(.scaleTextPrimary)
                                        if let morph = animal.morph {
                                            Text(morph)
                                                .font(.scaleCaption)
                                                .foregroundColor(themeManager.currentTheme.textTertiary)
                                        }
                                    }

                                    Spacer()

                                    if selectedAnimal?.id == animal.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(ThemeManager.shared.currentTheme.primaryAccent)
                                    }
                                }
                                .padding(.vertical, ScaleSpacing.xs)
                            }
                            .listRowBackground(Color.cardBackground.opacity(0.5))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Select Animal")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search animals")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                }
            }
        }
    }
}

// MARK: - Health Note Type Color Extension

extension HealthNoteType {
    var color: Color {
        switch self {
        case .observation: return .nebulaCyan
        case .vetVisit: return .scaleError
        case .medication: return .nebulaMagenta
        case .treatment: return .nebulaPurple
        case .injury: return .scaleWarning
        case .illness: return .heatLampAmber
        case .parasite: return .nebulaLavender
        case .respiratoryIssue: return .nebulaCyan
        case .scaleRot: return .scaleMuted
        case .mites: return .nebulaGold
        case .burnInjury: return .scaleError
        case .mouthRot: return .scaleWarning
        case .other: return .scaleMuted
        }
    }
}

// MARK: - Preview

#Preview {
    QuickNoteView()
        .environmentObject(AppState())
        .modelContainer(for: [Animal.self, HealthNote.self], inMemory: true)
}
