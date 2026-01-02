import Foundation
import SwiftData

// MARK: - Pairing Entity

@Model
public final class Pairing {
    // MARK: - Identity
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date

    // MARK: - Animals
    public var maleID: UUID
    public var femaleID: UUID

    // MARK: - Timeline
    public var introductionDate: Date
    public var separationDate: Date?
    public var breedingSeason: String? // e.g., "2024-2025"

    // MARK: - Observations
    public var observedLocks: [LockObservation]?
    public var notes: String?

    // MARK: - Status
    public var status: PairingStatus

    // MARK: - Relationships
    @Relationship(deleteRule: .cascade, inverse: \Clutch.pairing)
    public var clutches: [Clutch]?

    // MARK: - Computed
    private var locksData: Data?

    public var locks: [LockObservation] {
        get {
            guard let data = locksData else { return [] }
            return (try? JSONDecoder().decode([LockObservation].self, from: data)) ?? []
        }
        set {
            locksData = try? JSONEncoder().encode(newValue)
        }
    }

    // MARK: - Init
    public init(
        id: UUID = UUID(),
        maleID: UUID,
        femaleID: UUID,
        introductionDate: Date = Date()
    ) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.maleID = maleID
        self.femaleID = femaleID
        self.introductionDate = introductionDate
        self.status = .active
    }
}

// MARK: - Pairing Status

public enum PairingStatus: String, Codable, CaseIterable {
    case active
    case successful
    case unsuccessful
    case cancelled

    public var displayName: String {
        switch self {
        case .active: return "Active"
        case .successful: return "Successful"
        case .unsuccessful: return "Unsuccessful"
        case .cancelled: return "Cancelled"
        }
    }
}

// MARK: - Lock Observation

public struct LockObservation: Codable, Identifiable, Equatable {
    public var id: UUID
    public var observedAt: Date
    public var durationMinutes: Int?
    public var notes: String?

    public init(
        id: UUID = UUID(),
        observedAt: Date = Date(),
        durationMinutes: Int? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.observedAt = observedAt
        self.durationMinutes = durationMinutes
        self.notes = notes
    }
}

// MARK: - Clutch Entity

@Model
public final class Clutch {
    // MARK: - Identity
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date

    // MARK: - Laying
    public var layDate: Date
    public var totalEggs: Int
    public var fertileEggs: Int?
    public var infertileEggs: Int?
    public var slugs: Int?

    // MARK: - Incubation
    public var incubationStartDate: Date?
    public var incubationTempF: Double?
    public var incubationHumidity: Int?
    public var incubationMethod: IncubationMethod?

    // MARK: - Hatching
    public var firstPipDate: Date?
    public var hatchStartDate: Date?
    public var hatchEndDate: Date?
    public var totalHatched: Int?

    // MARK: - Notes
    public var notes: String?

    // MARK: - Status
    public var status: ClutchStatus

    // MARK: - Relationships
    public var pairing: Pairing?

    // MARK: - Offspring IDs (stored separately to avoid circular refs)
    private var offspringIDsData: Data?

    public var offspringIDs: [UUID] {
        get {
            guard let data = offspringIDsData else { return [] }
            return (try? JSONDecoder().decode([UUID].self, from: data)) ?? []
        }
        set {
            offspringIDsData = try? JSONEncoder().encode(newValue)
        }
    }

    // MARK: - Computed
    public var fertilityRate: Double? {
        guard let fertile = fertileEggs, totalEggs > 0 else { return nil }
        return Double(fertile) / Double(totalEggs) * 100
    }

    public var hatchRate: Double? {
        guard let hatched = totalHatched, let fertile = fertileEggs, fertile > 0 else { return nil }
        return Double(hatched) / Double(fertile) * 100
    }

    public var incubationDays: Int? {
        guard let start = incubationStartDate, let end = hatchStartDate else { return nil }
        return Calendar.current.dateComponents([.day], from: start, to: end).day
    }

    // MARK: - Init
    public init(
        id: UUID = UUID(),
        layDate: Date = Date(),
        totalEggs: Int
    ) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.layDate = layDate
        self.totalEggs = totalEggs
        self.status = .incubating
    }
}

// MARK: - Clutch Status

public enum ClutchStatus: String, Codable, CaseIterable {
    case incubating
    case pipping
    case hatching
    case hatched
    case failed

    public var displayName: String {
        switch self {
        case .incubating: return "Incubating"
        case .pipping: return "Pipping"
        case .hatching: return "Hatching"
        case .hatched: return "Hatched"
        case .failed: return "Failed"
        }
    }

    public var iconName: String {
        switch self {
        case .incubating: return "thermometer.medium"
        case .pipping: return "burst.fill"
        case .hatching: return "arrow.up.circle.fill"
        case .hatched: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
}

// MARK: - Incubation Method

public enum IncubationMethod: String, Codable, CaseIterable {
    case incubator
    case maternalIncubation = "maternal"
    case roomTemperature = "room_temp"
    case suspended
    case other

    public var displayName: String {
        switch self {
        case .incubator: return "Incubator"
        case .maternalIncubation: return "Maternal"
        case .roomTemperature: return "Room Temp"
        case .suspended: return "Suspended"
        case .other: return "Other"
        }
    }
}
