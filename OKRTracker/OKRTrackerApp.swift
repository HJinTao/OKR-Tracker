import SwiftUI

@main
struct OKRTrackerApp: App {
    @AppStorage("appTheme") private var currentTheme: AppTheme = .system
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(currentTheme.colorScheme)
        }
    }
}
