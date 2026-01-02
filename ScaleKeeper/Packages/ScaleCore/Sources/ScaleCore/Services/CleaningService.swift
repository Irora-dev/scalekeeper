import Foundation
import SwiftData

// MARK: - Cleaning Service

@MainActor
public final class CleaningService: ObservableObject {
    public static let shared = CleaningService()

    private let dataService: DataService
    private let notificationService: NotificationService

    // MARK: - Published State
    @Published public private(set) var enclosuresNeedingAttention: [CleaningStatus] = []
    @Published public private(set) var overdueCleanings: [CleaningStatus] = []
    @Published public private(set) var upcomingCleanings: [CleaningStatus] = []
    @Published public private(set) var isLoading = false

    // MARK: - Init
    private init(
        dataService: DataService = .shared,
        notificationService: NotificationService = .shared
    ) {
        self.dataService = dataService
        self.notificationService = notificationService
    }

    // MARK: - Refresh

    /// Refresh all cleaning status data
    public func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let enclosures = try dataService.fetchEnclosures()
            var overdue: [CleaningStatus] = []
            var dueSoon: [CleaningStatus] = []
            var needsAttention: [CleaningStatus] = []

            for enclosure in enclosures {
                let schedules = try dataService.fetchCleaningSchedules(for: enclosure)

                for schedule in schedules {
                    let lastCleaning = try dataService.lastCleaning(for: enclosure, type: schedule.cleaningType)

                    let status = CleaningStatus(
                        cleaningType: schedule.cleaningType,
                        lastCleaned: lastCleaning?.cleanedAt,
                        scheduledIntervalDays: schedule.intervalDays,
                        enclosureName: enclosure.name
                    )

                    switch status.urgency {
                    case .overdue:
                        overdue.append(status)
                        needsAttention.append(status)
                    case .dueSoon:
                        dueSoon.append(status)
                        needsAttention.append(status)
                    case .onTrack:
                        break
                    }
                }
            }

