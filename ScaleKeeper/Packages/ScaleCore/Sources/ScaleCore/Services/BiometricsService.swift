import Foundation
import SwiftData

// MARK: - Biometrics Service

@MainActor
public final class BiometricsService: ObservableObject {
    public static let shared = BiometricsService()

    private let dataService: DataService

    // MARK: - Init
    private init(dataService: DataService = .shared) {
        self.dataService = dataService
    }

    // MARK: - Length Records

    /// Log a length measurement
    public func logLength(
        for animal: Animal,
        lengthCm: Double,
        method: MeasurementMethod = .estimated,
        notes: String? = nil
    ) throws -> LengthRecord {
        let record = LengthRecord(
            recordedAt: Date(),
            lengthCm: lengthCm,
            measurementMethod: method
        )
        record.animal = animal
        record.notes = notes

        dataService.insert(record)
        try dataService.save()

        return record
    }

    /// Get length history for an animal
    public func lengthHistory(for animal: Animal, limit: Int? = nil) throws -> [LengthRecord] {
        return try dataService.fetchLengths(for: animal, limit: limit)
    }

    /// Get most recent length for an animal
    public func currentLength(for animal: Animal) throws -> LengthRecord? {
        let records = try dataService.fetchLengths(for: animal, limit: 1)
        return records.first
    }

    /// Calculate length change between two records
    public func lengthChange(for animal: Animal, days: Int = 30) throws -> LengthChange? {
        let records = try dataService.fetchLengths(for: animal, limit: nil)
        guard records.count >= 2 else { return nil }

        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let oldRecords = records.filter { $0.recordedAt <= cutoff }

        guard let current = records.first,
              let previous = oldRecords.first else { return nil }

        let daysBetween = Calendar.current.dateComponents(
            [.day],
            from: previous.recordedAt,
            to: current.recordedAt
        ).day ?? 1

        return LengthChange(
            previousLength: previous.lengthCm,
            currentLength: current.lengthCm,
            daysBetween: daysBetween
        )
    }

    // MARK: - Body Condition

    /// Calculate body condition score for an animal
    public func bodyCondition(for animal: Animal) throws -> BodyConditionScore? {
        let weights = try dataService.fetchWeights(for: animal)
        let lengths = try dataService.fetchLengths(for: animal, limit: 1)

        guard let currentWeight = weights.first,
              let currentLength = lengths.first else { return nil }

        return BodyConditionScore(
            weightGrams: currentWeight.weightGrams,
            lengthCm: currentLength.lengthCm
        )
    }

    // MARK: - Growth Analysis

    /// Get growth data for charts
    public func growthData(for animal: Animal, months: Int = 12) throws -> GrowthData {
        let cutoff = Calendar.current.date(byAdding: .month, value: -months, to: Date())!

        let weights = try dataService.fetchWeights(for: animal)
            .filter { $0.recordedAt >= cutoff }
            .sorted { $0.recordedAt < $1.recordedAt }

        let lengths = try dataService.fetchLengths(for: animal, limit: nil)
            .filter { $0.recordedAt >= cutoff }
            .sorted { $0.recordedAt < $1.recordedAt }

        return GrowthData(
            weights: weights,
            lengths: lengths,
            startDate: cutoff,
            endDate: Date()
        )
    }

    /// Calculate growth rate (percentage per month)
    public func growthRate(for animal: Animal, months: Int = 3) throws -> GrowthRate? {
        let cutoff = Calendar.current.date(byAdding: .month, value: -months, to: Date())!

        let weights = try dataService.fetchWeights(for: animal)
            .filter { $0.recordedAt >= cutoff }
            .sorted { $0.recordedAt < $1.recordedAt }

        guard weights.count >= 2,
              let first = weights.first,
              let last = weights.last else { return nil }

        let daysBetween = Calendar.current.dateComponents(
            [.day],
            from: first.recordedAt,
            to: last.recordedAt
        ).day ?? 1

        guard daysBetween > 0 else { return nil }

        let weightChange = last.weightGrams - first.weightGrams
        let percentChange = (weightChange / first.weightGrams) * 100
        let monthlyRate = percentChange / (Double(daysBetween) / 30.0)

        return GrowthRate(
            totalChange: weightChange,
            percentChange: percentChange,
            monthlyRate: monthlyRate,
            periodDays: daysBetween
        )
    }
}

// MARK: - Growth Data

public struct GrowthData {
    public let weights: [WeightRecord]
    public let lengths: [LengthRecord]
    public let startDate: Date
    public let endDate: Date

    public var weightDataPoints: [(date: Date, value: Double)] {
        weights.map { ($0.recordedAt, $0.weightGrams) }
    }

    public var lengthDataPoints: [(date: Date, value: Double)] {
        lengths.map { ($0.recordedAt, $0.lengthCm) }
    }

    public var hasWeightData: Bool {
        !weights.isEmpty
    }

    public var hasLengthData: Bool {
        !lengths.isEmpty
    }

    public init(weights: [WeightRecord], lengths: [LengthRecord], startDate: Date, endDate: Date) {
        self.weights = weights
        self.lengths = lengths
        self.startDate = startDate
        self.endDate = endDate
    }
}

// MARK: - Growth Rate

public struct GrowthRate {
    public let totalChange: Double // grams
    public let percentChange: Double
    public let monthlyRate: Double // percent per month
    public let periodDays: Int

    public var trend: GrowthTrend {
        if monthlyRate > 2 {
            return .growing
        } else if monthlyRate < -2 {
            return .shrinking
        } else {
            return .stable
        }
    }

    public var displayText: String {
        if monthlyRate > 0 {
            return String(format: "+%.1f%% per month", monthlyRate)
        } else {
            return String(format: "%.1f%% per month", monthlyRate)
        }
    }

    public init(totalChange: Double, percentChange: Double, monthlyRate: Double, periodDays: Int) {
        self.totalChange = totalChange
        self.percentChange = percentChange
        self.monthlyRate = monthlyRate
        self.periodDays = periodDays
    }
}
