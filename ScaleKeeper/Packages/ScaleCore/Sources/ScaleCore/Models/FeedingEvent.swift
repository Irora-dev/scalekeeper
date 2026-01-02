import Foundation
import SwiftData

// MARK: - Feeding Event Entity

@Model
public final class FeedingEvent {
    // MARK: - Identity
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date

    // MARK: - Timing
    public var feedingDate: Date

    // MARK: - Prey Details
    public var preyType: PreyType
    public var preySize: PreySize
    public var preyState: PreyState
    public var quantity: Int
    public var preyWeightGrams: Double? // NEW: Precise prey weight

    // MARK: - Response
    public var feedingResponse: FeedingResponse
    public var feedingResponseTime: FeedingResponseTime? // NEW: How quickly they struck
    public var refusedReason: String?

    // MARK: - Regurgitation (NEW)
    public var regurgitationDate: Date? // May be days after feeding
    public var regurgitationNotes: String?

    // MARK: - Notes
    public var notes: String?

    // MARK: - Relationships
    public var animal: Animal?

    // MARK: - Init
    public init(
        id: UUID = UUID(),
        feedingDate: Date = Date(),
        preyType: PreyType,
        preySize: PreySize,
        preyState: PreyState = .frozenThawed,
        quantity: Int = 1,
        feedingResponse: FeedingResponse = .struckImmediately
    ) {
        self.id = id
        self.createdAt = Date()
        self.feedingDate = feedingDate
        self.preyType = preyType
        self.preySize = preySize
        self.preyState = preyState
        self.quantity = quantity
        self.feedingResponse = feedingResponse
    }
}

// MARK: - Prey Type

public enum PreyType: String, Codable, CaseIterable {
    // Rodents
    case mouse
    case rat
    case asf = "african_soft_fur"
    case hamster
    case gerbil
    case guineaPig = "guinea_pig"
    case rabbit

    // Insects
    case cricket
    case dubia = "dubia_roach"
    case discoid = "discoid_roach"
    case mealworm
    case superworm
    case hornworm
    case silkworm
    case waxworm
    case blackSoldierFly = "bsfl"
    case locust

    // Other
    case fish
    case shrimp
    case earthworm
    case pinkie = "pinkie_mouse"
    case chick
    case quail
    case reptilinks
    case other

    public var displayName: String {
        switch self {
        case .mouse: return "Mouse"
        case .rat: return "Rat"
        case .asf: return "African Soft Fur"
        case .hamster: return "Hamster"
        case .gerbil: return "Gerbil"
        case .guineaPig: return "Guinea Pig"
        case .rabbit: return "Rabbit"
        case .cricket: return "Cricket"
        case .dubia: return "Dubia Roach"
        case .discoid: return "Discoid Roach"
        case .mealworm: return "Mealworm"
        case .superworm: return "Superworm"
        case .hornworm: return "Hornworm"
        case .silkworm: return "Silkworm"
        case .waxworm: return "Waxworm"
        case .blackSoldierFly: return "BSFL"
        case .locust: return "Locust"
        case .fish: return "Fish"
        case .shrimp: return "Shrimp"
        case .earthworm: return "Earthworm"
        case .pinkie: return "Pinkie Mouse"
        case .chick: return "Chick"
        case .quail: return "Quail"
        case .reptilinks: return "Reptilinks"
        case .other: return "Other"
        }
    }

    public var category: PreyCategory {
        switch self {
        case .mouse, .rat, .asf, .hamster, .gerbil, .guineaPig, .rabbit, .pinkie:
            return .rodent
        case .cricket, .dubia, .discoid, .mealworm, .superworm, .hornworm, .silkworm, .waxworm, .blackSoldierFly, .locust:
            return .insect
        case .fish, .shrimp:
            return .aquatic
        case .chick, .quail:
            return .avian
        case .earthworm, .reptilinks, .other:
            return .other
        }
    }
}

public enum PreyCategory: String, Codable {
    case rodent
    case insect
    case aquatic
    case avian
    case other
}

// MARK: - Prey Size

public enum PreySize: String, Codable, CaseIterable {
    // Rodent sizes
    case pinky
    case fuzzy
    case hopper
    case weaned
    case small
    case medium
    case large
    case xlarge = "x_large"
    case jumbo

    // Insect sizes
    case micro
    case mini
    case standard
    case adult

