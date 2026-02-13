import SwiftUI

// App Theme Enum
enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { self.rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct SettingsView: View {
    @ObservedObject var localization = LocalizationManager.shared
    @AppStorage("appTheme") private var currentTheme: AppTheme = .system
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance".localized)) {
                    Picker("Appearance".localized, selection: $currentTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.rawValue.localized).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Language".localized)) {
                    Picker("Language".localized, selection: $localization.currentLanguage) {
                        ForEach(LocalizationManager.Language.allCases) { lang in
                            Text(lang.rawValue).tag(lang)
                        }
                    }
                }
                
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text("OKR Tracker")
                                .font(.headline)
                            Text("Version 1.0.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("Settings".localized)
        }
    }
}
