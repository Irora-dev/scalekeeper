import Foundation
import SwiftData

// MARK: - Feeding Service

@MainActor
public final class FeedingService: ObservableObject {
    public static let shared = FeedingService()

    private let dataService: DataService

    // MARK: - Published State
    @Published public private(set) var dueToday: [Animal] = []
    @Published public private(set) var overdue: [Animal] = []
    @Published public private(set) var upcoming: [Animal] = []
    @Published public private(set) var fedToday: [Animal] = []
    @Published public private(set) var isLoading = false

    // MARK: - Init
    private init(dataService: DataService = .shared) {
        self.dataService = dataService
    }

    // MARK: - Public Methods

    /// Refresh all feeding lists
    public func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let animals = try dataService.fetchActiveAnimals()
            let today = Calendar.current.startOfDay(for: Date())

            var due: [Animal] = []
            var late: [Animal] = []
            var soon: [Animal] = []
            var done: [Animal] = []

            for animal in animals {
                let status = try feedingStatus(for: animal)

                switch status {
                case .fedToday:
                    done.append(animal)
                case .dueToday:
                    due.append(animal)
                case .overdue:
                    late.append(animal)
                case .upcoming:
                    soon.append(animal)
                case .notScheduled:
                    // Include in upcoming if no schedule
                    soon.append(animal)
                }
            }

            self.dueToday = due
            self.overdue = late
            self.upcoming = soon
            self.fedToday = done
        } catch {
            print("Error refreshing feeding data: \(error)")
        }
    }

    /// Log a feeding event for an animal
    public func logFeeding(
        for animal: Animal,
        preyType: PreyType,
        preySize: PreySize,
        preyState: PreyState = .frozenThawed,
        quantity: Int = 1,
        response: FeedingResponse = .struckImmediately,
        notes: String? = nil
    ) throws {
        let feeding = FeedingEvent(
            feedingDate: Date(),
            preyType: preyType,
            preySize: preySize,
            preyState: preyState,
            quantity: quantity,
            feedingResponse: response
        )
        feeding.notes = notes
        feeding.animal = animal

        dataService.insert(feeding)
        try dataService.save()

        Task {
            await refresh()
        }
    }

    /// Quick feed with animal's default prey
    public func quickFeed(animal: Animal) throws {
        // Use most recent feeding as template
        guard let lastFeeding = try dataService.lastFeeding(for: animal) else {
            throw FeedingError.noFeedingHistory
        }

        try logFeeding(
            for: animal,
            preyType: lastFeeding.preyType,
            preySize: lastFeeding.preySize,
            preyState: lastFeeding.preyState,
            quantity: lastFeeding.quantity,
            response: .struckImmediately
        )
    }

    /// Batch feed multiple animals
    public func batchFeed(
        animals: [Animal],
        preyType: PreyType,
        preySize: PreySize,
        preyState: PreyState = .frozenThawed,
        quantity: Int = 1
    ) throws {
        for animal in animals {
            try logFeeding(
                for: animal,
                preyType: preyType,
                preySize: preySize,
                preyState: preyState,
                quantity: quantity
            )
        }
    }

    /// Get feeding status for a specific animal
    public func feedingStatus(for animal: Animal) throws -> FeedingStatus {
        let lastFeeding = try dataService.lastFeeding(for: animal)
        let today = Calendar.current.startOfDay(for: Date())

        // Check if fed today
        if let last = lastFeeding {
            let lastFeedingDay = Calendar.current.startOfDay(for: last.feedingDate)
            if lastFeedingDay == today {
                return .fedToday
            }

            // Calculate next feeding based on species default or custom interval
            let intervalDays = defaultFeedingInterval(for: animal)
            let nextFeeding = Calendar.current.date(byAdding: .day, value: intervalDays, to: last.feedingDate)!

            if nextFeeding < today {
                return .overdue(daysPast: Calendar.current.dateComponents([.day], from: nextFeeding, to: today).day ?? 0)
            } else if Calendar.current.isDateInToday(nextFeeding) {
                return .dueToday
            } else {
                return .upcoming(daysUntil: Calendar.current.dateComponents([.day], from: today, to: nextFeeding).day ?? 0)
            }
        }

        return .notScheduled
    }

    /// Get feeding statistics for an animal
    public func feedingStats(for animal: Animal) throws -> FeedingStats {
        let feedings = try dataService.fetchFeedings(for: animal)

        let successfulFeedings = feedings.filter { $0.feedingResponse.isSuccessful }
        let refusals = feedings.filter { $0.feedingResponse == .refused }

        // Calculate average interval
        var intervals: [Int] = []
        for i in 0..<(feedings.count - 1) {
            let days = Calendar.current.dateComponents(
                [.day],
                from: feedings[i + 1].feedingDate,
                to: feedings[i].feedingDate
            ).day ?? 0
            intervals.append(days)
        }

        let avgInterval = intervals.isEmpty ? 0 : intervals.reduce(0, +) / intervals.count

        return FeedingStats(
            totalFeedings: feedings.count,
            successfulFeedings: successfulFeedings.count,
            refusals: refusals.count,
            averageIntervalDays: avgInterval,
            lastFeedingDate: feedings.first?.feedingDate
        )
    }

    // MARK: - Hunger Duration (NEW - "Udon Feature")

    /// Calculate hunger duration for an animal
    public func hungerDuration(for animal: Animal) throws -> HungerDuration {
        let feedings = try dataService.fetchFeedings(for: animal)

        // Find last successful feeding
        let successfulFeedings = feedings.filter { $0.feedingResponse.isSuccessful }
        let lastSuccessful = successfulFeedings.first

        // Calculate days since last meal
        let daysSinceLastMeal: Int?
        if let last = lastSuccessful {
            daysSinceLastMeal = Calendar.current.dateComponents([.day], from: last.feedingDate, to: Date()).day
        } else {
            daysSinceLastMeal = nil
        }

        // Count consecutive refusals
        var refusalCount = 0
        for feeding in feedings {
            if feeding.feedingResponse == .refused {
                refusalCount += 1
            } else if feeding.feedingResponse.isSuccessful {
                break
            }
        }

        // Calculate weight change during strike (if we have weight data)
        var weightChangeDuringStrike: Double?
        if let lastSuccessfulDate = lastSuccessful?.feedingDate {
            let weights = try dataService.fetchWeights(for: animal)
            let weightsBeforeStrike = weights.filter { $0.recordedAt <= lastSuccessfulDate }
            let weightsDuringStrike = weights.filter { $0.recordedAt > lastSuccessfulDate }

            if let beforeWeight = weightsBeforeStrike.first?.weightGrams,
               let currentWeight = weightsDuringStrike.first?.weightGrams,
               beforeWeight > 0 {
                weightChangeDuringStrike = ((currentWeight - beforeWeight) / beforeWeight) * 100
            }
        }

        return HungerDuration(
            daysSinceLastMeal: daysSinceLastMeal,
            lastSuccessfulFeeding: lastSuccessful?.feedingDate,
            refusalCount: refusalCount,
            weightChangeDuringStrike: weightChangeDuringStrike
        )
    }

    /// Get comprehensive feeding insight for an animal
    public func feedingInsight(for animal: Animal, days: Int = 90) throws -> FeedingInsight {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!

        let allFeedings = try dataService.fetchFeedings(for: animal)
        let recentFeedings = allFeedings.filter { $0.feedingDate >= cutoff }

        let allWeights = try dataService.fetchWeights(for: animal)
        let recentWeights = allWeights.filter { $0.recordedAt >= cutoff }

        let hunger = try hungerDuration(for: animal)

        return FeedingInsight(
            animal: animal,
            recentFeedings: recentFeedings,
            weights: recentWeights,
            hungerDuration: hunger
        )
    }

    /// Get animals with extended hunger (for picky eater dashboard)
    public func animalsWithExtendedHunger() async throws -> [(Animal, HungerDuration)] {
        let animals = try dataService.fetchActiveAnimals()
        var results: [(Animal, HungerDuration)] = []

        for animal in animals {
            let hunger = try hungerDuration(for: animal)
            if hunger.urgencyLevel != .normal && hunger.urgencyLevel != .unknown {
                results.append((animal, hunger))
            }
        }

        // Sort by urgency (critical first)
        return results.sorted { a, b in
            a.1.daysSinceLastMeal ?? 0 > b.1.daysSinceLastMeal ?? 0
        }
    }

    // MARK: - Private Helpers

    private func defaultFeedingInterval(for animal: Animal) -> Int {
        // TODO: Look up species default, fall back to reasonable default
        // For now, return 7 days
        return 7
    }
}

