import SwiftUI
import SwiftData

@main
struct QuillApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Reminder.self,
            Category.self,
            Tag.self
        ])
    }
}