    public var displayName: String {
        switch self {
        case .pinky: return "Pinky"
        case .fuzzy: return "Fuzzy"
        case .hopper: return "Hopper"
        case .weaned: return "Weaned"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .xlarge: return "X-Large"
        case .jumbo: return "Jumbo"
        case .micro: return "Micro"
        case .mini: return "Mini"
        case .standard: return "Standard"
        case .adult: return "Adult"
        }
    }
}

// MARK: - Prey State

public enum PreyState: String, Codable, CaseIterable {
    case live
    case freshKilled = "fresh_killed"
    case frozenThawed = "frozen_thawed"

    public var displayName: String {
        switch self {
        case .live: return "Live"
        case .freshKilled: return "Fresh Killed"
        case .frozenThawed: return "Frozen/Thawed"
        }
    }
}

// MARK: - Feeding Response

public enum FeedingResponse: String, Codable, CaseIterable {
    case struckImmediately = "struck_immediately"
    case reluctant
    case assistedFeed = "assisted_feed"
    case refused
    case regurgitated

    public var displayName: String {
        switch self {
        case .struckImmediately: return "Struck Immediately"
        case .reluctant: return "Reluctant"
        case .assistedFeed: return "Assisted Feed"
        case .refused: return "Refused"
        case .regurgitated: return "Regurgitated"
        }
    }

    public var isSuccessful: Bool {
        switch self {
        case .struckImmediately, .reluctant, .assistedFeed:
            return true
        case .refused, .regurgitated:
            return false
        }
    }

    public var iconName: String {
        switch self {
        case .struckImmediately: return "checkmark.circle.fill"
        case .reluctant: return "checkmark.circle"
        case .assistedFeed: return "hand.raised.fill"
        case .refused: return "xmark.circle"
        case .regurgitated: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Feeding Schedule

// MARK: - Feeding Response Time (NEW)

public enum FeedingResponseTime: String, Codable, CaseIterable {
    case immediate // Within seconds
    case hesitant // Inspected first, then ate
    case coaxed // Required encouragement/movement
    case forceFed = "force_fed" // Had to assist

    public var displayName: String {
        switch self {
        case .immediate: return "Immediate"
        case .hesitant: return "Hesitant"
        case .coaxed: return "Coaxed"
        case .forceFed: return "Force Fed"
        }
    }

    public var iconName: String {
        switch self {
        case .immediate: return "bolt.fill"
        case .hesitant: return "questionmark.circle"
        case .coaxed: return "hand.wave"
        case .forceFed: return "hand.raised.fill"
        }
    }
}

// MARK: - Feeding Schedule (ENHANCED)

public struct FeedingSchedule: Codable, Equatable {
    public var intervalDays: Int
    public var lastFeedingDate: Date?
    public var preferredDayOfWeek: Int? // 1-7, Sunday = 1
    public var preferredTimeOfDay: Date? // Time component only
    public var autoRescheduleOnRefusal: Bool // Push next attempt based on interval
    public var skipDuringShed: Bool // Auto-skip if in shed
    public var notes: String?

    public var nextFeedingDate: Date? {
        guard let lastFeeding = lastFeedingDate else { return nil }
        return Calendar.current.date(byAdding: .day, value: intervalDays, to: lastFeeding)
    }

    public var isDue: Bool {
        guard let nextDate = nextFeedingDate else { return true }
        return nextDate <= Date()
    }

    public var daysUntilDue: Int? {
        guard let nextDate = nextFeedingDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: nextDate).day
    }

    public var daysSinceLastFeeding: Int? {
        guard let lastFeeding = lastFeedingDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastFeeding, to: Date()).day
    }

    public init(
        intervalDays: Int,
        lastFeedingDate: Date? = nil,
        preferredDayOfWeek: Int? = nil,
        preferredTimeOfDay: Date? = nil,
        autoRescheduleOnRefusal: Bool = true,
        skipDuringShed: Bool = true,
        notes: String? = nil
    ) {
        self.intervalDays = intervalDays
        self.lastFeedingDate = lastFeedingDate
        self.preferredDayOfWeek = preferredDayOfWeek
        self.preferredTimeOfDay = preferredTimeOfDay
        self.autoRescheduleOnRefusal = autoRescheduleOnRefusal
        self.skipDuringShed = skipDuringShed
        self.notes = notes
    }
}

// MARK: - Hunger Duration (NEW)

public struct HungerDuration {
    public let daysSinceLastMeal: Int?
    public let lastSuccessfulFeeding: Date?
    public let refusalCount: Int // Consecutive refusals
    public let weightChangeDuringStrike: Double? // Percentage

