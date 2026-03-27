import SwiftUI
import SwiftData

struct SmartListView: View {
    let title: String
    let reminders: [Reminder]

    @Environment(\.modelContext) private var modelContext

    private var viewModel: RemindersViewModel {
        RemindersViewModel(modelContext: modelContext)
    }

    var body: some View {
        List {
            if reminders.isEmpty {
                ContentUnavailableView {
                    Label("No Reminders", systemImage: "tray")
                } description: {
                    Text("Nothing here yet.")
                }
            } else {
                ForEach(reminders) { reminder in
                    NavigationLink {
                        ReminderDetailView(reminder: reminder)
                    } label: {
                        ReminderCardView(
                            reminder: reminder,
                            onToggle: { viewModel.toggleComplete(reminder) }
                        )
                    }
                }
            }
        }
        .navigationTitle(title)
    }
}
