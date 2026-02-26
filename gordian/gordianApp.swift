import SwiftUI
import FamilyControls

@main
struct GordianApp: App {
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @StateObject private var unlockManager = UnlockManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(screenTimeManager)
                .environmentObject(unlockManager)
                .task {
                    await screenTimeManager.requestAuthorization()
                }
        }
    }
}
