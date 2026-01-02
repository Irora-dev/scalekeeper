import Foundation
import SwiftData

// MARK: - Medication Entity

@Model
public final class Medication {
    // MARK: - Identity
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date

    // MARK: - Details
    public var name: String
    public var medicationType: MedicationType
    public var defaultDosageNotes: String?
    public var manufacturer: String?

    // MARK: - Common Protocols (JSON encoded)
    private var commonProtocolsData: Data?

    public var commonProtocols: [MedicationProtocol] {
        get {
            guard let data = commonProtocolsData else { return [] }
            return (try? JSONDecoder().decode([MedicationProtocol].self, from: data)) ?? []
        }
        set {
            commonProtocolsData = try? JSONEncoder().encode(newValue)
        }
    }

    // MARK: - Init
    public init(
        id: UUID = UUID(),
        name: String,
        medicationType: MedicationType
    ) {
        self.id = id
        self.createdAt = Date()
        self.name = name
        self.medicationType = medicationType
    }
}

// MARK: - Medication Type

public enum MedicationType: String, Codable, CaseIterable {
    case topical
    case oral
    case injectable
    case soak
    case environmental
    case supplement

    public var displayName: String {
        switch self {
        case .topical: return "Topical"
        case .oral: return "Oral"
        case .injectable: return "Injectable"
        case .soak: return "Soak"
        case .environmental: return "Environmental"
        case .supplement: return "Supplement"
        }
    }

    public var iconName: String {
        switch self {
        case .topical: return "hand.point.up.left"
        case .oral: return "pill"
        case .injectable: return "syringe"
        case .soak: return "drop.fill"
        case .environmental: return "aqi.medium"
        case .supplement: return "capsule"
        }
    }
}

// MARK: - Medication Protocol

public struct MedicationProtocol: Codable, Identifiable, Equatable {
    public var id: UUID
    public var name: String
    public var frequencyHours: Int
    public var totalDoses: Int
    public var notes: String?

    public init(
        id: UUID = UUID(),
        name: String,
        frequencyHours: Int,
        totalDoses: Int,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.frequencyHours = frequencyHours
        self.totalDoses = totalDoses
        self.notes = notes
    }
}

// MARK: - Treatment Plan Entity

@Model
public final class TreatmentPlan {
    // MARK: - Identity
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date

    // MARK: - Treatment Details
    public var conditionTreated: String
    public var dosage: String
    public var frequencyHours: Int
    public var totalDoses: Int?
    public var prescribedBy: String?
    public var notes: String?

    // MARK: - Dates
    public var startDate: Date
    public var endDate: Date?

    // MARK: - Status
    public var status: TreatmentStatus

    // MARK: - Relationships
    public var animal: Animal?
    public var medication: Medication?
    @Relationship(deleteRule: .cascade, inverse: \MedicationDose.treatmentPlan)
    public var doses: [MedicationDose]?

    // MARK: - Computed
    public var completedDoses: Int {
        doses?.filter { $0.status == .administered }.count ?? 0
    }

    public var progressPercentage: Double {
        guard let total = totalDoses, total > 0 else { return 0 }
        return Double(completedDoses) / Double(total) * 100
    }

    public var nextScheduledDose: MedicationDose? {
        doses?
            .filter { $0.status == .scheduled }
            .sorted { $0.scheduledTime < $1.scheduledTime }
            .first
    }

    public var isComplete: Bool {
        guard let total = totalDoses else { return false }
        return completedDoses >= total
    }

    // MARK: - Init
    public init(
        id: UUID = UUID(),
        conditionTreated: String,
        dosage: String,
        frequencyHours: Int,
        totalDoses: Int? = nil,
        startDate: Date = Date()
    ) {
        self.id = id
        self.createdAt = Date()
        self.conditionTreated = conditionTreated
        self.dosage = dosage
        self.frequencyHours = frequencyHours
        self.totalDoses = totalDoses
        self.startDate = startDate
        self.status = .active
    }
}

// MARK: - Treatment Status

public enum TreatmentStatus: String, Codable, CaseIterable {
    case active
    case completed
    case discontinued
    case paused

    public var displayName: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .discontinued: return "Discontinued"
        case .paused: return "Paused"
        }
    }

    public var iconName: String {
        switch self {
        case .active: return "pills.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .discontinued: return "xmark.circle.fill"
        case .paused: return "pause.circle.fill"
        }
    }
}

// MARK: - Medication Dose Entity

@Model
public final class MedicationDose {
    // MARK: - Identity
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date

    // MARK: - Timing
    public var scheduledTime: Date
    public var administeredTime: Date?

    // MARK: - Status
    public var status: DoseStatus

    // MARK: - Notes
    public var notes: String?

    // MARK: - Relationships
    public var treatmentPlan: TreatmentPlan?

    // MARK: - Computed
    public var isOverdue: Bool {
        guard status == .scheduled else { return false }
        return scheduledTime < Date()
    }

    public var hoursOverdue: Int? {
        guard isOverdue else { return nil }
        return Calendar.current.dateComponents([.hour], from: scheduledTime, to: Date()).hour
    }

    // MARK: - Init
    public init(
        id: UUID = UUID(),
        scheduledTime: Date,
        status: DoseStatus = .scheduled
    ) {
        self.id = id
        self.createdAt = Date()
        self.scheduledTime = scheduledTime
        self.status = status
    }
}

// MARK: - Dose Status

public enum DoseStatus: String, Codable, CaseIterable {
    case scheduled
    case administered
    case skipped
    case missed

    public var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .administered: return "Administered"
        case .skipped: return "Skipped"
        case .missed: return "Missed"
        }
    }

    public var iconName: String {
        switch self {
        case .scheduled: return "clock"
        case .administered: return "checkmark.circle.fill"
        case .skipped: return "arrow.uturn.right"
        case .missed: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Active Treatment Summary

public struct ActiveTreatmentSummary {
    public let treatmentPlan: TreatmentPlan
    public let animalName: String
    public let medicationName: String
    public let dosesToday: [MedicationDose]
    public let nextDose: MedicationDose?

    public var hasDosesDueToday: Bool {
        !dosesToday.filter { $0.status == .scheduled }.isEmpty
    }

    public var completedToday: Int {
        dosesToday.filter { $0.status == .administered }.count
    }

    public var remainingToday: Int {
        dosesToday.filter { $0.status == .scheduled }.count
    }

    public init(
        treatmentPlan: TreatmentPlan,
        animalName: String,
        medicationName: String,
        dosesToday: [MedicationDose],
        nextDose: MedicationDose?
    ) {
        self.treatmentPlan = treatmentPlan
        self.animalName = animalName
        self.medicationName = medicationName
        self.dosesToday = dosesToday
        self.nextDose = nextDose
    }
}
