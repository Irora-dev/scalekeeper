import SwiftUI
import SwiftData
import ScaleCore
import ScaleUI
import UserNotifications

@main
struct ScaleKeeperApp: App {
    // MARK: - State
    @StateObject private var appState = AppState()
    @ObservedObject private var themeManager = ThemeManager.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - Init
    init() {
        configureAppearance()
    }

    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            if themeManager.hasCompletedOnboarding {
                RootView()
                    .environmentObject(appState)
                    .environmentObject(themeManager)
                    .modelContainer(DataService.shared.container)
                    .tint(themeManager.currentTheme.primaryAccent)
                    .onAppear {
                        // Set the appState reference for notification handling
                        appDelegate.appState = appState
                    }
            } else {
                ThemeOnboardingView()
                    .environmentObject(themeManager)
            }
        }
    }

    // MARK: - Configuration
    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.substrateDark)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance

        // Configure tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(Color.substrateDark)

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var appState: AppState?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Register notification categories
        Task { @MainActor in
            NotificationService.shared.registerCategories()
        }

        return true
    }

    // MARK: - Notification Handling

    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification tap or action button
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let categoryIdentifier = response.notification.request.content.categoryIdentifier
        let actionIdentifier = response.actionIdentifier

        Task { @MainActor in
            handleNotificationAction(
                categoryIdentifier: categoryIdentifier,
                actionIdentifier: actionIdentifier,
                userInfo: userInfo
            )
        }

        completionHandler()
    }

    // MARK: - Deep Link Routing

    @MainActor
    private func handleNotificationAction(
        categoryIdentifier: String,
        actionIdentifier: String,
        userInfo: [AnyHashable: Any]
    ) {
        guard let appState = appState else { return }

        switch categoryIdentifier {
        case ScaleConstants.Notifications.feedingReminderCategory:
            handleFeedingNotification(
                actionIdentifier: actionIdentifier,
                userInfo: userInfo,
                appState: appState
            )

        case ScaleConstants.Notifications.environmentAlertCategory:
            handleEnvironmentNotification(
                actionIdentifier: actionIdentifier,
                userInfo: userInfo,
                appState: appState
            )

        case ScaleConstants.Notifications.medicationReminderCategory:
            handleMedicationNotification(
                actionIdentifier: actionIdentifier,
                userInfo: userInfo,
                appState: appState
            )

        case ScaleConstants.Notifications.cleaningReminderCategory:
            handleCleaningNotification(
                actionIdentifier: actionIdentifier,
                userInfo: userInfo,
                appState: appState
            )

        case ScaleConstants.Notifications.brumationReminderCategory:
            handleBrumationNotification(
                actionIdentifier: actionIdentifier,
                userInfo: userInfo,
                appState: appState
            )

        default:
            // Default tap - open relevant section based on userInfo
            if let animalIDString = userInfo["animalID"] as? String,
               let animalID = UUID(uuidString: animalIDString) {
                // Navigate to animal detail or quick feed
                appState.presentSheet(.quickFeed(animalID: animalID))
            }
        }
    }

    @MainActor
    private func handleFeedingNotification(
        actionIdentifier: String,
        userInfo: [AnyHashable: Any],
        appState: AppState
    ) {
        guard let animalIDString = userInfo["animalID"] as? String,
              let animalID = UUID(uuidString: animalIDString) else {
            return
        }

        switch actionIdentifier {
        case "MARK_FED":
            // Open quick feed to log the feeding
            appState.presentSheet(.quickFeed(animalID: animalID))

        case "SNOOZE":
            // Snooze handled by rescheduling notification (1 hour later)
            Task {
                // Re-schedule notification for 1 hour later
                let content = UNMutableNotificationContent()
                content.title = "Feeding Reminder (Snoozed)"
                content.body = "Time to feed your animal"
                content.sound = .default
                content.categoryIdentifier = ScaleConstants.Notifications.feedingReminderCategory
                content.userInfo = ["animalID": animalIDString]

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "feeding-snooze-\(animalIDString)",
                    content: content,
                    trigger: trigger
                )
                try? await UNUserNotificationCenter.current().add(request)
            }

        case UNNotificationDefaultActionIdentifier:
            // Default tap - open quick feed
            appState.presentSheet(.quickFeed(animalID: animalID))

        default:
            break
        }
    }

    @MainActor
    private func handleEnvironmentNotification(
        actionIdentifier: String,
        userInfo: [AnyHashable: Any],
        appState: AppState
    ) {
        switch actionIdentifier {
        case "VIEW_ENCLOSURE":
            // Navigate to enclosures tab
            appState.selectedTab = .care
            // If we had enclosure navigation, we'd use it here

        case "DISMISS":
            // Just dismiss - do nothing
            break

        case UNNotificationDefaultActionIdentifier:
            // Default tap - go to care tab
            appState.selectedTab = .care

        default:
            break
        }
    }

    @MainActor
    private func handleMedicationNotification(
        actionIdentifier: String,
        userInfo: [AnyHashable: Any],
        appState: AppState
    ) {
        // Navigate to medications section
        appState.selectedTab = .care
        // Could expand to navigate to specific treatment plan
    }

    @MainActor
    private func handleCleaningNotification(
        actionIdentifier: String,
        userInfo: [AnyHashable: Any],
        appState: AppState
    ) {
        // Navigate to enclosures for cleaning
        appState.selectedTab = .care
    }

    @MainActor
    private func handleBrumationNotification(
        actionIdentifier: String,
        userInfo: [AnyHashable: Any],
        appState: AppState
    ) {
        guard let animalIDString = userInfo["animalID"] as? String,
              let _ = UUID(uuidString: animalIDString) else {
            return
        }

        // Navigate to animal in collection
        appState.selectedTab = .collection
    }
}
