import Foundation
import SwiftData

// MARK: - Data Service

@MainActor
public final class DataService: ObservableObject {
    public static let shared = DataService()

    // MARK: - Container
    public let container: ModelContainer

    // MARK: - Context
    public var modelContext: ModelContext {
        container.mainContext
    }

    // MARK: - Init
    private init() {
        do {
            // Note: CloudKit disabled until all model attributes have defaults
            // To enable: cloudKitDatabase: .private(ScaleConstants.cloudKitContainerIdentifier)
            let config = ModelConfiguration(
                schema: ScaleSchema.schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                groupContainer: .identifier(ScaleConstants.appGroupIdentifier),
                cloudKitDatabase: .none
            )

            container = try ModelContainer(
                for: ScaleSchema.schema,
                configurations: [config]
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    // MARK: - Preview Container
    public static func previewContainer() -> ModelContainer {
        do {
            let config = ModelConfiguration(
                schema: ScaleSchema.schema,
                isStoredInMemoryOnly: true
            )
            return try ModelContainer(for: ScaleSchema.schema, configurations: [config])
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }

    // MARK: - Generic CRUD Operations

    public func save() throws {
        try modelContext.save()
    }

    public func insert<T: PersistentModel>(_ model: T) {
        modelContext.insert(model)
    }

    public func delete<T: PersistentModel>(_ model: T) {
        modelContext.delete(model)
    }

    public func fetch<T: PersistentModel>(
        _ type: T.Type,
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = []
    ) throws -> [T] {
        let descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
        return try modelContext.fetch(descriptor)
    }

    public func count<T: PersistentModel>(
        _ type: T.Type,
        predicate: Predicate<T>? = nil
    ) throws -> Int {
        let descriptor = FetchDescriptor<T>(predicate: predicate)
        return try modelContext.fetchCount(descriptor)
    }
}

// MARK: - Animal-Specific Operations

extension DataService {
    public func fetchAllAnimals() throws -> [Animal] {
        let descriptor = FetchDescriptor<Animal>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func fetchActiveAnimals() throws -> [Animal] {
        let activeStatus = AnimalStatus.active
        let predicate = #Predicate<Animal> { animal in
            animal.status == activeStatus
        }
        let descriptor = FetchDescriptor<Animal>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func fetchAnimal(byID id: UUID) throws -> Animal? {
        let predicate = #Predicate<Animal> { $0.id == id }
        let descriptor = FetchDescriptor<Animal>(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    public func animalCount() throws -> Int {
        try count(Animal.self)
    }

    public func activeAnimalCount() throws -> Int {
        let activeStatus = AnimalStatus.active
        let predicate = #Predicate<Animal> { $0.status == activeStatus }
        return try count(Animal.self, predicate: predicate)
    }
}

// MARK: - Species Operations

extension DataService {
    public func fetchAllSpecies() throws -> [Species] {
        let descriptor = FetchDescriptor<Species>(
            sortBy: [SortDescriptor(\.commonName)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func fetchSpecies(byCategory category: SpeciesCategory) throws -> [Species] {
        let predicate = #Predicate<Species> { $0.category == category }
        let descriptor = FetchDescriptor<Species>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.commonName)]
        )
        return try modelContext.fetch(descriptor)
    }
}

// MARK: - Feeding Operations

extension DataService {
    public func fetchFeedings(for animal: Animal, limit: Int? = nil) throws -> [FeedingEvent] {
        let animalID = animal.id
        let predicate = #Predicate<FeedingEvent> { feeding in
            feeding.animal?.id == animalID
        }
        var descriptor = FetchDescriptor<FeedingEvent>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.feedingDate, order: .reverse)]
        )
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        return try modelContext.fetch(descriptor)
    }

    public func lastFeeding(for animal: Animal) throws -> FeedingEvent? {
        try fetchFeedings(for: animal, limit: 1).first
    }

    public func feedingsToday() throws -> [FeedingEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = #Predicate<FeedingEvent> { feeding in
            feeding.feedingDate >= startOfDay && feeding.feedingDate < endOfDay
        }
        let descriptor = FetchDescriptor<FeedingEvent>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.feedingDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
}

// MARK: - User Operations

extension DataService {
    public func fetchCurrentUser() throws -> ScaleUser? {
        let descriptor = FetchDescriptor<ScaleUser>()
        return try modelContext.fetch(descriptor).first
    }

    public func getOrCreateUser() throws -> ScaleUser {
        if let existingUser = try fetchCurrentUser() {
            return existingUser
        }

        let newUser = ScaleUser()
        modelContext.insert(newUser)
        try modelContext.save()
        return newUser
    }
}

// MARK: - Weight Operations

extension DataService {
    public func fetchWeights(for animal: Animal, limit: Int? = nil) throws -> [WeightRecord] {
        let animalID = animal.id
        let predicate = #Predicate<WeightRecord> { record in
            record.animal?.id == animalID
        }
        var descriptor = FetchDescriptor<WeightRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        return try modelContext.fetch(descriptor)
    }

    public func lastWeight(for animal: Animal) throws -> WeightRecord? {
        try fetchWeights(for: animal, limit: 1).first
    }
}

// MARK: - Length Operations

extension DataService {
    public func fetchLengths(for animal: Animal, limit: Int? = nil) throws -> [LengthRecord] {
        let animalID = animal.id
        let predicate = #Predicate<LengthRecord> { record in
            record.animal?.id == animalID
        }
        var descriptor = FetchDescriptor<LengthRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        return try modelContext.fetch(descriptor)
    }

    public func lastLength(for animal: Animal) throws -> LengthRecord? {
        try fetchLengths(for: animal, limit: 1).first
    }
}

// MARK: - Enclosure Operations

extension DataService {
    public func fetchEnclosures() throws -> [Enclosure] {
        let descriptor = FetchDescriptor<Enclosure>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func fetchEnclosure(byID id: UUID) throws -> Enclosure? {
        let predicate = #Predicate<Enclosure> { $0.id == id }
        let descriptor = FetchDescriptor<Enclosure>(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }
}

// MARK: - Cleaning Operations

extension DataService {
    public func fetchCleaningEvents(for enclosure: Enclosure, limit: Int? = nil) throws -> [CleaningEvent] {
        let enclosureID = enclosure.id
        let predicate = #Predicate<CleaningEvent> { event in
            event.enclosure?.id == enclosureID
        }
        var descriptor = FetchDescriptor<CleaningEvent>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.cleanedAt, order: .reverse)]
        )
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        return try modelContext.fetch(descriptor)
    }

    public func lastCleaning(for enclosure: Enclosure, type: CleaningType) throws -> CleaningEvent? {
        let enclosureID = enclosure.id
        let predicate = #Predicate<CleaningEvent> { event in
            event.enclosure?.id == enclosureID && event.cleaningType == type
        }
        var descriptor = FetchDescriptor<CleaningEvent>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.cleanedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    public func fetchCleaningSchedules(for enclosure: Enclosure) throws -> [CleaningSchedule] {
        let enclosureID = enclosure.id
        let predicate = #Predicate<CleaningSchedule> { schedule in
            schedule.enclosure?.id == enclosureID
        }
        let descriptor = FetchDescriptor<CleaningSchedule>(predicate: predicate)
        return try modelContext.fetch(descriptor)
    }
}

