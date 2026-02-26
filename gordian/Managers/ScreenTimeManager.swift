import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import Combine

@MainActor
class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()

    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var rules: [ScreenTimeRule] = []

    private let center = AuthorizationCenter.shared
    private let store = ManagedSettingsStore()
    private let rulesKey = "gordian.screentime.rules"

    enum AuthorizationStatus {
        case notDetermined, authorized, denied
    }

    private init() {
        loadRules()
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
            authorizationStatus = .authorized
            applyRules()
        } catch {
            authorizationStatus = .denied
            print("FamilyControls authorization error: \(error)")
        }
    }

    // MARK: - Rules Persistence

    func loadRules() {
        guard let data = UserDefaults.standard.data(forKey: rulesKey),
              let decoded = try? JSONDecoder().decode([ScreenTimeRule].self, from: data) else {
            rules = []
            return
        }
        rules = decoded
    }

    func saveRules() {
        do {
            let data = try JSONEncoder().encode(rules)
            UserDefaults.standard.set(data, forKey: rulesKey)
        } catch {
            print("Gordian: failed to encode rules – \(error)")
        }
    }

    func addRule(_ rule: ScreenTimeRule) {
        rules.append(rule)
        saveRules()
        applyRules()
    }

    func updateRule(_ rule: ScreenTimeRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
            saveRules()
            applyRules()
        }
    }

    func deleteRule(at offsets: IndexSet) {
        rules.remove(atOffsets: offsets)
        saveRules()
        applyRules()
    }

    // MARK: - Apply Rules

    func applyRules() {
        // Collect all blocked apps from enabled rules
        var combinedSelection = FamilyActivitySelection()
        var allApplications: Set<ApplicationToken> = []
        var allCategories: Set<ActivityCategoryToken> = []
        var allWebDomains: Set<WebDomainToken> = []

        for rule in rules where rule.isEnabled {
            allApplications.formUnion(rule.blockedApps.applicationTokens)
            allCategories.formUnion(rule.blockedApps.categoryTokens)
            allWebDomains.formUnion(rule.blockedApps.webDomainTokens)
        }

        combinedSelection.applicationTokens = allApplications
        combinedSelection.categoryTokens = allCategories
        combinedSelection.webDomainTokens = allWebDomains

        store.shield.applications = allApplications.isEmpty ? nil : allApplications
        store.shield.applicationCategories = allCategories.isEmpty ? nil : ShieldSettings.ActivityCategoryPolicy.specific(allCategories)
        store.shield.webDomains = allWebDomains.isEmpty ? nil : allWebDomains
    }

    // MARK: - Unlock

    func unlock(duration: TimeInterval) {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        // Re-locking after duration is handled by UnlockManager.
    }

    func reapplyRules() {
        applyRules()
    }
}
