import SwiftUI

struct ContentView: View {
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @EnvironmentObject var unlockManager: UnlockManager

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            RulesView()
                .tabItem {
                    Label("Rules", systemImage: "shield.fill")
                }

            UnlockView()
                .tabItem {
                    Label("Unlock", systemImage: "lock.open.fill")
                }

            SetupView()
                .tabItem {
                    Label("Setup", systemImage: "gearshape.fill")
                }

            SecureModeView()
                .tabItem {
                    Label("Secure", systemImage: "lock.shield.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ScreenTimeManager.shared)
        .environmentObject(UnlockManager.shared)
}
