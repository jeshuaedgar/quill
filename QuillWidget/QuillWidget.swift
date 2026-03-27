import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Provider

struct QuillTimelineProvider: TimelineProvider {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(for: Reminder.self, Category.self, Tag.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    func placeholder(in context: Context) -> QuillEntry {
        QuillEntry(
            date: Date(),
            reminders: [
                WidgetReminder(title: "Sample Reminder", dueDate: Date(), priority: .medium, isOverdue: false)
            ],
            totalCount: 3
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuillEntry) -> Void) {
        Task { @MainActor in
            let entry = fetchEntry()
            completion(entry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuillEntry>) -> Void) {
        Task { @MainActor in
            let entry = fetchEntry()
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    @MainActor
    private func fetchEntry() -> QuillEntry {
        let context = modelContainer.mainContext
        
        let descriptor = FetchDescriptor<Reminder>(
            predicate: #Predicate { !$0.isCompleted },
            sortBy: [SortDescriptor(\.dueDate)]
        )
        
        do {
            let reminders = try context.fetch(descriptor)
            let widgetReminders = reminders.prefix(5).map { reminder in
                WidgetReminder(
                    title: reminder.title,
                    dueDate: reminder.dueDate,
                    priority: reminder.priority,
                    isOverdue: reminder.dueDate.map { $0 < Date() } ?? false
                )
            }
            
            return QuillEntry(
                date: Date(),
                reminders: Array(widgetReminders),
                totalCount: reminders.count
            )
        } catch {
            return QuillEntry(date: Date(), reminders: [], totalCount: 0)
        }
    }
}

// MARK: - Widget Entry

struct QuillEntry: TimelineEntry {
    let date: Date
    let reminders: [WidgetReminder]
    let totalCount: Int
}

struct WidgetReminder: Identifiable {
    let id = UUID()
    let title: String
    let dueDate: Date?
    let priority: Priority
    let isOverdue: Bool
}

// MARK: - Small Widget View

struct QuillWidgetSmallView: View {
    let entry: QuillEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "pencil.and.outline")
                    .foregroundStyle(.purple)
                Text("Quill")
                    .font(.caption)
                    .fontWeight(.bold)
                Spacer()
                Text("\(entry.totalCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if let first = entry.reminders.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text(first.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    if let due = first.dueDate {
                        Text(formatDate(due))
                            .font(.caption2)
                            .foregroundStyle(first.isOverdue ? .red : .secondary)
                    }
                }
                
                Spacer()
                
                if entry.reminders.count > 1 {
                    Text("+\(entry.totalCount - 1) more")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Spacer()
                Text("All clear! 🎉")
                    .font(.subheadline)
                Spacer()
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget View

struct QuillWidgetMediumView: View {
    let entry: QuillEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "pencil.and.outline")
                    .foregroundStyle(.purple)
                Text("Quill")
                    .font(.caption)
                    .fontWeight(.bold)
                Spacer()
                Text("\(entry.totalCount) active")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if entry.reminders.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("No reminders — enjoy your day! 🎉")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(entry.reminders.prefix(3)) { reminder in
                    HStack(spacing: 8) {
                        Circle()
                            .stroke(priorityColor(for: reminder.priority), lineWidth: 2)
                            .frame(width: 16, height: 16)
                        
                        Text(reminder.title)
                            .font(.caption)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if let due = reminder.dueDate {
                            Text(formatDate(due))
                                .font(.caption2)
                                .foregroundStyle(reminder.isOverdue ? .red : .secondary)
                        }
                    }
                }
                
                if entry.totalCount > 3 {
                    Text("+\(entry.totalCount - 3) more")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private func priorityColor(for priority: Priority) -> Color {
        switch priority {
        case .none: return Color(.systemGray3)
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

// MARK: - Date Formatting Helper

private func formatDate(_ date: Date) -> String {
    if Calendar.current.isDateInToday(date) { return "Today" }
    if Calendar.current.isDateInTomorrow(date) { return "Tomorrow" }
    
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    return formatter.localizedString(for: date, relativeTo: Date())
}

// MARK: - Widget Definition

struct QuillWidget: Widget {
    let kind: String = "QuillWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuillTimelineProvider()) { entry in
            QuillWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Quill Reminders")
        .description("See your upcoming reminders at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct QuillWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: QuillEntry
    
    var body: some View {
        switch family {
        case .systemSmall:
            QuillWidgetSmallView(entry: entry)
        case .systemMedium:
            QuillWidgetMediumView(entry: entry)
        default:
            QuillWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    QuillWidget()
} timeline: {
    QuillEntry(
        date: Date(),
        reminders: [
            WidgetReminder(title: "Call dentist", dueDate: Date(), priority: .high, isOverdue: false)
        ],
        totalCount: 5
    )
}

#Preview(as: .systemMedium) {
    QuillWidget()
} timeline: {
    QuillEntry(
        date: Date(),
        reminders: [
            WidgetReminder(title: "Call dentist", dueDate: Date(), priority: .high, isOverdue: false),
            WidgetReminder(title: "Buy groceries", dueDate: Date().addingTimeInterval(3600), priority: .medium, isOverdue: false),
            WidgetReminder(title: "Submit report", dueDate: nil, priority: .urgent, isOverdue: true)
        ],
        totalCount: 7
    )
}
