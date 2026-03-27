import Foundation

@Observable
class FocusModeManager {
    static let shared = FocusModeManager()
    
    private init() {}
    
    // Available focus modes
    static let focusModes: [(name: String, icon: String)] = [
        ("All", "tray.full.fill"),
        ("Work", "briefcase.fill"),
        ("Personal", "person.fill"),
        ("Health", "heart.fill"),
        ("Education", "book.fill"),
        ("Finance", "dollarsign.circle.fill"),
        ("Home", "house.fill"),
        ("Travel", "airplane")
    ]
    
    var activeFocus: String = "All" {
        didSet {
            UserDefaults.standard.set(activeFocus, forKey: "activeFocus")
        }
    }
    
    init(loadSaved: Bool = true) {
        if loadSaved {
            self.activeFocus = UserDefaults.standard.string(forKey: "activeFocus") ?? "All"
        }
    }
    
    // MARK: - Filter Reminders
    
    func filterReminders(_ reminders: [Reminder]) -> [Reminder] {
        guard activeFocus != "All" else { return reminders }
        
        return reminders.filter { reminder in
            // Match by focus filter
            if let filter = reminder.focusFilter {
                return filter.lowercased() == activeFocus.lowercased()
            }
            
            // Match by category name
            if let category = reminder.category {
                return category.name.lowercased() == activeFocus.lowercased()
            }
            
            // Show uncategorized reminders in all focus modes
            return true
        }
    }
}
