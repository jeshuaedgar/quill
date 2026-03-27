import Foundation
import SwiftData

class CategoryClassifier {
    static let shared = CategoryClassifier()
    
    private init() {}
    
    // MARK: - Auto-Assign Category
    
    func findOrSuggestCategory(
        for text: String,
        existingCategories: [Category],
        modelContext: ModelContext
    ) -> Category? {
        
        // Get AI suggestion
        guard let suggestedName = NLParser.shared.suggestCategory(from: text) else {
            return nil
        }
        
        // Check if category already exists (case-insensitive)
        if let existing = existingCategories.first(where: {
            $0.name.lowercased() == suggestedName.lowercased()
        }) {
            return existing
        }
        
        // Create new category with appropriate icon
        let icon = iconForCategory(suggestedName)
        let color = colorForCategory(suggestedName)
        let newCategory = Category(name: suggestedName, icon: icon, colorHex: color)
        modelContext.insert(newCategory)
        
        return newCategory
    }
    
    // MARK: - Category Icons
    
    private func iconForCategory(_ name: String) -> String {
        let icons: [String: String] = [
            "Work": "briefcase.fill",
            "Shopping": "cart.fill",
            "Health": "heart.fill",
            "Personal": "person.fill",
            "Finance": "dollarsign.circle.fill",
            "Home": "house.fill",
            "Education": "book.fill",
            "Travel": "airplane"
        ]
        return icons[name] ?? "folder.fill"
    }
    
    // MARK: - Category Colors
    
    private func colorForCategory(_ name: String) -> String {
        let colors: [String: String] = [
            "Work": "#007AFF",
            "Shopping": "#34C759",
            "Health": "#FF2D55",
            "Personal": "#AF52DE",
            "Finance": "#FF9500",
            "Home": "#5AC8FA",
            "Education": "#5856D6",
            "Travel": "#FF3B30"
        ]
        return colors[name] ?? "#8E8E93"
    }
}
