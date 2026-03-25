import SwiftUI

struct PriorityBadge: View {
    let priority: Priority

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: priority.icon)
            Text(priority.label)
        }
        .font(.caption2)
        .fontWeight(.semibold)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color(priority.color).opacity(0.15))
        .foregroundStyle(Color(priority.color))
        .clipShape(Capsule())
    }
}
