import Foundation

enum UnlockType: String, Codable, CaseIterable {
    case qrCode = "QR Code"
    case nfc = "NFC (Amiibo)"
}

struct UnlockMechanism: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var type: UnlockType
    var identifier: String // QR code content or NFC tag UID

    init(id: UUID = UUID(), name: String, type: UnlockType, identifier: String) {
        self.id = id
        self.name = name
        self.type = type
        self.identifier = identifier
    }
}
