import SwiftUI
import CoreImage.CIFilterBuiltins

struct SetupView: View {
    @State private var mechanisms: [UnlockMechanism] = []
    @State private var showingAddSheet = false
    @State private var newMechType: UnlockType = .qrCode
    @State private var newMechName: String = ""
    @State private var isScanning = false
    @State private var scannedIdentifier: String = ""
    @State private var showingQRPreview = false
    @State private var previewMechanism: UnlockMechanism?

    private let storageKey = "gordian.unlock.mechanisms"

    var body: some View {
        NavigationView {
            List {
                if mechanisms.isEmpty {
                    ContentUnavailableView(
                        "No Unlock Mechanisms",
                        systemImage: "qrcode",
                        description: Text("Add a QR code or NFC tag to use as a physical key")
                    )
                } else {
                    ForEach(mechanisms) { mechanism in
                        HStack {
                            Image(systemName: mechanism.type == .qrCode ? "qrcode" : "wave.3.right")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .frame(width: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mechanism.name)
                                    .font(.headline)
                                Text(mechanism.type.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(mechanism.identifier.prefix(20) + (mechanism.identifier.count > 20 ? "…" : ""))
                                    .font(.caption2)
                                    .foregroundColor(.tertiary)
                                    .monospaced()
                            }
                            Spacer()
                            if mechanism.type == .qrCode {
                                Button {
                                    previewMechanism = mechanism
                                    showingQRPreview = true
                                } label: {
                                    Image(systemName: "eye")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    .onDelete(perform: deleteMechanisms)
                }
            }
            .navigationTitle("Unlock Keys")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        newMechName = ""
                        newMechType = .qrCode
                        scannedIdentifier = ""
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddMechanismView(
                    mechanisms: $mechanisms,
                    onSave: saveMechanisms
                )
            }
            .sheet(isPresented: $showingQRPreview) {
                if let mech = previewMechanism {
                    QRPreviewSheet(mechanism: mech)
                }
            }
            .onAppear { loadMechanisms() }
        }
    }

    private func loadMechanisms() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([UnlockMechanism].self, from: data) else { return }
        mechanisms = decoded
    }

    private func saveMechanisms() {
        if let data = try? JSONEncoder().encode(mechanisms) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func deleteMechanisms(at offsets: IndexSet) {
        mechanisms.remove(atOffsets: offsets)
        saveMechanisms()
    }
}

// MARK: - Add Mechanism Sheet

struct AddMechanismView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var mechanisms: [UnlockMechanism]
    var onSave: () -> Void

    @State private var name: String = ""
    @State private var type: UnlockType = .qrCode
    @State private var identifier: String = ""
    @State private var showingScanner = false
    @State private var showingNFCReader = false

    var body: some View {
        NavigationView {
            Form {
                Section("Name") {
                    TextField("e.g. My Amiibo / My QR Code", text: $name)
                }

                Section("Type") {
                    Picker("Unlock Type", selection: $type) {
                        ForEach(UnlockType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Identifier") {
                    if identifier.isEmpty {
                        Text("No identifier yet")
                            .foregroundColor(.secondary)
                    } else {
                        Text(identifier)
                            .font(.caption)
                            .monospaced()
                            .lineLimit(2)
                    }

                    if type == .qrCode {
                        Button("Generate New QR Code") {
                            identifier = QRCodeManager.shared.generateIdentifier()
                        }
                        Button("Scan Existing QR Code") {
                            showingScanner = true
                        }
                    } else {
                        Button("Read NFC Tag (Amiibo)") {
                            showingNFCReader = true
                        }
                    }
                }
            }
            .navigationTitle("Add Unlock Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let mech = UnlockMechanism(
                            name: name.isEmpty ? type.rawValue : name,
                            type: type,
                            identifier: identifier
                        )
                        mechanisms.append(mech)
                        onSave()
                        dismiss()
                    }
                    .disabled(identifier.isEmpty)
                }
            }
            .sheet(isPresented: $showingScanner) {
                QRScannerView { code in
                    identifier = code
                    showingScanner = false
                }
            }
            .onChange(of: showingNFCReader) { isShowing in
                if isShowing {
                    NFCManager.shared.startReading { uid in
                        identifier = uid
                        showingNFCReader = false
                    }
                }
            }
        }
    }
}

// MARK: - QR Preview Sheet

struct QRPreviewSheet: View {
    let mechanism: UnlockMechanism
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Scan this code to unlock")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let image = QRCodeManager.shared.generateQRCode(from: mechanism.identifier) {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 8)
                }

                Text(mechanism.identifier)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .monospaced()
                    .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle(mechanism.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SetupView()
}
