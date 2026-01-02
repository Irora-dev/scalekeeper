import Foundation
import StoreKit

// MARK: - Subscription Service

@MainActor
public final class SubscriptionService: ObservableObject {
    public static let shared = SubscriptionService()

    // MARK: - Product IDs
    private enum ProductID {
        static let keeperMonthly = "com.scalekeeper.keeper.monthly"
        static let keeperAnnual = "com.scalekeeper.keeper.annual"
        static let breederMonthly = "com.scalekeeper.breeder.monthly"
        static let breederAnnual = "com.scalekeeper.breeder.annual"
        static let professionalMonthly = "com.scalekeeper.professional.monthly"
        static let professionalAnnual = "com.scalekeeper.professional.annual"
        static let lifetime = "com.scalekeeper.lifetime"

        static let all = [
            keeperMonthly, keeperAnnual,
            breederMonthly, breederAnnual,
            professionalMonthly, professionalAnnual,
            lifetime
        ]
    }

    // MARK: - Published State
    @Published public private(set) var currentTier: SubscriptionTier = .free
    @Published public private(set) var expirationDate: Date?
    @Published public private(set) var isLoading = false
    @Published public private(set) var products: [Product] = []

    // MARK: - Computed
    public var isPremium: Bool {
        currentTier != .free
    }

    public var isKeeper: Bool {
        [.keeper, .breeder, .professional].contains(currentTier)
    }

    public var isBreeder: Bool {
        [.breeder, .professional].contains(currentTier)
    }

    public var isProfessional: Bool {
        currentTier == .professional
    }

    // MARK: - Init
    private init() {
        Task {
            await loadProducts()
            await checkEntitlement()
        }
    }

    // MARK: - Product Loading

    public func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: ProductID.all)
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Entitlement Check

    public func checkEntitlement() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                await updateTier(for: transaction.productID)

                if let expirationDate = transaction.expirationDate {
                    self.expirationDate = expirationDate
                }
            }
        }
    }

    // MARK: - Purchase

    public func purchase(_ product: Product) async throws -> Transaction? {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateTier(for: transaction.productID)
            await transaction.finish()
            return transaction

        case .userCancelled:
            return nil

        case .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    // MARK: - Restore

    public func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }

        try await AppStore.sync()
        await checkEntitlement()
    }

    // MARK: - Feature Access

    public func hasAccess(to feature: PremiumFeature) -> Bool {
        switch currentTier {
        case .free:
            return false
        case .keeper:
            return feature.requiredTier == .keeper
        case .breeder:
            return feature.requiredTier == .keeper || feature.requiredTier == .breeder
        case .professional:
            return true
        }
    }

    public func canAddAnimal(currentCount: Int) -> Bool {
        if isPremium {
            return true
        }
        return currentCount < ScaleConstants.Limits.freeAnimalLimit
    }

    // MARK: - Private Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    private func updateTier(for productID: String) async {
        switch productID {
        case ProductID.keeperMonthly, ProductID.keeperAnnual:
            currentTier = .keeper
        case ProductID.breederMonthly, ProductID.breederAnnual:
            currentTier = .breeder
        case ProductID.professionalMonthly, ProductID.professionalAnnual, ProductID.lifetime:
            currentTier = .professional
        default:
            break
        }

        // Update user model
        do {
            let user = try DataService.shared.getOrCreateUser()
            user.subscriptionTier = currentTier
            user.subscriptionExpiresAt = expirationDate
            try DataService.shared.save()
        } catch {
            print("Failed to update user subscription: \(error)")
        }
    }
}

// MARK: - Subscription Errors

public enum SubscriptionError: Error, LocalizedError {
    case verificationFailed
    case purchaseFailed(underlying: Error)
    case restoreFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "Transaction verification failed"
        case .purchaseFailed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        case .restoreFailed(let error):
            return "Restore failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Product Extensions

extension Product {
    public var tierType: SubscriptionTier? {
        switch id {
        case "com.scalekeeper.keeper.monthly", "com.scalekeeper.keeper.annual":
            return .keeper
        case "com.scalekeeper.breeder.monthly", "com.scalekeeper.breeder.annual":
            return .breeder
        case "com.scalekeeper.professional.monthly", "com.scalekeeper.professional.annual", "com.scalekeeper.lifetime":
            return .professional
        default:
            return nil
        }
    }

    public var isAnnual: Bool {
        id.contains("annual")
    }

    public var isLifetime: Bool {
        id.contains("lifetime")
    }
}
