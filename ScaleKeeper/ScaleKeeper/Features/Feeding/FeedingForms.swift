import SwiftUI
import SwiftData
import ScaleCore
import ScaleUI

// MARK: - Log Feeding View

struct LogFeedingView: View {
    let animalID: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var themeManager = ThemeManager.shared

    // Form state
    @State private var animal: Animal?
    @State private var lastFeeding: FeedingEvent?
    @State private var feedingDate: Date = Date()
    @State private var preyType: PreyType = .mouse
    @State private var preySize: PreySize = .medium
    @State private var preyState: PreyState = .frozenThawed
    @State private var quantity: Int = 1
    @State private var feedingResponse: FeedingResponse = .struckImmediately
    @State private var refusedReason: String = ""
    @State private var notes: String = ""
    @State private var showingLastFeedingBanner = false

    // UI state
    @State private var isSaving = false
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                if isLoading {
                    ScaleLoadingState(message: "Loading...")
                } else {
                    ScrollView {
                        VStack(spacing: ScaleSpacing.lg) {
                            // Animal info header
                            if let animal = animal {
                                animalHeader(animal)
                            }

                            // Smart defaults banner
                            if showingLastFeedingBanner, let last = lastFeeding {
                                smartDefaultsBanner(last)
                            }

                            // Date/Time
                            dateSection

                            // Prey details
                            preySection

                            // Response
                            responseSection

                            // Notes
                            notesSection

                            Color.clear.frame(height: 100)
                        }
                        .padding(.horizontal, ScaleSpacing.md)
                        .padding(.top, ScaleSpacing.md)
                    }
                }
            }
            .navigationTitle("Log Feeding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.scaleTextSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveFeeding()
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

    // MARK: - Sections

    private func animalHeader(_ animal: Animal) -> some View {
        HStack(spacing: ScaleSpacing.md) {
            Circle()
                .fill(themeManager.currentTheme.cardBackground)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "pawprint.fill")
                        .foregroundStyle(themeManager.currentTheme.primaryAccent)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(animal.name)
                    .font(.scaleHeadline)
                    .foregroundStyle(Color.scaleTextPrimary)

                Text(animal.morph ?? "Unknown morph")
                    .font(.scaleCaption)
                    .foregroundStyle(Color.scaleTextTertiary)
            }

            Spacer()
        }
        .padding(ScaleSpacing.md)
        .background(themeManager.currentTheme.cardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
    }

    private func smartDefaultsBanner(_ lastFeeding: FeedingEvent) -> some View {
        HStack(spacing: ScaleSpacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 16))
                .foregroundColor(.nebulaGold)

            VStack(alignment: .leading, spacing: 2) {
                Text("Pre-filled from last feeding")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.scaleTextPrimary)

                Text("\(lastFeeding.preySize.displayName) \(lastFeeding.preyType.displayName) • \(lastFeeding.feedingDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(size: 11))
                    .foregroundColor(themeManager.currentTheme.textTertiary)
            }

            Spacer()

            Button {
                withAnimation {
                    showingLastFeedingBanner = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.currentTheme.textTertiary)
            }
        }
        .padding(ScaleSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ScaleRadius.md)
                .fill(Color.nebulaGold.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: ScaleRadius.md)
                        .stroke(Color.nebulaGold.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.md) {
            ScaleSectionHeader("Date & Time")

            ScaleDatePicker(
                "Feeding Date",
                date: $feedingDate,
                displayedComponents: [.date, .hourAndMinute]
            )
        }
    }

    private var preySection: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.md) {
            ScaleSectionHeader("Prey Details")

            ScalePicker(
                "Prey Type",
                selection: $preyType,
                options: PreyType.allCases,
                isRequired: true
            ) { type in
                Text(type.displayName)
            }

            ScalePicker(
                "Prey Size",
                selection: $preySize,
                options: PreySize.allCases,
                isRequired: true
            ) { size in
                Text(size.displayName)
            }

            ScalePicker(
                "Prey State",
                selection: $preyState,
                options: PreyState.allCases,
                isRequired: true
            ) { state in
                Text(state.displayName)
            }

            ScaleStepper(
                "Quantity",
                value: $quantity,
                range: 1...20,
                icon: "number"
            )
        }
    }

    private var responseSection: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.md) {
            ScaleSectionHeader("Feeding Response")

            ScaleSegmentedPicker(
                selection: $feedingResponse,
                options: FeedingResponse.allCases
            ) { response in
                VStack(spacing: 2) {
                    Image(systemName: response.iconName)
                        .font(.system(size: 16))
                    Text(response.shortName)
                        .font(.scaleCaption)
                }
            }

            if feedingResponse == .refused {
                ScaleTextField(
                    "Refused Reason",
                    text: $refusedReason,
                    placeholder: "Why did the animal refuse?",
                    icon: "questionmark.circle.fill"
                )
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.md) {
            ScaleSectionHeader("Notes")

            ScaleTextEditor(
                "Notes",
                text: $notes,
                placeholder: "Any observations about this feeding...",
                helpText: "Feeding behavior, issues, etc."
            )
        }
    }

    // MARK: - Load & Save

    private func loadAnimal() {
        isLoading = true

        let predicate = #Predicate<Animal> { $0.id == animalID }
        let descriptor = FetchDescriptor<Animal>(predicate: predicate)

        if let fetchedAnimal = try? modelContext.fetch(descriptor).first {
            animal = fetchedAnimal

            // Pre-populate from last feeding (smart defaults)
            if let feedings = fetchedAnimal.feedings?.sorted(by: { $0.feedingDate > $1.feedingDate }),
               let last = feedings.first {
                lastFeeding = last
                preyType = last.preyType
                preySize = last.preySize
                preyState = last.preyState
                quantity = last.quantity
                showingLastFeedingBanner = true
            }
        }

        isLoading = false
    }

    private func saveFeeding() {
        guard let animal = animal else { return }

        isSaving = true

        let feeding = FeedingEvent(
            preyType: preyType,
            preySize: preySize,
            preyState: preyState,
            quantity: quantity,
            feedingResponse: feedingResponse
        )

        feeding.feedingDate = feedingDate
        feeding.animal = animal

        if feedingResponse == .refused && !refusedReason.isEmpty {
            feeding.refusedReason = refusedReason
        }

        if !notes.isEmpty {
            feeding.notes = notes
        }

        // Update animal's feeding schedule
        animal.feedings?.append(feeding)

        do {
            try modelContext.save()
            ScaleToastManager.shared.success("Feeding logged!")
            ScaleHaptics.success()
            dismiss()
        } catch {
            ScaleToastManager.shared.error("Failed to save feeding")
            isSaving = false
        }
    }
}

