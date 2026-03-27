import SwiftUI
import SwiftData
import MapKit

struct ReminderDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var reminder: Reminder

    @State private var isEditing = false
    @State private var showLocationPicker = false
    @State private var isFocused = false

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

                if let dueDate = reminder.dueDate {
                    LabeledContent("Due") {
                        Text(dueDate.formatted(date: .long, time: .shortened))
                            .foregroundStyle(
                                dueDate < Date() && !reminder.isCompleted
                                ? .red : .secondary
                            )
                    }
                }

                if let category = reminder.category {
                    LabeledContent("Category") {
                        Label(category.name, systemImage: category.icon)
                    }
                }

                LabeledContent("Status") {
                    Text(reminder.isCompleted ? "Completed" : "Active")
                        .foregroundStyle(reminder.isCompleted ? .green : .blue)
                }
                
                if let focus = reminder.focusFilter {
                    LabeledContent("Focus Mode") {
                        Text(focus)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // MARK: - Location
            if reminder.hasLocation {
                Section("Location") {
                    if let name = reminder.locationName {
                        Label(name, systemImage: "mappin.circle.fill")
                    }
                    
                    Text(reminder.triggerOnArrival ? "Triggers on arrival" : "Triggers on departure")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let coordinate = reminder.coordinate {
                        Map {
                            Marker(
                                reminder.locationName ?? "Location",
                                coordinate: coordinate
                            )
                            .tint(.red)
                            
                            MapCircle(
                                center: coordinate,
                                radius: reminder.locationRadius ?? 100
                            )
                            .foregroundStyle(.blue.opacity(0.15))
                            .stroke(.blue, lineWidth: 1)
                        }
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    }
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
                if !reminder.isCompleted {
                    Button {
                        if isFocused {
                            LiveActivityManager.shared.endActivity(for: reminder)
                            isFocused = false
                        } else {
                            LiveActivityManager.shared.startActivity(for: reminder)
                            isFocused = true
                        }
                        HapticManager.shared.selection()
                    } label: {
                        Label(
                            isFocused ? "Stop Focus" : "Start Focus",
                            systemImage: isFocused ? "target" : "target"
                        )
                        .foregroundStyle(isFocused ? .orange : .blue)
                    }
                }

                Button {
                    withAnimation {
                        viewModel.toggleComplete(reminder)
                        if reminder.isCompleted {
                            LiveActivityManager.shared.endActivity(for: reminder)
                            isFocused = false
                        }
                    }
                    HapticManager.shared.success()
                } label: {
                    Label(
                        reminder.isCompleted ? "Mark as Active" : "Mark as Complete",
                        systemImage: reminder.isCompleted ? "arrow.uturn.backward" : "checkmark.circle"
                    )
                }

                Button(role: .destructive) {
                    LiveActivityManager.shared.endActivity(for: reminder)
                    viewModel.deleteReminder(reminder)
                    HapticManager.shared.warning()
                    dismiss()
                } label: {
                    Label("Delete Reminder", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isFocused = reminder.activityID != nil
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(isEditing ? "Done" : "Edit") {
                    withAnimation {
                        if isEditing {
                            viewModel.updateReminder(reminder)
                            HapticManager.shared.success()
                        }
                        isEditing.toggle()
                    }
                }
            }
        }
    }
}
