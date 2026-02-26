import SwiftUI
import FamilyControls

struct AddRuleView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var screenTimeManager: ScreenTimeManager

    var rule: ScreenTimeRule?

    @State private var name: String = ""
    @State private var selection: FamilyActivitySelection = FamilyActivitySelection()
    @State private var dailyLimitMinutes: Int = 0
    @State private var isEnabled: Bool = true
    @State private var showingActivityPicker = false

    var isEditing: Bool { rule != nil }

    var body: some View {
        NavigationView {
            Form {
                Section("Rule Name") {
                    TextField("e.g. Social Media", text: $name)
                }

                Section("Blocked Apps & Categories") {
                    Button {
                        showingActivityPicker = true
                    } label: {
                        HStack {
                            Text("Select Apps")
                            Spacer()
                            let count = selection.applicationTokens.count + selection.categoryTokens.count
                            Text("\(count) selected")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                }

                Section("Daily Time Limit") {
                    Stepper(value: $dailyLimitMinutes, in: 0...1440, step: 15) {
                        if dailyLimitMinutes == 0 {
                            Text("Always blocked")
                        } else {
                            Text("\(dailyLimitMinutes) minutes per day")
                        }
                    }
                    Text("Set to 0 to block apps completely")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    Toggle("Enable Rule", isOn: $isEnabled)
                }
            }
            .navigationTitle(isEditing ? "Edit Rule" : "New Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .familyActivityPicker(isPresented: $showingActivityPicker, selection: $selection)
            .onAppear {
                if let rule {
                    name = rule.name
                    selection = rule.blockedApps
                    dailyLimitMinutes = rule.dailyLimitMinutes
                    isEnabled = rule.isEnabled
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if var existing = rule {
            existing.name = trimmedName
            existing.blockedApps = selection
            existing.dailyLimitMinutes = dailyLimitMinutes
            existing.isEnabled = isEnabled
            screenTimeManager.updateRule(existing)
        } else {
            let newRule = ScreenTimeRule(
                name: trimmedName,
                blockedApps: selection,
                dailyLimitMinutes: dailyLimitMinutes,
                isEnabled: isEnabled
            )
            screenTimeManager.addRule(newRule)
        }
        dismiss()
    }
}

#Preview {
    AddRuleView(rule: nil)
        .environmentObject(ScreenTimeManager.shared)
}
