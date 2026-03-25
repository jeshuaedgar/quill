import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var createdAt: Date

    // Relationship
    @Relationship(deleteRule: .nullify, inverse: \Reminder.category)
    var reminders: [Reminder]

    init(
        name: String,
        icon: String = "folder",
        colorHex: String = "#007AFF"
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = Date()
        self.reminders = []
    }
}
