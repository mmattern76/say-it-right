import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            Form {
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
            }
            .navigationTitle("Settings")
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
