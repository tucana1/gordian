import DeviceActivity
import ManagedSettings

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // Called when a monitored activity interval starts (e.g. beginning of day)
        // Re-apply restrictions
        applyRestrictions()
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        // Called when a monitored interval ends
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        // Called when a usage threshold is hit — apply the shield
        applyRestrictions()
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
    }

    private func applyRestrictions() {
        // Read stored rule data from shared UserDefaults (App Group).
        // NOTE: The App Group "group.com.gordian.app" must be configured in both
        // the main app and this extension's entitlements/provisioning profile.
        // The storage key below must match ScreenTimeManager.rulesKey in the main app.
        guard let defaults = UserDefaults(suiteName: "group.com.gordian.app") else {
            print("Gordian DeviceActivity: App Group UserDefaults unavailable – restrictions not applied")
            return
        }
        guard let data = defaults.data(forKey: "gordian.screentime.rules"),
              let rules = try? JSONDecoder().decode([ScreenTimeRuleSnapshot].self, from: data) else {
            return
        }

        var allApplications: Set<ApplicationToken> = []

        for rule in rules where rule.isEnabled {
            allApplications.formUnion(rule.applicationTokens)
        }

        store.shield.applications = allApplications.isEmpty ? nil : allApplications
    }
}

// Lightweight snapshot for inter-process rule sharing
struct ScreenTimeRuleSnapshot: Codable {
    var isEnabled: Bool
    var applicationTokens: Set<ApplicationToken>

    enum CodingKeys: String, CodingKey {
        case isEnabled, applicationTokensData
    }

    init(isEnabled: Bool, applicationTokens: Set<ApplicationToken>) {
        self.isEnabled = isEnabled
        self.applicationTokens = applicationTokens
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        if let data = try? container.decode(Data.self, forKey: .applicationTokensData),
           let tokens = try? JSONDecoder().decode(Set<ApplicationToken>.self, from: data) {
            applicationTokens = tokens
        } else {
            applicationTokens = []
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isEnabled, forKey: .isEnabled)
        if let data = try? JSONEncoder().encode(applicationTokens) {
            try container.encode(data, forKey: .applicationTokensData)
        }
    }
}
