import SwiftUI

/// Parent-only settings section, protected by PIN and/or Face ID.
///
/// Contains:
/// - Anthropic model picker (dynamically fetched from API)
/// - API key override (overrides Config.plist key)
/// - Debug mode toggle (enables in-flight data collection)
/// - Parent PIN management
/// - Biometric (Face ID / Touch ID) toggle
struct ParentSettingsView: View {
    @Bindable var settings: AppSettings
    @State var gate: ParentGate
    var catalog: ModelCatalog

    @State private var showPINEntry = false
    @State private var showSetPIN = false
    @State private var showRemovePINConfirm = false
    @State private var apiKeyInput = ""
    @State private var showAPIKey = false
    @State private var newPIN = ""
    @State private var confirmPIN = ""
    @State private var pinMismatch = false

    init(settings: AppSettings = .shared, catalog: ModelCatalog = .shared) {
        self.settings = settings
        self._gate = State(initialValue: ParentGate(settings: settings))
        self.catalog = catalog
    }

    var body: some View {
        Group {
            if gate.isUnlocked {
                settingsContent
            } else {
                lockedView
            }
        }
        .navigationTitle("Parent Settings")
        .onDisappear { gate.lock() }
        .task {
            // Refresh model list when settings are opened
            if let url = settings.backendURL, let key = settings.backendAPIKey {
                await catalog.refresh(backendURL: url, apiKey: key)
            }
        }
    }

    // MARK: - Locked State

    private var lockedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Parent Access Required")
                .font(.title3)

