import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

class LLMService {
    static let shared = LLMService()
    
    private init() {}
    
    // MARK: - Check Availability
    
    var isAvailable: Bool {
        if #available(iOS 26, *) {
            #if canImport(FoundationModels)
            return true
            #else
            return false
            #endif
        }
        return false
    }
    
    // MARK: - Generate Daily Briefing
    
    func generateDailyBriefing(reminders: [BriefingReminder]) async -> String {
        if #available(iOS 26, *) {
            #if canImport(FoundationModels)
            return await generateWithLLM(reminders: reminders)
            #else
            return generateFallbackBriefing(reminders: reminders)
            #endif
        }
        return generateFallbackBriefing(reminders: reminders)
    }
    
    // MARK: - Summarize Reminders
    
    func summarizeReminders(_ reminders: [BriefingReminder]) async -> String {
        if #available(iOS 26, *) {
            #if canImport(FoundationModels)
            return await summarizeWithLLM(reminders: reminders)
            #else
            return fallbackSummary(reminders: reminders)
            #endif
        }
        return fallbackSummary(reminders: reminders)
    }
    
    // MARK: - Foundation Models (iOS 26+)
    
    @available(iOS 26, *)
    private func generateWithLLM(reminders: [BriefingReminder]) async -> String {
        #if canImport(FoundationModels)
        do {
            let session = LanguageModelSession()
            
            let reminderList = reminders.map { reminder in
                var line = "- \(reminder.title)"
                if let due = reminder.dueDescription {
                    line += " (due: \(due))"
                }
                if let priority = reminder.priority {
                    line += " [priority: \(priority)]"
                }
                return line
            }.joined(separator: "\n")
            
            let prompt = """
            You are a helpful personal assistant inside a reminders app called Quill.
            Generate a brief, friendly daily briefing based on these reminders.
            Keep it concise — 2-3 sentences max. Be encouraging.
            
            Today's reminders:
            \(reminderList)
            
            If there are no reminders, say something encouraging about having a free day.
            """
            
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            return generateFallbackBriefing(reminders: reminders)
        }
        #else
        return generateFallbackBriefing(reminders: reminders)
        #endif
    }
    
    @available(iOS 26, *)
    private func summarizeWithLLM(reminders: [BriefingReminder]) async -> String {
        #if canImport(FoundationModels)
        do {
            let session = LanguageModelSession()
            
            let reminderList = reminders.map { "- \($0.title)" }.joined(separator: "\n")
            
            let prompt = """
            Summarize these reminders in one brief sentence. 
            Group them by theme if possible.
            
            Reminders:
            \(reminderList)
            """
            
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            return fallbackSummary(reminders: reminders)
        }
        #else
        return fallbackSummary(reminders: reminders)
        #endif
    }
    
    // MARK: - Fallback (iOS 18)
    
    private func generateFallbackBriefing(reminders: [BriefingReminder]) -> String {
        if reminders.isEmpty {
            return "You're all clear today! No reminders scheduled. Enjoy your free time. 🎉"
        }
        
        let count = reminders.count
        let urgentCount = reminders.filter { $0.priority == "urgent" || $0.priority == "high" }.count
        
        var briefing = "Good morning! You have \(count) reminder\(count == 1 ? "" : "s") today."
        
        if urgentCount > 0 {
            briefing += " \(urgentCount) \(urgentCount == 1 ? "is" : "are") high priority."
        }
        
        if let first = reminders.first {
            briefing += " First up: \(first.title)."
        }
        
        return briefing
    }
    
    private func fallbackSummary(reminders: [BriefingReminder]) -> String {
        if reminders.isEmpty {
            return "No reminders to summarize."
        }
        
        let count = reminders.count
        return "You have \(count) reminder\(count == 1 ? "" : "s") to review."
    }
}

// MARK: - Briefing Data Model

struct BriefingReminder {
    let title: String
    let dueDescription: String?
    let priority: String?
    
    init(from reminder: Reminder) {
        self.title = reminder.title
        self.dueDescription = reminder.dueDate?.formatted(date: .abbreviated, time: .shortened)
        self.priority = reminder.priority.label.lowercased()
    }
}
