import ActivityKit
import SwiftUI
import WidgetKit

struct QuillActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let reminderTitle: String
        let dueDate: Date?
        let priorityRaw: Int
        let isCompleted: Bool

        var priority: Priority {
            Priority(rawValue: priorityRaw) ?? .none
        }
    }

    let reminderID: String
}
