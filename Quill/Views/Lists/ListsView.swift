import SwiftUI
import SwiftData

struct ListsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]

    @State private var showAddCategory = false
    @State private var newCategoryName = ""
    @State private var newCategoryIcon = "folder"

    private var viewModel: RemindersViewModel {
        RemindersViewModel(modelContext: modelContext)
    }

    // Smart lists data
    @Query(filter: #Predicate<Reminder> { !$0.isCompleted }) private var activeReminders: [Reminder]
    @Query(filter: #Predicate<Reminder> { $0.isCompleted }) private var completedReminders: [Reminder]

    private var todayReminders: [Reminder] {
        activeReminders.filter { reminder in
            guard let dueDate = reminder.dueDate else { return false }
            return Calendar.current.isDateInToday(dueDate)
        }
    }

    private var overdueReminders: [Reminder] {
        activeReminders.filter { reminder in
            guard let dueDate = reminder.dueDate else { return false }
            return dueDate < Date()
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Smart Lists
                Section("Smart Lists") {
                    NavigationLink {
                        SmartListView(
                            title: "Today",
                            reminders: todayReminders
                        )
                    } label: {
                        Label("Today", systemImage: "sun.max.fill")
                            .badge(todayReminders.count)
                    }

                    NavigationLink {
                        SmartListView(
                            title: "Overdue",
                            reminders: overdueReminders
                        )
                    } label: {
                        Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                            .badge(overdueReminders.count)
                            .foregroundStyle(overdueReminders.isEmpty ? Color.primary : Color.red)
                    }

                    NavigationLink {
                        SmartListView(
                            title: "All Active",
                            reminders: activeReminders
                        )
                    } label: {
                        Label("All Active", systemImage: "tray.full.fill")
                            .badge(activeReminders.count)
                    }

                    NavigationLink {
                        SmartListView(
                            title: "Completed",
                            reminders: completedReminders
                        )
                    } label: {
                        Label("Completed", systemImage: "checkmark.circle.fill")
                            .badge(completedReminders.count)
                    }
                }

                // MARK: - Custom Categories
                Section("Categories") {
                    ForEach(categories) { category in
                        NavigationLink {
                            SmartListView(
                                title: category.name,
                                reminders: category.reminders.filter { !$0.isCompleted }
                            )
                        } label: {
                            Label(category.name, systemImage: category.icon)
                                .badge(category.reminders.filter { !$0.isCompleted }.count)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.deleteCategory(categories[index])
                        }
                    }

                    Button {
                        showAddCategory = true
                    } label: {
                        Label("Add Category", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Lists")
            .alert("New Category", isPresented: $showAddCategory) {
                TextField("Category name", text: $newCategoryName)
                Button("Cancel", role: .cancel) {
                    newCategoryName = ""
                }
                Button("Add") {
                    if !newCategoryName.isEmpty {
                        viewModel.addCategory(
                            name: newCategoryName,
                            icon: newCategoryIcon,
                            colorHex: "#007AFF"
                        )
                        newCategoryName = ""
                    }
                }
            }
        }
    }
}
