import Foundation
import UserNotifications

// MARK: - Notification Service

@MainActor
public final class NotificationService: ObservableObject {
    public static let shared = NotificationService()

    // MARK: - State
    @Published public private(set) var isAuthorized = false
    @Published public private(set) var pendingNotifications: [UNNotificationRequest] = []

    private let center = UNUserNotificationCenter.current()

    // MARK: - Init
    private init() {
        Task {
            await checkAuthorization()
        }
    }

    // MARK: - Authorization

    public func requestAuthorization() async throws -> Bool {
        let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        isAuthorized = granted
        return granted
    }

    public func checkAuthorization() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Feeding Reminders

    /// Schedule a feeding reminder for an animal
    public func scheduleFeedingReminder(
        for animal: Animal,
        at date: Date,
        repeatInterval: DateComponents? = nil
    ) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }

        let content = UNMutableNotificationContent()
        content.title = "Feeding Reminder"
        content.body = "\(animal.name) is due for feeding"
        content.sound = .default
        content.categoryIdentifier = ScaleConstants.Notifications.feedingReminderCategory
        content.userInfo = ["animalID": animal.id.uuidString]

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )

        let trigger: UNNotificationTrigger
        if let repeatInterval = repeatInterval {
            trigger = UNCalendarNotificationTrigger(dateMatching: repeatInterval, repeats: true)
        } else {
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        }

        let request = UNNotificationRequest(
            identifier: "feeding-\(animal.id.uuidString)",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
        await refreshPendingNotifications()
    }

    /// Cancel feeding reminder for an animal
    public func cancelFeedingReminder(for animal: Animal) {
        center.removePendingNotificationRequests(withIdentifiers: ["feeding-\(animal.id.uuidString)"])
        Task {
            await refreshPendingNotifications()
        }
    }

    // MARK: - Environment Alerts

    /// Schedule an environment alert (temperature/humidity out of range)
    public func sendEnvironmentAlert(
        enclosureName: String,
        alertType: EnvironmentAlertType,
        currentValue: Double,
        targetRange: ClosedRange<Double>
    ) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }

        let content = UNMutableNotificationContent()
        content.title = "Environment Alert"
        content.sound = .default
        content.categoryIdentifier = ScaleConstants.Notifications.environmentAlertCategory
        content.interruptionLevel = .timeSensitive

        switch alertType {
        case .temperatureHigh:
            content.body = "\(enclosureName): Temperature too high (\(String(format: "%.1f", currentValue))°F)"
        case .temperatureLow:
            content.body = "\(enclosureName): Temperature too low (\(String(format: "%.1f", currentValue))°F)"
        case .humidityHigh:
            content.body = "\(enclosureName): Humidity too high (\(Int(currentValue))%)"
        case .humidityLow:
            content.body = "\(enclosureName): Humidity too low (\(Int(currentValue))%)"
        }

        let request = UNNotificationRequest(
            identifier: "env-alert-\(UUID().uuidString)",
            content: content,
            trigger: nil // Immediate
        )

        try await center.add(request)
    }

    // MARK: - Overdue Feeding Alert

    /// Send an alert for overdue feeding
    public func sendOverdueFeedingAlert(for animal: Animal, daysPast: Int) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }

        let content = UNMutableNotificationContent()
        content.title = "Overdue Feeding"
        content.body = "\(animal.name) hasn't been fed in \(daysPast) days"
        content.sound = .default
        content.categoryIdentifier = ScaleConstants.Notifications.feedingReminderCategory
        content.userInfo = ["animalID": animal.id.uuidString]

        let request = UNNotificationRequest(
            identifier: "overdue-\(animal.id.uuidString)",
            content: content,
            trigger: nil // Immediate
        )

        try await center.add(request)
    }

    // MARK: - Medication Reminders

    /// Schedule a medication dose reminder
    public func scheduleMedicationReminder(
        for plan: TreatmentPlan,
        dose: MedicationDose
    ) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Medication Due"
        content.body = "\(plan.animal?.name ?? "Animal"): \(plan.medication?.name ?? "Medication") - \(plan.dosage)"
        content.sound = .default
        content.categoryIdentifier = ScaleConstants.Notifications.medicationReminderCategory
        content.userInfo = [
            "treatmentPlanID": plan.id.uuidString,
            "doseID": dose.id.uuidString
        ]
        content.interruptionLevel = .timeSensitive

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: dose.scheduledTime
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "medication-\(dose.id.uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule medication reminder: \(error)")
            }
        }
    }

    /// Cancel all medication reminders for a treatment plan
    public func cancelMedicationReminders(for treatmentPlanID: UUID) {
        Task {
            let pending = await center.pendingNotificationRequests()
            let toRemove = pending.filter {
                $0.identifier.hasPrefix("medication-") &&
                ($0.content.userInfo["treatmentPlanID"] as? String) == treatmentPlanID.uuidString
            }.map { $0.identifier }

            center.removePendingNotificationRequests(withIdentifiers: toRemove)
            await refreshPendingNotifications()
        }
    }

    // MARK: - Cleaning Reminders

    /// Schedule a cleaning reminder for an enclosure
    public func scheduleCleaningReminder(
        for enclosure: Enclosure,
        type: CleaningType,
        dueDate: Date
    ) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Cleaning Due"
        content.body = "\(enclosure.name): \(type.displayName) due"
        content.sound = .default
        content.categoryIdentifier = ScaleConstants.Notifications.cleaningReminderCategory
        content.userInfo = [
            "enclosureID": enclosure.id.uuidString,
            "cleaningType": type.rawValue
        ]

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour],
            from: dueDate
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "cleaning-\(enclosure.id.uuidString)-\(type.rawValue)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule cleaning reminder: \(error)")
            }
        }
    }

    /// Cancel cleaning reminder for an enclosure/type
    public func cancelCleaningReminder(for enclosureID: UUID, type: CleaningType) {
        center.removePendingNotificationRequests(
            withIdentifiers: ["cleaning-\(enclosureID.uuidString)-\(type.rawValue)"]
        )
        Task {
            await refreshPendingNotifications()
        }
    }

    // MARK: - Brumation Reminders

    /// Schedule a brumation phase transition reminder
    public func scheduleBrumationReminder(
        for animal: Animal,
        cycle: BrumationCycle,
        phase: BrumationPhase,
        date: Date
    ) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Brumation Alert"
        content.body = "\(animal.name): \(phase.displayName) phase starting"
        content.sound = .default
        content.categoryIdentifier = ScaleConstants.Notifications.brumationReminderCategory
        content.userInfo = [
            "animalID": animal.id.uuidString,
            "brumationCycleID": cycle.id.uuidString,
            "phase": phase.rawValue
        ]

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour],
            from: date
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "brumation-\(cycle.id.uuidString)-\(phase.rawValue)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule brumation reminder: \(error)")
            }
        }
    }

    /// Cancel all brumation reminders for a cycle
    public func cancelBrumationReminders(for cycleID: UUID) {
        let identifiers = BrumationPhase.allCases.map { "brumation-\(cycleID.uuidString)-\($0.rawValue)" }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        Task {
            await refreshPendingNotifications()
        }
    }

    // MARK: - Management

    /// Refresh list of pending notifications
    public func refreshPendingNotifications() async {
        pendingNotifications = await center.pendingNotificationRequests()
    }

    /// Cancel all notifications
    public func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        pendingNotifications = []
    }

    /// Cancel specific notification
    public func cancelNotification(withIdentifier identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        Task {
            await refreshPendingNotifications()
        }
    }

    // MARK: - Badge Management

    public func setBadgeCount(_ count: Int) async throws {
        try await center.setBadgeCount(count)
    }

    public func clearBadge() async throws {
        try await center.setBadgeCount(0)
    }
}

// MARK: - Environment Alert Type

public enum EnvironmentAlertType {
    case temperatureHigh
    case temperatureLow
    case humidityHigh
    case humidityLow
}

// MARK: - Notification Errors

public enum NotificationError: Error, LocalizedError {
    case notAuthorized
    case schedulingFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Notifications are not authorized. Please enable in Settings."
        case .schedulingFailed(let error):
            return "Failed to schedule notification: \(error.localizedDescription)"
        }
    }
}

// MARK: - Notification Categories Setup

extension NotificationService {
    /// Register notification categories for action buttons
    public func registerCategories() {
        // Feeding reminder actions
        let markFedAction = UNNotificationAction(
            identifier: "MARK_FED",
            title: "Mark as Fed",
            options: []
        )
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Snooze 1 Hour",
            options: []
        )
        let feedingCategory = UNNotificationCategory(
            identifier: ScaleConstants.Notifications.feedingReminderCategory,
            actions: [markFedAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        // Environment alert actions
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ENCLOSURE",
            title: "View Enclosure",
            options: [.foreground]
        )
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: []
        )
        let environmentCategory = UNNotificationCategory(
            identifier: ScaleConstants.Notifications.environmentAlertCategory,
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([feedingCategory, environmentCategory])
    }
}
