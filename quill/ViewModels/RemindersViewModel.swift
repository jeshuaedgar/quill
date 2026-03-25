import Foundation
import SwiftData
import SwiftUI

@Observable
class RemindersViewModel {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD Operations

    func addReminder(
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        priority: Priority = .none,
        category: Category? = nil,
        tags: [Tag] = []
    ) {
        let reminder = Reminder(
            title: title,
            notes: notes,
            dueDate: dueDate,
            priority: priority,
            category: category,
            tags: tags
        )
        modelContext.insert(reminder)
        save()

        // Schedule notification if due date exists
        if dueDate != nil {
            NotificationManager.shared.scheduleNotification(for: reminder)
        }
    }

    func updateReminder(_ reminder: Reminder) {
        save()

        // Reschedule notification
        if let notificationID = reminder.notificationID {
            NotificationManager.shared.cancelNotification(id: notificationID)
        }
        if reminder.dueDate != nil && !reminder.isCompleted {
            NotificationManager.shared.scheduleNotification(for: reminder)
        }
    }

    func deleteReminder(_ reminder: Reminder) {
        // Cancel notification
        if let notificationID = reminder.notificationID {
            NotificationManager.shared.cancelNotification(id: notificationID)
        }
        modelContext.delete(reminder)
        save()
    }

    func toggleComplete(_ reminder: Reminder) {
        reminder.isCompleted.toggle()
        reminder.completedAt = reminder.isCompleted ? Date() : nil

        if reminder.isCompleted {
            if let notificationID = reminder.notificationID {
                NotificationManager.shared.cancelNotification(id: notificationID)
            }
        }
        save()
    }

    // MARK: - Categories

    func addCategory(name: String, icon: String, colorHex: String) {
        let category = Category(name: name, icon: icon, colorHex: colorHex)
        modelContext.insert(category)
        save()
    }

    func deleteCategory(_ category: Category) {
        modelContext.delete(category)
        save()
    }

    // MARK: - Tags

    func addTag(name: String) -> Tag {
        let tag = Tag(name: name)
        modelContext.insert(tag)
        save()
        return tag
    }

    func deleteTag(_ tag: Tag) {
        modelContext.delete(tag)
        save()
    }

    // MARK: - Save

    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving: \(error.localizedDescription)")
        }
    }
}
