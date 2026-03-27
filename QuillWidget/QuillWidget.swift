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
            totalCount: 3,
            overdueCount: 0,
            urgentCount: 1
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
                totalCount: reminders.count,
                overdueCount: reminders.filter { r in
                    guard let due = r.dueDate else { return false }
                    return due < Date()
                }.count,
                urgentCount: reminders.filter { $0.priority == .urgent }.count
            )
        } catch {
            return QuillEntry(date: Date(), reminders: [], totalCount: 0, overdueCount: 0, urgentCount: 0)
        }
    }
}

// MARK: - Widget Entry

struct QuillEntry: TimelineEntry {
    let date: Date
    let reminders: [WidgetReminder]
    let totalCount: Int
    let overdueCount: Int
    let urgentCount: Int
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
                Text("🪶")
                Text("Quill")
                    .font(.caption)
                    .fontWeight(.bold)
                Spacer()
                if entry.totalCount > 0 {
                    Text("\(entry.totalCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
                Text("🪶")
                Text("Quill")
                    .font(.caption)
                    .fontWeight(.bold)
                Spacer()
                if entry.totalCount > 0 {
                    Text("\(entry.totalCount) active")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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

// MARK: - Large Widget View

struct QuillWidgetLargeView: View {
    let entry: QuillEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text("🪶")
                Text("Quill")
                    .font(.caption)
                    .fontWeight(.bold)
                Spacer()
                Text(entry.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            // Stats row
            HStack(spacing: 16) {
                StatMini(label: "Active", count: entry.totalCount, color: .blue)
                StatMini(label: "Overdue", count: entry.overdueCount, color: .red)
                StatMini(label: "Urgent", count: entry.urgentCount, color: .orange)
            }
            .font(.caption2)
            
            Divider()
            
            if entry.reminders.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                        Text("All clear!")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("No active reminders.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(entry.reminders.prefix(8)) { reminder in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(priorityColor(for: reminder.priority))
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(reminder.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(2)
                            
                            if let due = reminder.dueDate {
                                Text(formatDate(due))
                                    .font(.caption2)
                                    .foregroundStyle(reminder.isOverdue ? .red : .secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if reminder.isOverdue {
                            Text("OVERDUE")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(.red, in: Capsule())
                        }
                    }
                    
                    if reminder.id != entry.reminders.prefix(8).last?.id {
                        Divider()
                    }
                }
                
                if entry.totalCount > 8 {
                    Text("+\(entry.totalCount - 8) more")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
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

private struct StatMini: View {
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 3) {
            Text("\(count)")
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Lock Screen: Rectangular Widget

struct QuillWidgetRectangularView: View {
    let entry: QuillEntry
    
    var body: some View {
        if let next = entry.reminders.first {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("🪶")
                        .font(.caption2)
                    Text("Quill")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                
                Text(next.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                if let due = next.dueDate {
                    Label(formatDate(due), systemImage: "clock")
                        .font(.caption2)
                        .foregroundStyle(next.isOverdue ? .red : .secondary)
                }
            }
            .widgetURL(URL(string: "quill://reminder/next"))
        } else {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("🪶")
                        .font(.caption2)
                    Text("Quill")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                Text("No upcoming reminders")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Lock Screen: Circular Widget

struct QuillWidgetCircularView: View {
    let entry: QuillEntry
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            if entry.totalCount == 0 {
                Image(systemName: "checkmark")
                    .font(.title3)
                    .fontWeight(.bold)
            } else {
                VStack(spacing: 2) {
                    Text("\(entry.totalCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .contentTransition(.numericText())

                    Text("tasks")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .widgetURL(URL(string: "quill://reminders"))
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
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryCircular])
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
        case .systemLarge:
            QuillWidgetLargeView(entry: entry)
        case .accessoryRectangular:
            QuillWidgetRectangularView(entry: entry)
        case .accessoryCircular:
            QuillWidgetCircularView(entry: entry)
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
        totalCount: 5,
        overdueCount: 1,
        urgentCount: 0
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
        totalCount: 7,
        overdueCount: 2,
        urgentCount: 1
    )
}

#Preview(as: .systemLarge) {
    QuillWidget()
} timeline: {
    QuillEntry(
        date: Date(),
        reminders: [
            WidgetReminder(title: "Call dentist", dueDate: Date(), priority: .high, isOverdue: false),
            WidgetReminder(title: "Buy groceries", dueDate: Date().addingTimeInterval(3600), priority: .medium, isOverdue: false),
            WidgetReminder(title: "Submit report", dueDate: Date().addingTimeInterval(-3600), priority: .urgent, isOverdue: true),
            WidgetReminder(title: "Review PR", dueDate: Date().addingTimeInterval(7200), priority: .low, isOverdue: false),
            WidgetReminder(title: "Gym session", dueDate: Date().addingTimeInterval(18000), priority: .none, isOverdue: false)
        ],
        totalCount: 12,
        overdueCount: 3,
        urgentCount: 2
    )
}

#Preview(as: .accessoryRectangular) {
    QuillWidget()
} timeline: {
    QuillEntry(
        date: Date(),
        reminders: [
            WidgetReminder(title: "Call dentist tomorrow at 3pm", dueDate: Date().addingTimeInterval(86400), priority: .high, isOverdue: false)
        ],
        totalCount: 5,
        overdueCount: 0,
        urgentCount: 1
    )
}

#Preview(as: .accessoryCircular) {
    QuillWidget()
} timeline: {
    QuillEntry(
        date: Date(),
        reminders: [],
        totalCount: 7,
        overdueCount: 2,
        urgentCount: 1
    )
}
