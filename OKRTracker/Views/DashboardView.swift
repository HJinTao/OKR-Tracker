import SwiftUI
import Charts

struct DashboardView: View {
    @ObservedObject var store: OKRStore
    @ObservedObject var localization = LocalizationManager.shared
    
    // For heatmap
    let columns = Array(repeating: GridItem(.fixed(12), spacing: 4), count: 7) // 7 rows (days of week)
    
    @State private var showingDetailChart = false
    @State private var showingDetailHeatmap = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Global Progress Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overall Progress".localized)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if overallProgressPoints.isEmpty {
                            Text("No data available".localized)
                                .foregroundColor(.secondary)
                                .frame(height: 180)
                                .frame(maxWidth: .infinity)
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(16)
                                .padding(.horizontal)
                        } else {
                            VStack {
                                Chart {
                                    ForEach(overallProgressPoints) { point in
                                        LineMark(
                                            x: .value("Date", point.date),
                                            y: .value("Progress", point.value * 100)
                                        )
                                        .interpolationMethod(.catmullRom)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        
                                        AreaMark(
                                            x: .value("Date", point.date),
                                            y: .value("Progress", point.value * 100)
                                        )
                                        .interpolationMethod(.catmullRom)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.05)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                    }
                                }
                                .chartYScale(domain: 0...100)
                                .chartXAxis(.hidden)
                                .chartYAxis(.hidden)
                                .frame(height: 120)
                            }
                            .padding()
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                            .padding(.horizontal)
                            .onTapGesture {
                                showingDetailChart = true
                            }
                        }
                    }
                    
                    // Heatmap Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Activity Heatmap".localized)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHGrid(rows: columns, spacing: 4) {
                                ForEach(heatmapData) { day in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(color(for: day.intensity))
                                        .frame(width: 12, height: 12)
                                }
                            }
                            .padding()
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .onTapGesture {
                            showingDetailHeatmap = true
                        }
                    }
                    
                    // Summary Stats
                    HStack(spacing: 16) {
                        StatCard(title: "Active Goals".localized, value: "\(activeGoalsCount)", icon: "target", color: .blue)
                        StatCard(title: "Completed Tasks".localized, value: "\(completedTasksCount)", icon: "checkmark.circle.fill", color: .green)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Dashboard".localized)
            .sheet(isPresented: $showingDetailChart) {
                DetailedProgressView(store: store, overallPoints: overallProgressPoints)
            }
            .sheet(isPresented: $showingDetailHeatmap) {
                DetailedHeatmapView(store: store)
            }
        }
    }
    
    // MARK: - Data Helpers
    
    var activeGoalsCount: Int {
        store.okrs.filter { !$0.isArchived && !$0.isCompleted }.count
    }
    
    var completedTasksCount: Int {
        store.okrs.flatMap { $0.keyResults }.flatMap { $0.tasks }.filter { $0.isCompleted }.count
    }
    
    // Aggregate progress of all OKRs
    var overallProgressPoints: [DatePoint] {
        // Collect all dates from all OKRs histories
        let allHistories = store.okrs.flatMap { $0.progressHistory }
        guard !allHistories.isEmpty else { return [] }
        
        let allDates = Set(allHistories.map { Calendar.current.startOfDay(for: $0.date) }).sorted()
        
        var points: [DatePoint] = []
        
        for date in allDates {
            // Calculate average progress of all ACTIVE OKRs at this date
            // An OKR is "active" at this date if startDate <= date
            let activeOKRsAtDate = store.okrs.filter { Calendar.current.startOfDay(for: $0.startDate) <= date }
            
            if !activeOKRsAtDate.isEmpty {
                let totalProgress = activeOKRsAtDate.reduce(0.0) { sum, okr in
                    // Find the progress value for this OKR at this date
                    // We look for the last point <= date
                    let history = okr.progressHistory
                    let relevantPoint = history.last { $0.date <= date.addingTimeInterval(86399) }
                    return sum + (relevantPoint?.value ?? 0.0)
                }
                let avg = totalProgress / Double(activeOKRsAtDate.count)
                points.append(DatePoint(date: date, value: avg))
            }
        }
        
        return points
    }
    
    // Heatmap Data Generation
    struct HeatmapDay: Identifiable {
        var id = UUID()
        var date: Date
        var intensity: Int // 0-4
    }
    
    var heatmapData: [HeatmapDay] {
        let calendar = Calendar.current
        let today = Date()
        // Generate last ~20 weeks (140 days)
        guard let startDate = calendar.date(byAdding: .day, value: -140, to: today) else { return [] }
        
        var days: [HeatmapDay] = []
        
        // Loop from start to today
        var currentDate = startDate
        while currentDate <= today {
            let intensity = calculateIntensity(for: currentDate)
            days.append(HeatmapDay(date: currentDate, intensity: intensity))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return days
    }
    
    func calculateIntensity(for date: Date) -> Int {
        let calendar = Calendar.current
        
        // Count completed tasks on this date
        let completedTasks = store.okrs.flatMap { $0.keyResults }
            .flatMap { $0.tasks }
            .filter { $0.isCompleted && calendar.isDate($0.date, inSameDayAs: date) }
            .count
        
        // Count activity logs on this date
        let logs = store.okrs.flatMap { $0.keyResults }
            .flatMap { $0.logs }
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .count
        
        let totalActivity = completedTasks + logs
        
        if totalActivity == 0 { return 0 }
        if totalActivity <= 2 { return 1 }
        if totalActivity <= 4 { return 2 }
        if totalActivity <= 6 { return 3 }
        return 4
    }
    
    func color(for intensity: Int) -> Color {
        switch intensity {
        case 0: return Color.gray.opacity(0.2)
        case 1: return Color.green.opacity(0.3)
        case 2: return Color.green.opacity(0.5)
        case 3: return Color.green.opacity(0.7)
        case 4: return Color.green
        default: return Color.green
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
                Text(value)
                    .font(.system(.title, design: .rounded))
                    .bold()
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct DetailedProgressView: View {
    @ObservedObject var store: OKRStore
    let overallPoints: [DatePoint]
    @ObservedObject var localization = LocalizationManager.shared
    @Environment(\.dismiss) var dismiss
    
    // View State
    @State private var selectedGoalId: UUID? = nil // nil means "Overall"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Chart Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedGoalId == nil ? "Overall Progress".localized : (store.okrs.first(where: { $0.id == selectedGoalId })?.title ?? ""))
                            .font(.title2.bold())
                            .padding(.horizontal)
                        
                        Chart {
                            if let goalId = selectedGoalId, let goal = store.okrs.first(where: { $0.id == goalId }) {
                                // Individual Goal Chart
                                ForEach(goal.progressHistory) { point in
                                    LineMark(
                                        x: .value("Date", point.date),
                                        y: .value("Progress", point.value * 100)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(goal.healthColor)
                                    .symbol {
                                        Circle()
                                            .fill(goal.healthColor)
                                            .frame(width: 6, height: 6)
                                            .shadow(radius: 2)
                                    }
                                    
                                    AreaMark(
                                        x: .value("Date", point.date),
                                        y: .value("Progress", point.value * 100)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [goal.healthColor.opacity(0.3), goal.healthColor.opacity(0.05)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                }
                            } else {
                                // Overall Chart
                                ForEach(overallPoints) { point in
                                    LineMark(
                                        x: .value("Date", point.date),
                                        y: .value("Progress", point.value * 100)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .symbol {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 6, height: 6)
                                            .shadow(radius: 2)
                                    }
                                    
                                    AreaMark(
                                        x: .value("Date", point.date),
                                        y: .value("Progress", point.value * 100)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.05)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                }
                            }
                        }
                        .chartYScale(domain: 0...100)
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                                if let date = value.as(Date.self) {
                                    AxisValueLabel {
                                        Text(date.formatted(.dateTime.month().day()))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                AxisGridLine()
                                    .foregroundStyle(Color.gray.opacity(0.1))
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading, values: .stride(by: 25)) { value in
                                AxisValueLabel {
                                    if let intValue = value.as(Int.self) {
                                        Text("\(intValue)%")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                AxisGridLine()
                                    .foregroundStyle(Color.gray.opacity(0.1))
                            }
                        }
                        .frame(height: 300)
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        .padding(.horizontal)
                    }
                    
                    // Goal Selection List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Breakdown".localized)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // "Overall" Option
                        Button(action: { selectedGoalId = nil }) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .clipShape(Circle())
                                
                                Text("Overall Progress".localized)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedGoalId == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Individual Goals
                        ForEach(store.okrs) { okr in
                            Button(action: { selectedGoalId = okr.id }) {
                                HStack {
                                    Image(systemName: okr.icon)
                                        .foregroundColor(okr.healthColor)
                                        .frame(width: 32, height: 32)
                                        .background(okr.healthColor.opacity(0.1))
                                        .clipShape(Circle())
                                    
                                    Text(okr.title)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    if selectedGoalId == okr.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Progress Details".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done".localized) { dismiss() }
                }
            }
        }
    }
}

struct DetailedHeatmapView: View {
    @ObservedObject var store: OKRStore
    @ObservedObject var localization = LocalizationManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedGoalId: UUID? = nil
    
    // Grid config
    // 7 rows (Mon-Sun), columns determined by date range
    let rows = Array(repeating: GridItem(.fixed(14), spacing: 4), count: 7)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Heatmap Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedGoalId == nil ? "Overall Activity".localized : (store.okrs.first(where: { $0.id == selectedGoalId })?.title ?? ""))
                            .font(.title2.bold())
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 4) {
                                // Month Labels
                                HStack(spacing: 0) {
                                    ForEach(monthLabels, id: \.self) { label in
                                        Text(label.text)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .frame(width: label.width, alignment: .leading)
                                    }
                                }
                                .padding(.leading, 30) // Offset for day labels
                                
                                HStack(spacing: 4) {
                                    // Day Labels (Mon, Wed, Fri)
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(0..<7) { day in
                                            if day % 2 == 1 { // Show label for 1, 3, 5 (Tue, Thu, Sat) or just specific ones
                                                // GitHub shows Mon, Wed, Fri. Let's do Mon(1), Wed(3), Fri(5) if 0 is Sun.
                                                // Calendar.current.firstWeekday usually 1 (Sun).
                                                // If we map 0->Sun, 1->Mon...
                                                // Let's just show Mon, Wed, Fri.
                                                Text(dayLabel(for: day))
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                    .frame(height: 14)
                                            } else {
                                                Spacer().frame(height: 14)
                                            }
                                        }
                                    }
                                    .frame(width: 26)
                                    
                                    // Heatmap Grid
                                    LazyHGrid(rows: rows, spacing: 4) {
                                        ForEach(heatmapData) { day in
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(color(for: day.intensity))
                                                .frame(width: 14, height: 14)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 2)
                                                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                                                )
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        .padding(.horizontal)
                        
                        // Legend
                        HStack(spacing: 12) {
                            Text("Less".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ForEach(0..<5) { intensity in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(color(for: intensity))
                                    .frame(width: 14, height: 14)
                            }
                            
                            Text("More".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                    
                    // Goal Selection List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Breakdown".localized)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // "Overall" Option
                        Button(action: { selectedGoalId = nil }) {
                            HStack {
                                Image(systemName: "square.grid.3x3.fill")
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.green)
                                    .clipShape(Circle())
                                
                                Text("Overall Activity".localized)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedGoalId == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Individual Goals
                        ForEach(store.okrs) { okr in
                            Button(action: { selectedGoalId = okr.id }) {
                                HStack {
                                    Image(systemName: okr.icon)
                                        .foregroundColor(okr.healthColor)
                                        .frame(width: 32, height: 32)
                                        .background(okr.healthColor.opacity(0.1))
                                        .clipShape(Circle())
                                    
                                    Text(okr.title)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    if selectedGoalId == okr.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Activity Details".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done".localized) { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Data Logic
    
    struct HeatmapDay: Identifiable {
        var id = UUID()
        var date: Date
        var intensity: Int
    }
    
    struct MonthLabel: Hashable {
        let text: String
        let width: CGFloat
    }
    
    var heatmapData: [HeatmapDay] {
        let calendar = Calendar.current
        let today = Date()
        
        // We want to show roughly the last year or 6 months.
        // GitHub usually shows a full year.
        // Let's show ~6 months (26 weeks) for mobile fit, or maybe more.
        // Let's do 20 weeks as before but align to weeks.
        // Find the start date (Sunday) of 20 weeks ago.
        
        // Ensure we end on today (or end of this week)
        // Let's start from 180 days ago
        guard let baseDate = calendar.date(byAdding: .day, value: -180, to: today) else { return [] }
        
        // Find the start of the week for baseDate
        // Assuming Sunday start
        var startOfWeek: Date = Date()
        var interval: TimeInterval = 0
        _ = calendar.dateInterval(of: .weekOfYear, start: &startOfWeek, interval: &interval, for: baseDate)
        
        var days: [HeatmapDay] = []
        var currentDate = startOfWeek
        
        // Generate until we cover today
        while currentDate <= today {
            let intensity = calculateIntensity(for: currentDate)
            days.append(HeatmapDay(date: currentDate, intensity: intensity))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return days
    }
    
    var monthLabels: [MonthLabel] {
        // Calculate labels based on weeks
        // Each column is a week (width ~18px: 14 + 4 spacing)
        // We iterate through weeks and check if month changes
        let calendar = Calendar.current
        let data = heatmapData
        guard !data.isEmpty else { return [] }
        
        var labels: [MonthLabel] = []
        var currentMonth = -1
        var weekCount = 0
        var currentLabelWeeks = 0
        
        // Iterate by week (every 7 days)
        for i in stride(from: 0, to: data.count, by: 7) {
            let date = data[i].date
            let month = calendar.component(.month, from: date)
            
            if month != currentMonth {
                if currentMonth != -1 {
                    // Append previous month label
                    let monthName = DateFormatter().shortMonthSymbols[currentMonth - 1]
                    // Approximate width: weeks * (14+4)
                    labels.append(MonthLabel(text: monthName, width: CGFloat(currentLabelWeeks) * 18))
                }
                currentMonth = month
                currentLabelWeeks = 0
            }
            currentLabelWeeks += 1
            weekCount += 1
        }
        
        // Add last month
        if currentMonth != -1 {
            let monthName = DateFormatter().shortMonthSymbols[currentMonth - 1]
            labels.append(MonthLabel(text: monthName, width: CGFloat(currentLabelWeeks) * 18))
        }
        
        return labels
    }
    
    func dayLabel(for index: Int) -> String {
        // index 0..6
        // GitHub: Mon(1), Wed(3), Fri(5) are shown (indices relative to grid rows)
        // If row 0 is Sun, row 1 is Mon...
        // Let's check Calendar.current.firstWeekday.
        // Assuming standard Gregorian where 1=Sun.
        // If our grid fills column by column, row 0 is the first day of week.
        // If we started on Sunday (startOfWeek), then row 0 is Sunday.
        // Then Mon=1, Wed=3, Fri=5.
        let symbols = DateFormatter().shortWeekdaySymbols!
        // symbols usually ["Sun", "Mon", ...]
        return symbols[index]
    }
    
    func calculateIntensity(for date: Date) -> Int {
        let calendar = Calendar.current
        
        // Filter OKRs if selected
        let okrsToCheck = selectedGoalId == nil ? store.okrs : store.okrs.filter { $0.id == selectedGoalId }
        
        let completedCount = okrsToCheck.flatMap { $0.keyResults }
            .flatMap { $0.tasks }
            .filter { task in
                task.completedDates.contains { calendar.isDate($0, inSameDayAs: date) }
            }
            .count
        
        // Count activity logs on this date
        let logs = okrsToCheck.flatMap { $0.keyResults }
            .flatMap { $0.logs }
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .count
        
        let totalActivity = completedCount + logs
        
        if totalActivity == 0 { return 0 }
        if totalActivity <= 2 { return 1 }
        if totalActivity <= 4 { return 2 }
        if totalActivity <= 6 { return 3 }
        return 4
    }
    
    func color(for intensity: Int) -> Color {
        switch intensity {
        case 0: return Color.gray.opacity(0.15)
        case 1: return Color.green.opacity(0.3)
        case 2: return Color.green.opacity(0.5)
        case 3: return Color.green.opacity(0.7)
        case 4: return Color.green
        default: return Color.green
        }
    }
}
