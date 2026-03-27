import Foundation
import SwiftData

@Model
final class SharedList {
    var id: UUID
    var name: String
    var icon: String
    var ownerName: String
    var sharedWithNames: [String]
    var createdAt: Date
    var reminders: [Reminder]
    
    init(
        name: String,
        icon: String = "person.2.fill",
        ownerName: String = "Me"
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.ownerName = ownerName
        self.sharedWithNames = []
        self.createdAt = Date()
        self.reminders = []
    }
}
