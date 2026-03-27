import Foundation
import NaturalLanguage

class NLParser {
    static let shared = NLParser()
    
    private init() {}
    
    struct ParseResult {
        var title: String
        var date: Date?
        var hasTime: Bool
        var suggestedCategory: String?
        var suggestedPriority: Priority
        var people: [String]
        var locations: [String]
    }
    
    // MARK: - Full Parse
    
    func parse(_ text: String) -> ParseResult {
        // Extract date first
        let dateResult = DateExtractor.shared.extract(from: text)
        
        // Extract entities from original text
        let entities = extractEntities(from: text)
        
        // Suggest category
        let category = suggestCategory(from: text)
        
        // Suggest priority
        let priority = suggestPriority(from: text)
        
        return ParseResult(
            title: dateResult.cleanedTitle,
            date: dateResult.date,
            hasTime: dateResult.hasTime,
            suggestedCategory: category,
            suggestedPriority: priority,
            people: entities.people,
            locations: entities.locations
        )
    }
    
    // MARK: - Entity Extraction
    
    private struct Entities {
        var people: [String]
        var locations: [String]
    }
    
    private func extractEntities(from text: String) -> Entities {
        var people: [String] = []
        var locations: [String] = []
        
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation]
        
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .nameType,
            options: options
        ) { tag, range in
            let entity = String(text[range])
            
            switch tag {
            case .personalName:
                people.append(entity)
            case .placeName:
                locations.append(entity)
            default:
                break
            }
            
            return true
        }
        
        return Entities(people: people, locations: locations)
    }
    
    // MARK: - Category Suggestion
    
    func suggestCategory(from text: String) -> String? {
        let lowercased = text.lowercased()
        
        let categoryKeywords: [String: [String]] = [
            "Work": [
                "meeting", "email", "report", "presentation", "deadline",
                "project", "client", "office", "boss", "colleague",
                "submit", "review", "invoice", "proposal", "agenda"
            ],
            "Shopping": [
                "buy", "purchase", "shop", "grocery", "groceries",
                "store", "order", "pick up", "milk", "bread",
                "amazon", "market", "mall"
            ],
            "Health": [
                "doctor", "dentist", "gym", "workout", "exercise",
                "medicine", "appointment", "pharmacy", "vitamin",
                "run", "yoga", "meditation", "therapy", "checkup"
            ],
            "Personal": [
                "call", "text", "message", "birthday", "anniversary",
                "gift", "party", "dinner", "lunch", "friend",
                "family", "mom", "dad", "brother", "sister"
            ],
            "Finance": [
                "pay", "bill", "rent", "mortgage", "insurance",
                "tax", "bank", "transfer", "budget", "invoice",
                "salary", "refund", "subscription"
            ],
            "Home": [
                "clean", "laundry", "dishes", "vacuum", "repair",
                "fix", "organize", "trash", "garbage", "mow",
                "garden", "cook", "maintenance"
            ],
            "Education": [
                "study", "homework", "assignment", "exam", "test",
                "class", "lecture", "read", "book", "course",
                "learn", "research", "paper", "essay"
            ],
            "Travel": [
                "flight", "hotel", "booking", "passport", "visa",
                "pack", "luggage", "airport", "train", "trip",
                "vacation", "itinerary", "reservation"
            ]
        ]
        
        var bestMatch: String?
        var highestScore = 0
        
        for (category, keywords) in categoryKeywords {
            let score = keywords.filter { lowercased.contains($0) }.count
            if score > highestScore {
                highestScore = score
                bestMatch = category
            }
        }
        
        return highestScore > 0 ? bestMatch : nil
    }
    
    // MARK: - Priority Suggestion
    
    func suggestPriority(from text: String) -> Priority {
        let lowercased = text.lowercased()
        
        let urgentKeywords = [
            "urgent", "asap", "emergency", "immediately", "critical",
            "now", "right away", "important"
        ]
        
        let highKeywords = [
            "deadline", "due", "submit", "before", "must",
            "need to", "have to", "don't forget"
        ]
        
        let mediumKeywords = [
            "should", "plan", "prepare", "schedule", "arrange",
            "soon", "this week"
        ]
        
        for keyword in urgentKeywords {
            if lowercased.contains(keyword) { return .urgent }
        }
        
        for keyword in highKeywords {
            if lowercased.contains(keyword) { return .high }
        }
        
        for keyword in mediumKeywords {
            if lowercased.contains(keyword) { return .medium }
        }
        
        return .none
    }
}
