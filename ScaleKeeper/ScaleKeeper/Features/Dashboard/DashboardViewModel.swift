import SwiftUI
import ScaleCore

// MARK: - Dashboard View Model

@MainActor
@Observable
final class DashboardViewModel: ObservableObject {
    // MARK: - Dependencies
    private let dataService: DataService
    private let feedingService: FeedingService
    private let cleaningService: CleaningService
    private let medicationService: MedicationService

    // MARK: - State
    var totalAnimals: Int = 0
    var feedingsDue: [Animal] = []
    var fedToday: Int = 0
    var overdueCount: Int = 0
    var recentActivity: [ActivityItem] = []
    var cleaningAlerts: [CleaningStatus] = []
    var enclosureCount: Int = 0
    var activeTreatmentCount: Int = 0
    var isLoading = false
    var error: Error?

    // MARK: - Init
    init(
        dataService: DataService = .shared,
        feedingService: FeedingService = .shared,
        cleaningService: CleaningService = .shared,
        medicationService: MedicationService = .shared
    ) {
        self.dataService = dataService
        self.feedingService = feedingService
        self.cleaningService = cleaningService
        self.medicationService = medicationService
    }

    // MARK: - Load Data

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Load animal count
            totalAnimals = try dataService.activeAnimalCount()

            // Refresh feeding service
            await feedingService.refresh()

            // Get feeding status
            feedingsDue = feedingService.dueToday + feedingService.overdue
            fedToday = feedingService.fedToday.count
            overdueCount = feedingService.overdue.count

            // Load enclosure data
            let enclosures = try dataService.fetchEnclosures()
            enclosureCount = enclosures.count

            // Load cleaning alerts
            await cleaningService.refresh()
            cleaningAlerts = cleaningService.enclosuresNeedingAttention

            // Load medication data
            await medicationService.refresh()
            activeTreatmentCount = medicationService.activeTreatments.count

            // Load recent activity
            await loadRecentActivity()

        } catch {
            self.error = error
            print("Dashboard load error: \(error)")
        }
    }

    // MARK: - Recent Activity

    private func loadRecentActivity() async {
        var activities: [ActivityItem] = []

        // Get recent feedings
        do {
            let feedings = try dataService.feedingsToday()
            for feeding in feedings.prefix(3) {
                if let animal = feeding.animal {
                    activities.append(ActivityItem(
                        title: "Fed \(animal.name)",
                        icon: "fork.knife",
                        color: .scaleSuccess,
                        timestamp: feeding.feedingDate
                    ))
                }
            }
        } catch {
            print("Failed to load recent feedings: \(error)")
        }

        // Sort by timestamp
        recentActivity = activities.sorted { $0.timestamp > $1.timestamp }
    }
}
