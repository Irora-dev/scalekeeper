import Foundation
import SwiftData

// MARK: - Species Entity

@Model
public final class Species {
    // MARK: - Identity
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date

    // MARK: - Classification
    public var commonName: String
    public var scientificName: String
    public var family: String?
    public var category: SpeciesCategory

    // MARK: - Husbandry Defaults
    public var defaultFeedingIntervalDays: Int?
    public var defaultTempRangeLowF: Double?
    public var defaultTempRangeHighF: Double?
    public var defaultHumidityLow: Int?
    public var defaultHumidityHigh: Int?

    // MARK: - Breeding Info
    public var breedingSeasonStart: Int? // Month 1-12
    public var breedingSeasonEnd: Int?
    public var averageClutchSize: Int?
    public var incubationDaysLow: Int?
    public var incubationDaysHigh: Int?

    // MARK: - Notes
    public var careNotes: String?

    // MARK: - Known Morphs (JSON)
    public var knownMorphsData: Data?

    // MARK: - Computed
    public var knownMorphs: [MorphDefinition]? {
        get {
            guard let data = knownMorphsData else { return nil }
            return try? JSONDecoder().decode([MorphDefinition].self, from: data)
        }
        set {
            knownMorphsData = try? JSONEncoder().encode(newValue)
        }
    }

    // MARK: - Init
    public init(
        id: UUID = UUID(),
        commonName: String,
        scientificName: String,
        category: SpeciesCategory
    ) {
        self.id = id
        self.createdAt = Date()
        self.commonName = commonName
        self.scientificName = scientificName
        self.category = category
    }
}

// MARK: - Species Category

public enum SpeciesCategory: String, Codable, CaseIterable {
    case snake
    case lizard
    case gecko
    case tortoise
    case turtle
    case crocodilian
    case frog
    case salamander
    case invertebrate
    case other

    public var displayName: String {
        switch self {
        case .snake: return "Snake"
        case .lizard: return "Lizard"
        case .gecko: return "Gecko"
        case .tortoise: return "Tortoise"
        case .turtle: return "Turtle"
        case .crocodilian: return "Crocodilian"
        case .frog: return "Frog"
        case .salamander: return "Salamander"
        case .invertebrate: return "Invertebrate"
        case .other: return "Other"
        }
    }

    public var iconName: String {
        switch self {
        case .snake: return "line.diagonal"
        case .lizard: return "lizard.fill"
        case .gecko: return "lizard.fill"
        case .tortoise: return "tortoise.fill"
        case .turtle: return "tortoise.fill"
        case .crocodilian: return "water.waves"
        case .frog: return "hare.fill"
        case .salamander: return "drop.fill"
        case .invertebrate: return "ant.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
}

// MARK: - Morph Definition

public struct MorphDefinition: Codable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var inheritanceType: InheritanceType
    public var geneCode: String? // e.g., "pi" for piebald
    public var description: String?
    public var isCombo: Bool // True if it's a combination morph
    public var componentGenes: [String]? // For combos

    public init(
        id: UUID = UUID(),
        name: String,
        inheritanceType: InheritanceType,
        geneCode: String? = nil,
        description: String? = nil,
        isCombo: Bool = false,
        componentGenes: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.inheritanceType = inheritanceType
        self.geneCode = geneCode
        self.description = description
        self.isCombo = isCombo
        self.componentGenes = componentGenes
    }
}