// MARK: - Medication/Treatment Operations

extension DataService {
    public func fetchActiveTreatments() throws -> [TreatmentPlan] {
        let activeStatus = TreatmentStatus.active
        let predicate = #Predicate<TreatmentPlan> { plan in
            plan.status == activeStatus
        }
        let descriptor = FetchDescriptor<TreatmentPlan>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func fetchTreatments(for animal: Animal) throws -> [TreatmentPlan] {
        let animalID = animal.id
        let predicate = #Predicate<TreatmentPlan> { plan in
            plan.animal?.id == animalID
        }
        let descriptor = FetchDescriptor<TreatmentPlan>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func fetchMedications() throws -> [Medication] {
        let descriptor = FetchDescriptor<Medication>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }
}

// MARK: - Brumation Operations

extension DataService {
    public func fetchBrumationCycles(for animal: Animal) throws -> [BrumationCycle] {
        let animalID = animal.id
        let predicate = #Predicate<BrumationCycle> { cycle in
            cycle.animal?.id == animalID
        }
        let descriptor = FetchDescriptor<BrumationCycle>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.year, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func fetchBrumationCycles() throws -> [BrumationCycle] {
        let descriptor = FetchDescriptor<BrumationCycle>(
            sortBy: [SortDescriptor(\.year, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func fetchActiveBrumations() throws -> [BrumationCycle] {
        let plannedStatus = BrumationStatus.planned
        let cooldownStatus = BrumationStatus.cooldown
        let activeStatus = BrumationStatus.active
        let warmupStatus = BrumationStatus.warmup

        let predicate = #Predicate<BrumationCycle> { cycle in
            cycle.status == plannedStatus ||
            cycle.status == cooldownStatus ||
            cycle.status == activeStatus ||
            cycle.status == warmupStatus
        }
        let descriptor = FetchDescriptor<BrumationCycle>(predicate: predicate)
        return try modelContext.fetch(descriptor)
    }
}

// MARK: - Shed Operations

extension DataService {
    public func fetchShedRecords(for animal: Animal, limit: Int? = nil) throws -> [ShedRecord] {
        let animalID = animal.id
        let predicate = #Predicate<ShedRecord> { record in
            record.animal?.id == animalID
        }
        var descriptor = FetchDescriptor<ShedRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.shedDate, order: .reverse)]
        )
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        return try modelContext.fetch(descriptor)
    }

    public func lastShed(for animal: Animal) throws -> ShedRecord? {
        try fetchShedRecords(for: animal, limit: 1).first
    }
}