// MARK: - Quick Feed View

struct QuickFeedView: View {
    let animalID: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var animal: Animal?
    @State private var lastFeeding: FeedingEvent?
    @State private var isLoading = true
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                if isLoading {
                    ScaleLoadingState(message: "Loading...")
                } else if let animal = animal {
                    VStack(spacing: ScaleSpacing.xl) {
                        Spacer()

                        // Animal info
                        VStack(spacing: ScaleSpacing.md) {
                            Circle()
                                .fill(themeManager.currentTheme.cardBackground)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "pawprint.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(themeManager.currentTheme.primaryAccent)
                                )

                            Text(animal.name)
                                .font(.scaleTitle2)
                                .foregroundStyle(Color.scaleTextPrimary)
                        }

                        // Last feeding info
                        if let last = lastFeeding {
                            VStack(spacing: ScaleSpacing.sm) {
                                Text("Last fed")
                                    .font(.scaleSubheadline)
                                    .foregroundStyle(Color.scaleTextTertiary)

                                HStack(spacing: ScaleSpacing.sm) {
                                    Image(systemName: "clock.fill")
                                        .foregroundStyle(Color.scaleTextSecondary)
                                    Text(last.feedingDate.formatted(date: .abbreviated, time: .shortened))
                                        .font(.scaleBody)
                                        .foregroundStyle(Color.scaleTextSecondary)
                                }

                                Text("\(last.quantity) \(last.preySize.displayName) \(last.preyType.displayName)")
                                    .font(.scaleCaption)
                                    .foregroundStyle(Color.scaleTextTertiary)
                            }
                            .padding(ScaleSpacing.md)
                            .background(themeManager.currentTheme.cardBackground.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
                        } else {
                            Text("No previous feedings recorded")
                                .font(.scaleSubheadline)
                                .foregroundStyle(Color.scaleTextTertiary)
                        }

                        Spacer()

                        // Quick feed button
                        VStack(spacing: ScaleSpacing.md) {
                            Button {
                                quickFeed()
                            } label: {
                                HStack(spacing: ScaleSpacing.sm) {
                                    Image(systemName: "bolt.fill")
                                    Text(lastFeeding != nil ? "Feed Same as Last Time" : "Log First Feeding")
                                }
                                .font(.scaleButton)
                                .foregroundStyle(themeManager.currentTheme.backgroundPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, ScaleSpacing.md)
                                .background(themeManager.currentTheme.primaryAccent)
                                .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
                            }
                            .disabled(isSaving || lastFeeding == nil)

                            Button {
                                dismiss()
                                // Navigate to full log feeding
                            } label: {
                                Text("Log Different Feeding")
                                    .font(.scaleButton)
                                    .foregroundStyle(Color.scaleTextSecondary)
                            }
                        }
                        .padding(.horizontal, ScaleSpacing.lg)
                        .padding(.bottom, ScaleSpacing.xl)
                    }
                } else {
                    ScaleEmptyState.error {
                        loadAnimal()
                    }
                }
            }
            .navigationTitle("Quick Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.scaleTextSecondary)
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

        if let fetchedAnimal = try? modelContext.fetch(descriptor).first {
            animal = fetchedAnimal

            // Get last feeding
            if let feedings = fetchedAnimal.feedings?.sorted(by: { $0.feedingDate > $1.feedingDate }) {
                lastFeeding = feedings.first
            }
        }

        isLoading = false
    }

    private func quickFeed() {
        guard let animal = animal, let last = lastFeeding else { return }

        isSaving = true

        let feeding = FeedingEvent(
            preyType: last.preyType,
            preySize: last.preySize,
            preyState: last.preyState,
            quantity: last.quantity,
            feedingResponse: .struckImmediately
        )

        feeding.feedingDate = Date()
        feeding.animal = animal
        animal.feedings?.append(feeding)

        do {
            try modelContext.save()
            ScaleToastManager.shared.success("Feeding logged!")
            ScaleHaptics.success()
            dismiss()
        } catch {
            ScaleToastManager.shared.error("Failed to save feeding")
            isSaving = false
        }
    }
}

