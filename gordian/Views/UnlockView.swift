import SwiftUI

struct UnlockView: View {
    @EnvironmentObject var unlockManager: UnlockManager
    @State private var mechanisms: [UnlockMechanism] = []
    @State private var showingQRScanner = false
    @State private var isReadingNFC = false
    @State private var unlockDurationMinutes: Int = 30
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var nfcTimeoutItem: DispatchWorkItem?

    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if unlockManager.isUnlocked {
                    unlockedBanner
                }

                Form {
                    Section("Unlock Duration") {
                        Picker("Duration", selection: $unlockDurationMinutes) {
                            Text("5 minutes").tag(5)
                            Text("15 minutes").tag(15)
                            Text("30 minutes").tag(30)
                            Text("1 hour").tag(60)
                            Text("2 hours").tag(120)
                        }
                        .pickerStyle(.menu)
                    }

                    Section("Scan to Unlock") {
                        Button {
                            showingQRScanner = true
                        } label: {
                            Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                                .font(.headline)
                        }

                        Button {
                            startNFCReading()
                        } label: {
                            Label(
                                isReadingNFC ? "Reading NFC…" : "Tap NFC Tag (Amiibo)",
                                systemImage: "wave.3.right"
                            )
                            .font(.headline)
                        }
                        .disabled(isReadingNFC)
                    }

                    if mechanisms.isEmpty {
                        Section {
                            Label("No unlock keys configured", systemImage: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("Go to Setup tab to add QR codes or NFC tags")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if unlockManager.isUnlocked {
                        Section {
                            Button(role: .destructive) {
                                unlockManager.lock()
                            } label: {
                                Label("Lock Now", systemImage: "lock.fill")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Unlock")
            .sheet(isPresented: $showingQRScanner) {
                NavigationView {
                    QRScannerView { code in
                        showingQRScanner = false
                        handleScannedValue(code)
                    }
                    .ignoresSafeArea()
                    .navigationTitle("Scan QR Code")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingQRScanner = false }
                        }
                    }
                }
            }
            .alert("Invalid Key", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .alert("Unlocked!", isPresented: $showSuccess) {
                Button("OK") {}
            } message: {
                Text("Apps unlocked for \(unlockDurationMinutes) minutes.")
            }
            .onAppear { loadMechanisms() }
        }
    }

    private var unlockedBanner: some View {
        HStack {
            Image(systemName: "lock.open.fill")
                .foregroundColor(.green)
            Text("Unlocked until \(formattedUnlockTime())")
                .font(.subheadline)
                .foregroundColor(.green)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color.green.opacity(0.15))
    }

    private func loadMechanisms() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([UnlockMechanism].self, from: data) else { return }
        mechanisms = decoded
    }

    private func startNFCReading() {
        isReadingNFC = true
        NFCManager.shared.startReading { uid in
            DispatchQueue.main.async {
                self.nfcTimeoutItem?.cancel()
                self.nfcTimeoutItem = nil
                isReadingNFC = false
                handleScannedValue(uid)
            }
        }
        // Cancel the NFC flag if the session times out without a read
        let workItem = DispatchWorkItem {
            isReadingNFC = false
            nfcTimeoutItem = nil
        }
        nfcTimeoutItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: workItem)
    }

    private func handleScannedValue(_ value: String) {
        let matched = mechanisms.first { $0.identifier == value }
        if matched != nil {
            let duration = TimeInterval(unlockDurationMinutes * 60)
            unlockManager.unlock(for: duration)
            showSuccess = true
        } else {
            errorMessage = "This key is not registered. Add it in the Setup tab first."
            showError = true
        }
    }

    private func formattedUnlockTime() -> String {
        guard let date = unlockManager.unlockUntil else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    UnlockView()
        .environmentObject(UnlockManager.shared)
}
