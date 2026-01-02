import Foundation
import SwiftData

// MARK: - ScaleKeeper User Entity

@Model
public final class ScaleUser {
    // MARK: - Identity
    @Attribute(.unique) public var id: UUID
    public var appleUserID: String?
    public var createdAt: Date

    // MARK: - Profile
    public var displayName: String?
    public var email: String?
    public var businessName: String?

    // MARK: - Subscription
    public var subscriptionTier: SubscriptionTier
    public var subscriptionExpiresAt: Date?
    public var subscriptionProductID: String?
    public var originalPurchaseDate: Date?
    public var hasLifetimePurchase: Bool

    // MARK: - Preferences
    public var preferredWeightUnit: WeightUnit
    public var preferredTempUnit: TempUnit
    public var preferredLengthUnit: LengthUnit
    public var weekStartsOnMonday: Bool
    public var timezone: String

    // MARK: - Notifications
    public var feedingRemindersEnabled: Bool
    public var feedingReminderTime: Date?
    public var environmentAlertsEnabled: Bool

    // MARK: - Onboarding
    public var hasCompletedOnboarding: Bool
    public var onboardingCompletedAt: Date?

    // MARK: - Statistics Cache
    public var totalAnimals: Int
    public var totalFeedings: Int

    // MARK: - Init
    public init(
        id: UUID = UUID()
    ) {
        self.id = id
        self.createdAt = Date()
        self.subscriptionTier = .free
        self.hasLifetimePurchase = false
        self.preferredWeightUnit = .grams
        self.preferredTempUnit = .fahrenheit
        self.preferredLengthUnit = .inches
        self.weekStartsOnMonday = false
        self.timezone = TimeZone.current.identifier
        self.feedingRemindersEnabled = true
        self.environmentAlertsEnabled = true
        self.hasCompletedOnboarding = false
        self.totalAnimals = 0
        self.totalFeedings = 0
    }
}

// MARK: - Subscription Tier

public enum SubscriptionTier: String, Codable, CaseIterable {
    case free
    case keeper
    case breeder
    case professional

    public var displayName: String {
        switch self {
        case .free: return "Free"
        case .keeper: return "Keeper"
        case .breeder: return "Breeder"
        case .professional: return "Professional"
        }
    }

    public var animalLimit: Int? {
        switch self {
        case .free: return 5
        case .keeper, .breeder, .professional: return nil
        }
    }

    public var hasGeneticsEngine: Bool {
        switch self {
        case .free, .keeper: return false
        case .breeder, .professional: return true
        }
    }

    public var hasBreedingTools: Bool {
        switch self {
        case .free, .keeper: return false
        case .breeder, .professional: return true
        }
    }

    public var hasIoTIntegration: Bool {
        switch self {
        case .free: return false
        case .keeper, .breeder, .professional: return true
        }
    }

    public var hasMultiUser: Bool {
        switch self {
        case .free, .keeper, .breeder: return false
        case .professional: return true
        }
    }

    public var monthlyPrice: Decimal {
        switch self {
        case .free: return 0
        case .keeper: return 9.99
        case .breeder: return 29.99
        case .professional: return 99.99
        }
    }
}

// MARK: - Premium Features

public enum PremiumFeature: String, CaseIterable {
    // Keeper tier
    case unlimitedAnimals
    case fullHistory
    case iotBasic
    case cloudBackup

    // Breeder tier
    case geneticsEngine
    case breedingTools
    case marketplace
    case expoTools
    case advancedReporting

    // Professional tier
    case multiUser
    case apiAccess
    case whiteLabel
    case prioritySupport

    public var requiredTier: SubscriptionTier {
        switch self {
        case .unlimitedAnimals, .fullHistory, .iotBasic, .cloudBackup:
            return .keeper
        case .geneticsEngine, .breedingTools, .marketplace, .expoTools, .advancedReporting:
            return .breeder
        case .multiUser, .apiAccess, .whiteLabel, .prioritySupport:
            return .professional
        }
    }

    public var displayName: String {
        switch self {
        case .unlimitedAnimals: return "Unlimited Animals"
        case .fullHistory: return "Full History"
        case .iotBasic: return "IoT Integration"
        case .cloudBackup: return "Cloud Backup"
        case .geneticsEngine: return "Genetics Calculator"
        case .breedingTools: return "Breeding Tools"
        case .marketplace: return "Marketplace Access"
        case .expoTools: return "Expo Tools"
        case .advancedReporting: return "Advanced Reports"
        case .multiUser: return "Multi-User Access"
        case .apiAccess: return "API Access"
        case .whiteLabel: return "White Label"
        case .prioritySupport: return "Priority Support"
        }
    }
}

// MARK: - Units

public enum WeightUnit: String, Codable, CaseIterable {
    case grams
    case ounces
    case pounds

    public var displayName: String {
        switch self {
        case .grams: return "Grams (g)"
        case .ounces: return "Ounces (oz)"
        case .pounds: return "Pounds (lb)"
        }
    }

    public var abbreviation: String {
        switch self {
        case .grams: return "g"
        case .ounces: return "oz"
        case .pounds: return "lb"
        }
    }
}

public enum TempUnit: String, Codable, CaseIterable {
    case fahrenheit
    case celsius

    public var displayName: String {
        switch self {
        case .fahrenheit: return "Fahrenheit (°F)"
        case .celsius: return "Celsius (°C)"
        }
    }

    public var abbreviation: String {
        switch self {
        case .fahrenheit: return "°F"
        case .celsius: return "°C"
        }
    }
}

public enum LengthUnit: String, Codable, CaseIterable {
    case inches
    case centimeters

    public var displayName: String {
        switch self {
        case .inches: return "Inches (in)"
        case .centimeters: return "Centimeters (cm)"
        }
    }

    public var abbreviation: String {
        switch self {
        case .inches: return "in"
        case .centimeters: return "cm"
        }
    }
}
