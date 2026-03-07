import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        #if os(macOS)
        settingsForm(settings: settings)
            .frame(width: 400)
            .padding()
        #else
        NavigationStack {
            settingsForm(settings: settings)
                .navigationTitle("Settings")
        }
        #endif
    }

    private func settingsForm(settings: AppSettings) -> some View {
        @Bindable var settings = settings

        return Form {
            Section("Language / Sprache") {
                Picker("Content Language", selection: $settings.language) {
                    ForEach(AppLanguage.allCases, id: \.rawValue) { lang in
                        Text("\(lang.flag) \(lang.displayName)")
                            .tag(lang.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                Text(settings.language == "de"
                     ? "Barbara spricht Deutsch mit dir."
                     : "Barbara speaks English with you.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Display Name") {
                TextField("Your name", text: $settings.displayName)
            }

            Section {
                NavigationLink {
                    ParentSettingsView(settings: settings)
                } label: {
                    Label(
                        settings.language == "de" ? "Eltern-Einstellungen" : "Parent Settings",
                        systemImage: "lock.shield"
                    )
                }
            } footer: {
                Text(settings.language == "de"
                     ? "API-Key, KI-Modell und Debug-Optionen"
                     : "API key, AI model, and debug options")
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(AppVersion.displayString)
                        .foregroundStyle(.secondary)
                }

                Button(settings.language == "de" ? "Onboarding wiederholen" : "Replay Onboarding", role: .destructive) {
                    settings.hasCompletedOnboarding = false
                }
            }
        }
    }
}

#Preview("English") {
    let settings = AppSettings.shared
    SettingsView()
        .environment(settings)
        .onAppear { settings.language = "en" }
}

#Preview("German") {
    let settings = AppSettings.shared
    SettingsView()
        .environment(settings)
        .onAppear { settings.language = "de" }
}