            // Sort by urgency
            overdueCleanings = overdue.sorted { ($0.daysSinceLastClean ?? 999) > ($1.daysSinceLastClean ?? 999) }
            upcomingCleanings = dueSoon.sorted { $0.daysUntilDue < $1.daysUntilDue }
            enclosuresNeedingAttention = needsAttention.sorted { $0.daysUntilDue < $1.daysUntilDue }
        } catch {
            print("Error refreshing cleaning data: \(error)")
        }
    }

    // MARK: - Cleaning Event Management

    /// Log a cleaning event
    public func logCleaning(
        for enclosure: Enclosure,
        type: CleaningType,
        notes: String? = nil,
        suppliesUsed: [String]? = nil
    ) throws -> CleaningEvent {
        let event = CleaningEvent(
            cleanedAt: Date(),
            cleaningType: type
        )
        event.enclosure = enclosure
        event.notes = notes

        if let supplies = suppliesUsed {
            event.suppliesUsed = supplies
        }

        // Update enclosure's lastDeepClean if it's a deep clean
        if type == .deepClean {
            enclosure.lastDeepClean = Date()
        }

        dataService.insert(event)
        try dataService.save()

        // Reschedule reminder
        rescheduleCleaningReminder(for: enclosure, type: type)

        Task {
            await refresh()
        }

        return event
    }

    /// Quick clean - log a spot clean
    public func quickClean(for enclosure: Enclosure) throws -> CleaningEvent {
        return try logCleaning(for: enclosure, type: .spotClean)
    }

    // MARK: - Schedule Management

    /// Create or update a cleaning schedule
    public func setCleaningSchedule(
        for enclosure: Enclosure,
        type: CleaningType,
        intervalDays: Int,
        reminderEnabled: Bool = true,
        reminderAdvanceDays: Int = 1
    ) throws -> CleaningSchedule {
        // Check for existing schedule
        let existingSchedules = try dataService.fetchCleaningSchedules(for: enclosure)

        if let existing = existingSchedules.first(where: { $0.cleaningType == type }) {
            // Update existing
            existing.intervalDays = intervalDays
            existing.reminderEnabled = reminderEnabled
            existing.reminderAdvanceDays = reminderAdvanceDays
            try dataService.save()

            if reminderEnabled {
                rescheduleCleaningReminder(for: enclosure, type: type)
            } else {
                cancelCleaningReminder(for: enclosure, type: type)
            }

            return existing
        } else {
            // Create new
            let schedule = CleaningSchedule(
                cleaningType: type,
                intervalDays: intervalDays,
                reminderEnabled: reminderEnabled,
                reminderAdvanceDays: reminderAdvanceDays
            )
            schedule.enclosure = enclosure

            dataService.insert(schedule)
            try dataService.save()

            if reminderEnabled {
                rescheduleCleaningReminder(for: enclosure, type: type)
            }

            return schedule
        }
    }

    /// Remove a cleaning schedule
    public func removeCleaningSchedule(for enclosure: Enclosure, type: CleaningType) throws {
        let schedules = try dataService.fetchCleaningSchedules(for: enclosure)

        if let schedule = schedules.first(where: { $0.cleaningType == type }) {
            cancelCleaningReminder(for: enclosure, type: type)
            dataService.delete(schedule)
            try dataService.save()
        }

        Task {
            await refresh()
        }
    }

    // MARK: - Query Methods

    /// Get cleaning history for an enclosure
    public func cleaningHistory(for enclosure: Enclosure, limit: Int? = nil) throws -> [CleaningEvent] {
        return try dataService.fetchCleaningEvents(for: enclosure, limit: limit)
    }

    /// Get cleaning status for a specific enclosure
    public func cleaningStatus(for enclosure: Enclosure) throws -> [CleaningStatus] {
        let schedules = try dataService.fetchCleaningSchedules(for: enclosure)
        var statuses: [CleaningStatus] = []

        for schedule in schedules {
            let lastCleaning = try dataService.lastCleaning(for: enclosure, type: schedule.cleaningType)

            let status = CleaningStatus(
                cleaningType: schedule.cleaningType,
                lastCleaned: lastCleaning?.cleanedAt,
                scheduledIntervalDays: schedule.intervalDays,
                enclosureName: enclosure.name
            )
            statuses.append(status)
        }

        return statuses.sorted { $0.daysUntilDue < $1.daysUntilDue }
    }

    /// Get days since last clean of any type
    public func daysSinceLastClean(for enclosure: Enclosure) throws -> Int? {
        let events = try dataService.fetchCleaningEvents(for: enclosure, limit: 1)
        guard let lastEvent = events.first else { return nil }
        return Calendar.current.dateComponents([.day], from: lastEvent.cleanedAt, to: Date()).day
    }

    /// Setup default cleaning schedules for a new enclosure
    public func setupDefaultSchedules(for enclosure: Enclosure) throws {
        // Spot clean every 3 days
        _ = try setCleaningSchedule(for: enclosure, type: .spotClean, intervalDays: 3)

        // Water change weekly
        _ = try setCleaningSchedule(for: enclosure, type: .waterChange, intervalDays: 7)

        // Substrate change monthly
        _ = try setCleaningSchedule(for: enclosure, type: .substrateChange, intervalDays: 30)

        // Deep clean quarterly
        _ = try setCleaningSchedule(for: enclosure, type: .deepClean, intervalDays: 90)

        // Bioactive maintenance if applicable
        if enclosure.isBioactive {
            _ = try setCleaningSchedule(for: enclosure, type: .bioactiveMaintenance, intervalDays: 14)
        }
    }

    // MARK: - Notifications

    private func rescheduleCleaningReminder(for enclosure: Enclosure, type: CleaningType) {
        // Calculate next due date
        do {
            let schedules = try dataService.fetchCleaningSchedules(for: enclosure)
            guard let schedule = schedules.first(where: { $0.cleaningType == type }) else { return }

            let lastCleaning = try dataService.lastCleaning(for: enclosure, type: type)
            let lastDate = lastCleaning?.cleanedAt ?? Date()

            let nextDue = Calendar.current.date(
                byAdding: .day,
                value: schedule.intervalDays - schedule.reminderAdvanceDays,
                to: lastDate
            )!

            if nextDue > Date() {
                notificationService.scheduleCleaningReminder(
                    for: enclosure,
                    type: type,
                    dueDate: nextDue
                )
            }
        } catch {
            print("Error scheduling cleaning reminder: \(error)")
        }
    }

    private func cancelCleaningReminder(for enclosure: Enclosure, type: CleaningType) {
        notificationService.cancelCleaningReminder(for: enclosure.id, type: type)
    }
}

// MARK: - Cleaning Errors

public enum CleaningError: Error, LocalizedError {
    case enclosureNotFound
    case scheduleNotFound
    case saveFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .enclosureNotFound:
            return "Enclosure not found"
        case .scheduleNotFound:
            return "Cleaning schedule not found"
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        }
    }
}
