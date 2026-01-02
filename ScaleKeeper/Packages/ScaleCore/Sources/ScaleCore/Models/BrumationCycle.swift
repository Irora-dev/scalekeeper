import Foundation
import SwiftData

// MARK: - Brumation Cycle Entity

@Model
public final class BrumationCycle {
    // MARK: - Identity
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date

    // MARK: - Year/Season
    public var year: Int
    public var seasonName: String? // e.g., "2024-2025 Winter"

    // MARK: - Pre-Brumation
    public var preBrumationWeight: Double? // grams
    public var lastFeedingBefore: Date?

    // MARK: - Phase Dates
    public var cooldownStartDate: Date?
    public var fullBrumationStartDate: Date?
    public var warmupStartDate: Date?
    public var brumationEndDate: Date?

    // MARK: - Post-Brumation
    public var postBrumationWeight: Double? // grams
    public var firstFeedingAfter: Date?

    // MARK: - Temperature Targets
    public var targetTempLowF: Double?
    public var targetTempHighF: Double?

    // MARK: - Status
    public var status: BrumationStatus

    // MARK: - Notes
    public var notes: String?

    // MARK: - Relationships
    public var animal: Animal?

    // MARK: - Computed
    public var currentPhase: BrumationPhase? {
        let now = Date()

        guard status != .cancelled && status != .complete else {
            return nil
        }

        if let endDate = brumationEndDate, now >= endDate {
            return .complete
        }

        if let warmupStart = warmupStartDate, now >= warmupStart {
            return .warmup
        }

        if let fullStart = fullBrumationStartDate, now >= fullStart {
            return .active
        }

        if let cooldownStart = cooldownStartDate, now >= cooldownStart {
            return .cooldown
        }

        return .planned
    }

    public var daysInCurrentPhase: Int? {
        guard let phase = currentPhase else { return nil }

        let phaseStartDate: Date?
        switch phase {
        case .planned:
            return nil
        case .cooldown:
            phaseStartDate = cooldownStartDate
        case .active:
            phaseStartDate = fullBrumationStartDate
        case .warmup:
            phaseStartDate = warmupStartDate
        case .complete:
            phaseStartDate = brumationEndDate
        }

        guard let start = phaseStartDate else { return nil }
        return Calendar.current.dateComponents([.day], from: start, to: Date()).day
    }

    public var totalBrumationDays: Int? {
        guard let start = cooldownStartDate, let end = brumationEndDate else { return nil }
        return Calendar.current.dateComponents([.day], from: start, to: end).day
    }

    public var weightChange: Double? {
        guard let pre = preBrumationWeight, let post = postBrumationWeight else { return nil }
        return post - pre
    }

    public var weightChangePercentage: Double? {
        guard let pre = preBrumationWeight, let change = weightChange, pre > 0 else { return nil }
        return (change / pre) * 100
    }

    public var daysUntilNextPhase: Int? {
        guard let phase = currentPhase else { return nil }
        let now = Date()

        let nextPhaseDate: Date?
        switch phase {
        case .planned:
            nextPhaseDate = cooldownStartDate
        case .cooldown:
            nextPhaseDate = fullBrumationStartDate
        case .active:
            nextPhaseDate = warmupStartDate
        case .warmup:
            nextPhaseDate = brumationEndDate
        case .complete:
            return nil
        }

        guard let next = nextPhaseDate else { return nil }
        return Calendar.current.dateComponents([.day], from: now, to: next).day
    }

    // MARK: - Init
    public init(
        id: UUID = UUID(),
        year: Int,
        status: BrumationStatus = .planned
    ) {
        self.id = id
        self.createdAt = Date()
        self.year = year
        self.status = status
    }
}

// MARK: - Brumation Status

public enum BrumationStatus: String, Codable, CaseIterable {
    case planned
    case cooldown
    case active
    case warmup
    case complete
    case cancelled

    public var displayName: String {
        switch self {
        case .planned: return "Planned"
        case .cooldown: return "Cooling Down"
        case .active: return "Brumating"
        case .warmup: return "Warming Up"
        case .complete: return "Complete"
        case .cancelled: return "Cancelled"
        }
    }

    public var iconName: String {
        switch self {
        case .planned: return "calendar"
        case .cooldown: return "thermometer.snowflake"
        case .active: return "moon.zzz.fill"
        case .warmup: return "thermometer.sun.fill"
        case .complete: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
}

// MARK: - Brumation Phase

public enum BrumationPhase: String, CaseIterable {
    case planned
    case cooldown
    case active
    case warmup
    case complete

    public var displayName: String {
        switch self {
        case .planned: return "Planned"
        case .cooldown: return "Cooling Down"
        case .active: return "Full Brumation"
        case .warmup: return "Warming Up"
        case .complete: return "Complete"
        }
    }

    public var description: String {
        switch self {
        case .planned:
            return "Preparing for brumation - verify health and last feeding"
        case .cooldown:
            return "Gradually reducing temperatures over 1-2 weeks"
        case .active:
            return "Full brumation - minimal disturbance, monitor weekly"
        case .warmup:
            return "Gradually increasing temperatures over 1-2 weeks"
        case .complete:
            return "Brumation complete - resume normal care and feeding"
        }
    }

    public var tasks: [String] {
        switch self {
        case .planned:
            return [
                "Confirm animal is healthy",
                "Record pre-brumation weight",
                "Last feeding 2 weeks before cooldown",
                "Clean enclosure thoroughly"
            ]
        case .cooldown:
            return [
                "Reduce temps by 2-3°F every few days",
                "Reduce photoperiod gradually",
                "Monitor for signs of stress",
                "Ensure fresh water available"
            ]
        case .active:
            return [
                "Maintain cool temperatures (50-60°F typical)",
                "Minimal disturbance",
                "Weekly health check",
                "Keep water dish clean"
            ]
        case .warmup:
            return [
                "Increase temps by 2-3°F every few days",
                "Extend photoperiod gradually",
                "Offer water frequently",
                "Prepare for first feeding"
            ]
        case .complete:
            return [
                "Record post-brumation weight",
                "Offer first meal",
                "Resume normal feeding schedule",
                "Consider breeding pairings"
            ]
        }
    }
}

// MARK: - Brumation Summary

public struct BrumationSummary {
    public let cycle: BrumationCycle
    public let animalName: String
    public let speciesName: String

    public var phaseProgress: Double {
        guard let phase = cycle.currentPhase,
              let daysInPhase = cycle.daysInCurrentPhase else { return 0 }

        // Estimate typical phase durations
        let estimatedDuration: Int
        switch phase {
        case .planned: return 0
        case .cooldown: estimatedDuration = 14
        case .active: estimatedDuration = 60
        case .warmup: estimatedDuration = 14
        case .complete: return 1.0
        }

        return min(Double(daysInPhase) / Double(estimatedDuration), 1.0)
    }

    public init(cycle: BrumationCycle, animalName: String, speciesName: String) {
        self.cycle = cycle
        self.animalName = animalName
        self.speciesName = speciesName
    }
}
