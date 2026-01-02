import Foundation
import SwiftData

// MARK: - Weight Record Entity

@Model
public final class WeightRecord {
    // MARK: - Identity
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date

    // MARK: - Measurement
    public var recordedAt: Date
    public var weightGrams: Double

    // MARK: - Notes
    public var notes: String?

    // MARK: - Relationships
    public var animal: Animal?

    // MARK: - Init
    public init(
        id: UUID = UUID(),
        recordedAt: Date = Date(),
        weightGrams: Double
    ) {
        self.id = id
        self.createdAt = Date()
        self.recordedAt = recordedAt
        self.weightGrams = weightGrams
    }
}

// MARK: - Weight Utilities

extension WeightRecord {
    /// Weight in ounces
    public var weightOunces: Double {
        weightGrams / 28.3495
    }

    /// Weight in pounds
    public var weightPounds: Double {
        weightGrams / 453.592
    }

    /// Formatted weight string based on size
    public var formattedWeight: String {
        if weightGrams >= 1000 {
            let kg = weightGrams / 1000
            return String(format: "%.2f kg", kg)
        } else {
            return String(format: "%.0f g", weightGrams)
        }
    }
}

// MARK: - Weight Change Analysis

public struct WeightChange {
    public let previousWeight: Double
    public let currentWeight: Double
    public let daysBetween: Int

    public var absoluteChange: Double {
        currentWeight - previousWeight
    }

    public var percentageChange: Double {
        guard previousWeight > 0 else { return 0 }
        return ((currentWeight - previousWeight) / previousWeight) * 100
    }

    public var dailyChangeRate: Double {
        guard daysBetween > 0 else { return 0 }
        return absoluteChange / Double(daysBetween)
    }

    public var isSignificantLoss: Bool {
        percentageChange < -10
    }

    public var trend: WeightTrend {
        if percentageChange > 5 {
            return .gaining
        } else if percentageChange < -5 {
            return .losing
        } else {
            return .stable
        }
    }

    public init(previousWeight: Double, currentWeight: Double, daysBetween: Int) {
        self.previousWeight = previousWeight
        self.currentWeight = currentWeight
        self.daysBetween = daysBetween
    }
}

public enum WeightTrend: String {
    case gaining
    case stable
    case losing

    public var displayName: String {
        switch self {
        case .gaining: return "Gaining"
        case .stable: return "Stable"
        case .losing: return "Losing"
        }
    }

    public var iconName: String {
        switch self {
        case .gaining: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .losing: return "arrow.down.right"
        }
    }
}