    public var urgencyLevel: HungerUrgency {
        guard let days = daysSinceLastMeal else { return .unknown }

        // These thresholds should be species-specific
        // Ball pythons can safely go 30-60+ days
        // Corn snakes typically 14-21 days max
        if days <= 14 {
            return .normal
        } else if days <= 30 {
            return .extended
        } else if days <= 60 {
            return .concerning
        } else {
            return .critical
        }
    }

    public var displayText: String {
        guard let days = daysSinceLastMeal else {
            return "No feeding records"
        }

        if days == 0 {
            return "Fed today"
        } else if days == 1 {
            return "Last ate yesterday"
        } else {
            return "Last ate \(days) days ago"
        }
    }

    public init(
        daysSinceLastMeal: Int?,
        lastSuccessfulFeeding: Date?,
        refusalCount: Int = 0,
        weightChangeDuringStrike: Double? = nil
    ) {
        self.daysSinceLastMeal = daysSinceLastMeal
        self.lastSuccessfulFeeding = lastSuccessfulFeeding
        self.refusalCount = refusalCount
        self.weightChangeDuringStrike = weightChangeDuringStrike
    }
}

public enum HungerUrgency: String {
    case unknown
    case normal
    case extended
    case concerning
    case critical

    public var displayName: String {
        switch self {
        case .unknown: return "Unknown"
        case .normal: return "Normal"
        case .extended: return "Extended"
        case .concerning: return "Concerning"
        case .critical: return "Critical"
        }
    }

    public var colorName: String {
        switch self {
        case .unknown: return "scaleMuted"
        case .normal: return "scaleSuccess"
        case .extended: return "nebulaGold"
        case .concerning: return "scaleWarning"
        case .critical: return "scaleError"
        }
    }

    public var advice: String {
        switch self {
        case .unknown:
            return "Log feedings to track hunger duration"
        case .normal:
            return "Within normal feeding window"
        case .extended:
            return "Extended fast - monitor weight"
        case .concerning:
            return "Consider vet consultation if weight loss exceeds 10%"
        case .critical:
            return "Urgent: Veterinary attention recommended"
        }
    }
}

// MARK: - Feeding Insight (NEW - for "Udon Feature")

public struct FeedingInsight {
    public let animal: Animal
    public let recentFeedings: [FeedingEvent]
    public let weights: [WeightRecord]
    public let hungerDuration: HungerDuration

    public var successRate: Double {
        guard !recentFeedings.isEmpty else { return 0 }
        let successful = recentFeedings.filter { $0.feedingResponse.isSuccessful }.count
        return Double(successful) / Double(recentFeedings.count) * 100
    }

    public var weightTrendDuringStrike: WeightTrend? {
        guard weights.count >= 2 else { return nil }
        let sorted = weights.sorted { $0.recordedAt < $1.recordedAt }
        guard let first = sorted.first, let last = sorted.last else { return nil }

        let change = WeightChange(
            previousWeight: first.weightGrams,
            currentWeight: last.weightGrams,
            daysBetween: Calendar.current.dateComponents([.day], from: first.recordedAt, to: last.recordedAt).day ?? 1
        )
        return change.trend
    }

    public var insightMessage: String {
        guard let days = hungerDuration.daysSinceLastMeal else {
            return "Start logging feedings to track patterns."
        }

        if days == 0 {
            return "Fed successfully today!"
        }

        if hungerDuration.urgencyLevel == .normal {
            return "Within normal feeding schedule."
        }

        // Extended fast analysis
        if let weightTrend = weightTrendDuringStrike {
            switch weightTrend {
            case .stable:
                return "Weight stable during food strike — no cause for concern yet."
            case .losing:
                if let change = hungerDuration.weightChangeDuringStrike, change < -10 {
                    return "Weight down \(String(format: "%.0f", abs(change)))% during food strike — consider vet consultation."
                }
                return "Slight weight loss during strike — continue monitoring."
            case .gaining:
                return "Weight stable/gaining — healthy despite reduced feeding."
            }
        }

        return "Extended fast — monitor weight closely."
    }

    public init(
        animal: Animal,
        recentFeedings: [FeedingEvent],
        weights: [WeightRecord],
        hungerDuration: HungerDuration
    ) {
        self.animal = animal
        self.recentFeedings = recentFeedings
        self.weights = weights
        self.hungerDuration = hungerDuration
    }
}
