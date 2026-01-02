import Foundation

// MARK: - Species Database

public struct SpeciesDatabase {

    // MARK: - Default Species

    public static let defaultSpecies: [SpeciesTemplate] = [
        // Snakes - Pythons
        SpeciesTemplate(
            commonName: "Ball Python",
            scientificName: "Python regius",
            category: .snake,
            averageAdultWeightGrams: 1800,
            feedingIntervalDays: 10,
            defaultPreyType: .rat,
            defaultPreySize: .small,
            temperatureRangeLow: 75,
            temperatureRangeHigh: 90,
            humidityRangeLow: 50,
            humidityRangeHigh: 60
        ),
        SpeciesTemplate(
            commonName: "Carpet Python",
            scientificName: "Morelia spilota",
            category: .snake,
            averageAdultWeightGrams: 4000,
            feedingIntervalDays: 14,
            defaultPreyType: .rat,
            defaultPreySize: .medium
        ),
        SpeciesTemplate(
            commonName: "Green Tree Python",
            scientificName: "Morelia viridis",
            category: .snake,
            averageAdultWeightGrams: 1200,
            feedingIntervalDays: 14,
            defaultPreyType: .rat,
            defaultPreySize: .small,
            temperatureRangeLow: 78,
            temperatureRangeHigh: 88,
            humidityRangeLow: 70,
            humidityRangeHigh: 80
        ),
        SpeciesTemplate(
            commonName: "Reticulated Python",
            scientificName: "Malayopython reticulatus",
            category: .snake,
            averageAdultWeightGrams: 30000,
            feedingIntervalDays: 21,
            defaultPreyType: .rabbit,
            defaultPreySize: .large
        ),
        SpeciesTemplate(
            commonName: "Blood Python",
            scientificName: "Python brongersmai",
            category: .snake,
            averageAdultWeightGrams: 9000,
            feedingIntervalDays: 14,
            defaultPreyType: .rat,
            defaultPreySize: .large
        ),
        SpeciesTemplate(
            commonName: "Children's Python",
            scientificName: "Antaresia childreni",
            category: .snake,
            averageAdultWeightGrams: 350,
            feedingIntervalDays: 7,
            defaultPreyType: .mouse,
            defaultPreySize: .small
        ),
        SpeciesTemplate(
            commonName: "Woma Python",
            scientificName: "Aspidites ramsayi",
            category: .snake,
            averageAdultWeightGrams: 3000,
            feedingIntervalDays: 14,
            defaultPreyType: .rat,
            defaultPreySize: .medium
        ),

        // Snakes - Boas
        SpeciesTemplate(
            commonName: "Boa Constrictor",
            scientificName: "Boa constrictor",
            category: .snake,
            averageAdultWeightGrams: 15000,
            feedingIntervalDays: 14,
            defaultPreyType: .rat,
            defaultPreySize: .large
        ),
        SpeciesTemplate(
            commonName: "Brazilian Rainbow Boa",
            scientificName: "Epicrates cenchria",
            category: .snake,
            averageAdultWeightGrams: 2500,
            feedingIntervalDays: 10,
            defaultPreyType: .rat,
            defaultPreySize: .medium,
            humidityRangeLow: 70,
            humidityRangeHigh: 90
        ),
        SpeciesTemplate(
            commonName: "Rosy Boa",
            scientificName: "Lichanura trivirgata",
            category: .snake,
            averageAdultWeightGrams: 400,
            feedingIntervalDays: 10,
            defaultPreyType: .mouse,
            defaultPreySize: .medium
        ),
        SpeciesTemplate(
            commonName: "Kenyan Sand Boa",
            scientificName: "Gongylophis colubrinus",
            category: .snake,
            averageAdultWeightGrams: 300,
            feedingIntervalDays: 10,
            defaultPreyType: .mouse,
            defaultPreySize: .small
        ),

        // Snakes - Colubrids
        SpeciesTemplate(
            commonName: "Corn Snake",
            scientificName: "Pantherophis guttatus",
            category: .snake,
            averageAdultWeightGrams: 500,
            feedingIntervalDays: 7,
            defaultPreyType: .mouse,
            defaultPreySize: .medium
        ),
        SpeciesTemplate(
            commonName: "California Kingsnake",
            scientificName: "Lampropeltis californiae",
            category: .snake,
            averageAdultWeightGrams: 700,
            feedingIntervalDays: 7,
            defaultPreyType: .mouse,
            defaultPreySize: .medium
        ),
        SpeciesTemplate(
            commonName: "Mexican Black Kingsnake",
            scientificName: "Lampropeltis getula nigrita",
            category: .snake,
            averageAdultWeightGrams: 900,
            feedingIntervalDays: 7,
            defaultPreyType: .mouse,
            defaultPreySize: .large
        ),
        SpeciesTemplate(
            commonName: "Milk Snake",
            scientificName: "Lampropeltis triangulum",
            category: .snake,
            averageAdultWeightGrams: 500,
            feedingIntervalDays: 7,
            defaultPreyType: .mouse,
            defaultPreySize: .medium
        ),
        SpeciesTemplate(
            commonName: "Hognose Snake",
            scientificName: "Heterodon nasicus",
            category: .snake,
            averageAdultWeightGrams: 250,
            feedingIntervalDays: 7,
            defaultPreyType: .mouse,
            defaultPreySize: .small
        ),
        SpeciesTemplate(
            commonName: "Rat Snake",
            scientificName: "Pantherophis obsoletus",
            category: .snake,
            averageAdultWeightGrams: 800,
            feedingIntervalDays: 7,
            defaultPreyType: .mouse,
            defaultPreySize: .large
        ),
        SpeciesTemplate(
            commonName: "Garter Snake",
            scientificName: "Thamnophis sirtalis",
            category: .snake,
            averageAdultWeightGrams: 150,
            feedingIntervalDays: 5,
            defaultPreyType: .earthworm,
            defaultPreySize: .standard
        ),

        // Geckos
        SpeciesTemplate(
            commonName: "Leopard Gecko",
            scientificName: "Eublepharis macularius",
            category: .gecko,
            averageAdultWeightGrams: 65,
            feedingIntervalDays: 3,
            defaultPreyType: .cricket,
            defaultPreySize: .adult,
            temperatureRangeLow: 75,
            temperatureRangeHigh: 90
        ),
        SpeciesTemplate(
            commonName: "Crested Gecko",
            scientificName: "Correlophus ciliatus",
            category: .gecko,
            averageAdultWeightGrams: 45,
            feedingIntervalDays: 2,
            defaultPreyType: .cricket,
            defaultPreySize: .small,
            temperatureRangeLow: 70,
            temperatureRangeHigh: 80,
            humidityRangeLow: 60,
            humidityRangeHigh: 80
        ),
        SpeciesTemplate(
            commonName: "Gargoyle Gecko",
            scientificName: "Rhacodactylus auriculatus",
            category: .gecko,
            averageAdultWeightGrams: 55,
            feedingIntervalDays: 2,
            defaultPreyType: .cricket,
            defaultPreySize: .small,
            humidityRangeLow: 50,
            humidityRangeHigh: 70
        ),
        SpeciesTemplate(
            commonName: "Leachianus Gecko",
            scientificName: "Rhacodactylus leachianus",
            category: .gecko,
            averageAdultWeightGrams: 280,
            feedingIntervalDays: 3,
            defaultPreyType: .dubia,
            defaultPreySize: .adult
        ),
        SpeciesTemplate(
            commonName: "African Fat-Tailed Gecko",
            scientificName: "Hemitheconyx caudicinctus",
            category: .gecko,
            averageAdultWeightGrams: 50,
            feedingIntervalDays: 3,
            defaultPreyType: .cricket,
            defaultPreySize: .adult,
            humidityRangeLow: 50,
            humidityRangeHigh: 70
        ),
        SpeciesTemplate(
            commonName: "Tokay Gecko",
            scientificName: "Gekko gecko",
            category: .gecko,
            averageAdultWeightGrams: 150,
            feedingIntervalDays: 2,
            defaultPreyType: .dubia,
            defaultPreySize: .adult
        ),
        SpeciesTemplate(
            commonName: "Day Gecko",
            scientificName: "Phelsuma madagascariensis",
            category: .gecko,
            averageAdultWeightGrams: 60,
            feedingIntervalDays: 2,
            defaultPreyType: .cricket,
            defaultPreySize: .adult
        ),

        // Lizards - Bearded Dragons
        SpeciesTemplate(
            commonName: "Bearded Dragon",
            scientificName: "Pogona vitticeps",
            category: .lizard,
            averageAdultWeightGrams: 500,
            feedingIntervalDays: 1,
            defaultPreyType: .dubia,
            defaultPreySize: .adult,
            temperatureRangeLow: 75,
            temperatureRangeHigh: 105
        ),

        // Lizards - Blue Tongue Skinks
        SpeciesTemplate(
            commonName: "Blue Tongue Skink",
            scientificName: "Tiliqua scincoides",
            category: .lizard,
            averageAdultWeightGrams: 600,
            feedingIntervalDays: 2,
            defaultPreyType: .other,
            defaultPreySize: .standard
        ),

        // Lizards - Monitors
        SpeciesTemplate(
            commonName: "Savannah Monitor",
            scientificName: "Varanus exanthematicus",
            category: .lizard,
            averageAdultWeightGrams: 5000,
            feedingIntervalDays: 3,
            defaultPreyType: .rat,
            defaultPreySize: .small
        ),
        SpeciesTemplate(
            commonName: "Ackie Monitor",
            scientificName: "Varanus acanthurus",
            category: .lizard,
            averageAdultWeightGrams: 300,
            feedingIntervalDays: 2,
            defaultPreyType: .dubia,
            defaultPreySize: .adult
        ),
        SpeciesTemplate(
            commonName: "Black Throat Monitor",
            scientificName: "Varanus albigularis ionidesi",
            category: .lizard,
            averageAdultWeightGrams: 15000,
            feedingIntervalDays: 7,
            defaultPreyType: .rabbit,
            defaultPreySize: .medium
        ),

        // Lizards - Tegus
        SpeciesTemplate(
            commonName: "Argentine Black and White Tegu",
            scientificName: "Salvator merianae",
            category: .lizard,
            averageAdultWeightGrams: 7000,
            feedingIntervalDays: 2,
            defaultPreyType: .other,
            defaultPreySize: .large
        ),
        SpeciesTemplate(
            commonName: "Red Tegu",
            scientificName: "Salvator rufescens",
            category: .lizard,
            averageAdultWeightGrams: 5000,
            feedingIntervalDays: 2,
            defaultPreyType: .other,
            defaultPreySize: .large
        ),

        // Lizards - Other
        SpeciesTemplate(
            commonName: "Green Iguana",
            scientificName: "Iguana iguana",
            category: .lizard,
            averageAdultWeightGrams: 4000,
            feedingIntervalDays: 1,
            defaultPreyType: .other,
            defaultPreySize: .standard
        ),
        SpeciesTemplate(
            commonName: "Uromastyx",
            scientificName: "Uromastyx sp.",
            category: .lizard,
            averageAdultWeightGrams: 400,
            feedingIntervalDays: 1,
            defaultPreyType: .other,
            defaultPreySize: .standard,
            humidityRangeLow: 20,
            humidityRangeHigh: 40
        ),
        SpeciesTemplate(
            commonName: "Chinese Water Dragon",
            scientificName: "Physignathus cocincinus",
            category: .lizard,
            averageAdultWeightGrams: 500,
            feedingIntervalDays: 2,
            defaultPreyType: .cricket,
            defaultPreySize: .adult,
            humidityRangeLow: 70,
            humidityRangeHigh: 80
        ),

        // Tortoises
        SpeciesTemplate(
            commonName: "Russian Tortoise",
            scientificName: "Testudo horsfieldii",
            category: .tortoise,
            averageAdultWeightGrams: 1500,
            feedingIntervalDays: 1,
            defaultPreyType: .other,
            defaultPreySize: .standard
        ),
        SpeciesTemplate(
            commonName: "Sulcata Tortoise",
            scientificName: "Centrochelys sulcata",
            category: .tortoise,
            averageAdultWeightGrams: 45000,
            feedingIntervalDays: 1,
            defaultPreyType: .other,
            defaultPreySize: .standard
        ),
        SpeciesTemplate(
            commonName: "Red-Footed Tortoise",
            scientificName: "Chelonoidis carbonarius",
            category: .tortoise,
            averageAdultWeightGrams: 5000,
            feedingIntervalDays: 1,
            defaultPreyType: .other,
            defaultPreySize: .standard,
            humidityRangeLow: 60,
            humidityRangeHigh: 80
        ),
        SpeciesTemplate(
            commonName: "Hermann's Tortoise",
            scientificName: "Testudo hermanni",
            category: .tortoise,
            averageAdultWeightGrams: 1800,
            feedingIntervalDays: 1,
            defaultPreyType: .other,
            defaultPreySize: .standard
        ),
        SpeciesTemplate(
            commonName: "Greek Tortoise",
            scientificName: "Testudo graeca",
            category: .tortoise,
            averageAdultWeightGrams: 2000,
            feedingIntervalDays: 1,
            defaultPreyType: .other,
            defaultPreySize: .standard
        ),
        SpeciesTemplate(
            commonName: "Leopard Tortoise",
            scientificName: "Stigmochelys pardalis",
            category: .tortoise,
            averageAdultWeightGrams: 18000,
            feedingIntervalDays: 1,
            defaultPreyType: .other,
            defaultPreySize: .standard
        ),

        // Frogs
        SpeciesTemplate(
            commonName: "Pacman Frog",
            scientificName: "Ceratophrys ornata",
            category: .frog,
            averageAdultWeightGrams: 500,
            feedingIntervalDays: 5,
            defaultPreyType: .dubia,
            defaultPreySize: .adult,
            humidityRangeLow: 60,
            humidityRangeHigh: 80
        ),
        SpeciesTemplate(
            commonName: "Whites Tree Frog",
            scientificName: "Litoria caerulea",
            category: .frog,
            averageAdultWeightGrams: 100,
            feedingIntervalDays: 2,
            defaultPreyType: .cricket,
            defaultPreySize: .adult,
            humidityRangeLow: 50,
            humidityRangeHigh: 70
        ),
        SpeciesTemplate(
            commonName: "Red-Eyed Tree Frog",
            scientificName: "Agalychnis callidryas",
            category: .frog,
            averageAdultWeightGrams: 12,
            feedingIntervalDays: 2,
            defaultPreyType: .cricket,
            defaultPreySize: .small,
            humidityRangeLow: 80,
            humidityRangeHigh: 100
        ),
        SpeciesTemplate(
            commonName: "Poison Dart Frog",
            scientificName: "Dendrobates sp.",
            category: .frog,
            averageAdultWeightGrams: 5,
            feedingIntervalDays: 1,
            defaultPreyType: .other,
            defaultPreySize: .micro,
            humidityRangeLow: 80,
            humidityRangeHigh: 100
        ),
        SpeciesTemplate(
            commonName: "African Bullfrog",
            scientificName: "Pyxicephalus adspersus",
            category: .frog,
            averageAdultWeightGrams: 1400,
            feedingIntervalDays: 5,
            defaultPreyType: .mouse,
            defaultPreySize: .small
        ),

        // Chameleons
        SpeciesTemplate(
            commonName: "Veiled Chameleon",
            scientificName: "Chamaeleo calyptratus",
            category: .lizard,
            averageAdultWeightGrams: 150,
            feedingIntervalDays: 2,
            defaultPreyType: .cricket,
            defaultPreySize: .adult,
            humidityRangeLow: 50,
            humidityRangeHigh: 70
        ),
        SpeciesTemplate(
            commonName: "Panther Chameleon",
            scientificName: "Furcifer pardalis",
            category: .lizard,
            averageAdultWeightGrams: 180,
            feedingIntervalDays: 2,
            defaultPreyType: .cricket,
            defaultPreySize: .adult,
            humidityRangeLow: 60,
            humidityRangeHigh: 80
        ),
        SpeciesTemplate(
            commonName: "Jackson's Chameleon",
            scientificName: "Trioceros jacksonii",
            category: .lizard,
            averageAdultWeightGrams: 90,
            feedingIntervalDays: 2,
            defaultPreyType: .cricket,
            defaultPreySize: .adult,
            humidityRangeLow: 50,
            humidityRangeHigh: 80
        )
    ]

