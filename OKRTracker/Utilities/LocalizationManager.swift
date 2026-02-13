import Foundation
import Combine

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    enum Language: String, CaseIterable, Identifiable {
        case english = "English"
        case chinese = "中文"
        
        var id: String { self.rawValue }
    }
    
    @Published var currentLanguage: Language = .english {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selectedLanguage")
        }
    }
    
    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage"),
           let language = Language(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            // Default to system language if possible, otherwise English
            let systemLang = Locale.current.languageCode
            if systemLang == "zh" {
                self.currentLanguage = .chinese
            } else {
                self.currentLanguage = .english
            }
        }
    }
    
    func localized(_ key: String) -> String {
        guard let dict = translations[key] else { return key }
        return dict[currentLanguage] ?? key
    }
    
    private let translations: [String: [Language: String]] = [
        // Common
        "Cancel": [.english: "Cancel", .chinese: "取消"],
        "Save": [.english: "Save", .chinese: "保存"],
        "Add": [.english: "Add", .chinese: "添加"],
        "Update": [.english: "Update", .chinese: "更新"],
        "Details": [.english: "Details", .chinese: "详情"],
        "Delete": [.english: "Delete", .chinese: "删除"],
        "Edit": [.english: "Edit", .chinese: "编辑"],
        "Done": [.english: "Done", .chinese: "完成"],
        
        // ContentView
        "Goals": [.english: "Goals", .chinese: "目标"],
        "No OKRs yet": [.english: "No OKRs yet", .chinese: "暂无 OKR"],
        "Set your first objective to get started": [.english: "Set your first objective to get started", .chinese: "创建你的第一个目标"],
        "Create OKR": [.english: "Create OKR", .chinese: "创建 OKR"],
        "Progress": [.english: "Progress", .chinese: "进度"],
        "Show Archived": [.english: "Show Archived", .chinese: "显示已归档"],
        "Hide Archived": [.english: "Hide Archived", .chinese: "隐藏已归档"],
        
        // AddOKRView
        "New Objective": [.english: "New Objective", .chinese: "新建目标"],
        "Goal": [.english: "Goal", .chinese: "目标"],
        "Objective Title": [.english: "Objective Title", .chinese: "目标标题"],
        "Description (Optional)": [.english: "Description (Optional)", .chinese: "描述 (可选)"],
        "Target Date": [.english: "Target Date", .chinese: "目标日期"],
        "Key Results": [.english: "Key Results", .chinese: "关键结果"],
        "No key results added yet": [.english: "No key results added yet", .chinese: "暂无关键结果"],
        "Add Key Result": [.english: "Add Key Result", .chinese: "添加关键结果"],
        "Key results measure the progress towards your objective.": [.english: "Key results measure the progress towards your objective.", .chinese: "关键结果用于衡量目标的进度。"],
        "New Key Result": [.english: "New Key Result", .chinese: "新建关键结果"],
        "Basic Info": [.english: "Basic Info", .chinese: "基本信息"],
        "Title (e.g. Read Books)": [.english: "Title (e.g. Read Books)", .chinese: "标题 (例如: 阅读书籍)"],
        "Type": [.english: "Type", .chinese: "类型"],
        "Target": [.english: "Target", .chinese: "目标值"],
        "Target Value": [.english: "Target Value", .chinese: "目标数值"],
        "Unit": [.english: "Unit", .chinese: "单位"],
        "Value": [.english: "Value", .chinese: "数值"],
        "e.g. books": [.english: "e.g. books", .chinese: "例如: 本"],
        "Select Icon": [.english: "Select Icon", .chinese: "选择图标"],
        
        // OKRDetailView
        "Complete": [.english: "Complete", .chinese: "完成"],
        "Title": [.english: "Title", .chinese: "标题"],
        "Description": [.english: "Description", .chinese: "描述"],
        "Due Date": [.english: "Due Date", .chinese: "截止日期"],
        "No key results yet. Add one to track progress.": [.english: "No key results yet. Add one to track progress.", .chinese: "暂无关键结果，请添加以追踪进度。"],
        "KR Title": [.english: "KR Title", .chinese: "关键结果标题"],
        "Current Progress": [.english: "Current Progress", .chinese: "当前进度"],
        "Completed": [.english: "Completed", .chinese: "已完成"],
        "Not Done": [.english: "Not Done", .chinese: "未完成"],
        "History": [.english: "History", .chinese: "历史记录"],
        "Check-in": [.english: "Check-in", .chinese: "打卡"],
        "Update Progress": [.english: "Update Progress", .chinese: "更新进度"],
        "Current:": [.english: "Current:", .chinese: "当前:"],
        "New Value:": [.english: "New Value:", .chinese: "新值:"],
        "Note": [.english: "Note", .chinese: "备注"],
        "What did you achieve?": [.english: "What did you achieve?", .chinese: "完成了什么?"],
        "Progress update": [.english: "Progress update", .chinese: "进度更新"],
        "Quick update": [.english: "Quick update", .chinese: "快速更新"],
        "Marked as done": [.english: "Marked as done", .chinese: "标记为完成"],
        "Marked as not done": [.english: "Marked as not done", .chinese: "标记为未完成"],
        "Time Remaining": [.english: "Time Remaining", .chinese: "剩余时间"],
        "Time Elapsed": [.english: "Time Elapsed", .chinese: "已用时间"],
        "Archive Goal": [.english: "Archive Goal", .chinese: "归档目标"],
        "Unarchive Goal": [.english: "Unarchive Goal", .chinese: "取消归档"],
        "Weight": [.english: "Weight", .chinese: "权重"],
        "Progress Over Time": [.english: "Progress Over Time", .chinese: "进度曲线"],
        
        // KeyResultType
        "Number": [.english: "Number", .chinese: "数值"],
        "Percentage": [.english: "Percentage", .chinese: "百分比"],
        "Currency": [.english: "Currency", .chinese: "货币"],
        "Yes/No": [.english: "Yes/No", .chinese: "是/否"],
        
        // OKRHealth
        "On Track": [.english: "On Track", .chinese: "正常"],
        "At Risk": [.english: "At Risk", .chinese: "风险"],
        "Off Track": [.english: "Off Track", .chinese: "滞后"],
        // "Completed" is already defined above
        
        // Units
        "times": [.english: "times", .chinese: "次"],
        "Done_Unit": [.english: "Done", .chinese: "完成"], // specific context for boolean unit
        
        // New Dashboard & Planning Keys
        "Dashboard": [.english: "Dashboard", .chinese: "仪表盘"],
        "Daily Plan": [.english: "Daily Plan", .chinese: "每日计划"],
        "Overall Progress": [.english: "Overall Progress", .chinese: "总进度"],
        "Activity Heatmap": [.english: "Activity Heatmap", .chinese: "活跃热力图"],
        "Active Goals": [.english: "Active Goals", .chinese: "进行中目标"],
        "Completed Tasks": [.english: "Completed Tasks", .chinese: "已完成任务"],
        "Today's Tasks": [.english: "Today's Tasks", .chinese: "今日任务"],
        "No tasks for this day": [.english: "No tasks for this day", .chinese: "今日无任务"],
        "Task Details": [.english: "Task Details", .chinese: "任务详情"],
        "Task Title": [.english: "Task Title", .chinese: "任务标题"],
        "Add Task": [.english: "Add Task", .chinese: "添加任务"],
        "No planned tasks": [.english: "No planned tasks", .chinese: "暂无计划任务"],
        "Start:": [.english: "Start:", .chinese: "开始:"],
        "End:": [.english: "End:", .chinese: "结束:"],
        "Date": [.english: "Date", .chinese: "日期"],
        "Start Date": [.english: "Start Date", .chinese: "开始日期"],
        "Repeat": [.english: "Repeat", .chinese: "重复"],
        "No tasks": [.english: "No tasks", .chinese: "暂无任务"],
        
        // Recurrence
        "None": [.english: "None", .chinese: "不重复"],
        "Daily": [.english: "Daily", .chinese: "每天"],
        "Weekly": [.english: "Weekly", .chinese: "每周"],
        "Weekdays": [.english: "Weekdays", .chinese: "工作日"],
        
        "Weight (%)": [.english: "Weight (%)", .chinese: "权重 (%)"],
        "Weight (Value)": [.english: "Weight (Value)", .chinese: "权重 (分值)"],
        "Progress Details": [.english: "Progress Details", .chinese: "进度详情"],
        "Breakdown": [.english: "Breakdown", .chinese: "目标细分"],
        "Activity Details": [.english: "Activity Details", .chinese: "活跃详情"],
        "Overall Activity": [.english: "Overall Activity", .chinese: "总活跃度"],
        "Less": [.english: "Less", .chinese: "少"],
        "More": [.english: "More", .chinese: "多"],
        
        "Delete Goal": [.english: "Delete Goal", .chinese: "删除目标"],
        "Are you sure you want to delete this goal? This action cannot be undone.": [.english: "Are you sure you want to delete this goal? This action cannot be undone.", .chinese: "你确定要删除这个目标吗？此操作无法撤销。"],
        "Delete Key Result": [.english: "Delete Key Result", .chinese: "删除关键结果"],
        "Delete Key Result?": [.english: "Delete Key Result?", .chinese: "删除关键结果?"],
        "This action cannot be undone.": [.english: "This action cannot be undone.", .chinese: "此操作无法撤销。"],
        "Value Contribution": [.english: "Value Contribution", .chinese: "数值贡献"],
        "How much this task adds to progress": [.english: "How much this task adds to progress", .chinese: "此任务对进度的贡献值"],
        "Archived": [.english: "Archived", .chinese: "已归档"],
        "Edit Task": [.english: "Edit Task", .chinese: "编辑任务"],
    ]
}

extension String {
    var localized: String {
        LocalizationManager.shared.localized(self)
    }
}
