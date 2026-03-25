import SwiftUI

struct ReminderCardView: View {
    let reminder: Reminder
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                withAnimation(.snappy) {
                    onToggle()
                }
            } label: {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(
                        reminder.isCompleted
                        ? .green
                        : priorityColor
                    )
            }
            .buttonStyle(.plain)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(reminder.isCompleted)
                    .foregroundStyle(reminder.isCompleted ? .secondary : .primary)

                HStack(spacing: 8) {
                    // Due date
                    if let dueDate = reminder.dueDate {
                        Label(dueDate.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(isOverdue ? .red : .secondary)
                    }

                    // Category
                    if let category = reminder.category {
                        Label(category.name, systemImage: category.icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Priority badge
                    if reminder.priority != .none {
                        PriorityBadge(priority: reminder.priority)
                    }
                }

                // Tags
                if !reminder.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(reminder.tags) { tag in
                            TagChip(tag: tag)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var priorityColor: Color {
        Color(reminder.priority.color)
    }

    private var isOverdue: Bool {
        guard let dueDate = reminder.dueDate else { return false }
        return dueDate < Date() && !reminder.isCompleted
    }
}
