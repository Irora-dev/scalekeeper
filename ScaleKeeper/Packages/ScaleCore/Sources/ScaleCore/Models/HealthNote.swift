import Foundation
import SwiftData

// MARK: - Health Note Entity

@Model
public final class HealthNote {
    // MARK: - Identity
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date

    // MARK: - Content
    public var recordedAt: Date
    public var noteType: HealthNoteType
    public var title: String
    public var content: String?

    // MARK: - Vet Visit Details
    public var vetName: String?
    public var vetClinic: String?
    public var diagnosis: String?
    public var treatment: String?

    // MARK: - Medication
    public var medicationName: String?
    public var medicationDosage: String?
    public var medicationFrequency: String?
    public var medicationStartDate: Date?
    public var medicationEndDate: Date?

    // MARK: - Follow-up
    public var followUpDate: Date?
    public var isResolved: Bool

    // MARK: - Cost
    public var cost: Decimal?

    // MARK: - Relationships
    public var animal: Animal?

    // MARK: - Init
    public init(
        id: UUID = UUID(),
        recordedAt: Date = Date(),
        noteType: HealthNoteType,
        title: String,
        content: String? = nil
    ) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.recordedAt = recordedAt
        self.noteType = noteType
        self.title = title
        self.content = content
        self.isResolved = false
    }
}

// MARK: - Health Note Type

public enum HealthNoteType: String, Codable, CaseIterable {
    case observation
    case vetVisit = "vet_visit"
    case medication
    case treatment
    case injury
    case illness
    case parasite
    case respiratoryIssue = "respiratory_issue"
    case scaleRot = "scale_rot"
    case mites
    case burnInjury = "burn_injury"
    case mouthRot = "mouth_rot"
    case other

    public var displayName: String {
        switch self {
        case .observation: return "Observation"
        case .vetVisit: return "Vet Visit"
        case .medication: return "Medication"
        case .treatment: return "Treatment"
        case .injury: return "Injury"
        case .illness: return "Illness"
        case .parasite: return "Parasite"
        case .respiratoryIssue: return "Respiratory Issue"
        case .scaleRot: return "Scale Rot"
        case .mites: return "Mites"
        case .burnInjury: return "Burn"
        case .mouthRot: return "Mouth Rot"
        case .other: return "Other"
        }
    }

    public var iconName: String {
        switch self {
        case .observation: return "eye.fill"
        case .vetVisit: return "cross.case.fill"
        case .medication: return "pills.fill"
        case .treatment: return "bandage.fill"
        case .injury: return "exclamationmark.triangle.fill"
        case .illness: return "heart.text.square.fill"
        case .parasite: return "ant.fill"
        case .respiratoryIssue: return "lungs.fill"
        case .scaleRot: return "circle.hexagongrid.fill"
        case .mites: return "ladybug.fill"
        case .burnInjury: return "flame.fill"
        case .mouthRot: return "mouth.fill"
        case .other: return "note.text"
        }
    }

    public var severity: HealthSeverity {
        switch self {
        case .observation:
            return .low
        case .vetVisit, .medication, .treatment:
            return .medium
        case .injury, .illness, .parasite, .respiratoryIssue, .scaleRot, .mites, .burnInjury, .mouthRot:
            return .high
        case .other:
            return .low
        }
    }
}

public enum HealthSeverity: Int, Codable {
    case low = 1
    case medium = 2
    case high = 3

    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}
