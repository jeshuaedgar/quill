import SwiftUI

struct ReminderCardView: View {
    let reminder: Reminder
    let onToggle: () -> Void
    
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 12) {
            // Animated Checkbox
            AnimatedCheckbox(
                isChecked: reminder.isCompleted,
                priority: reminder.priority,
                onToggle: onToggle
            )

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
                        Label(
                            dueDate.relativeDescription,
                            systemImage: "calendar"
                        )
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
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.quaternary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private var isOverdue: Bool {
        guard let dueDate = reminder.dueDate else { return false }
        return dueDate < Date() && !reminder.isCompleted
    }
}
