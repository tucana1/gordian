import Foundation
import FamilyControls

struct ScreenTimeRule: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var blockedApps: FamilyActivitySelection
    var dailyLimitMinutes: Int // 0 = block always
    var isEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, blockedApps, dailyLimitMinutes, isEnabled
    }

    init(id: UUID = UUID(), name: String, blockedApps: FamilyActivitySelection = FamilyActivitySelection(), dailyLimitMinutes: Int = 0, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.blockedApps = blockedApps
        self.dailyLimitMinutes = dailyLimitMinutes
        self.isEnabled = isEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        dailyLimitMinutes = try container.decode(Int.self, forKey: .dailyLimitMinutes)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        if let appsData = try? container.decode(Data.self, forKey: .blockedApps),
           let apps = try? JSONDecoder().decode(FamilyActivitySelection.self, from: appsData) {
            blockedApps = apps
        } else {
            blockedApps = FamilyActivitySelection()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(dailyLimitMinutes, forKey: .dailyLimitMinutes)
        try container.encode(isEnabled, forKey: .isEnabled)
        if let appsData = try? JSONEncoder().encode(blockedApps) {
            try container.encode(appsData, forKey: .blockedApps)
        }
    }
}
