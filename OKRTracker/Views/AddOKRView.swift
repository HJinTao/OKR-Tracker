import SwiftUI

struct AddOKRView: View {
    @ObservedObject var store: OKRStore
    @Environment(\.dismiss) var dismiss
    @ObservedObject var localization = LocalizationManager.shared
    
    @State private var title = ""
    @State private var description = ""
    @State private var icon = "target"
    @State private var dueDate = Date().addingTimeInterval(86400 * 30)
    @State private var keyResults: [KeyResult] = []
    
    @State private var showingIconPicker = false
    
    // Key Result Temp State
    @State private var showingAddKR = false
    @State private var tempKRTitle = ""
    @State private var tempKRType: KeyResultType = .number
    @State private var tempKRTarget = 10.0
    @State private var tempKRUnit = "times"
    
    let availableIcons = [
        "target", "star.fill", "heart.fill", "flame.fill", "bolt.fill",
        "leaf.fill", "drop.fill", "book.fill", "graduationcap.fill", "briefcase.fill",
        "building.2.fill", "cart.fill", "creditcard.fill", "chart.bar.fill", "chart.pie.fill",
        "airplane", "car.fill", "figure.run", "dumbbell.fill", "gamecontroller.fill"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Spacer()
                        Button(action: { showingIconPicker = true }) {
                            ZStack {
                                Circle()
                                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                                    .frame(width: 80, height: 80)
                                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                
                                Image(systemName: icon)
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                            }
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    
                    TextField("Objective Title".localized, text: $title)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    TextField("Description (Optional)".localized, text: $description)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    DatePicker("Target Date".localized, selection: $dueDate, displayedComponents: .date)
                } header: {
                    Text("Goal".localized)
                }
                
                Section {
                    if keyResults.isEmpty {
                        Text("No key results added yet".localized)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    
                    ForEach(keyResults) { kr in
                        HStack {
                            Image(systemName: kr.type.icon)
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(kr.title)
                                    .font(.headline)
                                HStack {
                                    if kr.type == .boolean {
                                        Text("\("Target".localized): \("Done_Unit".localized)")
                                    } else {
                                        Text("\("Target".localized): \(kr.targetValue, specifier: "%.1f") \(kr.unit.localized)")
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteKR)
                    
                    Button(action: {
                        resetTempKR()
                        showingAddKR = true
                    }) {
                        Label("Add Key Result".localized, systemImage: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                } header: {
                    Text("Key Results".localized)
                } footer: {
                    Text("Key results measure the progress towards your objective.".localized)
                }
            }
            .navigationTitle("New Objective".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save".localized) { saveOKR() }
                        .disabled(title.isEmpty)
                        .font(.headline)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                NavigationView {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 20) {
                            ForEach(availableIcons, id: \.self) { iconName in
                                Button(action: {
                                    self.icon = iconName
                                    showingIconPicker = false
                                }) {
                                    Image(systemName: iconName)
                                        .font(.system(size: 30))
                                        .frame(width: 60, height: 60)
                                        .background(self.icon == iconName ? Color.blue.opacity(0.1) : Color.clear)
                                        .foregroundColor(self.icon == iconName ? .blue : .primary)
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
            .sheet(isPresented: $showingAddKR) {
                NavigationView {
                    Form {
                        Section("Basic Info".localized) {
                            TextField("Title (e.g. Read Books)".localized, text: $tempKRTitle)
                            
                            Picker("Type".localized, selection: $tempKRType) {
                                ForEach(KeyResultType.allCases) { type in
                                    Label(type.localized, systemImage: type.icon)
                                        .tag(type)
                                }
                            }
                            .onChange(of: tempKRType) { _, newType in
                                updateDefaults(for: newType)
                            }
                        }
                        
                        if tempKRType != .boolean {
                            Section("Target".localized) {
                                HStack {
                                    Text("Target Value".localized)
                                    Spacer()
                                    TextField("Value".localized, value: $tempKRTarget, formatter: NumberFormatter())
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 100)
                                }
                                
                                HStack {
                                    Text("Unit".localized)
                                    Spacer()
                                    TextField("e.g. books".localized, text: $tempKRUnit)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 150)
                                }
                            }
                        }
                    }
                    .navigationTitle("New Key Result".localized)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel".localized) { showingAddKR = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add".localized) {
                                addKeyResult()
                            }
                            .disabled(tempKRTitle.isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
    
    private func updateDefaults(for type: KeyResultType) {
        switch type {
        case .number:
            tempKRUnit = "times"
            tempKRTarget = 10
        case .percentage:
            tempKRUnit = "%"
            tempKRTarget = 100
        case .currency:
            tempKRUnit = "$"
            tempKRTarget = 1000
        case .boolean:
            tempKRUnit = "Done_Unit" // Will be localized when displayed
            tempKRTarget = 1
        }
    }
    
    private func resetTempKR() {
        tempKRTitle = ""
        tempKRType = .number
        tempKRTarget = 10.0
        tempKRUnit = "times"
    }
    
    private func deleteKR(at offsets: IndexSet) {
        keyResults.remove(atOffsets: offsets)
    }
    
    private func addKeyResult() {
        let newKR = KeyResult(
            id: UUID(),
            title: tempKRTitle,
            type: tempKRType,
            currentValue: 0,
            targetValue: tempKRType == .boolean ? 1.0 : tempKRTarget,
            unit: tempKRUnit
        )
        keyResults.append(newKR)
        showingAddKR = false
    }
    
    private func saveOKR() {
        let newOKR = OKR(
            id: UUID(),
            title: title,
            description: description,
            icon: icon,
            keyResults: keyResults,
            startDate: Date(), // Explicitly set startDate to now
            dueDate: dueDate,
            isCompleted: false
        )
        store.addOKR(newOKR)
        dismiss()
    }
}
