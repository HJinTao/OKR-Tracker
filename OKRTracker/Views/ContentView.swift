import SwiftUI

struct ContentView: View {
    @StateObject var store = OKRStore()
    @ObservedObject var localization = LocalizationManager.shared
    
    var body: some View {
        TabView {
            DashboardView(store: store)
                .tabItem {
                    Label("Dashboard".localized, systemImage: "chart.bar.fill")
                }
            
            GoalListView(store: store)
                .tabItem {
                    Label("Goals".localized, systemImage: "target")
                }
            
            DailyTasksView(store: store)
                .tabItem {
                    Label("Daily Plan".localized, systemImage: "list.bullet.rectangle.portrait.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings".localized, systemImage: "gear")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
