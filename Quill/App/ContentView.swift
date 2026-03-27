import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: Tab = .home

    enum Tab {
        case home
        case lists
        case settings
    }

    var body: some View {
        if hasCompletedOnboarding {
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
            .tint(ThemeManager.shared.accentColor)
            .transition(.opacity)
        } else {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .transition(.opacity)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Reminder.self, Category.self, Tag.self], inMemory: true)
}
