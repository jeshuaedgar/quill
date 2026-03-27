import SwiftUI
import SwiftData

struct ExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allReminders: [Reminder]
    
    @State private var exportFormat: ExportFormat = .json
    @State private var includeCompleted = true
    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var exportURL: URL?
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Format
                Section("Format") {
                    Picker("Export Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Label(format.label, systemImage: format.icon)
                                .tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // MARK: - Options
                Section("Options") {
                    Toggle("Include completed reminders", isOn: $includeCompleted)
                    
                    LabeledContent("Reminders to export") {
                        Text("\(remindersToExport.count)")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // MARK: - Preview
                Section("Preview") {
                    if remindersToExport.isEmpty {
                        Text("No reminders to export")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(remindersToExport.prefix(5)) { reminder in
                            HStack {
                                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(reminder.isCompleted ? .green : .secondary)
                                    .font(.caption)
                                
                                Text(reminder.title)
                                    .font(.subheadline)
                                    .lineLimit(1)
                            }
                        }
                        
                        if remindersToExport.count > 5 {
                            Text("+ \(remindersToExport.count - 5) more...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // MARK: - Export Button
                Section {
                    Button {
                        exportData()
                    } label: {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Label(
                                isExporting ? "Exporting..." : "Export \(exportFormat.label)",
                                systemImage: "square.and.arrow.up"
                            )
                            .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(remindersToExport.isEmpty || isExporting)
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Export Successful", isPresented: $showSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your reminders have been exported as \(exportFormat.label).")
            }
        }
    }
    
    // MARK: - Computed
    
    private var remindersToExport: [Reminder] {
        if includeCompleted {
            return allReminders
        }
        return allReminders.filter { !$0.isCompleted }
    }
    
    // MARK: - Export
    
    private func exportData() {
        isExporting = true
        HapticManager.shared.lightImpact()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let url: URL?
            
            switch exportFormat {
            case .json:
                url = exportAsJSON()
            case .csv:
                url = exportAsCSV()
            }
            
            DispatchQueue.main.async {
                isExporting = false
                
                if let url = url {
                    exportURL = url
                    showShareSheet = true
                    HapticManager.shared.success()
                } else {
                    HapticManager.shared.error()
                }
            }
        }
    }
    
    private func exportAsJSON() -> URL? {
        let exportItems = remindersToExport.map { $0.exportData }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        guard let data = try? encoder.encode(exportItems) else { return nil }
        
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("quill_reminders_\(dateStamp()).json")
        
        try? data.write(to: url)
        return url
    }
    
    private func exportAsCSV() -> URL? {
        var csv = "Title,Notes,Due Date,Completed,Priority,Category,Tags,Location,Created\n"
        
        for reminder in remindersToExport {
            let fields: [String] = [
                escapeCSV(reminder.title),
                escapeCSV(reminder.notes),
                reminder.dueDate?.formatted(date: .abbreviated, time: .shortened) ?? "",
                reminder.isCompleted ? "Yes" : "No",
                reminder.priority.label,
                reminder.category?.name ?? "",
                reminder.tags.map { $0.name }.joined(separator: "; "),
                reminder.locationName ?? "",
                reminder.createdAt.formatted(date: .abbreviated, time: .shortened)
            ]
            csv += fields.joined(separator: ",") + "\n"
        }
        
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("quill_reminders_\(dateStamp()).csv")
        
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    
    private func escapeCSV(_ text: String) -> String {
        if text.contains(",") || text.contains("\"") || text.contains("\n") {
            return "\"\(text.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return text
    }
    
    private func dateStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Export Format

enum ExportFormat: String, CaseIterable, Identifiable {
    case json
    case csv
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .json: return "JSON"
        case .csv: return "CSV"
        }
    }
    
    var icon: String {
        switch self {
        case .json: return "curlybraces"
        case .csv: return "tablecells"
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
