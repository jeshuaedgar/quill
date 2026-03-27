import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No Reminders", systemImage: "tray")
        } description: {
            Text("Tap the + button to create your first reminder.")
        }
    }
}
