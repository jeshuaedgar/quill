import Foundation

class DateExtractor {
    static let shared = DateExtractor()
    
    private init() {}
    
    struct ExtractionResult {
        var cleanedTitle: String
        var date: Date?
        var hasTime: Bool
    }
    
    // MARK: - Extract Date from Natural Language
    
    func extract(from text: String) -> ExtractionResult {
        var detectedDate: Date?
        var hasTime = false
        var dateRanges: [Range<String.Index>] = []
        
        // Use NSDataDetector to find dates
        let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.date.rawValue
        )
        
        let nsRange = NSRange(text.startIndex..., in: text)
        
        detector?.enumerateMatches(
            in: text,
            options: [],
            range: nsRange
        ) { result, _, _ in
            guard let result = result,
                  let date = result.date else { return }
            
            // Only take the first date found
            if detectedDate == nil {
                detectedDate = date
                hasTime = result.timeZone != nil
                
                if let range = Range(result.range, in: text) {
                    dateRanges.append(range)
                }
            }
        }
        
        // Also handle relative keywords NSDataDetector might miss
        let relativeParsed = parseRelativeKeywords(from: text)
        if detectedDate == nil && relativeParsed.date != nil {
            detectedDate = relativeParsed.date
            hasTime = relativeParsed.hasTime
            if let range = relativeParsed.range {
                dateRanges.append(range)
            }
        }
        
        // Clean the title by removing date text
        var cleanedTitle = text
        for range in dateRanges.reversed() {
            cleanedTitle.removeSubrange(range)
        }
        
        // Clean up extra whitespace and prepositions
        cleanedTitle = cleanPrepositions(from: cleanedTitle)
        
        return ExtractionResult(
            cleanedTitle: cleanedTitle,
            date: detectedDate,
            hasTime: hasTime
        )
    }
    
    // MARK: - Relative Keyword Parsing
    
    private struct RelativeResult {
        var date: Date?
        var hasTime: Bool
        var range: Range<String.Index>?
    }
    
    private func parseRelativeKeywords(from text: String) -> RelativeResult {
        let lowercased = text.lowercased()
        let calendar = Calendar.current
        let now = Date()
        
        // Today
        if let range = lowercased.range(of: "today") {
            return RelativeResult(
                date: calendar.startOfDay(for: now).addingTimeInterval(9 * 3600),
                hasTime: false,
                range: range
            )
        }
        
        // Tomorrow
        if let range = lowercased.range(of: "tomorrow") {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
            return RelativeResult(
                date: calendar.startOfDay(for: tomorrow).addingTimeInterval(9 * 3600),
                hasTime: false,
                range: range
            )
        }
        
        // Next week
        if let range = lowercased.range(of: "next week") {
            let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: now)!
            return RelativeResult(
                date: calendar.startOfDay(for: nextWeek).addingTimeInterval(9 * 3600),
                hasTime: false,
                range: range
            )
        }
        
        // Tonight
        if let range = lowercased.range(of: "tonight") {
            return RelativeResult(
                date: calendar.startOfDay(for: now).addingTimeInterval(20 * 3600),
                hasTime: true,
                range: range
            )
        }
        
        // This evening
        if let range = lowercased.range(of: "this evening") {
            return RelativeResult(
                date: calendar.startOfDay(for: now).addingTimeInterval(18 * 3600),
                hasTime: true,
                range: range
            )
        }
        
        // This afternoon
        if let range = lowercased.range(of: "this afternoon") {
            return RelativeResult(
                date: calendar.startOfDay(for: now).addingTimeInterval(14 * 3600),
                hasTime: true,
                range: range
            )
        }
        
        // Day names (next Monday, Tuesday, etc.)
        let dayNames = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
        for (index, dayName) in dayNames.enumerated() {
            if let range = lowercased.range(of: dayName) {
                let targetWeekday = index + 2 // Calendar weekday: Sunday=1, Monday=2...
                let currentWeekday = calendar.component(.weekday, from: now)
                var daysAhead = targetWeekday - currentWeekday
                if daysAhead <= 0 { daysAhead += 7 }
                
                let targetDate = calendar.date(byAdding: .day, value: daysAhead, to: now)!
                return RelativeResult(
                    date: calendar.startOfDay(for: targetDate).addingTimeInterval(9 * 3600),
                    hasTime: false,
                    range: range
                )
            }
        }
        
        return RelativeResult(date: nil, hasTime: false, range: nil)
    }
    
    // MARK: - Clean Prepositions
    
    private func cleanPrepositions(from text: String) -> String {
        var cleaned = text
        
        // Remove trailing prepositions
        let trailingWords = [" on", " at", " by", " for", " in", " next", " this"]
        for word in trailingWords {
            if cleaned.lowercased().hasSuffix(word) {
                cleaned = String(cleaned.dropLast(word.count))
            }
        }
        
        // Remove leading prepositions
        let leadingWords = ["on ", "at ", "by ", "for ", "in "]
        for word in leadingWords {
            if cleaned.lowercased().hasPrefix(word) {
                cleaned = String(cleaned.dropFirst(word.count))
            }
        }
        
        // Clean up whitespace
        cleaned = cleaned
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
    }
}