    // MARK: - Get Species by Category

    public static func species(for category: SpeciesCategory) -> [SpeciesTemplate] {
        return defaultSpecies.filter { $0.category == category }
    }

    // MARK: - Search Species

    public static func search(_ query: String) -> [SpeciesTemplate] {
        guard !query.isEmpty else { return defaultSpecies }

        let lowercased = query.lowercased()
        return defaultSpecies.filter {
            $0.commonName.lowercased().contains(lowercased) ||
            $0.scientificName.lowercased().contains(lowercased)
        }
    }
}

// MARK: - Species Template

public struct SpeciesTemplate: Identifiable, Hashable {
    public let id = UUID()
    public let commonName: String
    public let scientificName: String
    public let category: SpeciesCategory
    public let averageAdultWeightGrams: Double
    public let feedingIntervalDays: Int
    public let defaultPreyType: PreyType
    public let defaultPreySize: PreySize
    public let temperatureRangeLow: Double
    public let temperatureRangeHigh: Double
    public let humidityRangeLow: Int
    public let humidityRangeHigh: Int

    public init(
        commonName: String,
        scientificName: String,
        category: SpeciesCategory,
        averageAdultWeightGrams: Double,
        feedingIntervalDays: Int,
        defaultPreyType: PreyType,
        defaultPreySize: PreySize,
        temperatureRangeLow: Double = 75,
        temperatureRangeHigh: Double = 85,
        humidityRangeLow: Int = 40,
        humidityRangeHigh: Int = 60
    ) {
        self.commonName = commonName
        self.scientificName = scientificName
        self.category = category
        self.averageAdultWeightGrams = averageAdultWeightGrams
        self.feedingIntervalDays = feedingIntervalDays
        self.defaultPreyType = defaultPreyType
        self.defaultPreySize = defaultPreySize
        self.temperatureRangeLow = temperatureRangeLow
        self.temperatureRangeHigh = temperatureRangeHigh
        self.humidityRangeLow = humidityRangeLow
        self.humidityRangeHigh = humidityRangeHigh
    }

    public static func == (lhs: SpeciesTemplate, rhs: SpeciesTemplate) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Note: SpeciesCategory enum is defined in Species.swift
