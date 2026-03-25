import SwiftUI

struct SettingsView: View {
    @AppStorage("appTheme") private var appTheme = "system"
    @AppStorage("defaultPriority") private var defaultPriority = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $appTheme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                }

                Section("Defaults") {
                    Picker("Default Priority", selection: $defaultPriority) {
                        ForEach(Priority.allCases) { level in
                            Text(level.label).tag(level.rawValue)
                        }
                    }
                }

                Section("Notifications") {
                    Button("Request Permission") {
                        NotificationManager.shared.requestPermission()
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Build", value: "1")

                    Link(destination: URL(string: "https://github.com/yourusername/quill")!) {
                        Label("GitHub", systemImage: "link")
                    }
                }

                Section("Danger Zone") {
                    Button("Cancel All Notifications", role: .destructive) {
                        NotificationManager.shared.cancelAllNotifications()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
