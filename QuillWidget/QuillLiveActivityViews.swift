import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Lock Screen / Notification Banner

struct QuillLiveActivityBannerView: View {
    let context: ActivityViewContext<QuillActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            priorityCircle
            
            VStack(alignment: .leading, spacing: 2) {
                Text(context.state.reminderTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                if let due = context.state.dueDate {
                    Label(dueLabel(for: due), systemImage: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if context.state.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var priorityCircle: some View {
        Circle()
            .fill(priorityColor)
            .frame(width: 36, height: 36)
            .overlay {
                Image(systemName: "pencil.and.outline")
                    .font(.caption2)
                    .foregroundStyle(.white)
            }
    }
    
    private var priorityColor: Color {
        switch context.state.priority {
        case .none: return .gray
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }
    
    private func dueLabel(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return formatter.localizedString(for: date, relativeTo: Date())
        }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}

// MARK: - Dynamic Island: Expanded

struct QuillLiveActivityExpandedView: View {
    let context: ActivityViewContext<QuillActivityAttributes>

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                priorityCircle
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.reminderTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    if let due = context.state.dueDate {
                        Text(due.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if context.state.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            
            Link(destination: URL(string: "quill://reminder/\(context.attributes.reminderID)")!) {
                Text("Open in Quill")
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
    }
    
    private var priorityCircle: some View {
        Circle()
            .fill(priorityColor)
            .frame(width: 32, height: 32)
            .overlay {
                Image(systemName: "pencil.and.outline")
                    .font(.caption2)
                    .foregroundStyle(.white)
            }
    }
    
    private var priorityColor: Color {
        switch context.state.priority {
        case .none: return .gray
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

// MARK: - Dynamic Island: Compact

struct QuillLiveActivityCompactView: View {
    let context: ActivityViewContext<QuillActivityAttributes>

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(priorityColor)
                .frame(width: 20, height: 20)
                .overlay {
                    Image(systemName: "pencil.and.outline")
                        .font(.system(size: 8))
                        .foregroundStyle(.white)
                }
            
            Text(context.state.reminderTitle)
                .font(.caption2)
                .fontWeight(.medium)
                .lineLimit(1)
        }
    }
    
    private var priorityColor: Color {
        switch context.state.priority {
        case .none: return .gray
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

// MARK: - Dynamic Island: Minimal

struct QuillLiveActivityMinimalView: View {
    let context: ActivityViewContext<QuillActivityAttributes>

    var body: some View {
        Circle()
            .fill(priorityColor)
            .frame(width: 20, height: 20)
            .overlay {
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: 8))
                    .foregroundStyle(.white)
            }
    }
    
    private var priorityColor: Color {
        switch context.state.priority {
        case .none: return .gray
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

// MARK: - Live Activity Widget

struct QuillLiveActivityWidget: Widget {
    let kind: String = "QuillLiveActivity"

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: QuillActivityAttributes.self) { context in
            QuillLiveActivityBannerView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    QuillLiveActivityExpandedView(context: context)
                        .padding(.leading, 8)
                }
            } compactLeading: {
                Circle()
                    .fill(priorityColor(for: context.state.priority))
                    .frame(width: 16, height: 16)
                    .overlay {
                        Image(systemName: "pencil.and.outline")
                            .font(.system(size: 7))
                            .foregroundStyle(.white)
                    }
            } compactTrailing: {
                Text(context.state.reminderTitle)
                    .font(.caption2)
                    .lineLimit(1)
            } minimal: {
                Circle()
                    .fill(priorityColor(for: context.state.priority))
                    .frame(width: 16, height: 16)
                    .overlay {
                        Image(systemName: "pencil.and.outline")
                            .font(.system(size: 7))
                            .foregroundStyle(.white)
                    }
            }
        }
    }
    
    private func priorityColor(for priority: Priority) -> Color {
        switch priority {
        case .none: return .gray
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }
}
