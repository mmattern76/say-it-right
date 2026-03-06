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

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(AppVersion.displayString)
                        .foregroundStyle(.secondary)
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
