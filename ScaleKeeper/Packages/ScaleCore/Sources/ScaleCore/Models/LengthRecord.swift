import Foundation
import SwiftData

// MARK: - Length Record Entity

@Model
public final class LengthRecord {
    // MARK: - Identity
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date

    // MARK: - Measurement
    public var recordedAt: Date
    public var lengthCm: Double // Store metric, display user preference

    // MARK: - Method
    public var measurementMethod: MeasurementMethod

    // MARK: - Notes
    public var notes: String?

    // MARK: - Relationships
    public var animal: Animal?

    // MARK: - Init
    public init(
        id: UUID = UUID(),
        recordedAt: Date = Date(),
        lengthCm: Double,
        measurementMethod: MeasurementMethod = .estimated
    ) {
        self.id = id
        self.createdAt = Date()
        self.recordedAt = recordedAt
        self.lengthCm = lengthCm
        self.measurementMethod = measurementMethod
    }
}

// MARK: - Measurement Method

public enum MeasurementMethod: String, Codable, CaseIterable {
    case estimated
    case tapeMeasure = "tape_measure"
    case tubeMethod = "tube_method"
    case photoCalculated = "photo_calculated"

    public var displayName: String {
        switch self {
        case .estimated: return "Estimated"
        case .tapeMeasure: return "Tape Measure"
        case .tubeMethod: return "Tube Method"
        case .photoCalculated: return "Photo Calculated"
        }
    }

    public var accuracy: String {
        switch self {
        case .estimated: return "Low"
        case .tapeMeasure: return "Medium"
        case .tubeMethod: return "High"
        case .photoCalculated: return "Medium"
        }
    }

    public var iconName: String {
        switch self {
        case .estimated: return "eye"
        case .tapeMeasure: return "ruler"
        case .tubeMethod: return "cylinder"
        case .photoCalculated: return "camera"
        }
    }
}

// MARK: - Length Utilities

extension LengthRecord {
    /// Length in inches
    public var lengthInches: Double {
        lengthCm / 2.54
    }

    /// Length in feet
    public var lengthFeet: Double {
        lengthInches / 12
    }

    /// Formatted length string based on size
    public var formattedLength: String {
        if lengthCm >= 100 {
            let meters = lengthCm / 100
            return String(format: "%.2f m", meters)
        } else {
            return String(format: "%.1f cm", lengthCm)
        }
    }

    /// Formatted length in imperial units
    public var formattedLengthImperial: String {
        if lengthInches >= 36 {
            let feet = Int(lengthFeet)
            let remainingInches = lengthInches.truncatingRemainder(dividingBy: 12)
            return String(format: "%d' %.1f\"", feet, remainingInches)
        } else {
            return String(format: "%.1f\"", lengthInches)
        }
    }
}

// MARK: - Length Change Analysis

public struct LengthChange {
    public let previousLength: Double
    public let currentLength: Double
    public let daysBetween: Int

    public var absoluteChange: Double {
        currentLength - previousLength
    }

    public var percentageChange: Double {
        guard previousLength > 0 else { return 0 }
        return ((currentLength - previousLength) / previousLength) * 100
    }

    public var dailyGrowthRate: Double {
        guard daysBetween > 0 else { return 0 }
        return absoluteChange / Double(daysBetween)
    }

    public var trend: GrowthTrend {
        if percentageChange > 2 {
            return .growing
        } else if percentageChange < -1 {
            return .shrinking // Measurement error likely
        } else {
            return .stable
        }
    }

    public init(previousLength: Double, currentLength: Double, daysBetween: Int) {
        self.previousLength = previousLength
        self.currentLength = currentLength
        self.daysBetween = daysBetween
    }
}

public enum GrowthTrend: String {
    case growing
    case stable
    case shrinking

    public var displayName: String {
        switch self {
        case .growing: return "Growing"
        case .stable: return "Stable"
        case .shrinking: return "Check Measurement"
        }
    }

    public var iconName: String {
        switch self {
        case .growing: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .shrinking: return "arrow.down.right"
        }
    }
}

// MARK: - Body Condition Score

public struct BodyConditionScore {
    public let weightGrams: Double
    public let lengthCm: Double

    /// Weight to length ratio (grams per cm)
    public var ratio: Double {
        guard lengthCm > 0 else { return 0 }
        return weightGrams / lengthCm
    }

    /// Body condition assessment
    public var condition: BodyCondition {
        // These are general guidelines - species-specific would be better
        // Typical healthy ball python: 2.5-4.0 g/cm
        // Typical healthy corn snake: 1.5-2.5 g/cm
        if ratio < 1.5 {
            return .underweight
        } else if ratio > 5.0 {
            return .overweight
        } else {
            return .healthy
        }
    }

    public init(weightGrams: Double, lengthCm: Double) {
        self.weightGrams = weightGrams
        self.lengthCm = lengthCm
    }
}

public enum BodyCondition: String {
    case underweight
    case healthy
    case overweight

    public var displayName: String {
        switch self {
        case .underweight: return "Underweight"
        case .healthy: return "Healthy"
        case .overweight: return "Overweight"
        }
    }

    public var iconName: String {
        switch self {
        case .underweight: return "exclamationmark.triangle"
        case .healthy: return "checkmark.circle.fill"
        case .overweight: return "exclamationmark.triangle"
        }
    }

    public var description: String {
        switch self {
        case .underweight: return "May be underweight for length"
        case .healthy: return "In healthy body condition"
        case .overweight: return "May be overweight for length"
        }
    }
}
