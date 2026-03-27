import SwiftUI

@Observable
class ThemeManager {
    static let shared = ThemeManager()
    
    var accentColorName: String {
        didSet {
            UserDefaults.standard.set(accentColorName, forKey: "accentColor")
        }
    }
    
    var appIconName: String {
        didSet {
            UserDefaults.standard.set(appIconName, forKey: "appIcon")
        }
    }
    
    var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode")
        }
    }
    
    init() {
        self.accentColorName = UserDefaults.standard.string(forKey: "accentColor") ?? "purple"
        self.appIconName = UserDefaults.standard.string(forKey: "appIcon") ?? "AppIcon"
        self.appearanceMode = AppearanceMode(
            rawValue: UserDefaults.standard.string(forKey: "appearanceMode") ?? "system"
        ) ?? .system
    }
    
    // MARK: - Accent Color
    
    var accentColor: Color {
        switch accentColorName {
        case "purple": return .purple
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "pink": return .pink
        case "teal": return .teal
        case "indigo": return .indigo
        default: return .purple
        }
    }
    
    static let availableColors: [(name: String, color: Color)] = [
        ("purple", .purple),
        ("blue", .blue),
        ("green", .green),
        ("orange", .orange),
        ("red", .red),
        ("pink", .pink),
        ("teal", .teal),
        ("indigo", .indigo)
    ]
    
    // MARK: - Color Scheme
    
    var colorScheme: ColorScheme? {
        switch appearanceMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Appearance Mode

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "gear"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}
