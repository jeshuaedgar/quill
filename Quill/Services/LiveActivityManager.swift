import ActivityKit
import Foundation
import SwiftData
import SwiftUI

struct QuillActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let reminderTitle: String
        let dueDate: Date?
        let priorityRaw: Int
        let isCompleted: Bool
    }

    let reminderID: String
}

@Observable
class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var activeActivities: [String: Activity<QuillActivityAttributes>] = [:]

    private init() {
        rehydrateActivities()
    }

    // MARK: - Start

    func startActivity(for reminder: Reminder) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard reminder.activityID == nil else { return }

        let attributes = QuillActivityAttributes(reminderID: reminder.id.uuidString)
        let state = QuillActivityAttributes.ContentState(
            reminderTitle: reminder.title,
            dueDate: reminder.dueDate,
            priorityRaw: reminder.priority.rawValue,
            isCompleted: reminder.isCompleted
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            activeActivities[reminder.id.uuidString] = activity
            reminder.activityID = activity.id
        } catch {
            print("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    // MARK: - Update

    func updateActivity(for reminder: Reminder) {
        guard let activityID = reminder.activityID,
              let activity = activeActivities[activityID] else { return }

        let state = QuillActivityAttributes.ContentState(
            reminderTitle: reminder.title,
            dueDate: reminder.dueDate,
            priorityRaw: reminder.priority.rawValue,
            isCompleted: reminder.isCompleted
        )

        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    // MARK: - End

    func endActivity(for reminder: Reminder) {
        guard let activityID = reminder.activityID,
              let activity = activeActivities[activityID] else { return }

        let state = QuillActivityAttributes.ContentState(
            reminderTitle: reminder.title,
            dueDate: reminder.dueDate,
            priorityRaw: reminder.priority.rawValue,
            isCompleted: reminder.isCompleted
        )

        Task {
            await activity.end(.init(state: state, staleDate: nil), dismissalPolicy: .immediate)
        }

        activeActivities.removeValue(forKey: activityID)
        reminder.activityID = nil
    }

    // MARK: - Auto-Start

    @MainActor
    func checkAutoStart(modelContext: ModelContext) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let thirtyMinutesFromNow = Date().addingTimeInterval(30 * 60)

        let descriptor = FetchDescriptor<Reminder>(
            predicate: #Predicate { reminder in
                !reminder.isCompleted && reminder.activityID == nil
            }
        )

        do {
            let reminders = try modelContext.fetch(descriptor)
            for reminder in reminders {
                guard let dueDate = reminder.dueDate else { continue }
                if dueDate <= thirtyMinutesFromNow && dueDate >= Date() {
                    startActivity(for: reminder)
                }
            }
        } catch {
            print("Failed to fetch reminders for auto-start: \(error.localizedDescription)")
        }
    }

    // MARK: - Rehydrate

    private func rehydrateActivities() {
        for activity in Activity<QuillActivityAttributes>.activities {
            activeActivities[activity.attributes.reminderID] = activity
        }
    }

    // MARK: - Has Active

    func hasActiveActivity(for reminder: Reminder) -> Bool {
        guard let activityID = reminder.activityID else { return false }
        return activeActivities[activityID] != nil
    }
}
