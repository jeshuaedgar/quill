import SwiftUI
import SwiftData

struct AddReminderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var categories: [Category]
    @Query private var tags: [Tag]

    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var priority: Priority = .none
    @State private var selectedCategory: Category?
    @State private var selectedTags: Set<Tag> = []
    @State private var newTagName = ""
    
    // Location
    @State private var showLocationPicker = false
    @State private var locationLatitude: Double?
    @State private var locationLongitude: Double?
    @State private var locationName: String?
    @State private var locationRadius: Double?
    @State private var triggerOnArrival = true
    
    // Focus
    @State private var focusFilter: String?

    private var viewModel: RemindersViewModel {
        RemindersViewModel(modelContext: modelContext)
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Basic Info
                Section {
                    TextField("Reminder title", text: $title)
                        .font(.headline)

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // MARK: - Date & Time
                Section {
                    Toggle("Due date", isOn: $hasDueDate.animation())

                    if hasDueDate {
                        DatePicker(
                            "Date & Time",
                            selection: $dueDate,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }

                // MARK: - Priority
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases) { level in
                            Label(level.label, systemImage: level.icon)
                                .tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // MARK: - Category
                if !categories.isEmpty {
                    Section("Category") {
                        Picker("Category", selection: $selectedCategory) {
                            Text("None").tag(nil as Category?)
                            ForEach(categories) { category in
                                Label(category.name, systemImage: category.icon)
                                    .tag(category as Category?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                // MARK: - Location
                Section("Location") {
                    if let name = locationName {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.red)
                            
                            VStack(alignment: .leading) {
                                Text(name)
                                    .font(.subheadline)
                                Text(triggerOnArrival ? "On arrival" : "On departure")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                showLocationPicker = true
                            } label: {
                                Text("Change")
                                    .font(.caption)
                            }
                        }
                    } else {
                        Button {
                            showLocationPicker = true
                        } label: {
                            Label("Add Location", systemImage: "mappin.and.ellipse")
                        }
                    }
                }
                
                // MARK: - Focus Filter
                Section("Focus Mode") {
                    Picker("Show during", selection: Binding(
                        get: { focusFilter ?? "All" },
                        set: { focusFilter = $0 == "All" ? nil : $0 }
                    )) {
                        ForEach(FocusModeManager.focusModes, id: \.name) { mode in
                            Label(mode.name, systemImage: mode.icon)
                                .tag(mode.name)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // MARK: - Tags
                Section("Tags") {
                    if !tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(tags) { tag in
                                    Button {
                                        toggleTag(tag)
                                    } label: {
                                        Text("#\(tag.name)")
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(
                                                selectedTags.contains(tag)
                                                ? Color.accentColor
                                                : Color.secondary.opacity(0.2)
                                            )
                                            .foregroundStyle(
                                                selectedTags.contains(tag)
                                                ? .white
                                                : .primary
                                            )
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    HStack {
                        TextField("New tag", text: $newTagName)
                        Button("Add") {
                            addNewTag()
                        }
                        .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addReminder()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(
                    selectedLatitude: $locationLatitude,
                    selectedLongitude: $locationLongitude,
                    selectedName: $locationName,
                    radius: $locationRadius,
                    triggerOnArrival: $triggerOnArrival
                )
            }
        }
    }

    // MARK: - Actions

    private func addReminder() {
        let reminder = Reminder(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            dueDate: hasDueDate ? dueDate : nil,
            priority: priority,
            category: selectedCategory,
            tags: Array(selectedTags),
            locationLatitude: locationLatitude,
            locationLongitude: locationLongitude,
            locationName: locationName,
            locationRadius: locationRadius,
            triggerOnArrival: triggerOnArrival,
            focusFilter: focusFilter
        )
        
        modelContext.insert(reminder)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving: \(error)")
        }
        
        // Schedule notifications
        if hasDueDate {
            NotificationManager.shared.scheduleNotification(for: reminder)
        }
        
        // Start location monitoring
        if locationLatitude != nil {
            LocationManager.shared.startMonitoring(for: reminder)
        }
        
        HapticManager.shared.success()
    }

    private func toggleTag(_ tag: Tag) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
        HapticManager.shared.selection()
    }

    private func addNewTag() {
        let name = newTagName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let tag = Tag(name: name)
        modelContext.insert(tag)
        selectedTags.insert(tag)
        newTagName = ""
        HapticManager.shared.lightImpact()
    }
}

#Preview {
    AddReminderView()
        .modelContainer(for: [Reminder.self, Category.self, Tag.self], inMemory: true)
}
