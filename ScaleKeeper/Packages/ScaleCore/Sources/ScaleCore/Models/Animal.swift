import Foundation
import SwiftData

// MARK: - Animal Entity

@Model
public final class Animal {
    // MARK: - Identity
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date

    // MARK: - Core Properties
    public var name: String
    public var speciesID: UUID
    public var morph: String?
    public var locale: String?
    public var sex: AnimalSex
    public var hatchDate: Date?
    public var acquisitionDate: Date
    public var acquisitionSource: String?
    public var acquisitionPrice: Decimal?

    // MARK: - Physical
    public var currentWeightGrams: Double?
    public var primaryPhotoID: UUID?

    // MARK: - Status
    public var status: AnimalStatus
    public var deceasedDate: Date?
    public var deceasedCause: String?

    // MARK: - Genetics (stored as JSON)
    public var geneticsData: Data?

    // MARK: - Lineage
    public var sireID: UUID?
    public var damID: UUID?
    public var breederSource: String?
    public var generation: Int?

    // MARK: - Housing
    public var enclosureID: UUID?

    // MARK: - Notes
    public var notes: String?

    // MARK: - Custom Fields (JSON for flexibility)
    public var customFieldsData: Data?

    // MARK: - Relationships
    @Relationship(deleteRule: .cascade, inverse: \FeedingEvent.animal)
    public var feedings: [FeedingEvent]?

    @Relationship(deleteRule: .cascade, inverse: \WeightRecord.animal)
    public var weights: [WeightRecord]?

    @Relationship(deleteRule: .cascade, inverse: \HealthNote.animal)
    public var healthNotes: [HealthNote]?

    @Relationship(deleteRule: .cascade, inverse: \ShedRecord.animal)
    public var sheds: [ShedRecord]?

    @Relationship(deleteRule: .cascade, inverse: \AnimalPhoto.animal)
    public var photos: [AnimalPhoto]?

    // MARK: - Computed Properties
    public var genetics: GeneticProfile? {
        get {
            guard let data = geneticsData else { return nil }
            return try? JSONDecoder().decode(GeneticProfile.self, from: data)
        }
        set {
            geneticsData = try? JSONEncoder().encode(newValue)
        }
    }

    public var customFields: [String: String]? {
        get {
            guard let data = customFieldsData else { return nil }
            return try? JSONDecoder().decode([String: String].self, from: data)
        }
        set {
            customFieldsData = try? JSONEncoder().encode(newValue)
        }
    }

    public var age: DateComponents? {
        guard let hatchDate = hatchDate else { return nil }
        return Calendar.current.dateComponents([.year, .month, .day], from: hatchDate, to: Date())
    }

    public var ageDescription: String? {
        guard let age = age else { return nil }
        if let years = age.year, years > 0 {
            return "\(years) year\(years == 1 ? "" : "s")"
        } else if let months = age.month, months > 0 {
            return "\(months) month\(months == 1 ? "" : "s")"
        } else if let days = age.day {
            return "\(days) day\(days == 1 ? "" : "s")"
        }
        return nil
    }

    // MARK: - Init
    public init(
        id: UUID = UUID(),
        name: String,
        speciesID: UUID,
        sex: AnimalSex = .unknown,
        acquisitionDate: Date = Date(),
        status: AnimalStatus = .active
    ) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.name = name
        self.speciesID = speciesID
        self.sex = sex
        self.acquisitionDate = acquisitionDate
        self.status = status
    }
}

// MARK: - Animal Sex

public enum AnimalSex: String, Codable, CaseIterable {
    case male
    case female
    case unknown
    case suspectedMale = "suspected_male"
    case suspectedFemale = "suspected_female"

    public var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .unknown: return "Unknown"
        case .suspectedMale: return "Suspected Male"
        case .suspectedFemale: return "Suspected Female"
        }
    }

    public var symbol: String {
        switch self {
        case .male, .suspectedMale: return "♂"
        case .female, .suspectedFemale: return "♀"
        case .unknown: return "?"
        }
    }
}

// MARK: - Animal Status

public enum AnimalStatus: String, Codable, CaseIterable {
    case active
    case breedingHold = "breeding_hold"
    case forSale = "for_sale"
    case sold
    case deceased
    case quarantine

    public var displayName: String {
        switch self {
        case .active: return "Active"
        case .breedingHold: return "Breeding Hold"
        case .forSale: return "For Sale"
        case .sold: return "Sold"
        case .deceased: return "Deceased"
        case .quarantine: return "Quarantine"
        }
    }

    public var iconName: String {
        switch self {
        case .active: return "checkmark.circle.fill"
        case .breedingHold: return "heart.fill"
        case .forSale: return "tag.fill"
        case .sold: return "dollarsign.circle.fill"
        case .deceased: return "xmark.circle.fill"
        case .quarantine: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Genetic Profile

public struct GeneticProfile: Codable, Equatable {
    public var confirmedGenes: [Gene]
    public var hetGenes: [HetGene]
    public var possibleHets: [PossibleHet]

    public init(
        confirmedGenes: [Gene] = [],
        hetGenes: [HetGene] = [],
        possibleHets: [PossibleHet] = []
    ) {
        self.confirmedGenes = confirmedGenes
        self.hetGenes = hetGenes
        self.possibleHets = possibleHets
    }
}

public struct Gene: Codable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var inheritanceType: InheritanceType

    public init(id: UUID = UUID(), name: String, inheritanceType: InheritanceType) {
        self.id = id
        self.name = name
        self.inheritanceType = inheritanceType
    }
}

public struct HetGene: Codable, Equatable, Identifiable {
    public var id: UUID
    public var geneName: String
    public var isProven: Bool

    public init(id: UUID = UUID(), geneName: String, isProven: Bool = false) {
        self.id = id
        self.geneName = geneName
        self.isProven = isProven
    }
}

public struct PossibleHet: Codable, Equatable, Identifiable {
    public var id: UUID
    public var geneName: String
    public var percentage: Int // 50, 66, etc.

    public init(id: UUID = UUID(), geneName: String, percentage: Int) {
        self.id = id
        self.geneName = geneName
        self.percentage = percentage
    }
}

public enum InheritanceType: String, Codable, CaseIterable {
    case recessive
    case dominant
    case coDominant = "co_dominant"
    case incompletelyDominant = "incompletely_dominant"
    case polygenic

    public var displayName: String {
        switch self {
        case .recessive: return "Recessive"
        case .dominant: return "Dominant"
        case .coDominant: return "Co-Dominant"
        case .incompletelyDominant: return "Incompletely Dominant"
        case .polygenic: return "Polygenic"
        }
    }
}
