import SwiftUI
import ScaleCore
import ScaleUI

// MARK: - Add Enclosure View

struct AddEnclosureView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddEnclosureViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    let onSave: (Enclosure) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                ScrollView {
                    VStack(spacing: ScaleSpacing.lg) {
                        // Basic Info
                        basicInfoSection

                        // Dimensions
                        dimensionsSection

                        // Substrate
                        substrateSection

                        // Environment
                        environmentSection
                    }
                    .padding(ScaleSpacing.lg)
                }
            }
            .navigationTitle("Add Enclosure")
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
                        if let enclosure = viewModel.save() {
                            onSave(enclosure)
                            dismiss()
                        }
                    }
                    .foregroundColor(.nebulaPurple)
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isValid)
                }
            }
        }
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        ScaleCard(
            header: .init(
                title: "Basic Info",
                icon: "info.circle",
                iconColor: .nebulaPurple
            )
        ) {
            VStack(spacing: ScaleSpacing.md) {
                // Name
                VStack(alignment: .leading, spacing: ScaleSpacing.xs) {
                    Text("Name")
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)

                    TextField("e.g., Main Vivarium", text: $viewModel.name)
                        .textFieldStyle(ScaleTextFieldStyle())
                }

                // Type
                VStack(alignment: .leading, spacing: ScaleSpacing.xs) {
                    Text("Type")
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: ScaleSpacing.sm) {
                            ForEach(EnclosureType.allCases, id: \.self) { type in
                                EnclosureTypeChip(
                                    type: type,
                                    isSelected: viewModel.enclosureType == type
                                ) {
                                    viewModel.enclosureType = type
                                }
                            }
                        }
                    }
                }

                // Location
                VStack(alignment: .leading, spacing: ScaleSpacing.xs) {
                    Text("Location (optional)")
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)

                    TextField("e.g., Reptile Room", text: $viewModel.location)
                        .textFieldStyle(ScaleTextFieldStyle())
                }
            }
        }
    }

    // MARK: - Dimensions Section

    private var dimensionsSection: some View {
        ScaleCard(
            header: .init(
                title: "Dimensions",
                subtitle: "In inches",
                icon: "ruler",
                iconColor: .nebulaLavender
            )
        ) {
            HStack(spacing: ScaleSpacing.md) {
                dimensionField(label: "Length", value: $viewModel.length)
                dimensionField(label: "Width", value: $viewModel.width)
                dimensionField(label: "Height", value: $viewModel.height)
            }

            if let volume = viewModel.calculatedVolume {
                HStack {
                    Text("Volume:")
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                    Text("\(Int(volume)) gallons")
                        .font(.scaleSubheadline)
                        .foregroundColor(.nebulaCyan)
                }
                .padding(.top, ScaleSpacing.sm)
            }
        }
    }

    private func dimensionField(label: String, value: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.xs) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(themeManager.currentTheme.textTertiary)

            TextField("0", text: value)
                .keyboardType(.decimalPad)
                .textFieldStyle(ScaleTextFieldStyle())
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Substrate Section

    private var substrateSection: some View {
        ScaleCard(
            header: .init(
                title: "Substrate",
                icon: "square.3.layers.3d.down.left",
                iconColor: .nebulaGold
            )
        ) {
            VStack(spacing: ScaleSpacing.md) {
                // Substrate picker
                Menu {
                    ForEach(SubstrateType.allCases, id: \.self) { type in
                        Button(type.displayName) {
                            viewModel.substrateType = type
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.substrateType?.displayName ?? "Select substrate")
                            .foregroundColor(viewModel.substrateType == nil ? themeManager.currentTheme.textTertiary : .scaleTextPrimary)
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

                // Bioactive toggle
                Toggle(isOn: $viewModel.isBioactive) {
                    HStack {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.nebulaCyan)
                        Text("Bioactive Setup")
                            .font(.scaleSubheadline)
                            .foregroundColor(.scaleTextPrimary)
                    }
                }
                .tint(.nebulaCyan)
            }
        }
    }

    // MARK: - Environment Section

    private var environmentSection: some View {
        ScaleCard(
            header: .init(
                title: "Environment Targets",
                subtitle: "Optional",
                icon: "thermometer",
                iconColor: .scaleError
            )
        ) {
            VStack(spacing: ScaleSpacing.md) {
                // Temperature
                HStack(spacing: ScaleSpacing.md) {
                    VStack(alignment: .leading, spacing: ScaleSpacing.xs) {
                        Text("Hot Side (°F)")
                            .font(.system(size: 10))
                            .foregroundColor(themeManager.currentTheme.textTertiary)

                        TextField("e.g., 90", text: $viewModel.targetTempHot)
                            .keyboardType(.numberPad)
                            .textFieldStyle(ScaleTextFieldStyle())
                    }

                    VStack(alignment: .leading, spacing: ScaleSpacing.xs) {
                        Text("Cool Side (°F)")
                            .font(.system(size: 10))
                            .foregroundColor(themeManager.currentTheme.textTertiary)

                        TextField("e.g., 75", text: $viewModel.targetTempCool)
                            .keyboardType(.numberPad)
                            .textFieldStyle(ScaleTextFieldStyle())
                    }
                }

                // Humidity
                VStack(alignment: .leading, spacing: ScaleSpacing.xs) {
                    Text("Target Humidity (%)")
                        .font(.system(size: 10))
                        .foregroundColor(themeManager.currentTheme.textTertiary)

                    TextField("e.g., 60", text: $viewModel.targetHumidity)
                        .keyboardType(.numberPad)
                        .textFieldStyle(ScaleTextFieldStyle())
                }
            }
        }
    }
}

