// ScaleCore - Core data models and services for ScaleKeeper
// Part of the ScaleKeeper iOS Application

import Foundation
import SwiftData

// MARK: - Public Exports

// Models
public typealias AnimalModel = Animal
public typealias SpeciesModel = Species
public typealias FeedingModel = FeedingEvent

// MARK: - Schema Definition

public enum ScaleSchema {
    public static var models: [any PersistentModel.Type] {
        [
            // Core
            ScaleUser.self,
            Animal.self,
            Species.self,

            // Feeding
            FeedingEvent.self,
            FeedingRoutine.self,

            // Biometrics
            WeightRecord.self,
            LengthRecord.self,

            // Health
            HealthNote.self,
            ShedRecord.self,

            // Photos
            AnimalPhoto.self,

            // Enclosures
            Enclosure.self,
            EnvironmentReading.self,

            // Cleaning
            CleaningEvent.self,
            CleaningSchedule.self,

            // Medications
            Medication.self,
            TreatmentPlan.self,
            MedicationDose.self,

            // Breeding
            Pairing.self,
            Clutch.self,
            BrumationCycle.self
        ]
    }

    public static var schema: Schema {
        Schema(models)
    }
}

// MARK: - App Group Constants

public enum ScaleConstants {
    public static let appGroupIdentifier = "group.com.scalekeeper.app"
    public static let cloudKitContainerIdentifier = "iCloud.com.scalekeeper.app"
    public static let bundleIdentifier = "com.scalekeeper.app"

    public enum Limits {
        public static let freeAnimalLimit = 5
        public static let freeHistoryWeeks = 4
        public static let maxPhotoSizeMB = 10
        public static let maxPhotosPerAnimal = 100
    }

    public enum Notifications {
        public static let feedingReminderCategory = "FEEDING_REMINDER"
        public static let environmentAlertCategory = "ENVIRONMENT_ALERT"
        public static let shedAlertCategory = "SHED_ALERT"
        public static let medicationReminderCategory = "MEDICATION_REMINDER"
        public static let cleaningReminderCategory = "CLEANING_REMINDER"
        public static let brumationReminderCategory = "BRUMATION_REMINDER"
    }
}
