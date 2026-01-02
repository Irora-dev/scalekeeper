import SwiftUI
import SwiftData
import ScaleCore
import ScaleUI

// MARK: - Quick Actions Hub View

struct QuickActionsHubView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedAnimalID: UUID?
    @State private var showingAnimalPicker = false
    @State private var pendingAction: QuickAction?

    var body: some View {
        NavigationStack {
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }

                VStack {
                    Spacer()

                    // Bottom sheet content
                    VStack(spacing: ScaleSpacing.lg) {
                        // Handle
                        RoundedRectangle(cornerRadius: 3)
                            .fill(themeManager.currentTheme.textTertiary.opacity(0.5))
                            .frame(width: 40, height: 5)
                            .padding(.top, ScaleSpacing.md)

                        // Title
                        Text("Quick Log")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.scaleTextPrimary)

                        // Action Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: ScaleSpacing.md) {
                            ForEach(QuickAction.allCases, id: \.self) { action in
                                HubQuickActionButton(action: action) {
                                    handleAction(action)
                                }
                            }
                        }
                        .padding(.horizontal, ScaleSpacing.md)

                        // Cancel button
                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, ScaleSpacing.md)
                        }
                        .padding(.bottom, ScaleSpacing.lg)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(themeManager.currentTheme.backgroundPrimary)
                            .ignoresSafeArea(edges: .bottom)
                    )
                }
            }
            .sheet(isPresented: $showingAnimalPicker) {
                AnimalPickerView(selectedAnimalID: $selectedAnimalID) {
                    if let animalID = selectedAnimalID, let action = pendingAction {
                        executeAction(action, for: animalID)
                    }
                }
            }
        }
        .presentationBackground(.clear)
    }

    private func handleAction(_ action: QuickAction) {
        if action.requiresAnimal {
            pendingAction = action
            showingAnimalPicker = true
        } else {
            executeActionWithoutAnimal(action)
        }
    }

    private func executeAction(_ action: QuickAction, for animalID: UUID) {
        dismiss()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            switch action {
            case .feeding:
                appState.presentSheet(.logFeeding(animalID: animalID))
            case .quickFeed:
                appState.presentSheet(.quickFeed(animalID: animalID))
            case .weight:
                appState.presentSheet(.addWeight(animalID: animalID))
            case .length:
                appState.presentSheet(.addLength(animalID: animalID))
            case .shed:
                appState.presentSheet(.addShed(animalID: animalID))
            case .healthNote:
                appState.presentSheet(.addHealthNote(animalID: animalID))
            case .batchFeed:
                appState.presentSheet(.batchFeed)
            case .quickNote:
                appState.presentSheet(.quickNote)
            case .addAnimal:
                appState.presentSheet(.addAnimal)
            }
        }
    }

    private func executeActionWithoutAnimal(_ action: QuickAction) {
        dismiss()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            switch action {
            case .batchFeed:
                appState.presentSheet(.batchFeed)
            case .quickNote:
                appState.presentSheet(.quickNote)
            case .addAnimal:
                appState.presentSheet(.addAnimal)
            default:
                break
            }
        }
    }
}

// MARK: - Quick Action Enum

enum QuickAction: String, CaseIterable {
    case feeding
    case quickFeed
    case weight
    case shed
    case healthNote
    case batchFeed
    case quickNote
    case addAnimal
    case length

    var title: String {
        switch self {
        case .feeding: return "Log Feed"
        case .quickFeed: return "Quick Feed"
        case .weight: return "Weight"
        case .length: return "Length"
        case .shed: return "Shed"
        case .healthNote: return "Health"
        case .batchFeed: return "Batch Feed"
        case .quickNote: return "Note"
        case .addAnimal: return "Add Animal"
        }
    }

    var icon: String {
        switch self {
        case .feeding: return "fork.knife"
        case .quickFeed: return "bolt.fill"
        case .weight: return "scalemass"
        case .length: return "ruler"
        case .shed: return "arrow.triangle.2.circlepath"
        case .healthNote: return "cross.case"
        case .batchFeed: return "square.stack.fill"
        case .quickNote: return "note.text"
        case .addAnimal: return "plus.circle"
        }
    }

    var color: Color {
        switch self {
        case .feeding: return .heatLampAmber
        case .quickFeed: return .nebulaGold
        case .weight: return .nebulaCyan
        case .length: return .nebulaPurple
        case .shed: return .shedPink
        case .healthNote: return .scaleError
        case .batchFeed: return .nebulaMagenta
        case .quickNote: return .nebulaLavender
        case .addAnimal: return .scaleSuccess
        }
    }

    var requiresAnimal: Bool {
        switch self {
        case .batchFeed, .quickNote, .addAnimal:
            return false
        default:
            return true
        }
    }
}

// MARK: - Hub Quick Action Button

struct HubQuickActionButton: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let action: QuickAction
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: ScaleSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(action.color.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: action.icon)
                        .font(.system(size: 24))
                        .foregroundColor(action.color)
                }

                Text(action.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.scaleTextPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ScaleSpacing.sm)
        }
    }
}

// MARK: - Animal Picker View

struct AnimalPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var themeManager = ThemeManager.shared
    @Binding var selectedAnimalID: UUID?
    let onSelect: () -> Void

    @State private var animals: [Animal] = []
    @State private var searchText = ""

    var filteredAnimals: [Animal] {
        if searchText.isEmpty {
            return animals
        }
        return animals.filter { animal in
            animal.name.localizedCaseInsensitiveContains(searchText) ||
            (animal.morph?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                if animals.isEmpty {
                    VStack(spacing: ScaleSpacing.lg) {
                        Image(systemName: "lizard")
                            .font(.system(size: 50))
                            .foregroundColor(themeManager.currentTheme.primaryAccent.opacity(0.5))

                        Text("No Animals")
                            .font(.scaleHeadline)
                            .foregroundColor(.scaleTextPrimary)

                        Text("Add animals to your collection first.")
                            .font(.scaleSubheadline)
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: ScaleSpacing.sm) {
                            ForEach(filteredAnimals, id: \.id) { animal in
                                Button {
                                    selectedAnimalID = animal.id
                                    dismiss()
                                    onSelect()
                                } label: {
                                    HStack(spacing: ScaleSpacing.md) {
                                        Circle()
                                            .fill(themeManager.currentTheme.primaryAccent.opacity(0.2))
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Image(systemName: "pawprint.fill")
                                                    .foregroundColor(themeManager.currentTheme.primaryAccent)
                                            )

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(animal.name)
                                                .font(.scaleHeadline)
                                                .foregroundColor(.scaleTextPrimary)

                                            if let morph = animal.morph {
                                                Text(morph)
                                                    .font(.scaleCaption)
                                                    .foregroundColor(themeManager.currentTheme.textTertiary)
                                            }
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(themeManager.currentTheme.textTertiary)
                                    }
                                    .padding(ScaleSpacing.md)
                                    .background(
                                        RoundedRectangle(cornerRadius: ScaleRadius.md)
                                            .fill(themeManager.currentTheme.cardBackground.opacity(0.7))
                                    )
                                }
                            }
                        }
                        .padding(ScaleSpacing.lg)
                    }
                }
            }
            .navigationTitle("Select Animal")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search animals...")
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
        }
    }

    private func loadAnimals() {
        let descriptor = FetchDescriptor<Animal>(sortBy: [SortDescriptor(\.name)])
        animals = (try? modelContext.fetch(descriptor)) ?? []
    }
}

// MARK: - Preview

#Preview {
    QuickActionsHubView()
        .environmentObject(AppState())
}