// MARK: - Feeding Status

public enum FeedingStatus: Equatable {
    case fedToday
    case dueToday
    case overdue(daysPast: Int)
    case upcoming(daysUntil: Int)
    case notScheduled

    public var displayName: String {
        switch self {
        case .fedToday:
            return "Fed Today"
        case .dueToday:
            return "Due Today"
        case .overdue(let days):
            return "Overdue (\(days)d)"
        case .upcoming(let days):
            return "In \(days) day\(days == 1 ? "" : "s")"
        case .notScheduled:
            return "Not Scheduled"
        }
    }

    public var priority: Int {
        switch self {
        case .overdue: return 0
        case .dueToday: return 1
        case .upcoming: return 2
        case .fedToday: return 3
        case .notScheduled: return 4
        }
    }
}

// MARK: - Feeding Stats

public struct FeedingStats {
    public let totalFeedings: Int
    public let successfulFeedings: Int
    public let refusals: Int
    public let averageIntervalDays: Int
    public let lastFeedingDate: Date?

    public var successRate: Double {
        guard totalFeedings > 0 else { return 0 }
        return Double(successfulFeedings) / Double(totalFeedings) * 100
    }

    public var refusalRate: Double {
        guard totalFeedings > 0 else { return 0 }
        return Double(refusals) / Double(totalFeedings) * 100
    }
}

// MARK: - Feeding Errors

public enum FeedingError: Error, LocalizedError {
    case noFeedingHistory
    case animalNotFound
    case saveFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .noFeedingHistory:
            return "No feeding history found for this animal"
        case .animalNotFound:
            return "Animal not found"
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        }
    }
}
