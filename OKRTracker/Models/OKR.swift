import Foundation

struct OKR: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String // Objective (O)
    var description: String
    var icon: String = "target" // Default icon
    var keyResults: [KeyResult] // Key Results (KR)
    var startDate: Date = Date() // Default to now if not specified
    var dueDate: Date
    var isCompleted: Bool = false
    var isArchived: Bool = false // Archived state
    
    // Auto-calculate health based on time remaining vs progress
    var health: OKRHealth {
        if isCompleted { return .completed }
        if progress >= 1.0 { return .completed }
        
        let totalTime = dueDate.timeIntervalSince(startDate)
        let elapsed = Date().timeIntervalSince(startDate)
        let timeRatio = totalTime > 0 ? elapsed / totalTime : 1.0
        
        // Simple logic: if less than 20% time left and less than 80% progress -> At Risk
        // For now, let's just use progress thresholds relative to time
        if timeRatio > 0.5 && progress < 0.2 { return .atRisk }
        if timeRatio > 0.8 && progress < 0.6 { return .offTrack }
        return .onTrack // Default
    }
    
    var progress: Double {
        guard !keyResults.isEmpty else { return 0.0 }
        
        let totalWeight = keyResults.reduce(0.0) { $0 + $1.weight }
        guard totalWeight > 0 else {
            // Fallback to simple average if weights are 0
            let totalProgress = keyResults.reduce(0.0) { $0 + $1.progress }
            return totalProgress / Double(keyResults.count)
        }
        
        let weightedProgress = keyResults.reduce(0.0) { $0 + ($1.progress * $1.weight) }
        return weightedProgress / totalWeight
    }
    
    var timeProgress: Double {
        let totalDuration = dueDate.timeIntervalSince(startDate)
        let elapsed = Date().timeIntervalSince(startDate)
        
        guard totalDuration > 0 else { return 1.0 }
        return min(max(elapsed / totalDuration, 0.0), 1.0)
    }
    
    // History points for charting (derived from key result logs)
    var progressHistory: [DatePoint] {
        var points: [DatePoint] = []
        
        // Add start point
        points.append(DatePoint(date: startDate, value: 0.0))
        
        // Collect all log dates from all KRs
        let allLogs = keyResults.flatMap { $0.logs }
        let sortedDates = Set(allLogs.map { $0.date }).sorted()
        
        // Calculate OKR progress at each log date
        for date in sortedDates {
            let progressAtDate = calculateProgress(at: date)
            points.append(DatePoint(date: date, value: progressAtDate))
        }
        
        // Add current point if not already there
        if let lastDate = points.last?.date, lastDate < Date().addingTimeInterval(-60) {
            points.append(DatePoint(date: Date(), value: progress))
        }
        
        return points.sorted { $0.date < $1.date }
    }
    
    private func calculateProgress(at date: Date) -> Double {
        guard !keyResults.isEmpty else { return 0.0 }
        
        let totalWeight = keyResults.reduce(0.0) { $0 + $1.weight }
        var weightedProgress = 0.0
        
        for kr in keyResults {
            // Find the value of this KR at the given date
            // Sort logs descending by date
            let relevantLogs = kr.logs.filter { $0.date <= date }.sorted { $0.date > $1.date }
            
            let valueAtDate: Double
            if let latestLog = relevantLogs.first {
                valueAtDate = latestLog.newValue
            } else {
                // If no logs before this date, it was 0
                valueAtDate = 0.0
            }
            
            let krProgress = kr.targetValue > 0 ? min(valueAtDate / kr.targetValue, 1.0) : 0.0
            weightedProgress += krProgress * kr.weight
        }
        
        return totalWeight > 0 ? weightedProgress / totalWeight : 0.0
    }
}

struct DatePoint: Identifiable {
    var id = UUID()
    var date: Date
    var value: Double
}

enum OKRHealth: String, Codable {
    case onTrack = "On Track"
    case atRisk = "At Risk"
    case offTrack = "Off Track"
    case completed = "Completed"
    
    var localized: String {
        return self.rawValue.localized
    }
}

struct KeyResult: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String // e.g., "Read 5 books"
    var type: KeyResultType = .number // Default to generic number
    var currentValue: Double // e.g., 2
    var targetValue: Double // e.g., 5
    var unit: String // e.g., "books", "%", "$"
    var weight: Double = 100.0 // Weight for this KR (default 100)
    
    var logs: [ActivityLog] = []
    
    // New fields for planning
    var tasks: [KRTask] = [] // Daily tasks linked to this KR
    
    var progress: Double {
        guard targetValue > 0 else { return 0.0 }
        return min(currentValue / targetValue, 1.0)
    }
    
    var isCompleted: Bool {
        return currentValue >= targetValue
    }
}

enum TaskRecurrence: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case weekdays = "Weekdays"
    
    var id: String { self.rawValue }
    
    var localized: String {
        return self.rawValue.localized
    }
}

struct KRTask: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var date: Date // Planned date (start date if recurring)
    var recurrence: TaskRecurrence = .none
    var weight: Double = 0.0 // Value contribution to KR progress (e.g. +5 to current value)
    var completedDates: [Date] = [] // History of completion dates (normalized to start of day)
    var createdAt: Date = Date()
    
    // Legacy support or simple check for non-recurring
    var isCompleted: Bool {
        return false // Placeholder
    }
}

enum KeyResultType: String, Codable, CaseIterable, Identifiable {
    case number = "Number"
    case percentage = "Percentage"
    case currency = "Currency"
    case boolean = "Yes/No"
    
    var id: String { self.rawValue }
    
    var localized: String {
        return self.rawValue.localized
    }
    
    var icon: String {
        switch self {
        case .number: return "number"
        case .percentage: return "percent"
        case .currency: return "dollarsign.circle"
        case .boolean: return "checkmark.circle"
        }
    }
}

struct ActivityLog: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var message: String
    var previousValue: Double
    var newValue: Double
}
