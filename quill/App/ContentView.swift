import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: Tab = .home

    enum Tab {
        case home
        case lists
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)

            ListsView()
                .tabItem {
                    Label("Lists", systemImage: "tray.full.fill")
                }
                .tag(Tab.lists)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(.primary)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Reminder.self, Category.self, Tag.self], inMemory: true)
}
