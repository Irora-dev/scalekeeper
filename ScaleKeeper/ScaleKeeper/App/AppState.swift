import SwiftUI
import ScaleCore

// MARK: - App State

@MainActor
final class AppState: ObservableObject {
    // MARK: - Navigation
    @Published var selectedTab: Tab = .dashboard
    @Published var navigationPath = NavigationPath()

    // MARK: - Sheets
    @Published var activeSheet: SheetType?
    @Published var isShowingPaywall = false
    @Published var isShowingQuickActionsHub = false
    @Published var previousTab: Tab = .dashboard

    // MARK: - Refresh Triggers
    @Published var dataRefreshTrigger = UUID()

    // MARK: - Services
    let dataService: DataService
    let feedingService: FeedingService
    let subscriptionService: SubscriptionService
    let notificationService: NotificationService

    // MARK: - User
    @Published var currentUser: ScaleUser?

    // MARK: - Init
    init(
        dataService: DataService = .shared,
        feedingService: FeedingService = .shared,
        subscriptionService: SubscriptionService = .shared,
        notificationService: NotificationService = .shared
    ) {
        self.dataService = dataService
        self.feedingService = feedingService
        self.subscriptionService = subscriptionService
        self.notificationService = notificationService

        Task {
            await loadUser()
        }
    }

    // MARK: - User Management

    func loadUser() async {
        do {
            currentUser = try dataService.getOrCreateUser()
        } catch {
            print("Failed to load user: \(error)")
        }
    }

    // MARK: - Navigation

    func navigate(to destination: any Hashable) {
        navigationPath.append(destination)
    }

    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }

    func navigateToRoot() {
        navigationPath = NavigationPath()
    }

    // MARK: - Sheets

    func presentSheet(_ sheet: SheetType) {
        activeSheet = sheet
    }

    func dismissSheet() {
        activeSheet = nil
    }

    // MARK: - Premium Check

    func requiresPremium(for feature: PremiumFeature, action: @escaping () -> Void) {
        if subscriptionService.hasAccess(to: feature) {
            action()
        } else {
            isShowingPaywall = true
        }
    }

    // MARK: - Data Refresh

    /// Call this to trigger all views to refresh their data
    func triggerDataRefresh() {
        dataRefreshTrigger = UUID()
    }
}

// MARK: - Tab

enum Tab: Int, CaseIterable, Identifiable {
    case dashboard
    case collection
    case hub
    case care
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Home"
        case .collection: return "Collection"
        case .hub: return "Log"
        case .care: return "Care"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .collection: return "lizard"
        case .hub: return "plus.circle"
        case .care: return "heart.text.square"
        case .settings: return "gearshape.fill"
        }
    }

    var selectedIcon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .collection: return "lizard.fill"
        case .hub: return "plus.circle.fill"
        case .care: return "heart.text.square.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Sheet Type

enum SheetType: Identifiable {
    case addAnimal
    case editAnimal(animalID: UUID)
    case logFeeding(animalID: UUID)
    case quickFeed(animalID: UUID)
    case batchFeed
    case addWeight(animalID: UUID)
    case addLength(animalID: UUID)
    case addHealthNote(animalID: UUID)
    case addShed(animalID: UUID)
    case quickNote // New: Quick note with animal selector
    case quickNoteForAnimal(animalID: UUID) // New: Quick note for specific animal
    case newPairing
    case editPairing(pairingID: UUID)
    case addClutch(pairingID: UUID)
    case settings
    case markRegurgitation(feedingID: UUID) // Mark a past feeding as regurgitated

    var id: String {
        switch self {
        case .addAnimal: return "addAnimal"
        case .editAnimal(let id): return "editAnimal-\(id)"
        case .logFeeding(let id): return "logFeeding-\(id)"
        case .quickFeed(let id): return "quickFeed-\(id)"
        case .batchFeed: return "batchFeed"
        case .addWeight(let id): return "addWeight-\(id)"
        case .addLength(let id): return "addLength-\(id)"
        case .addHealthNote(let id): return "addHealthNote-\(id)"
        case .addShed(let id): return "addShed-\(id)"
        case .quickNote: return "quickNote"
        case .quickNoteForAnimal(let id): return "quickNoteForAnimal-\(id)"
        case .newPairing: return "newPairing"
        case .editPairing(let id): return "editPairing-\(id)"
        case .addClutch(let id): return "addClutch-\(id)"
        case .settings: return "settings"
        case .markRegurgitation(let id): return "markRegurgitation-\(id)"
        }
    }
}
