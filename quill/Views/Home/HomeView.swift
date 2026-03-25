import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Reminder> { !$0.isCompleted },
        sort: \Reminder.dueDate,
        order: .forward
    ) private var activeReminders: [Reminder]

    @Query(
        filter: #Predicate<Reminder> { $0.isCompleted },
        sort: \Reminder.completedAt,
        order: .reverse
    ) private var completedReminders: [Reminder]

    @State private var showAddReminder = false
    @State private var searchText = ""

    private var viewModel: RemindersViewModel {
        RemindersViewModel(modelContext: modelContext)
    }

    private var filteredReminders: [Reminder] {
        if searchText.isEmpty {
            return activeReminders
        }
        return activeReminders.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.notes.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Active Reminders
                if filteredReminders.isEmpty && searchText.isEmpty {
                    EmptyStateView()
                } else {
                    Section {
                        ForEach(filteredReminders) { reminder in
                            ReminderCardView(
                                reminder: reminder,
                                onToggle: { viewModel.toggleComplete(reminder) }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        viewModel.deleteReminder(reminder)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        Text("Active (\(filteredReminders.count))")
                    }
                }

                // MARK: - Completed Reminders
                if !completedReminders.isEmpty {
                    Section {
                        ForEach(completedReminders.prefix(5)) { reminder in
                            ReminderCardView(
                                reminder: reminder,
                                onToggle: { viewModel.toggleComplete(reminder) }
                            )
                            .opacity(0.6)
                        }
                    } header: {
                        Text("Completed")
                    }
                }
            }
            .navigationTitle("Quill")
            .searchable(text: $searchText, prompt: "Search reminders")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddReminder = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showAddReminder) {
                AddReminderView()
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Reminder.self, Category.self, Tag.self], inMemory: true)
}
