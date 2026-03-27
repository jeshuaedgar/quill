import SwiftUI

struct DailyBriefingView: View {
    let reminders: [Reminder]
    
    @State private var briefingText = ""
    @State private var isLoading = true
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.purple)
                    
                    Text("Daily Briefing")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Generating briefing...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } else {
                    Text(briefingText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)
                        .transition(.opacity)
                }
                
                // Quick Stats
                HStack(spacing: 16) {
                    StatBadge(
                        icon: "checklist",
                        value: "\(reminders.count)",
                        label: "Total"
                    )
                    
                    StatBadge(
                        icon: "exclamationmark.triangle.fill",
                        value: "\(overdueCount)",
                        label: "Overdue",
                        color: overdueCount > 0 ? .red : .secondary
                    )
                    
                    StatBadge(
                        icon: "arrow.up.circle.fill",
                        value: "\(highPriorityCount)",
                        label: "Urgent",
                        color: highPriorityCount > 0 ? .orange : .secondary
                    )
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .task {
            await generateBriefing()
        }
    }
    
    // MARK: - Stats
    
    private var overdueCount: Int {
        reminders.filter { reminder in
            guard let dueDate = reminder.dueDate else { return false }
            return dueDate < Date()
        }.count
    }
    
    private var highPriorityCount: Int {
        reminders.filter {
            $0.priority == .high || $0.priority == .urgent
        }.count
    }
    
    // MARK: - Generate
    
    private func generateBriefing() async {
        let briefingReminders = reminders.map { BriefingReminder(from: $0) }
        let text = await LLMService.shared.generateDailyBriefing(reminders: briefingReminders)
        
        withAnimation {
            briefingText = text
            isLoading = false
        }
    }
}

// MARK: - Stat Badge Component

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = .secondary
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            .foregroundStyle(color)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
