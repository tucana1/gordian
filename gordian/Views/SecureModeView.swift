import SwiftUI
import CryptoKit

struct SecureModeView: View {
    @AppStorage("gordian.secureMode.enabled") private var secureModeEnabled = false
    /// Stores a hex-encoded SHA-256 hash of the PIN (never the raw PIN)
    @AppStorage("gordian.secureMode.pinHash") private var storedPINHash = ""
    @AppStorage("gordian.secureMode.requireUnlockToDisable") private var requireUnlockToDisable = true

    @State private var showingPINSetup = false
    @State private var enteredPIN = ""
    @State private var confirmPIN = ""
    @State private var pinError = ""
    @State private var showDisableConfirmation = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Secure Mode")
                                .font(.headline)
                            Text(secureModeEnabled ? "Active – app is protected" : "Inactive")
                                .font(.caption)
                                .foregroundColor(secureModeEnabled ? .green : .secondary)
                        }
                        Spacer()
                        Image(systemName: secureModeEnabled ? "lock.shield.fill" : "lock.shield")
                            .font(.title2)
                            .foregroundColor(secureModeEnabled ? .green : .secondary)
                    }
                }

                if secureModeEnabled {
                    Section("Protections Active") {
                        Label("PIN required to disable Gordian", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Label("Rules persist across restarts", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Label("Restrictions re-apply automatically", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }

                    Section {
                        Toggle("Require physical key to disable", isOn: $requireUnlockToDisable)
                        Text("If enabled, you must scan a registered QR or NFC key before disabling Secure Mode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Section {
                        Button("Change PIN") {
                            showingPINSetup = true
                        }
                        Button("Disable Secure Mode", role: .destructive) {
                            showDisableConfirmation = true
                        }

                    }
                } else {
                    Section {
                        Text("When Secure Mode is enabled, a PIN is required to change or disable these restrictions, making it harder for the user to bypass screentime rules.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }

                    Section {
                        Button("Enable Secure Mode") {
                            showingPINSetup = true
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                    }
                }

                Section("About Deletion Prevention") {
                    Text("To fully prevent app deletion, enable Screen Time restrictions in iOS Settings > Screen Time > Content & Privacy Restrictions and set a Screen Time passcode.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Open Screen Time Settings") {
                        if let url = URL(string: "App-prefs:SCREEN_TIME") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.caption)
                }
            }
            .navigationTitle("Secure Mode")
            .sheet(isPresented: $showingPINSetup) {
                PINSetupView(
                    storedPINHash: $storedPINHash,
                    secureModeEnabled: $secureModeEnabled
                )
            }
            .confirmationDialog(
                "Disable Secure Mode?",
                isPresented: $showDisableConfirmation,
                titleVisibility: .visible
            ) {
                Button("Disable", role: .destructive) {
                    secureModeEnabled = false
                    storedPINHash = ""
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove PIN protection. Rules will remain active.")
            }
        }
    }
}

// MARK: - PIN Setup View

struct PINSetupView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var storedPINHash: String
    @Binding var secureModeEnabled: Bool

    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Set PIN") {
                    SecureField("Enter 4+ digit PIN", text: $pin)
                        .keyboardType(.numberPad)
                    SecureField("Confirm PIN", text: $confirmPin)
                        .keyboardType(.numberPad)
                }

                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Text("Remember this PIN — it's required to disable Secure Mode.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Set PIN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { savePIN() }
                }
            }
        }
    }

    private func savePIN() {
        guard pin.count >= 4 else {
            errorMessage = "PIN must be at least 4 digits"
            return
        }
        guard pin == confirmPin else {
            errorMessage = "PINs do not match"
            return
        }
        storedPINHash = sha256(pin)
        secureModeEnabled = true
        dismiss()
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    SecureModeView()
}
