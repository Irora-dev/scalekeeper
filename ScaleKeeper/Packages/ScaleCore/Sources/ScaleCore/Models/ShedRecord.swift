import Foundation
import SwiftData

// MARK: - Shed Record Entity

@Model
public final class ShedRecord {
    // MARK: - Identity
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date

    // MARK: - Timing
    public var shedDate: Date
    public var bluePhaseStartDate: Date?

    // MARK: - Quality
    public var quality: ShedQuality
    public var issues: [ShedIssue]?

    // MARK: - Notes
    public var notes: String?

    // MARK: - Photo
    public var photoID: UUID?

    // MARK: - Relationships
    public var animal: Animal?

    // MARK: - Computed
    private var issuesData: Data?

    public var shedIssues: [ShedIssue] {
        get {
            guard let data = issuesData else { return [] }
            return (try? JSONDecoder().decode([ShedIssue].self, from: data)) ?? []
        }
        set {
            issuesData = try? JSONEncoder().encode(newValue)
        }
    }

    // MARK: - Init
    public init(
        id: UUID = UUID(),
        shedDate: Date = Date(),
        quality: ShedQuality = .complete
    ) {
        self.id = id
        self.createdAt = Date()
        self.shedDate = shedDate
        self.quality = quality
    }
}

// MARK: - Shed Quality

public enum ShedQuality: String, Codable, CaseIterable {
    case complete
    case partial
    case stuck
    case assisted

    public var displayName: String {
        switch self {
        case .complete: return "Complete"
        case .partial: return "Partial"
        case .stuck: return "Stuck"
        case .assisted: return "Assisted"
        }
    }

    public var iconName: String {
        switch self {
        case .complete: return "checkmark.circle.fill"
        case .partial: return "circle.lefthalf.filled"
        case .stuck: return "exclamationmark.circle.fill"
        case .assisted: return "hand.raised.fill"
        }
    }

    public var isProblematic: Bool {
        switch self {
        case .complete:
            return false
        case .partial, .stuck, .assisted:
            return true
        }
    }
}

// MARK: - Shed Issue

public enum ShedIssue: String, Codable, CaseIterable {
    case eyeCaps = "eye_caps"
    case tailTip = "tail_tip"
    case toes
    case bodyPatches = "body_patches"
    case headArea = "head_area"

    public var displayName: String {
        switch self {
        case .eyeCaps: return "Eye Caps"
        case .tailTip: return "Tail Tip"
        case .toes: return "Toes"
        case .bodyPatches: return "Body Patches"
        case .headArea: return "Head Area"
        }
    }

    public var requiresAttention: Bool {
        switch self {
        case .eyeCaps, .toes:
            return true
        case .tailTip, .bodyPatches, .headArea:
            return false
        }
    }
}

// MARK: - Shed Cycle Analysis

public struct ShedCycleInfo {
    public let averageIntervalDays: Int
    public let lastShedDate: Date?
    public let estimatedNextShed: Date?
    public let totalSheds: Int
    public let problematicShedCount: Int

    public var problematicShedPercentage: Double {
        guard totalSheds > 0 else { return 0 }
        return Double(problematicShedCount) / Double(totalSheds) * 100
    }

    public var isInBluePhase: Bool {
        guard let nextShed = estimatedNextShed else { return false }
        let daysUntilShed = Calendar.current.dateComponents([.day], from: Date(), to: nextShed).day ?? 0
        return daysUntilShed <= 7 && daysUntilShed >= 0
    }

    public init(
        averageIntervalDays: Int,
        lastShedDate: Date?,
        estimatedNextShed: Date?,
        totalSheds: Int,
        problematicShedCount: Int
    ) {
        self.averageIntervalDays = averageIntervalDays
        self.lastShedDate = lastShedDate
        self.estimatedNextShed = estimatedNextShed
        self.totalSheds = totalSheds
        self.problematicShedCount = problematicShedCount
    }
}
