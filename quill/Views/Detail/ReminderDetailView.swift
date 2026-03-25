import SwiftUI
import SwiftData

struct ReminderDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var reminder: Reminder

    @State private var isEditing = false

    private var viewModel: RemindersViewModel {
        RemindersViewModel(modelContext: modelContext)
    }

    var body: some View {
        List {
            // MARK: - Title & Notes
            Section {
                if isEditing {
                    TextField("Title", text: $reminder.title)
                        .font(.headline)
                    TextField("Notes", text: $reminder.notes, axis: .vertical)
                        .lineLimit(3...6)
                } else {
                    Text(reminder.title)
                        .font(.headline)
                    if !reminder.notes.isEmpty {
                        Text(reminder.notes)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // MARK: - Details
            Section("Details") {
                // Priority
                if isEditing {
                    Picker("Priority", selection: $reminder.priority) {
                        ForEach(Priority.allCases) { level in
                            Label(level.label, systemImage: level.icon)
                                .tag(level)
                        }
                    }
                } else {
                    LabeledContent("Priority") {
                        PriorityBadge(priority: reminder.priority)
                    }
                }

                // Due Date
                if let dueDate = reminder.dueDate {
                    LabeledContent("Due") {
                        Text(dueDate.formatted(date: .long, time: .shortened))
                            .foregroundStyle(
                                dueDate < Date() && !reminder.isCompleted
                                ? .red : .secondary
                            )
                    }
                }

                // Category
                if let category = reminder.category {
                    LabeledContent("Category") {
                        Label(category.name, systemImage: category.icon)
                    }
                }

                // Status
                LabeledContent("Status") {
                    Text(reminder.isCompleted ? "Completed" : "Active")
                        .foregroundStyle(reminder.isCompleted ? .green : .blue)
                }
            }

            // MARK: - Tags
            if !reminder.tags.isEmpty {
                Section("Tags") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(reminder.tags) { tag in
                                TagChip(tag: tag)
                            }
                        }
                    }
                }
            }

            // MARK: - Dates
            Section("Info") {
                LabeledContent("Created") {
                    Text(reminder.createdAt.formatted(date: .abbreviated, time: .shortened))
                }
                if let completedAt = reminder.completedAt {
                    LabeledContent("Completed") {
                        Text(completedAt.formatted(date: .abbreviated, time: .shortened))
                    }
                }
            }

            // MARK: - Actions
            Section {
                Button {
                    withAnimation {
                        viewModel.toggleComplete(reminder)
                    }
                } label: {
                    Label(
                        reminder.isCompleted ? "Mark as Active" : "Mark as Complete",
                        systemImage: reminder.isCompleted ? "arrow.uturn.backward" : "checkmark.circle"
                    )
                }

                Button(role: .destructive) {
                    viewModel.deleteReminder(reminder)
                    dismiss()
                } label: {
                    Label("Delete Reminder", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(isEditing ? "Done" : "Edit") {
                    withAnimation {
                        if isEditing {
                            viewModel.updateReminder(reminder)
                        }
                        isEditing.toggle()
                    }
                }
            }
        }
    }
}
