import Foundation
import SwiftData

// MARK: - Animal Photo Entity

@Model
public final class AnimalPhoto {
    // MARK: - Identity
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date

    // MARK: - Storage
    public var localPath: String?
    public var cloudIdentifier: String?
    public var thumbnailPath: String?
    @Attribute(.externalStorage) public var imageData: Data?

    // MARK: - Metadata
    public var capturedAt: Date
    public var caption: String?

    // MARK: - Classification
    public var photoType: AnimalPhotoType
    public var isPrimary: Bool

    // MARK: - Technical
    public var widthPixels: Int?
    public var heightPixels: Int?
    public var fileSizeBytes: Int?

    // MARK: - Context
    public var weightAtTimeGrams: Double?
    public var ageAtTimeDays: Int?

    // MARK: - Relationships
    public var animal: Animal?

    // MARK: - Init
    public init(
        id: UUID = UUID(),
        localPath: String? = nil,
        imageData: Data? = nil,
        capturedAt: Date = Date(),
        photoType: AnimalPhotoType = .general,
        isPrimary: Bool = false
    ) {
        self.id = id
        self.createdAt = Date()
        self.localPath = localPath
        self.imageData = imageData
        self.capturedAt = capturedAt
        self.photoType = photoType
        self.isPrimary = isPrimary
    }
}

// MARK: - Photo Type

public enum AnimalPhotoType: String, Codable, CaseIterable {
    case general
    case fullBody = "full_body"
    case headshot
    case pattern
    case belly
    case shed
    case feeding
    case enclosure
    case health
    case progress
    case sale

    public var displayName: String {
        switch self {
        case .general: return "General"
        case .fullBody: return "Full Body"
        case .headshot: return "Headshot"
        case .pattern: return "Pattern"
        case .belly: return "Belly"
        case .shed: return "Shed"
        case .feeding: return "Feeding"
        case .enclosure: return "Enclosure"
        case .health: return "Health"
        case .progress: return "Progress"
        case .sale: return "Sale Photo"
        }
    }

    public var iconName: String {
        switch self {
        case .general: return "photo"
        case .fullBody: return "figure.stand"
        case .headshot: return "person.crop.circle"
        case .pattern: return "circle.hexagongrid"
        case .belly: return "circle.bottomhalf.filled"
        case .shed: return "leaf"
        case .feeding: return "fork.knife"
        case .enclosure: return "house"
        case .health: return "cross.case"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .sale: return "tag"
        }
    }
}

// MARK: - Photo Gallery Helpers

public struct PhotoGalleryItem: Identifiable {
    public let id: UUID
    public let photo: AnimalPhoto
    public let index: Int

    public init(photo: AnimalPhoto, index: Int) {
        self.id = photo.id
        self.photo = photo
        self.index = index
    }
}

public struct PhotoTimeline {
    public let photos: [AnimalPhoto]
    public let groupedByMonth: [String: [AnimalPhoto]]

    public init(photos: [AnimalPhoto]) {
        self.photos = photos.sorted { $0.capturedAt > $1.capturedAt }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        var grouped: [String: [AnimalPhoto]] = [:]
        for photo in self.photos {
            let key = formatter.string(from: photo.capturedAt)
            grouped[key, default: []].append(photo)
        }
        self.groupedByMonth = grouped
    }

    public var monthKeys: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let sortedDates = photos.map { $0.capturedAt }.sorted(by: >)
        var seen = Set<String>()
        var result: [String] = []

        for date in sortedDates {
            let key = formatter.string(from: date)
            if !seen.contains(key) {
                seen.insert(key)
                result.append(key)
            }
        }
        return result
    }
}
