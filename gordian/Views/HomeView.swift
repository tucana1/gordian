import SwiftUI

struct HomeView: View {
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @EnvironmentObject var unlockManager: UnlockManager
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        NavigationView {
            List {
                // Status Section
                Section {
                    HStack {
                        Image(systemName: unlockManager.isUnlocked ? "lock.open.fill" : "lock.fill")
                            .foregroundColor(unlockManager.isUnlocked ? .green : .red)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(unlockManager.isUnlocked ? "Apps Unlocked" : "Apps Restricted")
                                .font(.headline)
                            if unlockManager.isUnlocked {
                                Text("Locks in \(formatTime(timeRemaining))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Scan QR or NFC to unlock")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        if unlockManager.isUnlocked {
                            Button("Lock Now") {
                                unlockManager.lock()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Status")
                }

                // Active Rules Section
                Section {
                    let enabledRules = screenTimeManager.rules.filter { $0.isEnabled }
                    if enabledRules.isEmpty {
                        Text("No active rules")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(enabledRules) { rule in
                            HStack {
                                Image(systemName: "shield.fill")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(rule.name)
                                        .font(.headline)
                                    Text(ruleSummary(rule))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Active Rules (\(screenTimeManager.rules.filter { $0.isEnabled }.count))")
                }

                // Authorization section
                if screenTimeManager.authorizationStatus == .denied {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Screen Time permission required", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    } header: {
                        Text("Permissions")
                    }
                }
            }
            .navigationTitle("Gordian")
            .onAppear { startTimer() }
            .onDisappear { stopTimer() }
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeRemaining = unlockManager.remainingTime() ?? 0
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func ruleSummary(_ rule: ScreenTimeRule) -> String {
        let appCount = rule.blockedApps.applicationTokens.count
        if rule.dailyLimitMinutes == 0 {
            return "\(appCount) app\(appCount == 1 ? "" : "s") – always blocked"
        } else {
            return "\(appCount) app\(appCount == 1 ? "" : "s") – \(rule.dailyLimitMinutes) min/day"
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(ScreenTimeManager.shared)
        .environmentObject(UnlockManager.shared)
}
