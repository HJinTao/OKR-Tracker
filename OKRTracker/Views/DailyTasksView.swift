import SwiftUI

struct DailyTasksView: View {
    @ObservedObject var store: OKRStore
    @ObservedObject var localization = LocalizationManager.shared
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        NavigationView {
            VStack {
                // Date Selector (Simple horizontal calendar strip could go here, for now just a Picker or current date)
                HStack {
                    Text("Today's Tasks".localized)
                        .font(.headline)
                    Spacer()
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .labelsHidden()
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        let tasks = tasksForDate(selectedDate)
                        
                        if tasks.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "checklist")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray.opacity(0.3))
                                Text("No tasks for this day".localized)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 40)
                        } else {
                            ForEach(tasks, id: \.task.id) { item in
                                TaskRow(
                                    task: item.task,
                                    okrTitle: item.okrTitle,
                                    krTitle: item.krTitle,
                                    color: item.color,
                                    isCompleted: item.isCompleted,
                                    onToggle: {
                                        toggleTask(okrId: item.okrId, krId: item.krId, taskId: item.task.id)
                                    }
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Daily Plan".localized)
        }
    }
    
    // Helper Model
    struct TaskItem {
        var okrId: UUID
        var krId: UUID
        var okrTitle: String
        var krTitle: String
        var color: Color
        var task: KRTask
        var isCompleted: Bool
    }
    
    func tasksForDate(_ date: Date) -> [TaskItem] {
        var items: [TaskItem] = []
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        for okr in store.okrs where !okr.isArchived {
            for kr in okr.keyResults {
                for task in kr.tasks {
                    var shouldShow = false
                    
                    // Logic to check if task should appear on this date
                    switch task.recurrence {
                    case .none:
                        // Only show on the specific date
                        shouldShow = calendar.isDate(task.date, inSameDayAs: date)
                    case .daily:
                        // Show if date is after or on start date
                        shouldShow = calendar.startOfDay(for: task.date) <= startOfDay
                    case .weekly:
                        // Show if date is after start date AND same weekday
                        if calendar.startOfDay(for: task.date) <= startOfDay {
                            let taskWeekday = calendar.component(.weekday, from: task.date)
                            let currentWeekday = calendar.component(.weekday, from: date)
                            shouldShow = taskWeekday == currentWeekday
                        }
                    case .weekdays:
                        // Show if date is after start date AND is a weekday (Mon-Fri)
                        if calendar.startOfDay(for: task.date) <= startOfDay {
                            let weekday = calendar.component(.weekday, from: date)
                            shouldShow = weekday >= 2 && weekday <= 6 // 1 is Sunday, 7 is Saturday
                        }
                    }
                    
                    if shouldShow {
                        // Check if completed on this specific date
                        let isCompleted = task.completedDates.contains {
                            calendar.isDate($0, inSameDayAs: date)
                        }
                        
                        items.append(TaskItem(
                            okrId: okr.id,
                            krId: kr.id,
                            okrTitle: okr.title,
                            krTitle: kr.title,
                            color: okr.healthColor,
                            task: task,
                            isCompleted: isCompleted
                        ))
                    }
                }
            }
        }
        return items.sorted { !$0.isCompleted && $1.isCompleted } // Pending first
    }
    
    func toggleTask(okrId: UUID, krId: UUID, taskId: UUID) {
        if let okrIndex = store.okrs.firstIndex(where: { $0.id == okrId }),
           let krIndex = store.okrs[okrIndex].keyResults.firstIndex(where: { $0.id == krId }),
           let taskIndex = store.okrs[okrIndex].keyResults[krIndex].tasks.firstIndex(where: { $0.id == taskId }) {
            
            var task = store.okrs[okrIndex].keyResults[krIndex].tasks[taskIndex]
            var kr = store.okrs[okrIndex].keyResults[krIndex] // Get copy of KR to update value
            
            let calendar = Calendar.current
            let dateToCheck = selectedDate // Use selectedDate from state
            
            // Normalize dateToCheck to start of day to match how we store/check
            let startOfDateToCheck = calendar.startOfDay(for: dateToCheck)
            
            if let index = task.completedDates.firstIndex(where: { calendar.isDate($0, inSameDayAs: startOfDateToCheck) }) {
                // Was completed, remove completion
                task.completedDates.remove(at: index)
                
                // Decrease KR progress by task weight
                if task.weight > 0 {
                    let newValue = max(0, kr.currentValue - task.weight)
                    
                    // Instead of adding "uncompleted" log, try to remove the previous "completed" log
                    // This keeps history clean as requested
                    if let logIndex = kr.logs.firstIndex(where: { 
                        $0.message.contains("Task completed: \(task.title)") && 
                        calendar.isDate($0.date, inSameDayAs: Date()) 
                    }) {
                        kr.logs.remove(at: logIndex)
                        
                        // Just update value without adding new log
                        store.okrs[okrIndex].keyResults[krIndex].currentValue = newValue
                        store.okrs[okrIndex].keyResults[krIndex].tasks[taskIndex] = task
                        // Manually trigger update since we bypassed updateKRProgress
                        store.okrs[okrIndex].keyResults[krIndex] = store.okrs[okrIndex].keyResults[krIndex]
                    } else {
                        // Fallback if log not found (e.g. from different day), just update value
                        // Maybe user doesn't want "Uncompleted" log at all?
                        // "if completed then cancelled, no History record"
                        // So we just update value silently if we can't find the original log to delete.
                        store.okrs[okrIndex].keyResults[krIndex].currentValue = newValue
                        store.okrs[okrIndex].keyResults[krIndex].tasks[taskIndex] = task
                        store.okrs[okrIndex].keyResults[krIndex] = store.okrs[okrIndex].keyResults[krIndex]
                    }
                } else {
                    // Weight 0, just update task status
                    store.okrs[okrIndex].keyResults[krIndex].tasks[taskIndex] = task
                }
            } else {
                // Not completed, add completion
                task.completedDates.append(startOfDateToCheck)
                
                // Increase KR progress by task weight
                if task.weight > 0 {
                    let newValue = min(kr.targetValue, kr.currentValue + task.weight)
                    updateKRProgress(krIndex: krIndex, okrIndex: okrIndex, newValue: newValue, message: "Task completed: \(task.title)")
                }
            }
            
            store.okrs[okrIndex].keyResults[krIndex].tasks[taskIndex] = task
            // Force UI update if needed, but @Published should handle it
        }
    }
    
    func updateKRProgress(krIndex: Int, okrIndex: Int, newValue: Double, message: String) {
        var kr = store.okrs[okrIndex].keyResults[krIndex]
        let oldValue = kr.currentValue
        kr.currentValue = newValue
        
        let log = ActivityLog(
            id: UUID(),
            date: Date(),
            message: message,
            previousValue: oldValue,
            newValue: newValue
        )
        kr.logs.insert(log, at: 0)
        store.okrs[okrIndex].keyResults[krIndex] = kr
    }
}

struct TaskRow: View {
    let task: KRTask
    let okrTitle: String
    let krTitle: String
    let color: Color
    let isCompleted: Bool
    let onToggle: () -> Void
    
    init(task: KRTask, okrTitle: String, krTitle: String, color: Color, isCompleted: Bool? = nil, onToggle: @escaping () -> Void) {
        self.task = task
        self.okrTitle = okrTitle
        self.krTitle = krTitle
        self.color = color
        self.isCompleted = isCompleted ?? false
        self.onToggle = onToggle
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: {
                HapticManager.shared.impact(style: .medium)
                onToggle()
            }) {
                Image(systemName: isCompleted ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundColor(isCompleted ? .gray : color)
            }
            .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(isCompleted)
                    .foregroundColor(isCompleted ? .secondary : .primary)
                
                HStack {
                    if task.recurrence != .none {
                        Image(systemName: "repeat")
                            .font(.caption2)
                    }
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                    Text(okrTitle)
                        .lineLimit(1)
                    Text("•")
                    Text(krTitle)
                        .lineLimit(1)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
        .opacity(isCompleted ? 0.6 : 1.0)
    }
}
