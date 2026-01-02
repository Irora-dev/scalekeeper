import Foundation
import SwiftData

// MARK: - Enclosure Entity

@Model
public final class Enclosure {
    // MARK: - Identity
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date

    // MARK: - Basic Info
    public var name: String
    public var enclosureType: EnclosureType
    public var location: String?

    // MARK: - Dimensions (inches)
    public var lengthInches: Double?
    public var widthInches: Double?
    public var heightInches: Double?

    // MARK: - Setup
    public var substrateType: SubstrateType?
    public var isBioactive: Bool
    public var lastDeepClean: Date?

    // MARK: - Environment Targets
    public var targetTempHotF: Double?
    public var targetTempCoolF: Double?
    public var targetHumidity: Int?

    // MARK: - IoT Sensors
    public var sensorIDs: [String]?

    // MARK: - Notes
    public var notes: String?

    // MARK: - Computed
    private var sensorIDsData: Data?

    public var sensors: [String] {
        get {
            guard let data = sensorIDsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            sensorIDsData = try? JSONEncoder().encode(newValue)
        }
    }

    public var volumeCubicInches: Double? {
        guard let l = lengthInches, let w = widthInches, let h = heightInches else {
            return nil
        }
        return l * w * h
    }

    public var volumeGallons: Double? {
        guard let cubic = volumeCubicInches else { return nil }
        return cubic / 231 // 231 cubic inches per gallon
    }

    // MARK: - Init
    public init(
        id: UUID = UUID(),
        name: String,
        enclosureType: EnclosureType = .terrarium
    ) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.name = name
        self.enclosureType = enclosureType
        self.isBioactive = false
    }
}

// MARK: - Enclosure Type

public enum EnclosureType: String, Codable, CaseIterable {
    case terrarium
    case vivarium
    case rack = "rack_tub"
    case aquarium
    case paludarium
    case outdoor
    case freeRoam = "free_roam"
    case other

    public var displayName: String {
        switch self {
        case .terrarium: return "Terrarium"
        case .vivarium: return "Vivarium"
        case .rack: return "Rack/Tub"
        case .aquarium: return "Aquarium"
        case .paludarium: return "Paludarium"
        case .outdoor: return "Outdoor"
        case .freeRoam: return "Free Roam"
        case .other: return "Other"
        }
    }

    public var iconName: String {
        switch self {
        case .terrarium: return "square.3.layers.3d"
        case .vivarium: return "leaf.fill"
        case .rack: return "square.grid.3x3.fill"
        case .aquarium: return "drop.fill"
        case .paludarium: return "water.waves.and.arrow.up"
        case .outdoor: return "sun.max.fill"
        case .freeRoam: return "house.fill"
        case .other: return "questionmark.square.fill"
        }
    }
}

// MARK: - Substrate Type

public enum SubstrateType: String, Codable, CaseIterable {
    // Paper-based
    case paperTowel = "paper_towel"
    case newspaper

    // Natural loose
    case coconutFiber = "coconut_fiber"
    case cypressMulch = "cypress_mulch"
    case aspenShavings = "aspen_shavings"
    case topsoil
    case spaghnumMoss = "sphagnum_moss"
    case orchidBark = "orchid_bark"

    // Bioactive
    case bioactiveMix = "bioactive_mix"
    case abg = "abg_mix" // Atlanta Botanical Garden mix

    // Solid
    case reptileCarpet = "reptile_carpet"
    case tile
    case shelfLiner = "shelf_liner"
    case bare

    // Specialty
    case sand
    case calciumSand = "calcium_sand"
    case excavatorClay = "excavator_clay"

    case other

    public var displayName: String {
        switch self {
        case .paperTowel: return "Paper Towel"
        case .newspaper: return "Newspaper"
        case .coconutFiber: return "Coconut Fiber"
        case .cypressMulch: return "Cypress Mulch"
        case .aspenShavings: return "Aspen Shavings"
        case .topsoil: return "Topsoil"
        case .spaghnumMoss: return "Sphagnum Moss"
        case .orchidBark: return "Orchid Bark"
        case .bioactiveMix: return "Bioactive Mix"
        case .abg: return "ABG Mix"
        case .reptileCarpet: return "Reptile Carpet"
        case .tile: return "Tile"
        case .shelfLiner: return "Shelf Liner"
        case .bare: return "Bare Bottom"
        case .sand: return "Sand"
        case .calciumSand: return "Calcium Sand"
        case .excavatorClay: return "Excavator Clay"
        case .other: return "Other"
        }
    }

    public var isBioactiveSuitable: Bool {
        switch self {
        case .coconutFiber, .topsoil, .bioactiveMix, .abg, .orchidBark:
            return true
        default:
            return false
        }
    }
}

// MARK: - Environment Reading Entity

@Model
public final class EnvironmentReading {
    // MARK: - Identity
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date

    // MARK: - Timing
    public var recordedAt: Date

    // MARK: - Measurements
    public var temperatureF: Double?
    public var humidity: Int?
    public var lightLevel: Int? // 0-100 percentage

    // MARK: - Sensor
    public var sensorID: String?
    public var sensorLocation: SensorLocation?

    // MARK: - Enclosure
    public var enclosureID: UUID

    // MARK: - Init
    public init(
        id: UUID = UUID(),
        recordedAt: Date = Date(),
        enclosureID: UUID,
        temperatureF: Double? = nil,
        humidity: Int? = nil
    ) {
        self.id = id
        self.createdAt = Date()
        self.recordedAt = recordedAt
        self.enclosureID = enclosureID
        self.temperatureF = temperatureF
        self.humidity = humidity
    }
}

// MARK: - Sensor Location

public enum SensorLocation: String, Codable, CaseIterable {
    case hotSide = "hot_side"
    case coolSide = "cool_side"
    case ambient
    case basking
    case hide

    public var displayName: String {
        switch self {
        case .hotSide: return "Hot Side"
        case .coolSide: return "Cool Side"
        case .ambient: return "Ambient"
        case .basking: return "Basking"
        case .hide: return "Hide"
        }
    }
}