            if settings.isParentPINEnabled {
                if settings.isBiometricEnabled {
                    Button("Unlock with Face ID") {
                        Task {
                            let success = await gate.unlockWithBiometrics()
                            if !success { showPINEntry = true }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button(settings.isBiometricEnabled ? "Use PIN Instead" : "Enter PIN") {
                    showPINEntry = true
                }
                .buttonStyle(.bordered)
            } else {
                // No PIN set — first time. Let them in to set one.
                Button("Set Up Parent Access") {
                    gate.isUnlocked = true
                    showSetPIN = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .sheet(isPresented: $showPINEntry) {
            PINEntryView(title: "Enter Parent PIN") { pin in
                await gate.unlockWithPIN(pin)
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - Unlocked Settings

    private var settingsContent: some View {
        Form {
            // MARK: AI Model
            Section {
                Picker("Claude Model", selection: $settings.selectedModelID) {
                    ForEach(catalog.models) { model in
                        Text(model.displayName).tag(model.id)
                    }
                }
                #if os(iOS)
                .pickerStyle(.navigationLink)
                #endif

                if catalog.isLoading {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Refreshing models...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let error = catalog.lastError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                        Text("Using cached list: \(error)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("Current: \(settings.selectedModelID)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Refresh Model List") {
                    Task {
                        if let url = settings.backendURL, let key = settings.backendAPIKey {
                            await catalog.refresh(backendURL: url, apiKey: key)
                        }
                    }
                }
            } header: {
                Text("AI Model")
            } footer: {
                Text("Models are fetched from the Anthropic API. If a selected model becomes unavailable, the app will automatically select the closest replacement.")
            }

            // MARK: API Key
            Section {
                HStack {
                    Group {
                        if showAPIKey {
                            TextField("sk-ant-...", text: $apiKeyInput)
                                .textContentType(.password)
                                #if os(iOS)
                                .autocapitalization(.none)
                                #endif
                        } else {
                            SecureField("sk-ant-...", text: $apiKeyInput)
                        }
                    }
                    .disableAutocorrection(true)

                    Button {
                        showAPIKey.toggle()
                    } label: {
                        Image(systemName: showAPIKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                }

                if !apiKeyInput.isEmpty {
                    Button("Save Override Key") {
                        settings.apiKeyOverride = apiKeyInput
                    }
                }

                if settings.apiKeyOverride != nil {
                    Button("Remove Override (use bundled key)", role: .destructive) {
                        settings.apiKeyOverride = nil
                        apiKeyInput = ""
                    }
                }

                apiKeyStatusRow
            } header: {
                Text("API Key")
            } footer: {
                Text("Override the bundled Config.plist key. Stored securely in Keychain.")
            }

            // MARK: Level Override
            Section {
                Picker("Learner Level", selection: $settings.levelOverride) {
                    Text("Auto (default)").tag(0)
                    Text("Level 1 — Klartext").tag(1)
                    Text("Level 2 — Ordnung").tag(2)
                    Text("Level 3 — Architektur").tag(3)
                    Text("Level 4 — Meisterschaft").tag(4)
                }

                if settings.levelOverride > 0 {
                    Text("Overriding learner level to \(settings.levelOverride). This unlocks all exercises for that level.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } header: {
                Text("Testing")
            } footer: {
                Text("Override the learner's level to test exercises that require higher levels (e.g. Spot the Gap requires L2+).")
            }

            // MARK: Debug Mode
            Section {
                Toggle("Debug Mode", isOn: $settings.isDebugModeEnabled)

                if settings.isDebugModeEnabled {
                    NavigationLink("View Debug Log") {
                        DebugLogView()
                    }
                }
            } header: {
                Text("Diagnostics")
            } footer: {
                Text("When enabled, collects API request/response timing, metadata, and session events. Data stays on-device.")
            }

            // MARK: Parent PIN
            Section {
                if settings.isParentPINEnabled {
                    Button("Change PIN") { showSetPIN = true }
                    Toggle("Face ID / Touch ID", isOn: $settings.isBiometricEnabled)
                    Button("Remove PIN", role: .destructive) { showRemovePINConfirm = true }
                } else {
                    Button("Set Parent PIN") { showSetPIN = true }
                }
            } header: {
                Text("Parent Access")
            } footer: {
                Text("A 4-digit PIN protects these settings from learners.")
            }
        }
        .onAppear { apiKeyInput = settings.apiKeyOverride ?? "" }
        .sheet(isPresented: $showSetPIN) { setPINSheet }
        .confirmationDialog("Remove PIN?", isPresented: $showRemovePINConfirm) {
            Button("Remove", role: .destructive) {
                Task { try? await gate.removePIN() }
            }
        } message: {
            Text("Anyone will be able to access parent settings.")
        }
    }

    // MARK: - API Key Status

    @ViewBuilder
    private var apiKeyStatusRow: some View {
        HStack {
            Image(systemName: settings.effectiveAPIKey != nil ? "checkmark.circle" : "xmark.circle")
                .foregroundStyle(settings.effectiveAPIKey != nil ? .green : .red)
            Text(apiKeyStatusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var apiKeyStatusText: String {
        if settings.apiKeyOverride != nil {
            return "Using override key from settings"
        } else if ConfigProvider.anthropicAPIKey != nil {
            return "Using bundled key from Config.plist"
        } else {
            return "No API key configured"
        }
    }

    // MARK: - Set PIN Sheet

    private var setPINSheet: some View {
        NavigationStack {
            Form {
                Section("New PIN") {
                    SecureField("4-digit PIN", text: $newPIN)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }
                Section("Confirm PIN") {
                    SecureField("Repeat PIN", text: $confirmPIN)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }
                if pinMismatch {
                    Text("PINs don't match")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            .navigationTitle("Set Parent PIN")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showSetPIN = false
                        newPIN = ""
                        confirmPIN = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard newPIN.count == 4, newPIN == confirmPIN else {
                            pinMismatch = true
                            return
                        }
                        Task {
                            try? await gate.setPIN(newPIN)
                            newPIN = ""
                            confirmPIN = ""
                            showSetPIN = false
                        }
                    }
                    .disabled(newPIN.count != 4)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        ParentSettingsView()
    }
}
