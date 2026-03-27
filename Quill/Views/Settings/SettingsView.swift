import SwiftUI

struct SettingsView: View {
    @State private var themeManager = ThemeManager.shared
    @AppStorage("defaultPriority") private var defaultPriority = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Appearance
                Section("Appearance") {
                    // Theme Mode
                    Picker("Mode", selection: $themeManager.appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Label(mode.label, systemImage: mode.icon)
                                .tag(mode)
                        }
                    }
                    
                    // Accent Color
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Accent Color")
                            .font(.subheadline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(ThemeManager.availableColors, id: \.name) { item in
                                    Button {
                                        withAnimation {
                                            themeManager.accentColorName = item.name
                                        }
                                        HapticManager.shared.selection()
                                    } label: {
                                        Circle()
                                            .fill(item.color)
                                            .frame(width: 32, height: 32)
                                            .overlay {
                                                if themeManager.accentColorName == item.name {
                                                    Image(systemName: "checkmark")
                                                        .font(.caption)
                                                        .fontWeight(.bold)
                                                        .foregroundStyle(.white)
                                                }
                                            }
                                            .shadow(
                                                color: themeManager.accentColorName == item.name
                                                    ? item.color.opacity(0.5) : .clear,
                                                radius: 4
                                            )
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                // MARK: - Defaults
                Section("Defaults") {
                    Picker("Default Priority", selection: $defaultPriority) {
                        ForEach(Priority.allCases) { level in
                            Label(level.label, systemImage: level.icon)
                                .tag(level.rawValue)
                        }
                    }
                }
                
                // MARK: - Intelligence
                Section("Intelligence") {
                    HStack {
                        Label("AI Features", systemImage: "sparkles")
                        Spacer()
                        if LLMService.shared.isAvailable {
                            Text("Full (iOS 26)")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            Text("Basic (NLP)")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    
                    HStack {
                        Label("On-Device Processing", systemImage: "lock.shield.fill")
                        Spacer()
                        Text("Always")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                
                // MARK: - Notifications
                Section("Notifications") {
                    Button {
                        NotificationManager.shared.requestPermission()
                        HapticManager.shared.success()
                    } label: {
                        Label("Request Permission", systemImage: "bell.badge")
                    }
                    
                    Button(role: .destructive) {
                        NotificationManager.shared.cancelAllNotifications()
                        HapticManager.shared.warning()
                    } label: {
                        Label("Cancel All Notifications", systemImage: "bell.slash")
                    }
                }
                
                // MARK: - About
                Section("About") {
                    LabeledContent("App", value: "Quill")
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Build", value: "1")
                    
                    Link(destination: URL(string: "https://github.com/yourusername/quill")!) {
                        HStack {
                            Label("GitHub", systemImage: "link")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // MARK: - Debug
                Section("Debug") {
                    Button {
                        hasCompletedOnboarding = false
                        HapticManager.shared.lightImpact()
                    } label: {
                        Label("Show Onboarding Again", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
