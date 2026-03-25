import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    var name: String

    @Relationship(deleteRule: .nullify, inverse: \Reminder.tags)
    var reminders: [Reminder]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.reminders = []
    }
}
