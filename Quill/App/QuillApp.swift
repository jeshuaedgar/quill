import SwiftUI
import SwiftData

@main
struct QuillApp: App {
    @State private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(themeManager.accentColor)
                .preferredColorScheme(themeManager.colorScheme)
        }
        .modelContainer(for: [
            Reminder.self,
            Category.self,
            Tag.self,
            SharedList.self
        ])
    }
}