// MARK: - Health Operations

extension DataService {
    public func fetchHealthNotes(for animal: Animal, limit: Int? = nil) throws -> [HealthNote] {
        let animalID = animal.id
        let predicate = #Predicate<HealthNote> { note in
            note.animal?.id == animalID
        }
        var descriptor = FetchDescriptor<HealthNote>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        return try modelContext.fetch(descriptor)
    }
}

// MARK: - Photo Operations

extension DataService {
    public func fetchPhotos(for animal: Animal, limit: Int? = nil) throws -> [AnimalPhoto] {
        let animalID = animal.id
        let predicate = #Predicate<AnimalPhoto> { photo in
            photo.animal?.id == animalID
        }
        var descriptor = FetchDescriptor<AnimalPhoto>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        return try modelContext.fetch(descriptor)
    }

    public func fetchPhotos(for animal: Animal, type: AnimalPhotoType) throws -> [AnimalPhoto] {
        let animalID = animal.id
        let predicate = #Predicate<AnimalPhoto> { photo in
            photo.animal?.id == animalID && photo.photoType == type
        }
        let descriptor = FetchDescriptor<AnimalPhoto>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func primaryPhoto(for animal: Animal) throws -> AnimalPhoto? {
        let animalID = animal.id
        let predicate = #Predicate<AnimalPhoto> { photo in
            photo.animal?.id == animalID && photo.isPrimary == true
        }
        var descriptor = FetchDescriptor<AnimalPhoto>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}

// MARK: - Feeding Routine Operations

extension DataService {
    public func fetchFeedingRoutines() throws -> [FeedingRoutine] {
        let descriptor = FetchDescriptor<FeedingRoutine>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func fetchActiveFeedingRoutines() throws -> [FeedingRoutine] {
        let predicate = #Predicate<FeedingRoutine> { $0.isActive == true }
        let descriptor = FetchDescriptor<FeedingRoutine>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func fetchFeedingRoutine(byID id: UUID) throws -> FeedingRoutine? {
        let predicate = #Predicate<FeedingRoutine> { $0.id == id }
        let descriptor = FetchDescriptor<FeedingRoutine>(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    public func fetchFeedingRoutines(for animal: Animal) throws -> [FeedingRoutine] {
        // Get all routines and filter by animal
        let allRoutines = try fetchFeedingRoutines()
        return allRoutines.filter { routine in
            routine.getAnimalIDs().contains(animal.id)
        }
    }

    public func upcomingWeekFeedings() throws -> [ScheduledFeeding] {
        let routines = try fetchActiveFeedingRoutines()
        var allFeedings: [ScheduledFeeding] = []

        for routine in routines {
            allFeedings.append(contentsOf: routine.getUpcomingWeekFeedings())
        }

        return allFeedings.sorted { $0.date < $1.date }
    }
}
