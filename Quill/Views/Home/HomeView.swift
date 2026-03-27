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
    @State private var showSmartAdd = false
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
    
    private var todayReminders: [Reminder] {
        activeReminders.filter { reminder in
            guard let dueDate = reminder.dueDate else { return false }
            return Calendar.current.isDateInToday(dueDate)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // MARK: - Daily Briefing
                    DailyBriefingView(reminders: todayReminders)
                        .padding(.top, 8)
                    
                    // MARK: - Smart Add Button
                    Button {
                        showSmartAdd = true
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Smart Add")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .foregroundStyle(.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Active Reminders
                    if filteredReminders.isEmpty && searchText.isEmpty {
                        EmptyStateView()
                            .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 8) {
                            Section {
                                ForEach(filteredReminders) { reminder in
                                    NavigationLink {
                                        ReminderDetailView(reminder: reminder)
                                    } label: {
                                        ReminderCardView(
                                            reminder: reminder,
                                            onToggle: {
                                                viewModel.toggleComplete(reminder)
                                            }
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal)
                                }
                            } header: {
                                HStack {
                                    Text("Active (\(filteredReminders.count))")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // MARK: - Completed
                    if !completedReminders.isEmpty {
                        LazyVStack(spacing: 8) {
                            Section {
                                ForEach(completedReminders.prefix(5)) { reminder in
                                    ReminderCardView(
                                        reminder: reminder,
                                        onToggle: {
                                            viewModel.toggleComplete(reminder)
                                        }
                                    )
                                    .opacity(0.6)
                                    .padding(.horizontal)
                                }
                            } header: {
                                HStack {
                                    Text("Completed")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.bottom, 80)
            }
            .navigationTitle("Quill")
            .searchable(text: $searchText, prompt: "Search reminders")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showSmartAdd = true
                        } label: {
                            Label("Smart Add", systemImage: "sparkles")
                        }
                        
                        Button {
                            showAddReminder = true
                        } label: {
                            Label("Manual Add", systemImage: "square.and.pencil")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showAddReminder) {
                AddReminderView()
            }
            .sheet(isPresented: $showSmartAdd) {
                SmartInputView()
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Reminder.self, Category.self, Tag.self], inMemory: true)
}
