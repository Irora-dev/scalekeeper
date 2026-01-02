import Foundation
import SwiftData

// MARK: - Cleaning Event Entity

@Model
public final class CleaningEvent {
    // MARK: - Identity
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date

    // MARK: - Timing
    public var cleanedAt: Date

    // MARK: - Details
    public var cleaningType: CleaningType
    public var notes: String?

    // MARK: - Supplies (JSON encoded)
    private var suppliesData: Data?

    public var suppliesUsed: [String] {
        get {
            guard let data = suppliesData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            suppliesData = try? JSONEncoder().encode(newValue)
        }
    }

    // MARK: - Relationships
    public var enclosure: Enclosure?

    // MARK: - Init
    public init(
        id: UUID = UUID(),
        cleanedAt: Date = Date(),
        cleaningType: CleaningType
    ) {
        self.id = id
        self.createdAt = Date()
        self.cleanedAt = cleanedAt
        self.cleaningType = cleaningType
    }
}

// MARK: - Cleaning Type

public enum CleaningType: String, Codable, CaseIterable {
    case spotClean = "spot_clean"
    case substrateChange = "substrate_change"
    case deepClean = "deep_clean"
    case waterChange = "water_change"
    case bioactiveMaintenance = "bioactive_maintenance"
    case custom

    public var displayName: String {
        switch self {
        case .spotClean: return "Spot Clean"
        case .substrateChange: return "Substrate Change"
        case .deepClean: return "Deep Clean"
        case .waterChange: return "Water Change"
        case .bioactiveMaintenance: return "Bioactive Maintenance"
        case .custom: return "Custom"
        }
    }

    public var iconName: String {
        switch self {
        case .spotClean: return "sparkles"
        case .substrateChange: return "square.3.layers.3d.down.left"
        case .deepClean: return "bubbles.and.sparkles"
        case .waterChange: return "drop.triangle"
        case .bioactiveMaintenance: return "leaf.arrow.triangle.circlepath"
        case .custom: return "wrench.and.screwdriver"
        }
    }

    public var defaultIntervalDays: Int {
        switch self {
        case .spotClean: return 3
        case .substrateChange: return 30
        case .deepClean: return 90
        case .waterChange: return 7
        case .bioactiveMaintenance: return 14
        case .custom: return 30
        }
    }

    public var description: String {
        switch self {
        case .spotClean: return "Remove waste and soiled substrate"
        case .substrateChange: return "Replace all substrate material"
        case .deepClean: return "Full sanitization of enclosure"
        case .waterChange: return "Replace water dish or water feature"
        case .bioactiveMaintenance: return "Add springtails, mist, or maintain cleanup crew"
        case .custom: return "Custom maintenance task"
        }
    }
}

// MARK: - Cleaning Schedule Entity

@Model
public final class CleaningSchedule {
    // MARK: - Identity
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date

    // MARK: - Schedule
    public var cleaningType: CleaningType
    public var intervalDays: Int
    public var reminderEnabled: Bool
    public var reminderAdvanceDays: Int // Remind X days before due

    // MARK: - Relationships
    public var enclosure: Enclosure?

    // MARK: - Computed
    public var nextDueDate: Date? {
        guard let enclosure = enclosure else { return nil }
        // Find most recent cleaning of this type
        // This would need to be computed from CleaningEvents
        return nil // Placeholder - computed in service layer
    }

    // MARK: - Init
    public init(
        id: UUID = UUID(),
        cleaningType: CleaningType,
        intervalDays: Int? = nil,
        reminderEnabled: Bool = true,
        reminderAdvanceDays: Int = 1
    ) {
        self.id = id
        self.createdAt = Date()
        self.cleaningType = cleaningType
        self.intervalDays = intervalDays ?? cleaningType.defaultIntervalDays
        self.reminderEnabled = reminderEnabled
        self.reminderAdvanceDays = reminderAdvanceDays
    }
}

// MARK: - Cleaning Status

public struct CleaningStatus {
    public let cleaningType: CleaningType
    public let lastCleaned: Date?
    public let scheduledIntervalDays: Int
    public let enclosureName: String

    public var daysSinceLastClean: Int? {
        guard let lastCleaned = lastCleaned else { return nil }
        return Calendar.current.dateComponents([.day], from: lastCleaned, to: Date()).day
    }

    public var daysUntilDue: Int {
        guard let days = daysSinceLastClean else { return 0 }
        return scheduledIntervalDays - days
    }

    public var urgency: CleaningUrgency {
        guard let daysSince = daysSinceLastClean else { return .overdue }

        let percentComplete = Double(daysSince) / Double(scheduledIntervalDays)

        if percentComplete >= 1.0 {
            return .overdue
        } else if percentComplete >= 0.8 {
            return .dueSoon
        } else {
            return .onTrack
        }
    }

    public init(
        cleaningType: CleaningType,
        lastCleaned: Date?,
        scheduledIntervalDays: Int,
        enclosureName: String
    ) {
        self.cleaningType = cleaningType
        self.lastCleaned = lastCleaned
        self.scheduledIntervalDays = scheduledIntervalDays
        self.enclosureName = enclosureName
    }
}

public enum CleaningUrgency: String {
    case onTrack
    case dueSoon
    case overdue

    public var displayName: String {
        switch self {
        case .onTrack: return "On Track"
        case .dueSoon: return "Due Soon"
        case .overdue: return "Overdue"
        }
    }

    public var colorName: String {
        switch self {
        case .onTrack: return "scaleSuccess"
        case .dueSoon: return "scaleWarning"
        case .overdue: return "scaleError"
        }
    }
}
