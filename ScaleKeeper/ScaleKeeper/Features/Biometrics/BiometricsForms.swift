import SwiftUI
import ScaleCore
import ScaleUI

// MARK: - Add Length View (Sheet Wrapper)

struct AddLengthView: View {
    let animalID: UUID
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var animal: Animal?
    @State private var isLoading = true
    private let dataService = DataService.shared

    var body: some View {
        Group {
            if isLoading {
                NavigationStack {
                    ZStack {
                        ScaleBackground()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .nebulaPurple))
                    }
                    .navigationTitle("Log Length")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                dismiss()
                            }
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                        }
                    }
                }
            } else if let animal = animal {
                LogLengthView(animal: animal) {
                    dismiss()
                }
            } else {
                NavigationStack {
                    ZStack {
                        ScaleBackground()
                        Text("Animal not found")
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }
                    .navigationTitle("Error")
                    .navigationBarTitleDisplayMode(.inline)
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
        .task {
            await loadAnimal()
        }
    }

    private func loadAnimal() async {
        do {
            animal = try dataService.fetchAnimal(byID: animalID)
        } catch {
            print("Failed to load animal: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Log Weight View

struct LogWeightView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: LogWeightViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    let onSave: () -> Void

    init(animal: Animal, onSave: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: LogWeightViewModel(animal: animal))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                ScrollView {
                    VStack(spacing: ScaleSpacing.lg) {
                        // Animal Header
                        animalHeader

                        // Weight Input
                        weightInputSection

                        // Unit Toggle
                        unitToggleSection

                        // Date
                        dateSection

                        // Notes
                        notesSection

                        // Recent History
                        if !viewModel.recentWeights.isEmpty {
                            recentHistorySection
                        }
                    }
                    .padding(ScaleSpacing.lg)
                }
            }
            .navigationTitle("Log Weight")
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
                    .foregroundColor(.nebulaCyan)
                    .disabled(!viewModel.canSave)
                }
            }
            .task {
                await viewModel.loadRecent()
            }
        }
    }

    // MARK: - Animal Header

    private var animalHeader: some View {
        HStack {
            Circle()
                .fill(Color.nebulaCyan.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "scalemass")
                        .font(.system(size: 20))
                        .foregroundColor(.nebulaCyan)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.animal.name)
                    .font(.scaleHeadline)
                    .foregroundColor(.scaleTextPrimary)

                if let lastWeight = viewModel.lastWeight {
                    Text("Last: \(lastWeight.formattedWeight)")
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
            }

            Spacer()
        }
        .padding(ScaleSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ScaleRadius.md)
                .fill(Color.cardBackground)
        )
    }

    // MARK: - Weight Input Section

    private var weightInputSection: some View {
        ScaleCard(header: .init(title: "Weight", icon: "scalemass", iconColor: .nebulaCyan)) {
            VStack(spacing: ScaleSpacing.md) {
                HStack(alignment: .bottom, spacing: ScaleSpacing.sm) {
                    TextField("0", text: $viewModel.weightInput)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.scaleTextPrimary)
                        .multilineTextAlignment(.center)

                    Text(viewModel.useGrams ? "g" : "oz")
                        .font(.scaleTitle2)
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                        .padding(.bottom, 8)
                }

                // Quick weight buttons
                HStack(spacing: ScaleSpacing.sm) {
                    ForEach(viewModel.quickWeightOptions, id: \.self) { weight in
                        Button {
                            viewModel.weightInput = weight
                        } label: {
                            Text(weight + (viewModel.useGrams ? "g" : "oz"))
                                .font(.scaleCaption)
                                .foregroundColor(.nebulaCyan)
                                .padding(.horizontal, ScaleSpacing.md)
                                .padding(.vertical, ScaleSpacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: ScaleRadius.sm)
                                        .fill(Color.nebulaCyan.opacity(0.1))
                                )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Unit Toggle Section

    private var unitToggleSection: some View {
        HStack {
            Text("Unit")
                .font(.scaleSubheadline)
                .foregroundColor(themeManager.currentTheme.textSecondary)

            Spacer()

            Picker("Unit", selection: $viewModel.useGrams) {
                Text("Grams").tag(true)
                Text("Ounces").tag(false)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
        }
        .padding(ScaleSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ScaleRadius.md)
                .fill(Color.cardBackground)
        )
    }

    // MARK: - Date Section

    private var dateSection: some View {
        ScaleCard(header: .init(title: "Date & Time", icon: "calendar", iconColor: .nebulaGold)) {
            DatePicker(
                "Measurement Date",
                selection: $viewModel.recordedDate,
                in: ...Date()
            )
            .datePickerStyle(.compact)
            .labelsHidden()
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        ScaleCard(header: .init(title: "Notes", icon: "note.text", iconColor: .scaleMuted)) {
            TextField("Add notes (optional)", text: $viewModel.notes, axis: .vertical)
                .font(.scaleSubheadline)
                .foregroundColor(.scaleTextPrimary)
                .lineLimit(3...6)
        }
    }

    // MARK: - Recent History Section

    private var recentHistorySection: some View {
        ScaleCard(header: .init(title: "Recent Weights", icon: "clock", iconColor: .scaleMuted)) {
            VStack(spacing: ScaleSpacing.sm) {
                ForEach(viewModel.recentWeights.prefix(5), id: \.id) { weight in
                    HStack {
                        Text(weight.formattedWeight)
                            .font(.scaleSubheadline)
                            .foregroundColor(.scaleTextPrimary)

                        Spacer()

                        Text(weight.recordedAt, style: .date)
                            .font(.scaleCaption)
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                    }
                    .padding(.vertical, ScaleSpacing.xs)
                }
            }
        }
    }
}

// MARK: - Log Weight View Model

@MainActor
@Observable
final class LogWeightViewModel: ObservableObject {
    let animal: Animal
    private let dataService: DataService

    var weightInput = ""
    var useGrams = true
    var recordedDate = Date()
    var notes = ""
    var recentWeights: [WeightRecord] = []
    var lastWeight: WeightRecord?
    var error: Error?

    var canSave: Bool {
        guard let weight = Double(weightInput), weight > 0 else { return false }
        return true
    }

    var quickWeightOptions: [String] {
        if useGrams {
            if let last = lastWeight?.weightGrams {
                let base = Int(last)
                return ["\(base - 50)", "\(base)", "\(base + 50)"].filter { Int($0) ?? 0 > 0 }
            }
            return ["100", "250", "500", "1000"]
        } else {
            return ["3", "5", "10", "20"]
        }
    }

    init(animal: Animal, dataService: DataService = .shared) {
        self.animal = animal
        self.dataService = dataService
    }

    func loadRecent() async {
        do {
            recentWeights = try dataService.fetchWeights(for: animal)
            lastWeight = recentWeights.first
        } catch {
            self.error = error
        }
    }

    func save() async {
        guard let inputWeight = Double(weightInput), inputWeight > 0 else { return }

        let weightGrams = useGrams ? inputWeight : inputWeight * 28.3495

        let record = WeightRecord(
            recordedAt: recordedDate,
            weightGrams: weightGrams
        )
        record.animal = animal
        record.notes = notes.isEmpty ? nil : notes

        do {
            dataService.insert(record)
            try dataService.save()
        } catch {
            self.error = error
        }
    }
}

// MARK: - Log Length View

struct LogLengthView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: LogLengthViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    let onSave: () -> Void

    init(animal: Animal, onSave: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: LogLengthViewModel(animal: animal))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                ScrollView {
                    VStack(spacing: ScaleSpacing.lg) {
                        // Animal Header
                        animalHeader

                        // Length Input
                        lengthInputSection

                        // Measurement Method
                        methodSection

                        // Date
                        dateSection

                        // Notes
                        notesSection

                        // Method Info
                        methodInfoSection

                        // Recent History
                        if !viewModel.recentLengths.isEmpty {
                            recentHistorySection
                        }
                    }
                    .padding(ScaleSpacing.lg)
                }
            }
            .navigationTitle("Log Length")
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
                    .foregroundColor(.nebulaPurple)
                    .disabled(!viewModel.canSave)
                }
            }
            .task {
                await viewModel.loadRecent()
            }
        }
    }

    // MARK: - Animal Header

    private var animalHeader: some View {
        HStack {
            Circle()
                .fill(Color.nebulaPurple.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "ruler")
                        .font(.system(size: 20))
                        .foregroundColor(.nebulaPurple)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.animal.name)
                    .font(.scaleHeadline)
                    .foregroundColor(.scaleTextPrimary)

                if let lastLength = viewModel.lastLength {
                    Text("Last: \(lastLength.formattedLength)")
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
            }

            Spacer()
        }
        .padding(ScaleSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ScaleRadius.md)
                .fill(Color.cardBackground)
        )
    }

    // MARK: - Length Input Section

    private var lengthInputSection: some View {
        ScaleCard(header: .init(title: "Length", icon: "ruler", iconColor: .nebulaPurple)) {
            VStack(spacing: ScaleSpacing.md) {
                HStack(alignment: .bottom, spacing: ScaleSpacing.sm) {
                    TextField("0", text: $viewModel.lengthInput)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.scaleTextPrimary)
                        .multilineTextAlignment(.center)

                    Text(viewModel.useCm ? "cm" : "in")
                        .font(.scaleTitle2)
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                        .padding(.bottom, 8)
                }

                // Unit toggle
                Picker("Unit", selection: $viewModel.useCm) {
                    Text("Centimeters").tag(true)
                    Text("Inches").tag(false)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // MARK: - Method Section

    private var methodSection: some View {
        ScaleCard(header: .init(title: "Measurement Method", icon: "target", iconColor: .nebulaGold)) {
            VStack(spacing: ScaleSpacing.sm) {
                ForEach(MeasurementMethod.allCases, id: \.self) { method in
                    Button {
                        viewModel.selectedMethod = method
                    } label: {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(viewModel.selectedMethod == method ? Color.nebulaPurple.opacity(0.15) : Color.clear)
                                    .frame(width: 40, height: 40)

                                Image(systemName: method.iconName)
                                    .font(.system(size: 16))
                                    .foregroundColor(viewModel.selectedMethod == method ? .nebulaPurple : themeManager.currentTheme.textTertiary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(method.displayName)
                                    .font(.scaleSubheadline)
                                    .foregroundColor(.scaleTextPrimary)

                                Text("Accuracy: \(method.accuracy)")
                                    .font(.scaleCaption)
                                    .foregroundColor(themeManager.currentTheme.textTertiary)
                            }

                            Spacer()

                            if viewModel.selectedMethod == method {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.nebulaPurple)
                            }
                        }
                        .padding(.vertical, ScaleSpacing.xs)
                    }
                }
            }
        }
    }

    // MARK: - Date Section

    private var dateSection: some View {
        ScaleCard(header: .init(title: "Date & Time", icon: "calendar", iconColor: .nebulaGold)) {
            DatePicker(
                "Measurement Date",
                selection: $viewModel.recordedDate,
                in: ...Date()
            )
            .datePickerStyle(.compact)
            .labelsHidden()
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        ScaleCard(header: .init(title: "Notes", icon: "note.text", iconColor: .scaleMuted)) {
            TextField("Add notes (optional)", text: $viewModel.notes, axis: .vertical)
                .font(.scaleSubheadline)
                .foregroundColor(.scaleTextPrimary)
                .lineLimit(3...6)
        }
    }

    // MARK: - Method Info Section

    private var methodInfoSection: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.sm) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.nebulaCyan)
                Text("Measurement Tips")
                    .font(.scaleSubheadline)
                    .foregroundColor(.scaleTextPrimary)
            }

            Text(methodTip(for: viewModel.selectedMethod))
                .font(.scaleCaption)
                .foregroundColor(themeManager.currentTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(ScaleSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ScaleRadius.md)
                .fill(Color.nebulaCyan.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: ScaleRadius.md)
                        .stroke(Color.nebulaCyan.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func methodTip(for method: MeasurementMethod) -> String {
        switch method {
        case .estimated:
            return "Visual estimates are quick but less accurate. Best for rough tracking when handling isn't possible."
        case .tapeMeasure:
            return "Use a flexible tape measure along the spine from nose to tail tip. Keep the snake calm for best results."
        case .tubeMethod:
            return "Guide the snake through a clear tube marked with measurements. Most accurate method as it prevents curving."
        case .photoCalculated:
            return "Place a ruler or known object in frame for scale. Photo software can calculate length from the image."
        }
    }

    // MARK: - Recent History Section

    private var recentHistorySection: some View {
        ScaleCard(header: .init(title: "Recent Lengths", icon: "clock", iconColor: .scaleMuted)) {
            VStack(spacing: ScaleSpacing.sm) {
                ForEach(viewModel.recentLengths.prefix(5), id: \.id) { length in
                    HStack {
                        Text(length.formattedLength)
                            .font(.scaleSubheadline)
                            .foregroundColor(.scaleTextPrimary)

                        Text(length.measurementMethod.displayName)
                            .font(.system(size: 10))
                            .foregroundColor(.nebulaPurple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.nebulaPurple.opacity(0.1))
                            )

                        Spacer()

                        Text(length.recordedAt, style: .date)
                            .font(.scaleCaption)
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                    }
                    .padding(.vertical, ScaleSpacing.xs)
                }
            }
        }
    }
}

