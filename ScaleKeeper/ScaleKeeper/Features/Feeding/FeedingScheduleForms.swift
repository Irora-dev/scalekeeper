import SwiftUI
import SwiftData
import ScaleCore
import ScaleUI

// MARK: - New Feeding Schedule View

struct NewFeedingScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var themeManager = ThemeManager.shared

    // Form state
    @State private var name: String = ""
    @State private var scheduleType: FeedingRoutineType = .weekly
    @State private var feedingTimes: [FeedingTime] = [FeedingTime(label: "Evening", hour: 18, minute: 0)]
    @State private var selectedDays: Set<Int> = [2, 5] // Mon, Thu default
    @State private var intervalDays: Int = 7
    @State private var startDate: Date = Date()
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Date().addingTimeInterval(86400 * 90)
    @State private var notes: String = ""
    @State private var selectedAnimals: Set<UUID> = []

    // Data
    @State private var allAnimals: [Animal] = []

    // UI state
    @State private var isSaving = false
    @State private var showingAnimalPicker = false

    var onSave: (() -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                ScrollView {
                    VStack(spacing: ScaleSpacing.lg) {
                        // Basic Info
                        basicInfoSection

                        // Schedule Type
                        scheduleTypeSection

                        // Feeding Times
                        feedingTimesSection

                        // Animals
                        animalsSection

                        // Date Range
                        dateRangeSection

                        // Notes
                        notesSection

                        // Save button
                        ScalePrimaryButton(
                            "Create Schedule",
                            icon: "checkmark.circle.fill",
                            isLoading: isSaving,
                            isDisabled: !canSave
                        ) {
                            saveSchedule()
                        }
                        .padding(.top, ScaleSpacing.md)

                        Color.clear.frame(height: 50)
                    }
                    .padding(.horizontal, ScaleSpacing.md)
                    .padding(.top, ScaleSpacing.md)
                }
            }
            .navigationTitle("New Schedule")
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
                loadAnimals()
            }
            .sheet(isPresented: $showingAnimalPicker) {
                AnimalMultiSelectView(
                    animals: allAnimals,
                    selectedIDs: $selectedAnimals
                )
            }
        }
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.md) {
            ScaleSectionHeader("Schedule Name")

            ScaleTextField(
                "Name",
                text: $name,
                placeholder: "e.g., Weekly Snake Feeding",
                icon: "calendar.badge.clock",
                isRequired: true
            )
        }
    }

    // MARK: - Schedule Type Section

    private var scheduleTypeSection: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.md) {
            ScaleSectionHeader("Frequency")

            ScalePicker(
                "Schedule Type",
                selection: $scheduleType,
                options: FeedingRoutineType.allCases
            ) { type in
                Text(type.displayName)
            }

            // Day selector for weekly/custom
            if scheduleType == .weekly || scheduleType == .custom {
                daySelector
            }

            // Interval picker for every N days
            if scheduleType == .everyNDays {
                intervalSelector
            }
        }
    }

    private var daySelector: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.sm) {
            Text("Feed on these days:")
                .font(.scaleSubheadline)
                .foregroundColor(themeManager.currentTheme.textSecondary)

            HStack(spacing: ScaleSpacing.xs) {
                ForEach(DayOfWeek.allCases, id: \.rawValue) { day in
                    Button {
                        if selectedDays.contains(day.rawValue) {
                            selectedDays.remove(day.rawValue)
                        } else {
                            selectedDays.insert(day.rawValue)
                        }
                        ScaleHaptics.light()
                    } label: {
                        Text(day.shortName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(selectedDays.contains(day.rawValue) ? themeManager.currentTheme.backgroundPrimary : .scaleTextSecondary)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(selectedDays.contains(day.rawValue) ? themeManager.currentTheme.primaryAccent : themeManager.currentTheme.cardBackground)
                            )
                            .overlay(
                                Circle()
                                    .stroke(selectedDays.contains(day.rawValue) ? themeManager.currentTheme.primaryAccent : themeManager.currentTheme.borderColor, lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    private var intervalSelector: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.sm) {
            Text("Feed every \(intervalDays) days")
                .font(.scaleSubheadline)
                .foregroundColor(themeManager.currentTheme.textSecondary)

            HStack(spacing: ScaleSpacing.md) {
                Button {
                    if intervalDays > 1 { intervalDays -= 1 }
                    ScaleHaptics.light()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(themeManager.currentTheme.primaryAccent)
                }

                Text("\(intervalDays)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.scaleTextPrimary)
                    .frame(width: 60)

                Button {
                    if intervalDays < 30 { intervalDays += 1 }
                    ScaleHaptics.light()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(themeManager.currentTheme.primaryAccent)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(themeManager.currentTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
    }

    // MARK: - Feeding Times Section

    private var feedingTimesSection: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.md) {
            HStack {
                ScaleSectionHeader("Feeding Times")
                Spacer()
                Button {
                    feedingTimes.append(FeedingTime(label: "Feeding \(feedingTimes.count + 1)", hour: 12, minute: 0))
                    ScaleHaptics.light()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(themeManager.currentTheme.primaryAccent)
                }
            }

            ForEach($feedingTimes) { $time in
                FeedingTimeRow(time: $time) {
                    if feedingTimes.count > 1 {
                        feedingTimes.removeAll { $0.id == time.id }
                    }
                }
            }
        }
    }

    // MARK: - Animals Section

    private var animalsSection: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.md) {
            ScaleSectionHeader("Animals")

            Button {
                showingAnimalPicker = true
            } label: {
                HStack {
                    Image(systemName: "pawprint.fill")
                        .foregroundColor(selectedAnimals.isEmpty ? .scaleTextTertiary : themeManager.currentTheme.primaryAccent)

                    if selectedAnimals.isEmpty {
                        Text("Select animals for this schedule")
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                    } else {
                        Text("\(selectedAnimals.count) animals selected")
                            .foregroundColor(.scaleTextPrimary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }
                .font(.scaleBody)
                .padding()
                .background(themeManager.currentTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: ScaleRadius.md)
                        .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
                )
            }

            // Show selected animals
            if !selectedAnimals.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ScaleSpacing.sm) {
                        ForEach(allAnimals.filter { selectedAnimals.contains($0.id) }, id: \.id) { animal in
                            HStack(spacing: 4) {
                                Text(animal.name)
                                    .font(.scaleCaption)
                                Button {
                                    selectedAnimals.remove(animal.id)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 12))
                                }
                            }
                            .foregroundColor(.scaleTextPrimary)
                            .padding(.horizontal, ScaleSpacing.sm)
                            .padding(.vertical, ScaleSpacing.xs)
                            .background(themeManager.currentTheme.primaryAccent.opacity(0.2))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    // MARK: - Date Range Section

    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.md) {
            ScaleSectionHeader("Schedule Period")

            ScaleDatePicker(
                "Start Date",
                date: $startDate
            )

            Toggle(isOn: $hasEndDate) {
                Text("Set end date")
                    .font(.scaleBody)
                    .foregroundColor(.scaleTextPrimary)
            }
            .tint(themeManager.currentTheme.primaryAccent)
            .padding()
            .background(themeManager.currentTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))

            if hasEndDate {
                ScaleDatePicker(
                    "End Date",
                    date: $endDate
                )
            }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.md) {
            ScaleSectionHeader("Notes")

            ScaleTextEditor(
                "Notes",
                text: $notes,
                placeholder: "Any notes about this feeding schedule..."
            )
        }
    }

    // MARK: - Validation

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedAnimals.isEmpty &&
        !feedingTimes.isEmpty &&
        (scheduleType != .weekly && scheduleType != .custom || !selectedDays.isEmpty)
    }

    // MARK: - Data Loading

    private func loadAnimals() {
        let descriptor = FetchDescriptor<Animal>(sortBy: [SortDescriptor(\.name)])
        allAnimals = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Save

    private func saveSchedule() {
        guard canSave else { return }

        isSaving = true

        let animalIDs = Array(selectedAnimals)

        let routine = FeedingRoutine(
            name: name.trimmingCharacters(in: .whitespaces),
            routineType: scheduleType,
            feedingTimes: feedingTimes,
            daysOfWeek: Array(selectedDays),
            animalIDs: animalIDs,
            intervalDays: intervalDays,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            isActive: true,
            notes: notes.isEmpty ? nil : notes
        )

        modelContext.insert(routine)

        do {
            try modelContext.save()
            ScaleToastManager.shared.success("Schedule created!")
            ScaleHaptics.success()
            onSave?()
            dismiss()
        } catch {
            ScaleToastManager.shared.error("Failed to save schedule")
            isSaving = false
        }
    }
}

// MARK: - Feeding Time Row

struct FeedingTimeRow: View {
    @Binding var time: FeedingTime
    let onDelete: () -> Void

    @State private var selectedDate: Date

    init(time: Binding<FeedingTime>, onDelete: @escaping () -> Void) {
        self._time = time
        self.onDelete = onDelete
        let calendar = Calendar.current
        let components = DateComponents(hour: time.wrappedValue.hour, minute: time.wrappedValue.minute)
        self._selectedDate = State(initialValue: calendar.date(from: components) ?? Date())
    }

    var body: some View {
        HStack {
            TextField("Label", text: $time.label)
                .font(.scaleBody)
                .foregroundColor(.scaleTextPrimary)
                .frame(maxWidth: 120)

            Spacer()

            DatePicker(
                "",
                selection: $selectedDate,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .tint(ThemeManager.shared.currentTheme.primaryAccent)
            .onChange(of: selectedDate) { _, newValue in
                let calendar = Calendar.current
                time.hour = calendar.component(.hour, from: newValue)
                time.minute = calendar.component(.minute, from: newValue)
            }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.scaleError)
            }
        }
        .padding()
        .background(ThemeManager.shared.currentTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
    }
}

// MARK: - Animal Multi-Select View

struct AnimalMultiSelectView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let animals: [Animal]
    @Binding var selectedIDs: Set<UUID>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                if animals.isEmpty {
                    ScaleEmptyState(
                        icon: "pawprint.fill",
                        title: "No Animals",
                        message: "Add animals to your collection first."
                    )
                } else {
                    List {
                        ForEach(animals, id: \.id) { animal in
                            Button {
                                if selectedIDs.contains(animal.id) {
                                    selectedIDs.remove(animal.id)
                                } else {
                                    selectedIDs.insert(animal.id)
                                }
                                ScaleHaptics.light()
                            } label: {
                                HStack {
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

                                    if selectedIDs.contains(animal.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(ThemeManager.shared.currentTheme.primaryAccent)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(themeManager.currentTheme.textTertiary)
                                    }
                                }
                                .padding(.vertical, ScaleSpacing.xs)
                            }
                            .listRowBackground(ThemeManager.shared.currentTheme.cardBackground.opacity(0.5))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Select Animals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.scaleTextSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundStyle(ThemeManager.shared.currentTheme.primaryAccent)
                }
            }
        }
    }
}

// MARK: - Feeding Routine Detail View

struct FeedingRoutineDetailView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let routine: FeedingRoutine
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var onUpdate: (() -> Void)?

    var body: some View {
        ZStack {
            ScaleBackground()

            ScrollView {
                VStack(spacing: ScaleSpacing.lg) {
                    // Status Card
                    statusCard

                    // Schedule Info
                    scheduleInfoCard

                    // Animals
                    animalsCard

                    // Upcoming Feedings
                    upcomingCard

                    // Delete button
                    Button {
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Schedule")
                        }
                        .font(.scaleButton)
                        .foregroundColor(.scaleError)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.scaleError.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
                    }
                    .padding(.top, ScaleSpacing.lg)
                }
                .padding(ScaleSpacing.lg)
            }
        }
        .navigationTitle(routine.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    routine.isActive.toggle()
                    try? modelContext.save()
                    onUpdate?()
                } label: {
                    Text(routine.isActive ? "Pause" : "Resume")
                        .foregroundColor(routine.isActive ? .nebulaGold : ThemeManager.shared.currentTheme.primaryAccent)
                }
            }
        }
        .alert("Delete Schedule?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteRoutine()
            }
        } message: {
            Text("This will permanently delete this feeding schedule.")
        }
    }

    private var statusCard: some View {
        ScaleCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: ScaleSpacing.sm) {
                        Circle()
                            .fill(routine.isActive ? Color.scaleSuccess : Color.scaleWarning)
                            .frame(width: 10, height: 10)
                        Text(routine.isActive ? "Active" : "Paused")
                            .font(.scaleHeadline)
                            .foregroundColor(.scaleTextPrimary)
                    }

                    Text(routine.routineType.displayName)
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }

                Spacer()

                if let next = routine.getNextFeedingDateFromNow() {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Next feeding")
                            .font(.scaleCaption)
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                        Text(next.formatted(date: .abbreviated, time: .shortened))
                            .font(.scaleSubheadline)
                            .foregroundColor(ThemeManager.shared.currentTheme.primaryAccent)
                    }
                }
            }
        }
    }

    private var scheduleInfoCard: some View {
        ScaleCard(
            header: .init(
                title: "Schedule Details",
                icon: "calendar",
                iconColor: .nebulaLavender
            )
        ) {
            VStack(spacing: ScaleSpacing.md) {
                // Times
                ForEach(routine.getFeedingTimes()) { time in
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.nebulaGold)
                        Text(time.label)
                            .font(.scaleBody)
                            .foregroundColor(.scaleTextPrimary)
                        Spacer()
                        Text(time.displayTime)
                            .font(.scaleSubheadline)
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }
                }

                ScaleDivider()

                // Days
                if routine.routineType == .weekly || routine.routineType == .custom {
                    HStack {
                        Text("Days:")
                            .font(.scaleBody)
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                        Spacer()
                        Text(routine.getDaysOfWeek().compactMap { DayOfWeek(rawValue: $0)?.shortName }.joined(separator: ", "))
                            .font(.scaleSubheadline)
                            .foregroundColor(.scaleTextPrimary)
                    }
                } else if routine.routineType == .everyNDays {
                    HStack {
                        Text("Interval:")
                            .font(.scaleBody)
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                        Spacer()
                        Text("Every \(routine.intervalDays) days")
                            .font(.scaleSubheadline)
                            .foregroundColor(.scaleTextPrimary)
                    }
                }
            }
        }
    }

    private var animalsCard: some View {
        let animalIDs = routine.getAnimalIDs()
        return ScaleCard(
            header: .init(
                title: "Animals",
                subtitle: "\(animalIDs.count) in schedule",
                icon: "pawprint.fill",
                iconColor: ThemeManager.shared.currentTheme.primaryAccent
            )
        ) {
            VStack(spacing: ScaleSpacing.sm) {
                ForEach(animalIDs, id: \.self) { animalID in
                    HStack {
                        Text(animalID.uuidString.prefix(8) + "...")
                            .font(.scaleBody)
                            .foregroundColor(.scaleTextPrimary)
                        Spacer()
                    }
                    .padding(.vertical, ScaleSpacing.xs)
                }
            }
        }
    }

    private var upcomingCard: some View {
        ScaleCard(
            header: .init(
                title: "Upcoming Week",
                icon: "calendar.badge.clock",
                iconColor: .nebulaCyan
            )
        ) {
            let upcoming = routine.getUpcomingWeekFeedings()
            if upcoming.isEmpty {
                Text("No feedings scheduled this week")
                    .font(.scaleSubheadline)
                    .foregroundColor(themeManager.currentTheme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                VStack(spacing: ScaleSpacing.sm) {
                    ForEach(upcoming) { feeding in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(feeding.isToday ? "Today" : (feeding.isTomorrow ? "Tomorrow" : feeding.dayOfWeek))
                                    .font(.scaleSubheadline)
                                    .foregroundColor(feeding.isToday ? ThemeManager.shared.currentTheme.primaryAccent : .scaleTextPrimary)
                                Text(feeding.formattedDate)
                                    .font(.scaleCaption)
                                    .foregroundColor(themeManager.currentTheme.textTertiary)
                            }

                            Spacer()

                            Text(feeding.formattedTime)
                                .font(.scaleBody)
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                        }
                        .padding(.vertical, ScaleSpacing.xs)
                    }
                }
            }
        }
    }

    private func deleteRoutine() {
        modelContext.delete(routine)
        try? modelContext.save()
        onUpdate?()
        dismiss()
    }
}

// MARK: - Preview

#Preview("New Schedule") {
    NewFeedingScheduleView()
        .modelContainer(for: [Animal.self, FeedingRoutine.self], inMemory: true)
}
