import Foundation
import SwiftData
import CoreLocation

@Model
final class Reminder {
    var id: UUID
    var title: String
    var notes: String
    var dueDate: Date?
    var isCompleted: Bool
    var priority: Priority
    var createdAt: Date
    var completedAt: Date?
    var notificationID: String?
    
    // Location
    var locationLatitude: Double?
    var locationLongitude: Double?
    var locationName: String?
    var locationRadius: Double?
    var triggerOnArrival: Bool
    
    // Focus Mode
    var focusFilter: String?
    
    // Collaboration
    var isShared: Bool
    var sharedWithIDs: [String]

    // Relationships
    var category: Category?
    var tags: [Tag]

    init(
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        isCompleted: Bool = false,
        priority: Priority = .none,
        category: Category? = nil,
        tags: [Tag] = [],
        locationLatitude: Double? = nil,
        locationLongitude: Double? = nil,
        locationName: String? = nil,
        locationRadius: Double? = nil,
        triggerOnArrival: Bool = true,
        focusFilter: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.priority = priority
        self.createdAt = Date()
        self.completedAt = nil
        self.notificationID = UUID().uuidString
        self.category = category
        self.tags = tags
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        self.locationName = locationName
        self.locationRadius = locationRadius
        self.triggerOnArrival = triggerOnArrival
        self.focusFilter = focusFilter
        self.isShared = false
        self.sharedWithIDs = []
    }
    
    // MARK: - Computed Properties
    
    var hasLocation: Bool {
        locationLatitude != nil && locationLongitude != nil
    }
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = locationLatitude, let lon = locationLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

// MARK: - Priority Enum

enum Priority: Int, Codable, CaseIterable, Identifiable {
    case none = 0
    case low = 1
    case medium = 2
    case high = 3
    case urgent = 4

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .none: return "None"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }

    var color: String {
        switch self {
        case .none: return "gray"
        case .low: return "blue"
        case .medium: return "yellow"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }

    var icon: String {
        switch self {
        case .none: return "minus"
        case .low: return "arrow.down"
        case .medium: return "equal"
        case .high: return "arrow.up"
        case .urgent: return "exclamationmark.2"
        }
    }
}

// MARK: - Exportable

extension Reminder {
    struct ExportData: Codable {
        let title: String
        let notes: String
        let dueDate: Date?
        let isCompleted: Bool
        let priority: Int
        let createdAt: Date
        let completedAt: Date?
        let categoryName: String?
        let tagNames: [String]
        let locationName: String?
    }
    
    var exportData: ExportData {
        ExportData(
            title: title,
            notes: notes,
            dueDate: dueDate,
            isCompleted: isCompleted,
            priority: priority.rawValue,
            createdAt: createdAt,
            completedAt: completedAt,
            categoryName: category?.name,
            tagNames: tags.map { $0.name },
            locationName: locationName
        )
    }
}
