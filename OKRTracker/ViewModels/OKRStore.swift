import Foundation
import Combine
import SwiftUI

class OKRStore: ObservableObject {
    @Published var okrs: [OKR] = [] {
        didSet {
            // Auto-archive completed OKRs
            var updated = false
            for i in 0..<okrs.count {
                if okrs[i].progress >= 1.0 && !okrs[i].isArchived {
                    okrs[i].isArchived = true
                    updated = true
                }
            }
            
            // If we updated okrs, this didSet will be called again recursively.
            // To prevent double saving or infinite loops if logic was different, we rely on the check above.
            // The recursion will stop because isArchived is now true.
            
            save()
        }
    }
    
    private let fileName = "okrs.json"
    
    init() {
        load()
        // If empty, add some sample data for demonstration
        if okrs.isEmpty {
            addSampleData()
        }
    }
    
    func addOKR(_ okr: OKR) {
        okrs.append(okr)
    }
    
    func deleteOKR(at offsets: IndexSet) {
        okrs.remove(atOffsets: offsets)
    }
    
    func updateKeyResult(okrID: UUID, krID: UUID, newValue: Double, logMessage: String? = nil) {
        if let okrIndex = okrs.firstIndex(where: { $0.id == okrID }) {
            if let krIndex = okrs[okrIndex].keyResults.firstIndex(where: { $0.id == krID }) {
                let oldValue = okrs[okrIndex].keyResults[krIndex].currentValue
                okrs[okrIndex].keyResults[krIndex].currentValue = newValue
                
                // Add log if requested or if value changed significantly
                if let message = logMessage, !message.isEmpty {
                    let log = ActivityLog(
                        id: UUID(),
                        date: Date(),
                        message: message,
                        previousValue: oldValue,
                        newValue: newValue
                    )
                    okrs[okrIndex].keyResults[krIndex].logs.insert(log, at: 0) // Newest first
                } else if abs(newValue - oldValue) > 0.001 {
                    // Auto-log significant changes without message
                    let log = ActivityLog(
                        id: UUID(),
                        date: Date(),
                        message: "Update progress",
                        previousValue: oldValue,
                        newValue: newValue
                    )
                    okrs[okrIndex].keyResults[krIndex].logs.insert(log, at: 0)
                }
            }
        }
    }
    
    // MARK: - Persistence
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private func load() {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        if let data = try? Data(contentsOf: url) {
            if let decoded = try? JSONDecoder().decode([OKR].self, from: data) {
                self.okrs = decoded
                return
            }
        }
    }
    
    private func save() {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            let encoded = try JSONEncoder().encode(okrs)
            try encoded.write(to: url)
        } catch {
            print("Failed to save okrs: \(error.localizedDescription)")
        }
    }
    
    private func addSampleData() {
        // Example 1: Physical Fitness (Mixed types)
        let kr1 = KeyResult(
            id: UUID(),
            title: "Run weekly",
            type: .number,
            currentValue: 1,
            targetValue: 3,
            unit: "times"
        )
        let kr2 = KeyResult(
            id: UUID(),
            title: "Lose weight",
            type: .number,
            currentValue: 0.5,
            targetValue: 5,
            unit: "kg"
        )
        let okr1 = OKR(
            id: UUID(),
            title: "Improve Physical Fitness",
            description: "Prepare for the summer marathon",
            keyResults: [kr1, kr2],
            startDate: Date().addingTimeInterval(-86400 * 5),
            dueDate: Date().addingTimeInterval(86400 * 30),
            isCompleted: false
        )
        
        // Example 2: Learning (Boolean and Percentage)
        let kr3 = KeyResult(
            id: UUID(),
            title: "Finish Swift Course",
            type: .percentage,
            currentValue: 25,
            targetValue: 100,
            unit: "%"
        )
        let kr4 = KeyResult(
            id: UUID(),
            title: "Publish App to App Store",
            type: .boolean,
            currentValue: 0,
            targetValue: 1,
            unit: "Done"
        )
        let okr2 = OKR(
            id: UUID(),
            title: "Master iOS Development",
            description: "Learn SwiftUI and Combine deeply",
            keyResults: [kr3, kr4],
            startDate: Date().addingTimeInterval(-86400 * 10),
            dueDate: Date().addingTimeInterval(86400 * 60),
            isCompleted: false
        )
        
        // Example 3: Business (Currency)
        let kr5 = KeyResult(
            id: UUID(),
            title: "Achieve Q1 Revenue",
            type: .currency,
            currentValue: 5000,
            targetValue: 20000,
            unit: "USD"
        )
        let okr3 = OKR(
            id: UUID(),
            title: "Grow Business Revenue",
            description: "Focus on new customer acquisition",
            keyResults: [kr5],
            startDate: Date().addingTimeInterval(-86400 * 15),
            dueDate: Date().addingTimeInterval(86400 * 90),
            isCompleted: false
        )
        
        self.okrs = [okr1, okr2, okr3]
    }
}
