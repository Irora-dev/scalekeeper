import Foundation
import SwiftData

// MARK: - Feeding Routine

@Model
public final class FeedingRoutine {
    // MARK: - Properties
    public var id: UUID
    public var name: String
    public var routineType: FeedingRoutineType
    public var feedingTimesData: Data // JSON-encoded [FeedingTime]
    public var daysOfWeekData: Data // JSON-encoded [Int]
    public var animalIDsData: Data // JSON-encoded [UUID]
    public var intervalDays: Int // For every N days schedule
    public var startDate: Date
    public var endDate: Date?
    public var isActive: Bool
    public var notes: String?
    public var createdAt: Date
    public var updatedAt: Date

    // MARK: - Init
    public init(
        id: UUID = UUID(),
        name: String,
        routineType: FeedingRoutineType = .daily,
        feedingTimes: [FeedingTime] = [],
        daysOfWeek: [Int] = [],
        animalIDs: [UUID] = [],
        intervalDays: Int = 7,
        startDate: Date = Date(),
        endDate: Date? = nil,
        isActive: Bool = true,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.routineType = routineType
        self.feedingTimesData = (try? JSONEncoder().encode(feedingTimes)) ?? Data()
        self.daysOfWeekData = (try? JSONEncoder().encode(daysOfWeek)) ?? Data()
        self.animalIDsData = (try? JSONEncoder().encode(animalIDs)) ?? Data()
        self.intervalDays = intervalDays
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Accessor Methods

    public func getFeedingTimes() -> [FeedingTime] {
        (try? JSONDecoder().decode([FeedingTime].self, from: feedingTimesData)) ?? []
    }

    public func setFeedingTimes(_ times: [FeedingTime]) {
        feedingTimesData = (try? JSONEncoder().encode(times)) ?? Data()
    }

    public func getDaysOfWeek() -> [Int] {
        (try? JSONDecoder().decode([Int].self, from: daysOfWeekData)) ?? []
    }

    public func setDaysOfWeek(_ days: [Int]) {
        daysOfWeekData = (try? JSONEncoder().encode(days)) ?? Data()
    }

    public func getAnimalIDs() -> [UUID] {
        (try? JSONDecoder().decode([UUID].self, from: animalIDsData)) ?? []
    }

    public func setAnimalIDs(_ ids: [UUID]) {
        animalIDsData = (try? JSONEncoder().encode(ids)) ?? Data()
    }

    // MARK: - Methods

    /// Get the next feeding date from now
    public func getNextFeedingDateFromNow() -> Date? {
        getNextFeedingDate(from: Date())
    }

    /// Get all feeding dates for the next 7 days
    public func getUpcomingWeekFeedings() -> [ScheduledFeeding] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var feedings: [ScheduledFeeding] = []
        let times = getFeedingTimes()
        let animalIDs = getAnimalIDs()

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }

            if shouldFeedOnDate(date) {
                for time in times {
                    guard let feedingDate = time.dateForDay(date) else { continue }
                    feedings.append(ScheduledFeeding(
                        scheduleID: id,
                        scheduleName: name,
                        date: feedingDate,
                        animalIDs: animalIDs,
                        timeLabel: time.label
                    ))
                }
            }
        }

        return feedings.sorted { $0.date < $1.date }
    }

    public func shouldFeedOnDate(_ date: Date) -> Bool {
        let calendar = Calendar.current

        // Check if date is within schedule range
        let startOfDate = calendar.startOfDay(for: date)
        let startOfStart = calendar.startOfDay(for: startDate)

        if startOfDate < startOfStart { return false }
        if let end = endDate, startOfDate > calendar.startOfDay(for: end) { return false }

        let days = getDaysOfWeek()

        switch routineType {
        case .daily:
            return true

        case .everyOtherDay:
            let dayCount = calendar.dateComponents([.day], from: startOfStart, to: startOfDate).day ?? 0
            return dayCount % 2 == 0

        case .weekly:
            let weekday = calendar.component(.weekday, from: date)
            return days.contains(weekday)

        case .everyNDays:
            let dayCount = calendar.dateComponents([.day], from: startOfStart, to: startOfDate).day ?? 0
            return dayCount % intervalDays == 0

        case .custom:
            // Custom schedules use daysOfWeek
            let weekday = calendar.component(.weekday, from: date)
            return days.contains(weekday)
        }
    }

    public func getNextFeedingDate(from date: Date) -> Date? {
        let calendar = Calendar.current
        var checkDate = calendar.startOfDay(for: date)
        let times = getFeedingTimes()

        // Check up to 30 days ahead
        for _ in 0..<30 {
            if shouldFeedOnDate(checkDate) {
                // Return the first feeding time on this day
                if let firstTime = times.sorted(by: { $0.hour < $1.hour || ($0.hour == $1.hour && $0.minute < $1.minute) }).first {
                    return firstTime.dateForDay(checkDate)
                }
                return checkDate
            }
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: checkDate) else { break }
            checkDate = nextDay
        }

        return nil
    }
}

// MARK: - Feeding Routine Type

public enum FeedingRoutineType: String, Codable, CaseIterable {
    case daily
    case everyOtherDay
    case weekly
    case everyNDays
    case custom

    public var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .everyOtherDay: return "Every Other Day"
        case .weekly: return "Weekly"
        case .everyNDays: return "Every N Days"
        case .custom: return "Custom"
        }
    }

    public var description: String {
        switch self {
        case .daily: return "Feed every day"
        case .everyOtherDay: return "Feed every other day"
        case .weekly: return "Feed on specific days of the week"
        case .everyNDays: return "Feed every N days"
        case .custom: return "Custom feeding schedule"
        }
    }
}

// MARK: - Feeding Time

public struct FeedingTime: Codable, Hashable, Identifiable {
    public var id: UUID
    public var label: String
    public var hour: Int
    public var minute: Int

    public init(
        id: UUID = UUID(),
        label: String = "Feeding",
        hour: Int = 18,
        minute: Int = 0
    ) {
        self.id = id
        self.label = label
        self.hour = hour
        self.minute = minute
    }

    public var displayTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let calendar = Calendar.current
        let components = DateComponents(hour: hour, minute: minute)
        if let date = calendar.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):\(String(format: "%02d", minute))"
    }

    public func dateForDay(_ day: Date) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)
    }
}

// MARK: - Scheduled Feeding (for display)

public struct ScheduledFeeding: Identifiable {
    public let id = UUID()
    public let scheduleID: UUID
    public let scheduleName: String
    public let date: Date
    public let animalIDs: [UUID]
    public let timeLabel: String

    public init(
        scheduleID: UUID,
        scheduleName: String,
        date: Date,
        animalIDs: [UUID],
        timeLabel: String
    ) {
        self.scheduleID = scheduleID
        self.scheduleName = scheduleName
        self.date = date
        self.animalIDs = animalIDs
        self.timeLabel = timeLabel
    }

    public var animalCount: Int {
        animalIDs.count
    }

    public var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    public var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    public var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(date)
    }
}

// MARK: - Day of Week Helper

public enum DayOfWeek: Int, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    public var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    public var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
}
