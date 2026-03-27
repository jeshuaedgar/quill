import SwiftUI
import SwiftData

struct SmartInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var categories: [Category]
    
    @State private var inputText = ""
    @State private var parseResult: NLParser.ParseResult?
    @State private var isProcessing = false
    
    // Editable overrides
    @State private var editedTitle = ""
    @State private var editedDate: Date = Date()
    @State private var hasDate = false
    @State private var editedPriority: Priority = .none
    @State private var editedCategory: Category?
    @State private var hasParsed = false
    
    private var viewModel: RemindersViewModel {
        RemindersViewModel(modelContext: modelContext)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Smart Input Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("What do you need to remember?")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.purple)
                        
                        TextField(
                            "e.g., Call dentist next Thursday at 3pm",
                            text: $inputText,
                            axis: .vertical
                        )
                        .lineLimit(1...3)
                        .onSubmit {
                            parseInput()
                        }
                        
                        if !inputText.isEmpty {
                            Button {
                                parseInput()
                            } label: {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.purple)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                if isProcessing {
                    ProgressView("Analyzing...")
                        .padding()
                }
                
                // MARK: - Parsed Results
                if hasParsed {
                    Form {
                        // Detected Title
                        Section("Title") {
                            TextField("Title", text: $editedTitle)
                                .font(.headline)
                        }
                        
                        // Detected Date
                        Section("Date & Time") {
                            Toggle("Due date", isOn: $hasDate.animation())
                            
                            if hasDate {
                                DatePicker(
                                    "Date & Time",
                                    selection: $editedDate,
                                    in: Date()...,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                            }
                        }
                        
                        // Detected Priority
                        Section("Priority") {
                            Picker("Priority", selection: $editedPriority) {
                                ForEach(Priority.allCases) { level in
                                    Label(level.label, systemImage: level.icon)
                                        .tag(level)
                                }
                            }
                            .pickerStyle(.menu)
                            
                            if let result = parseResult, result.suggestedPriority != .none {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundStyle(.purple)
                                    Text("AI suggested: \(result.suggestedPriority.label)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        // Detected Category
                        Section("Category") {
                            Picker("Category", selection: $editedCategory) {
                                Text("None").tag(nil as Category?)
                                ForEach(categories) { category in
                                    Label(category.name, systemImage: category.icon)
                                        .tag(category as Category?)
                                }
                            }
                            .pickerStyle(.menu)
                            
                            if let result = parseResult, result.suggestedCategory != nil {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundStyle(.purple)
                                    Text("AI suggested: \(result.suggestedCategory!)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        // Detected Entities
                        if let result = parseResult {
                            if !result.people.isEmpty || !result.locations.isEmpty {
                                Section("Detected") {
                                    if !result.people.isEmpty {
                                        Label(
                                            "People: \(result.people.joined(separator: ", "))",
                                            systemImage: "person.fill"
                                        )
                                        .font(.caption)
                                    }
                                    if !result.locations.isEmpty {
                                        Label(
                                            "Places: \(result.locations.joined(separator: ", "))",
                                            systemImage: "mappin"
                                        )
                                        .font(.caption)
                                    }
                                }
                            }
                        }
                        
                        // Save Button
                        Section {
                            Button {
                                saveReminder()
                            } label: {
                                HStack {
                                    Spacer()
                                    Label("Save Reminder", systemImage: "checkmark.circle.fill")
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                            }
                            .disabled(editedTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
            }
            .navigationTitle("Smart Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Parse
    
    private func parseInput() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isProcessing = true
        
        // Small delay for UX feel
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let result = NLParser.shared.parse(inputText)
            
            withAnimation(.spring(duration: 0.4)) {
                parseResult = result
                editedTitle = result.title
                editedPriority = result.suggestedPriority
                
                if let date = result.date {
                    editedDate = date
                    hasDate = true
                }
                
                // Auto-assign category
                if result.suggestedCategory != nil {
                    editedCategory = CategoryClassifier.shared.findOrSuggestCategory(
                        for: inputText,
                        existingCategories: categories,
                        modelContext: modelContext
                    )
                }
                
                hasParsed = true
                isProcessing = false
            }
        }
    }
    
    // MARK: - Save
    
    private func saveReminder() {
        let title = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        
        viewModel.addReminder(
            title: title,
            dueDate: hasDate ? editedDate : nil,
            priority: editedPriority,
            category: editedCategory
        )
        
        dismiss()
    }
}

#Preview {
    SmartInputView()
        .modelContainer(for: [Reminder.self, Category.self, Tag.self], inMemory: true)
}
