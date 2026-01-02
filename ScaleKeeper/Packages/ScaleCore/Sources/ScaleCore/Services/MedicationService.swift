import Foundation
import SwiftData

// MARK: - Medication Service

@MainActor
public final class MedicationService: ObservableObject {
    public static let shared = MedicationService()

    private let dataService: DataService
    private let notificationService: NotificationService

    // MARK: - Published State
    @Published public private(set) var activeTreatments: [TreatmentPlan] = []
    @Published public private(set) var dosesToday: [MedicationDose] = []
    @Published public private(set) var overdueDoses: [MedicationDose] = []
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

    /// Refresh all medication data
    public func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            activeTreatments = try dataService.fetchActiveTreatments()

            let today = Calendar.current.startOfDay(for: Date())
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

            var todayDoses: [MedicationDose] = []
            var lateDoses: [MedicationDose] = []

            for treatment in activeTreatments {
                guard let doses = treatment.doses else { continue }

                for dose in doses {
                    if dose.status == .scheduled {
                        if dose.scheduledTime < Date() {
                            lateDoses.append(dose)
                        } else if dose.scheduledTime >= today && dose.scheduledTime < tomorrow {
                            todayDoses.append(dose)
                        }
                    }
                }
            }

            dosesToday = todayDoses.sorted { $0.scheduledTime < $1.scheduledTime }
            overdueDoses = lateDoses.sorted { $0.scheduledTime < $1.scheduledTime }
        } catch {
            print("Error refreshing medication data: \(error)")
        }
    }

    // MARK: - Treatment Plan Management

    /// Create a new treatment plan with scheduled doses
    public func createTreatmentPlan(
        for animal: Animal,
        medication: Medication,
        conditionTreated: String,
        dosage: String,
        frequencyHours: Int,
        totalDoses: Int,
        startDate: Date = Date(),
        prescribedBy: String? = nil,
        notes: String? = nil
    ) throws -> TreatmentPlan {
        let plan = TreatmentPlan(
            conditionTreated: conditionTreated,
            dosage: dosage,
            frequencyHours: frequencyHours,
            totalDoses: totalDoses,
            startDate: startDate
        )
        plan.animal = animal
        plan.medication = medication
        plan.prescribedBy = prescribedBy
        plan.notes = notes

        // Generate scheduled doses
        var doses: [MedicationDose] = []
        var doseTime = startDate

        for _ in 0..<totalDoses {
            let dose = MedicationDose(scheduledTime: doseTime)
            dose.treatmentPlan = plan
            doses.append(dose)
            doseTime = Calendar.current.date(byAdding: .hour, value: frequencyHours, to: doseTime)!
        }

        plan.doses = doses

        // Calculate end date
        if let lastDose = doses.last {
            plan.endDate = lastDose.scheduledTime
        }

        dataService.insert(plan)
        for dose in doses {
            dataService.insert(dose)
        }
        try dataService.save()

        // Schedule notifications for each dose
        scheduleDoseReminders(for: plan)

        Task {
            await refresh()
        }

        return plan
    }

    /// Administer a scheduled dose
    public func administerDose(_ dose: MedicationDose, notes: String? = nil) throws {
        dose.status = .administered
        dose.administeredTime = Date()
        dose.notes = notes

        try dataService.save()

        // Check if treatment is complete
        if let plan = dose.treatmentPlan, plan.isComplete {
            plan.status = .completed
            try dataService.save()
        }

        Task {
            await refresh()
        }
    }

    /// Skip a dose
    public func skipDose(_ dose: MedicationDose, reason: String? = nil) throws {
        dose.status = .skipped
        dose.notes = reason

        try dataService.save()

        Task {
            await refresh()
        }
    }

    /// Mark a dose as missed
    public func markDoseMissed(_ dose: MedicationDose) throws {
        dose.status = .missed

        try dataService.save()

        Task {
            await refresh()
        }
    }

    /// Pause a treatment plan
    public func pauseTreatment(_ plan: TreatmentPlan) throws {
        plan.status = .paused

        // Cancel pending notifications
        cancelDoseReminders(for: plan)

        try dataService.save()

        Task {
            await refresh()
        }
    }

    /// Resume a paused treatment
    public func resumeTreatment(_ plan: TreatmentPlan) throws {
        plan.status = .active

        // Reschedule notifications
        scheduleDoseReminders(for: plan)

        try dataService.save()

        Task {
            await refresh()
        }
    }

    /// Discontinue a treatment
    public func discontinueTreatment(_ plan: TreatmentPlan, reason: String? = nil) throws {
        plan.status = .discontinued
        plan.endDate = Date()
        if let reason = reason {
            plan.notes = (plan.notes ?? "") + "\nDiscontinued: \(reason)"
        }

        // Cancel pending notifications
        cancelDoseReminders(for: plan)

        try dataService.save()

        Task {
            await refresh()
        }
    }

    // MARK: - Query Methods

    /// Get all treatments for an animal
    public func treatments(for animal: Animal) throws -> [TreatmentPlan] {
        return try dataService.fetchTreatments(for: animal)
    }

    /// Get active treatment summaries for dashboard
    public func activeTreatmentSummaries() throws -> [ActiveTreatmentSummary] {
        var summaries: [ActiveTreatmentSummary] = []

        for plan in activeTreatments {
            guard let animal = plan.animal,
                  let medication = plan.medication else { continue }

            let today = Calendar.current.startOfDay(for: Date())
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

            let todayDoses = plan.doses?.filter {
                $0.scheduledTime >= today && $0.scheduledTime < tomorrow
            } ?? []

            let summary = ActiveTreatmentSummary(
                treatmentPlan: plan,
                animalName: animal.name,
                medicationName: medication.name,
                dosesToday: todayDoses,
                nextDose: plan.nextScheduledDose
            )
            summaries.append(summary)
        }

        return summaries
    }

    /// Get animals currently on treatment
    public func animalsOnTreatment() throws -> [Animal] {
        let treatments = try dataService.fetchActiveTreatments()
        let animals = treatments.compactMap { $0.animal }
        return Array(Set(animals)) // Remove duplicates
    }

    // MARK: - Notifications

    private func scheduleDoseReminders(for plan: TreatmentPlan) {
        guard let doses = plan.doses else { return }

        for dose in doses where dose.status == .scheduled {
            notificationService.scheduleMedicationReminder(
                for: plan,
                dose: dose
            )
        }
    }

    private func cancelDoseReminders(for plan: TreatmentPlan) {
        notificationService.cancelMedicationReminders(for: plan.id)
    }
}

// MARK: - Medication Errors

public enum MedicationError: Error, LocalizedError {
    case treatmentNotFound
    case doseNotFound
    case invalidProtocol
    case saveFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .treatmentNotFound:
            return "Treatment plan not found"
        case .doseNotFound:
            return "Medication dose not found"
        case .invalidProtocol:
            return "Invalid medication protocol"
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        }
    }
}
