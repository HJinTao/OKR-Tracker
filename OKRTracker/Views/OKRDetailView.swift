import SwiftUI
import Charts

struct OKRDetailView: View {
    @Binding var okr: OKR
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var localization = LocalizationManager.shared
    
    // Toggle for Edit Mode
    @State private var isEditing = false
    @State private var showingIconPicker = false
    
    // Alert state for deletion
    @State private var showingDeleteAlert = false
    @State private var indexToDelete: IndexSet?
    
    let availableIcons = [
        "target", "star.fill", "heart.fill", "flame.fill", "bolt.fill",
        "leaf.fill", "drop.fill", "book.fill", "graduationcap.fill", "briefcase.fill",
        "building.2.fill", "cart.fill", "creditcard.fill", "chart.bar.fill", "chart.pie.fill",
        "airplane", "car.fill", "figure.run", "dumbbell.fill", "gamecontroller.fill"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section (Objective)
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 12)
                            .opacity(0.1)
                            .foregroundColor(.blue)
                        
                        Circle()
                            .trim(from: 0.0, to: CGFloat(okr.progress))
                            .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                            .foregroundColor(okr.healthColor)
                            .rotationEffect(Angle(degrees: 270.0))
                            .animation(.linear, value: okr.progress)
                        
                        VStack {
                            // Icon Display
                            if isEditing {
                                Button(action: { showingIconPicker = true }) {
                                    Image(systemName: okr.icon)
                                        .font(.system(size: 40))
                                        .foregroundColor(okr.healthColor)
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(Circle())
                                }
                            } else {
                                Image(systemName: okr.icon)
                                    .font(.system(size: 40))
                                    .foregroundColor(okr.healthColor)
                            }
                            
                            Text("\(Int(okr.progress * 100))%")
                                .font(.system(.title, design: .rounded))
                                .bold()
                                .foregroundColor(okr.healthColor)
                        }
                    }
                    .frame(width: 140, height: 140)
                    .padding(.top, 20)
                    
                    VStack(spacing: 12) {
                        if isEditing {
                            TextField("Title".localized, text: $okr.title)
                                .font(.title2.bold())
                                .multilineTextAlignment(.center)
                                .padding(8)
                                .background(Color(uiColor: .systemGray6))
                                .cornerRadius(8)
                            
                            TextField("Description".localized, text: $okr.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(8)
                                .background(Color(uiColor: .systemGray6))
                                .cornerRadius(8)
                            
                            HStack {
                                Text("Start:".localized)
                                DatePicker("", selection: $okr.startDate, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)

                            HStack {
                                Text("End:".localized)
                                DatePicker("", selection: $okr.dueDate, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            
                            Toggle("Archived", isOn: $okr.isArchived)
                                .labelsHidden()
                            if okr.isArchived {
                                Text("Archived".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text(okr.title)
                                .font(.title2.bold())
                                .multilineTextAlignment(.center)
                            
                            if !okr.description.isEmpty {
                                Text(okr.description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            
                            VStack(spacing: 4) {
                                HStack {
                                    Image(systemName: "calendar")
                                    Text("\(okr.dueDate.formatted(date: .abbreviated, time: .omitted))")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                                
                                // Time Progress Bar
                                VStack(spacing: 2) {
                                    HStack {
                                        Text("Time Elapsed".localized)
                                        Spacer()
                                        Text("\(Int(okr.timeProgress * 100))%")
                                    }
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            Rectangle()
                                                .frame(width: geometry.size.width, height: 4)
                                                .opacity(0.1)
                                                .foregroundColor(.gray)
                                                .cornerRadius(2)
                                            
                                            Rectangle()
                                                .frame(width: min(CGFloat(okr.timeProgress) * geometry.size.width, geometry.size.width), height: 4)
                                                .foregroundColor(timeProgressColor)
                                                .cornerRadius(2)
                                        }
                                    }
                                    .frame(height: 4)
                                }
                                .padding(.top, 4)
                                .frame(width: 200)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                
                // Chart Section Removed as per request

                
                // Key Results Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Key Results".localized)
                            .font(.title3.bold())
                        Spacer()
                        // Only allow adding KRs in edit mode
                        if isEditing {
                            Button(action: {
                                let newKR = KeyResult(title: "New Key Result".localized, currentValue: 0, targetValue: 10, unit: "times")
                                okr.keyResults.append(newKR)
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    if okr.keyResults.isEmpty {
                        Text("No key results yet. Add one to track progress.".localized)
                            .italic()
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach($okr.keyResults) { $kr in
                            VStack {
                                KeyResultCard(kr: $kr, isEditing: isEditing)
                                
                                if isEditing {
                                    Button(action: {
                                        if let index = okr.keyResults.firstIndex(where: { $0.id == $kr.wrappedValue.id }) {
                                            indexToDelete = IndexSet(integer: index)
                                            showingDeleteAlert = true
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "trash")
                                            Text("Delete Key Result".localized)
                                        }
                                        .foregroundColor(.red)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 8)
                                }
                            }
                        }
                        .alert("Delete Key Result?".localized, isPresented: $showingDeleteAlert) {
                            Button("Cancel".localized, role: .cancel) { }
                            Button("Delete".localized, role: .destructive) {
                                if let indexSet = indexToDelete {
                                    okr.keyResults.remove(atOffsets: indexSet)
                                }
                            }
                        } message: {
                            Text("This action cannot be undone.".localized)
                        }
                    }
                }
            }
            .padding(.vertical)
            
            // Archive Action Button
            if isEditing {
                Button(action: {
                    okr.isArchived.toggle()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text(okr.isArchived ? "Unarchive Goal".localized : "Archive Goal".localized)
                        .font(.headline)
                        .foregroundColor(okr.isArchived ? .blue : .red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Details".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation {
                        isEditing.toggle()
                    }
                }) {
                    Text(isEditing ? "Done".localized : "Edit".localized)
                        .fontWeight(isEditing ? .bold : .regular)
                }
            }
        }
        .sheet(isPresented: $showingIconPicker) {
            NavigationView {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 20) {
                        ForEach(availableIcons, id: \.self) { iconName in
                            Button(action: {
                                okr.icon = iconName
                                showingIconPicker = false
                            }) {
                                Image(systemName: iconName)
                                    .font(.system(size: 30))
                                    .frame(width: 60, height: 60)
                                    .background(okr.icon == iconName ? Color.blue.opacity(0.1) : Color.clear)
                                    .foregroundColor(okr.icon == iconName ? .blue : .primary)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle("Select Icon".localized)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel".localized) { showingIconPicker = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    var timeProgressColor: Color {
        if okr.timeProgress > 0.9 { return .red }
        if okr.timeProgress > 0.7 { return .orange }
        return .blue
    }
}

extension OKR {
    var healthColor: Color {
        switch health {
        case .completed: return .green
        case .onTrack: return .blue
        case .atRisk: return .orange
        case .offTrack: return .red
        }
    }
}

struct KeyResultCard: View {
    @Binding var kr: KeyResult
    var isEditing: Bool
    
    @State private var showingUpdateSheet = false
    @State private var showingHistory = false
    @State private var showingTaskSheet = false // New for adding tasks
    @State private var editingTask: KRTask? // New for editing existing task
    @ObservedObject var localization = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: Title & Type Icon
            HStack(alignment: .top) {
                Image(systemName: kr.type.icon)
                    .foregroundColor(.blue)
                    .font(.system(size: 20))
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    if isEditing {
                        TextField("KR Title".localized, text: $kr.title)
                            .font(.headline)
                            .padding(4)
                            .background(Color(uiColor: .systemGray6))
                            .cornerRadius(4)
                        
                        HStack {
                            if kr.type != .boolean {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\("Target".localized):")
                                        .foregroundColor(.secondary)
                                        .font(.caption2)
                                    TextField("Target".localized, value: $kr.targetValue, formatter: NumberFormatter())
                                        .keyboardType(.decimalPad)
                                        .padding(4)
                                        .background(Color(uiColor: .systemGray6))
                                        .cornerRadius(4)
                                }
                                .frame(width: 70)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\("Unit".localized):")
                                        .foregroundColor(.secondary)
                                        .font(.caption2)
                                    TextField("Unit".localized, text: $kr.unit)
                                        .padding(4)
                                        .background(Color(uiColor: .systemGray6))
                                        .cornerRadius(4)
                                }
                                .frame(width: 60)
                            }
                            
                            // Weight Input (Integer)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\("Weight".localized):")
                                    .foregroundColor(.secondary)
                                    .font(.caption2)
                                TextField("100", value: Binding(
                                    get: { Int(kr.weight) },
                                    set: { kr.weight = Double(max(0, min(100, $0))) }
                                ), formatter: NumberFormatter())
                                    .keyboardType(.numberPad)
                                    .padding(4)
                                    .background(Color(uiColor: .systemGray6))
                                    .cornerRadius(4)
                            }
                            .frame(width: 50)
                            
                            Text("%")
                                .foregroundColor(.secondary)
                                .padding(.top, 16)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    } else {
                        Text(kr.title)
                            .font(.headline)
                        
                        HStack {
                            if kr.type != .boolean {
                                Text("\("Target".localized): \(kr.targetValue, specifier: "%.1f") \(kr.unit.localized)")
                            } else {
                                Text("\("Target".localized): \("Done".localized)")
                            }
                            
                            if kr.weight != 100.0 {
                                Text("• \("Weight".localized): \(Int(kr.weight))%")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if kr.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                }
            }
            
            // Tasks Section (New)
            if !kr.tasks.isEmpty || isEditing || true { // Always show tasks section
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Daily Plan".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Spacer()
                        
                        Button(action: { 
                            editingTask = nil
                            showingTaskSheet = true 
                        }) {
                            Image(systemName: "plus.circle")
                                .font(.caption)
                        }
                    }
                    
                    if kr.tasks.isEmpty {
                        Text("No tasks".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach($kr.tasks) { $task in
                            HStack {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(task.title)
                                            .foregroundColor(.primary)
                                        if task.weight > 0 {
                                            Text("+\(Int(task.weight))")
                                                .font(.caption2)
                                                .padding(2)
                                                .background(Color.orange.opacity(0.1))
                                                .foregroundColor(.orange)
                                                .cornerRadius(4)
                                        }
                                    }
                                    HStack {
                                        Text(task.recurrence.localized)
                                            .font(.caption2)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .cornerRadius(4)
                                        
                                        Text(task.date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if isEditing {
                                        editingTask = task
                                        showingTaskSheet = true
                                    }
                                }
                                
                                Spacer()
                                
                                if isEditing {
                                    Button(action: {
                                        if let index = kr.tasks.firstIndex(where: { $0.id == task.id }) {
                                            kr.tasks.remove(at: index)
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .font(.subheadline)
                        }
                    }
                }
            }
            
            // Progress Display & Input
            // Only show progress updating if NOT in editing mode
            VStack(spacing: 12) {
                HStack {
                    Text("Current Progress".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(displayValue)
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                }
                
                // Input controls based on type
                if !isEditing {
                    Group {
                        if kr.type == .boolean {
                            Toggle(isOn: Binding(
                                get: { kr.currentValue >= 1.0 },
                                set: { isDone in
                                    updateProgress(to: isDone ? 1.0 : 0.0, message: isDone ? "Marked as done".localized : "Marked as not done".localized)
                                }
                            )) {
                                Text("Completed".localized)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .green))
                        } else {
                            // Progress Bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .frame(width: geometry.size.width, height: 8)
                                        .opacity(0.1)
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                    
                                    Rectangle()
                                        .frame(width: min(CGFloat(kr.progress) * geometry.size.width, geometry.size.width), height: 8)
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                }
                            }
                            .frame(height: 8)
                            
                            HStack {
                                if kr.type == .number {
                                    Stepper("Value".localized, value: Binding(
                                        get: { kr.currentValue },
                                        set: { newValue in
                                            updateProgress(to: newValue)
                                        }
                                    ), in: 0...kr.targetValue)
                                    .labelsHidden()
                                }
                                
                                Spacer()
                                
                                Button(action: { showingUpdateSheet = true }) {
                                    Text("Update".localized)
                                        .font(.subheadline.bold())
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 6)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }
                } else {
                    Text("Exit edit mode to update progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            
            // History Toggle
            if !kr.logs.isEmpty {
                Divider()
                Button(action: { showingHistory.toggle() }) {
                    HStack {
                        Text("\("History".localized) (\(kr.logs.count))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(showingHistory ? 90 : 0))
                    }
                }
                
                if showingHistory {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(kr.logs.filter { !$0.message.contains("uncompleted") }) { log in
                            HStack(alignment: .top) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 6)
                                VStack(alignment: .leading) {
                                    Text(log.message)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                    Text("\(log.date.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("\(log.newValue, specifier: "%.1f")")
                                    .font(.caption.bold())
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
        .padding(.horizontal)
        .sheet(isPresented: $showingUpdateSheet) {
            UpdateProgressView(kr: $kr)
        }
        .sheet(isPresented: $showingTaskSheet) {
            if let taskToEdit = editingTask {
                AddTaskView(kr: $kr, editingTask: taskToEdit)
            } else {
                AddTaskView(kr: $kr, editingTask: nil)
            }
        }
    }
    
    var displayValue: String {
        switch kr.type {
        case .currency:
            return "\(kr.unit)\(String(format: "%.2f", kr.currentValue)) / \(kr.unit)\(String(format: "%.2f", kr.targetValue))"
        case .percentage:
            return "\(Int(kr.currentValue))% / \(Int(kr.targetValue))%"
        case .boolean:
            return kr.isCompleted ? "Done".localized : "Not Done".localized
        default:
            return "\(String(format: "%.1f", kr.currentValue)) / \(String(format: "%.1f", kr.targetValue)) \(kr.unit.localized)"
        }
    }
    
    func updateProgress(to value: Double, message: String? = nil) {
        let oldValue = kr.currentValue
        kr.currentValue = value
        
        let logMessage = message ?? "Quick update".localized
        let log = ActivityLog(
            id: UUID(),
            date: Date(),
            message: logMessage,
            previousValue: oldValue,
            newValue: value
        )
        kr.logs.insert(log, at: 0)
    }
}

struct AddTaskView: View {
    @Binding var kr: KeyResult
    var editingTask: KRTask? // Optional task to edit
    @Environment(\.dismiss) var dismiss
    @State private var title: String = ""
    @State private var date: Date = Date()
    @State private var recurrence: TaskRecurrence = .none
    @State private var weight: Double = 0 // New state for weight
    @ObservedObject var localization = LocalizationManager.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details".localized) {
                    TextField("Task Title".localized, text: $title)
                    DatePicker("Start Date".localized, selection: $date, displayedComponents: .date)
                    Picker("Repeat".localized, selection: $recurrence) {
                        ForEach(TaskRecurrence.allCases) { option in
                            Text(option.localized).tag(option)
                        }
                    }
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Value Contribution".localized)
                            Text("How much this task adds to progress".localized)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        TextField("0", value: Binding(
                            get: { weight },
                            set: { 
                                // Limit weight to not exceed KR target value
                                let maxAllowed = kr.targetValue
                                weight = max(0, min(maxAllowed, $0)) 
                            }
                        ), formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                            .padding(4)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(4)
                    }
                }
            }
            .navigationTitle(editingTask == nil ? "Add Task".localized : "Edit Task".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingTask == nil ? "Add".localized : "Save".localized) {
                        if let existingTask = editingTask, let index = kr.tasks.firstIndex(where: { $0.id == existingTask.id }) {
                            // Update existing
                            kr.tasks[index].title = title
                            kr.tasks[index].date = date
                            kr.tasks[index].recurrence = recurrence
                            kr.tasks[index].weight = weight
                        } else {
                            // Add new
                            let newTask = KRTask(title: title, date: date, recurrence: recurrence, weight: weight)
                            kr.tasks.append(newTask)
                        }
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                if let task = editingTask {
                    title = task.title
                    date = task.date
                    recurrence = task.recurrence
                    weight = task.weight
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct UpdateProgressView: View {
    @Binding var kr: KeyResult
    @Environment(\.dismiss) var dismiss
    @ObservedObject var localization = LocalizationManager.shared
    @State private var newValue: Double = 0
    @State private var note: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Update Progress".localized) {
                    HStack {
                        Text("Current:".localized)
                        Spacer()
                        Text("\(kr.currentValue, specifier: "%.1f")")
                    }
                    
                    HStack {
                        Text("New Value:".localized)
                        Spacer()
                        TextField("Value".localized, value: $newValue, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    if kr.type == .percentage || kr.type == .number {
                         Slider(value: $newValue, in: 0...kr.targetValue)
                    }
                }
                
                Section("Note".localized) {
                    TextField("What did you achieve?".localized, text: $note)
                }
            }
            .navigationTitle("Check-in".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update".localized) {
                        let log = ActivityLog(
                            id: UUID(),
                            date: Date(),
                            message: note.isEmpty ? "Progress update".localized : note,
                            previousValue: kr.currentValue,
                            newValue: newValue
                        )
                        kr.currentValue = newValue
                        kr.logs.insert(log, at: 0)
                        dismiss()
                    }
                }
            }
            .onAppear {
                newValue = kr.currentValue
            }
        }
        .presentationDetents([.medium])
    }
}