// MARK: - Extensions for UI display

extension FeedingResponse {
    var shortName: String {
        switch self {
        case .struckImmediately: return "Struck"
        case .reluctant: return "Reluctant"
        case .assistedFeed: return "Assisted"
        case .refused: return "Refused"
        case .regurgitated: return "Regurg"
        }
    }
}

// MARK: - Mark Regurgitation View

struct MarkRegurgitationView: View {
    let feedingID: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var feeding: FeedingEvent?
    @State private var regurgitationDate: Date = Date()
    @State private var notes: String = ""
    @State private var isSaving = false
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                if isLoading {
                    ScaleLoadingState(message: "Loading...")
                } else if let feeding = feeding {
                    ScrollView {
                        VStack(spacing: ScaleSpacing.lg) {
                            // Feeding info header
                            feedingInfoHeader(feeding)

                            // Regurgitation date
                            ScaleCard(header: .init(title: "When Did This Happen?", icon: "calendar")) {
                                DatePicker(
                                    "Regurgitation Date",
                                    selection: $regurgitationDate,
                                    in: feeding.feedingDate...Date(),
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .datePickerStyle(.graphical)
                                .tint(themeManager.currentTheme.primaryAccent)
                            }

                            // Notes
                            ScaleCard(header: .init(title: "Notes", icon: "note.text")) {
                                TextField("Any observations about the regurgitation...", text: $notes, axis: .vertical)
                                    .lineLimit(3...6)
                                    .textFieldStyle(.plain)
                                    .padding(ScaleSpacing.md)
                                    .background(
                                        RoundedRectangle(cornerRadius: ScaleRadius.sm)
                                            .fill(themeManager.currentTheme.backgroundSecondary)
                                    )
                            }

                            // Info banner
                            HStack(spacing: ScaleSpacing.sm) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.nebulaCyan)
                                Text("Recording regurgitation helps track your animal's digestive health and identify patterns.")
                                    .font(.scaleCaption)
                                    .foregroundColor(themeManager.currentTheme.textSecondary)
                            }
                            .padding(ScaleSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: ScaleRadius.md)
                                    .fill(Color.nebulaCyan.opacity(0.1))
                            )

                            // Save button
                            ScalePrimaryButton("Mark as Regurgitated", isLoading: isSaving) {
                                Task {
                                    await saveRegurgitation()
                                }
                            }
                            .padding(.top, ScaleSpacing.md)
                        }
                        .padding(ScaleSpacing.lg)
                    }
                } else {
                    ScaleEmptyState(
                        icon: "exclamationmark.triangle",
                        title: "Feeding Not Found",
                        message: "Unable to find the feeding record."
                    )
                }
            }
            .navigationTitle("Mark Regurgitation")
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
                loadFeeding()
            }
        }
    }

    private func feedingInfoHeader(_ feeding: FeedingEvent) -> some View {
        ScaleCard(header: .init(title: "Original Feeding", icon: "fork.knife", iconColor: .heatLampAmber)) {
            VStack(spacing: ScaleSpacing.sm) {
                HStack {
                    Text("Date:")
                        .font(.scaleSubheadline)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                    Spacer()
                    Text(feeding.feedingDate, style: .date)
                        .font(.scaleSubheadline)
                        .foregroundColor(.scaleTextPrimary)
                }

                HStack {
                    Text("Prey:")
                        .font(.scaleSubheadline)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                    Spacer()
                    Text("\(feeding.quantity)x \(feeding.preySize.displayName) \(feeding.preyType.displayName)")
                        .font(.scaleSubheadline)
                        .foregroundColor(.scaleTextPrimary)
                }

                HStack {
                    Text("Response:")
                        .font(.scaleSubheadline)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                    Spacer()
                    Text(feeding.feedingResponse.displayName)
                        .font(.scaleSubheadline)
                        .foregroundColor(responseColor(for: feeding.feedingResponse))
                }

                if let animal = feeding.animal {
                    HStack {
                        Text("Animal:")
                            .font(.scaleSubheadline)
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                        Spacer()
                        Text(animal.name)
                            .font(.scaleSubheadline)
                            .foregroundColor(.scaleTextPrimary)
                    }
                }
            }
        }
    }

    private func loadFeeding() {
        let descriptor = FetchDescriptor<FeedingEvent>(
            predicate: #Predicate { $0.id == feedingID }
        )
        if let result = try? modelContext.fetch(descriptor).first {
            feeding = result
        }
        isLoading = false
    }

    private func saveRegurgitation() async {
        guard let feeding = feeding else { return }

        isSaving = true

        // Update the feeding record
        feeding.feedingResponse = .regurgitated
        feeding.regurgitationDate = regurgitationDate
        feeding.regurgitationNotes = notes.isEmpty ? nil : notes

        do {
            try modelContext.save()
            appState.triggerDataRefresh()
            dismiss()
        } catch {
            print("Failed to save regurgitation: \(error)")
        }

        isSaving = false
    }

    private func responseColor(for response: FeedingResponse) -> Color {
        switch response {
        case .struckImmediately:
            return .scaleSuccess
        case .reluctant:
            return .nebulaGold
        case .assistedFeed:
            return .nebulaCyan
        case .refused:
            return .scaleError
        case .regurgitated:
            return .scaleError
        }
    }
}

// MARK: - Previews

#Preview("Log Feeding") {
    LogFeedingView(animalID: UUID())
        .modelContainer(for: [Animal.self, FeedingEvent.self], inMemory: true)
}

#Preview("Quick Feed") {
    QuickFeedView(animalID: UUID())
        .modelContainer(for: [Animal.self, FeedingEvent.self], inMemory: true)
}

#Preview("Mark Regurgitation") {
    MarkRegurgitationView(feedingID: UUID())
        .modelContainer(for: [Animal.self, FeedingEvent.self], inMemory: true)
        .environmentObject(AppState())
}