// MARK: - Enclosure Type Chip

struct EnclosureTypeChip: View {
    let type: EnclosureType
    let isSelected: Bool
    let onTap: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: type.iconName)
                    .font(.system(size: 20))
                Text(type.displayName)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? .nebulaPurple : themeManager.currentTheme.textSecondary)
            .frame(width: 70, height: 60)
            .background(
                RoundedRectangle(cornerRadius: ScaleRadius.sm)
                    .fill(isSelected ? Color.nebulaPurple.opacity(0.15) : Color.cosmicDeep)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ScaleRadius.sm)
                    .stroke(isSelected ? Color.nebulaPurple : themeManager.currentTheme.borderColor, lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

// MARK: - Add Enclosure View Model

@MainActor
@Observable
final class AddEnclosureViewModel: ObservableObject {
    private let dataService: DataService
    private let cleaningService: CleaningService

    // Form fields
    var name = ""
    var enclosureType: EnclosureType = .terrarium
    var location = ""
    var length = ""
    var width = ""
    var height = ""
    var substrateType: SubstrateType?
    var isBioactive = false
    var targetTempHot = ""
    var targetTempCool = ""
    var targetHumidity = ""

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var calculatedVolume: Double? {
        guard let l = Double(length),
              let w = Double(width),
              let h = Double(height) else { return nil }
        let cubicInches = l * w * h
        return cubicInches / 231 // Convert to gallons
    }

    init(dataService: DataService = .shared, cleaningService: CleaningService = .shared) {
        self.dataService = dataService
        self.cleaningService = cleaningService
    }

    func save() -> Enclosure? {
        let enclosure = Enclosure(
            name: name.trimmingCharacters(in: .whitespaces),
            enclosureType: enclosureType
        )

        if !location.isEmpty {
            enclosure.location = location
        }

        if let l = Double(length) { enclosure.lengthInches = l }
        if let w = Double(width) { enclosure.widthInches = w }
        if let h = Double(height) { enclosure.heightInches = h }

        enclosure.substrateType = substrateType
        enclosure.isBioactive = isBioactive

        if let temp = Double(targetTempHot) { enclosure.targetTempHotF = temp }
        if let temp = Double(targetTempCool) { enclosure.targetTempCoolF = temp }
        if let humidity = Int(targetHumidity) { enclosure.targetHumidity = humidity }

        dataService.insert(enclosure)

        do {
            try dataService.save()

            // Setup default cleaning schedules
            try cleaningService.setupDefaultSchedules(for: enclosure)

            return enclosure
        } catch {
            print("Failed to save enclosure: \(error)")
            return nil
        }
    }
}

// MARK: - Edit Enclosure View

struct EditEnclosureView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    let enclosure: Enclosure
    let onSave: () -> Void

    @State private var name: String
    @State private var location: String
    @State private var enclosureType: EnclosureType
    @State private var length: String
    @State private var width: String
    @State private var height: String
    @State private var substrateType: SubstrateType?
    @State private var isBioactive: Bool
    @State private var targetTempHot: String
    @State private var targetTempCool: String
    @State private var targetHumidity: String

    init(enclosure: Enclosure, onSave: @escaping () -> Void) {
        self.enclosure = enclosure
        self.onSave = onSave

        _name = State(initialValue: enclosure.name)
        _location = State(initialValue: enclosure.location ?? "")
        _enclosureType = State(initialValue: enclosure.enclosureType)
        _length = State(initialValue: enclosure.lengthInches.map { String(Int($0)) } ?? "")
        _width = State(initialValue: enclosure.widthInches.map { String(Int($0)) } ?? "")
        _height = State(initialValue: enclosure.heightInches.map { String(Int($0)) } ?? "")
        _substrateType = State(initialValue: enclosure.substrateType)
        _isBioactive = State(initialValue: enclosure.isBioactive)
        _targetTempHot = State(initialValue: enclosure.targetTempHotF.map { String(Int($0)) } ?? "")
        _targetTempCool = State(initialValue: enclosure.targetTempCoolF.map { String(Int($0)) } ?? "")
        _targetHumidity = State(initialValue: enclosure.targetHumidity.map { String($0) } ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                ScrollView {
                    VStack(spacing: ScaleSpacing.lg) {
                        // Form fields (similar to AddEnclosureView)
                        ScaleCard {
                            VStack(spacing: ScaleSpacing.md) {
                                VStack(alignment: .leading, spacing: ScaleSpacing.xs) {
                                    Text("Name")
                                        .font(.scaleCaption)
                                        .foregroundColor(themeManager.currentTheme.textSecondary)
                                    TextField("Name", text: $name)
                                        .textFieldStyle(ScaleTextFieldStyle())
                                }

                                VStack(alignment: .leading, spacing: ScaleSpacing.xs) {
                                    Text("Location")
                                        .font(.scaleCaption)
                                        .foregroundColor(themeManager.currentTheme.textSecondary)
                                    TextField("Location", text: $location)
                                        .textFieldStyle(ScaleTextFieldStyle())
                                }

                                Toggle(isOn: $isBioactive) {
                                    HStack {
                                        Image(systemName: "leaf.fill")
                                            .foregroundColor(.nebulaCyan)
                                        Text("Bioactive Setup")
                                    }
                                }
                                .tint(.nebulaCyan)
                            }
                        }
                    }
                    .padding(ScaleSpacing.lg)
                }
            }
            .navigationTitle("Edit Enclosure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                        onSave()
                        dismiss()
                    }
                    .foregroundColor(.nebulaPurple)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveChanges() {
        enclosure.name = name
        enclosure.location = location.isEmpty ? nil : location
        enclosure.enclosureType = enclosureType
        enclosure.lengthInches = Double(length)
        enclosure.widthInches = Double(width)
        enclosure.heightInches = Double(height)
        enclosure.substrateType = substrateType
        enclosure.isBioactive = isBioactive
        enclosure.targetTempHotF = Double(targetTempHot)
        enclosure.targetTempCoolF = Double(targetTempCool)
        enclosure.targetHumidity = Int(targetHumidity)
        enclosure.updatedAt = Date()

        try? DataService.shared.save()
    }
}

// MARK: - Log Cleaning View

struct LogCleaningView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    let enclosure: Enclosure
    let onSave: () -> Void

    @State private var selectedType: CleaningType = .spotClean
    @State private var notes = ""
    @State private var suppliesUsed: [String] = []
    @State private var newSupply = ""

    private let cleaningService = CleaningService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                ScrollView {
                    VStack(spacing: ScaleSpacing.lg) {
                        // Cleaning Type
                        ScaleCard(
                            header: .init(
                                title: "Cleaning Type",
                                icon: "sparkles",
                                iconColor: .nebulaMagenta
                            )
                        ) {
                            VStack(spacing: ScaleSpacing.sm) {
                                ForEach(CleaningType.allCases, id: \.self) { type in
                                    CleaningTypeRow(
                                        type: type,
                                        isSelected: selectedType == type
                                    ) {
                                        selectedType = type
                                    }
                                }
                            }
                        }

                        // Notes
                        ScaleCard(
                            header: .init(
                                title: "Notes",
                                subtitle: "Optional",
                                icon: "note.text",
                                iconColor: .nebulaLavender
                            )
                        ) {
                            TextEditor(text: $notes)
                                .frame(minHeight: 80)
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

                        // Supplies Used
                        ScaleCard(
                            header: .init(
                                title: "Supplies Used",
                                subtitle: "Optional",
                                icon: "shippingbox",
                                iconColor: .nebulaGold
                            )
                        ) {
                            VStack(spacing: ScaleSpacing.sm) {
                                // Existing supplies
                                ForEach(suppliesUsed, id: \.self) { supply in
                                    HStack {
                                        Text(supply)
                                            .font(.scaleSubheadline)
                                            .foregroundColor(.scaleTextPrimary)
                                        Spacer()
                                        Button {
                                            suppliesUsed.removeAll { $0 == supply }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(themeManager.currentTheme.textTertiary)
                                        }
                                    }
                                    .padding(.vertical, ScaleSpacing.xs)
                                }

                                // Add new supply
                                HStack {
                                    TextField("Add supply...", text: $newSupply)
                                        .textFieldStyle(ScaleTextFieldStyle())

                                    Button {
                                        if !newSupply.isEmpty {
                                            suppliesUsed.append(newSupply)
                                            newSupply = ""
                                        }
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.nebulaPurple)
                                    }
                                    .disabled(newSupply.isEmpty)
                                }
                            }
                        }
                    }
                    .padding(ScaleSpacing.lg)
                }
            }
            .navigationTitle("Log Cleaning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCleaning()
                    }
                    .foregroundColor(.nebulaMagenta)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveCleaning() {
        do {
            _ = try cleaningService.logCleaning(
                for: enclosure,
                type: selectedType,
                notes: notes.isEmpty ? nil : notes,
                suppliesUsed: suppliesUsed.isEmpty ? nil : suppliesUsed
            )
            onSave()
            dismiss()
        } catch {
            print("Failed to log cleaning: \(error)")
        }
    }
}

