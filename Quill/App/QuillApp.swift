import SwiftUI
import SwiftData

@main
struct QuillApp: App {
    @State private var themeManager = ThemeManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                if let container = try? ModelContainer(for: Reminder.self, Category.self, Tag.self) {
                    LiveActivityManager.shared.checkAutoStart(modelContext: container.mainContext)
                }
            }
        }
    }
}
