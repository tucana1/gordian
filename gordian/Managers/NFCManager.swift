import Foundation
import CoreNFC

class NFCManager: NSObject, ObservableObject, NFCTagReaderSessionDelegate {
    static let shared = NFCManager()

    var onTagRead: ((String) -> Void)?
    private var session: NFCTagReaderSession?

    private override init() {}

    func startReading(onTagRead: @escaping (String) -> Void) {
        guard NFCTagReaderSession.readingAvailable else {
            print("NFC not available on this device")
            return
        }
        self.onTagRead = onTagRead
        session = NFCTagReaderSession(pollingOption: [.iso14443, .iso15693, .iso18092], delegate: self, queue: .main)
        session?.alertMessage = "Hold your NFC tag near the top of your iPhone"
        session?.begin()
    }

    func stopReading() {
        session?.invalidate()
        session = nil
    }

    // MARK: - NFCTagReaderSessionDelegate

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        let nfcError = error as? NFCReaderError
        if nfcError?.code != .readerSessionInvalidationErrorUserCanceled {
            print("NFC session error: \(error.localizedDescription)")
        }
        self.session = nil
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let firstTag = tags.first else { return }

        session.connect(to: firstTag) { [weak self] error in
            if let error {
                session.invalidate(errorMessage: "Connection failed: \(error.localizedDescription)")
                return
            }

            let uid = self?.extractUID(from: firstTag) ?? ""
            if uid.isEmpty {
                session.invalidate(errorMessage: "Could not read tag UID")
                return
            }

            session.alertMessage = "Tag read successfully!"
            session.invalidate()
            self?.onTagRead?(uid)
        }
    }

    private func extractUID(from tag: NFCTag) -> String {
        switch tag {
        case .miFare(let mifareTag):
            return mifareTag.identifier.map { String(format: "%02X", $0) }.joined()
        case .iso7816(let iso7816Tag):
            return iso7816Tag.identifier.map { String(format: "%02X", $0) }.joined()
        case .iso15693(let iso15693Tag):
            return iso15693Tag.identifier.map { String(format: "%02X", $0) }.joined()
        case .feliCa(let felicaTag):
            return felicaTag.currentIDm.map { String(format: "%02X", $0) }.joined()
        @unknown default:
            return ""
        }
    }
}