// MARK: - Cleaning Type Row

struct CleaningTypeRow: View {
    let type: CleaningType
    let isSelected: Bool
    let onTap: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        Button(action: onTap) {
            HStack {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.nebulaMagenta.opacity(0.15) : Color.cosmicDeep)
                        .frame(width: 40, height: 40)

                    Image(systemName: type.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(isSelected ? .nebulaMagenta : themeManager.currentTheme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(.scaleSubheadline)
                        .foregroundColor(isSelected ? .scaleTextPrimary : themeManager.currentTheme.textSecondary)

                    Text(type.description)
                        .font(.system(size: 11))
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.nebulaMagenta)
                } else {
                    Circle()
                        .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(.vertical, ScaleSpacing.xs)
        }
    }
}

// MARK: - Scale Text Field Style

struct ScaleTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: ScaleRadius.sm)
                    .fill(Color.cosmicDeep)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ScaleRadius.sm)
                    .stroke(Color.scaleBorder, lineWidth: 1)
            )
            .foregroundColor(.scaleTextPrimary)
    }
}

// MARK: - Preview

#Preview("Add Enclosure") {
    AddEnclosureView { _ in }
}

#Preview("Log Cleaning") {
    LogCleaningView(enclosure: Enclosure(name: "Test", enclosureType: .terrarium)) { }
}
