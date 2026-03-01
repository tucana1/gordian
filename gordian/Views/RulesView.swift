import SwiftUI

struct RulesView: View {
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @State private var showingAddRule = false
    @State private var ruleToEdit: ScreenTimeRule?

    var body: some View {
        NavigationView {
            List {
                if screenTimeManager.rules.isEmpty {
                    if #available(iOS 17.0, *) {
                        ContentUnavailableView(
                            "No Rules",
                            systemImage: "shield.slash",
                            description: Text("Add a rule to start blocking apps")
                        )
                    } else {
                        // Fallback on earlier versions
                    }
                } else {
                    ForEach($screenTimeManager.rules) { $rule in
                        RuleRow(rule: $rule, onTap: { ruleToEdit = rule })
                    }
                    .onDelete { offsets in
                        screenTimeManager.deleteRule(at: offsets)
                    }
                }
            }
            .navigationTitle("Rules")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddRule = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddRule) {
                AddRuleView(rule: nil)
            }
            .sheet(item: $ruleToEdit) { rule in
                AddRuleView(rule: rule)
            }
        }
    }
}

struct RuleRow: View {
    @Binding var rule: ScreenTimeRule
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    var onTap: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(rule.name)
                    .font(.headline)
                let appCount = rule.blockedApps.applicationTokens.count
                let catCount = rule.blockedApps.categoryTokens.count
                Text("\(appCount) app\(appCount == 1 ? "" : "s"), \(catCount) categor\(catCount == 1 ? "y" : "ies")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if rule.dailyLimitMinutes > 0 {
                    Text("\(rule.dailyLimitMinutes) min/day limit")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("Always blocked")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            Spacer()
            Toggle("", isOn: $rule.isEnabled)
                .onChange(of: rule.isEnabled) { _ in
                    screenTimeManager.updateRule(rule)
                }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

#Preview {
    RulesView()
        .environmentObject(ScreenTimeManager.shared)
}