// MARK: - Log Length View Model

@MainActor
@Observable
final class LogLengthViewModel: ObservableObject {
    let animal: Animal
    private let biometricsService: BiometricsService

    var lengthInput = ""
    var useCm = true
    var selectedMethod: MeasurementMethod = .estimated
    var recordedDate = Date()
    var notes = ""
    var recentLengths: [LengthRecord] = []
    var lastLength: LengthRecord?
    var error: Error?

    var canSave: Bool {
        guard let length = Double(lengthInput), length > 0 else { return false }
        return true
    }

    init(animal: Animal, biometricsService: BiometricsService = .shared) {
        self.animal = animal
        self.biometricsService = biometricsService
    }

    func loadRecent() async {
        do {
            recentLengths = try biometricsService.lengthHistory(for: animal)
            lastLength = recentLengths.first
        } catch {
            self.error = error
        }
    }

    func save() async {
        guard let inputLength = Double(lengthInput), inputLength > 0 else { return }

        let lengthCm = useCm ? inputLength : inputLength * 2.54

        do {
            _ = try biometricsService.logLength(
                for: animal,
                lengthCm: lengthCm,
                method: selectedMethod,
                notes: notes.isEmpty ? nil : notes
            )
        } catch {
            self.error = error
        }
    }
}

// MARK: - Preview

#Preview("Log Weight") {
    LogWeightView(animal: Animal(name: "Monty", speciesID: UUID())) {}
}

#Preview("Log Length") {
    LogLengthView(animal: Animal(name: "Monty", speciesID: UUID())) {}
}
