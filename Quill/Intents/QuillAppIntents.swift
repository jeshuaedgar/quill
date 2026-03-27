import AppIntents
import SwiftData

// MARK: - Add Reminder Intent

struct AddReminderIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Quill Reminder"
    static var description: IntentDescription = "Create a new reminder in Quill"
    
    @Parameter(title: "Title")
    var title: String
    
    @Parameter(title: "Notes", default: "")
    var notes: String
    
    @Parameter(title: "Due Date", default: nil)
    var dueDate: Date?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Add reminder \(\.$title)") {
            \.$notes
            \.$dueDate
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let parseResult = NLParser.shared.parse(title)
        
        let finalTitle = dueDate == nil ? parseResult.title : title
        let finalDate = dueDate ?? parseResult.date
        
        let container = try ModelContainer(for: Reminder.self, Category.self, Tag.self)
        let context = container.mainContext
        
        let reminder = Reminder(
            title: finalTitle,
            notes: notes,
            dueDate: finalDate,
            priority: parseResult.suggestedPriority
        )
        
        context.insert(reminder)
        try context.save()
        
        if finalDate != nil {
            NotificationManager.shared.scheduleNotification(for: reminder)
        }
        
        var response = "Added \"\(finalTitle)\" to Quill."
        if let date = finalDate {
            response += " Due \(date.formatted(date: .abbreviated, time: .shortened))."
        }
        
        return .result(dialog: IntentDialog(stringLiteral: response))
    }
}

// MARK: - Show Reminders Intent

struct ShowRemindersIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Quill Reminders"
    static var description: IntentDescription = "See your upcoming reminders"
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: Reminder.self, Category.self, Tag.self)
        let context = container.mainContext
        
        let descriptor = FetchDescriptor<Reminder>(
            predicate: #Predicate { !$0.isCompleted },
            sortBy: [SortDescriptor(\.dueDate)]
        )
        
        let reminders = try context.fetch(descriptor)
        
        if reminders.isEmpty {
            return .result(dialog: "You're all clear! No active reminders in Quill.")
        }
        
        let count = reminders.count
        let topReminders = reminders.prefix(3).map { reminder -> String in
            var line = "• \(reminder.title)"
            if let due = reminder.dueDate {
                line += " (\(due.relativeDescription))"
            }
            return line
        }.joined(separator: "\n")
        
        let response = "You have \(count) active reminder\(count == 1 ? "" : "s").\n\n\(topReminders)"
        
        return .result(dialog: IntentDialog(stringLiteral: response))
    }
}

// MARK: - App Shortcuts Provider

struct QuillShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddReminderIntent(),
            phrases: [
                "Add a reminder in \(.applicationName)",
                "Create a \(.applicationName) reminder",
                "Remind me in \(.applicationName)",
                "New \(.applicationName) reminder"
            ],
            shortTitle: "Add Reminder",
            systemImageName: "plus.circle.fill"
        )
        
        AppShortcut(
            intent: ShowRemindersIntent(),
            phrases: [
                "Show my \(.applicationName) reminders",
                "What's on \(.applicationName)",
                "Check \(.applicationName)",
                "Open \(.applicationName) reminders"
            ],
            shortTitle: "Show Reminders",
            systemImageName: "list.bullet"
        )
    }
}
