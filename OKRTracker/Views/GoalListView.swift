import SwiftUI

struct GoalListView: View {
    @ObservedObject var store: OKRStore
    @ObservedObject var localization = LocalizationManager.shared
    @State private var showingAddOKR = false
    @State private var showArchived = false
    
    // Delete Confirmation
    @State private var showingDeleteAlert = false
    @State private var deleteOffsets: IndexSet?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                if store.okrs.isEmpty && !showArchived {
                    EmptyStateView(showingAddOKR: $showingAddOKR)
                } else {
                    List {
                        ForEach($store.okrs) { $okr in
                            if okr.isArchived == showArchived {
                                ZStack {
                                    NavigationLink(destination: OKRDetailView(okr: $okr)) {
                                        EmptyView()
                                    }
                                    .opacity(0)
                                    
                                    OKRCardView(okr: okr)
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            }
                        }
                        .onDelete(perform: confirmDelete)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Goals".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Menu {
                            Picker("Language", selection: $localization.currentLanguage) {
                                ForEach(LocalizationManager.Language.allCases) { lang in
                                    Text(lang.rawValue).tag(lang)
                                }
                            }
                        } label: {
                            Image(systemName: "globe")
                                .font(.system(size: 20))
                        }
                        
                        Button(action: { showArchived.toggle() }) {
                            Image(systemName: showArchived ? "archivebox.fill" : "archivebox")
                                .font(.system(size: 20))
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddOKR = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddOKR) {
                AddOKRView(store: store)
            }
            .alert("Delete Goal".localized, isPresented: $showingDeleteAlert) {
                Button("Cancel".localized, role: .cancel) {
                    deleteOffsets = nil
                }
                Button("Delete".localized, role: .destructive) {
                    if let offsets = deleteOffsets {
                        store.deleteOKR(at: offsets)
                    }
                    deleteOffsets = nil
                }
            } message: {
                Text("Are you sure you want to delete this goal? This action cannot be undone.".localized)
            }
        }
    }
    
    private func confirmDelete(offsets: IndexSet) {
        deleteOffsets = offsets
        showingDeleteAlert = true
    }
}

struct EmptyStateView: View {
    @Binding var showingAddOKR: Bool
    @ObservedObject var localization = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            Text("No OKRs yet".localized)
                .font(.title3.bold())
                .foregroundColor(.secondary)
            Text("Set your first objective to get started".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: { showingAddOKR = true }) {
                Text("Create OKR".localized)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

struct OKRCardView: View {
    let okr: OKR
    @ObservedObject var localization = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Icon added here
                Image(systemName: okr.icon)
                    .font(.system(size: 24))
                    .foregroundColor(okr.healthColor)
                    .frame(width: 32, height: 32)
                    .background(okr.healthColor.opacity(0.1))
                    .clipShape(Circle())
                
                Text(okr.title)
                    .font(.system(.title3, design: .rounded))
                    .bold()
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Spacer()
                
                StatusBadge(status: okr.health)
            }
            
            if !okr.description.isEmpty {
                Text(okr.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Progress".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .frame(width: geometry.size.width, height: 6)
                                .opacity(0.1)
                                .foregroundColor(.blue)
                            
                            Rectangle()
                                .frame(width: min(CGFloat(okr.progress) * geometry.size.width, geometry.size.width), height: 6)
                                .foregroundColor(okr.healthColor)
                        }
                        .cornerRadius(3)
                    }
                    .frame(height: 6)
                }
                
                Text("\(Int(okr.progress * 100))%")
                    .font(.system(.caption, design: .monospaced))
                    .bold()
                    .foregroundColor(okr.healthColor)
                    .frame(width: 40, alignment: .trailing)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .opacity(okr.isArchived ? 0.6 : 1.0)
    }
}

struct StatusBadge: View {
    let status: OKRHealth
    @ObservedObject var localization = LocalizationManager.shared
    
    var body: some View {
        Text(status.localized)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor.opacity(0.15))
            .foregroundColor(backgroundColor)
            .cornerRadius(8)
    }
    
    var backgroundColor: Color {
        switch status {
        case .onTrack: return .blue
        case .atRisk: return .orange
        case .offTrack: return .red
        case .completed: return .green
        }
    }
}
