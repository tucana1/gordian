import Foundation
import Combine

@MainActor
class UnlockManager: ObservableObject {
    static let shared = UnlockManager()

    @Published var unlockUntil: Date?
    private var reapplyTimer: Timer?

    var isUnlocked: Bool {
        guard let unlockUntil else { return false }
        return Date() < unlockUntil
    }

    private init() {}

    func unlock(for duration: TimeInterval) {
        unlockUntil = Date().addingTimeInterval(duration)
        ScreenTimeManager.shared.unlock(duration: duration)

        reapplyTimer?.invalidate()
        reapplyTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.unlockUntil = nil
            }
        }
    }

    func remainingTime() -> TimeInterval? {
        guard let unlockUntil, isUnlocked else { return nil }
        return unlockUntil.timeIntervalSinceNow
    }

    func lock() {
        reapplyTimer?.invalidate()
        unlockUntil = nil
        ScreenTimeManager.shared.reapplyRules()
    }
}
