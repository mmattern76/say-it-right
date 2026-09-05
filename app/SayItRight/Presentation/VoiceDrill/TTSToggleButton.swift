import SwiftUI

/// Toolbar button to toggle TTS (Barbara speaking) on/off during a session.
///
/// Shows a speaker icon that toggles between enabled and disabled states.
/// Reads the default from AppSettings but allows per-session override.
///
/// When global Silent Mode is active (``AppSettings/effectiveIsTTSDisabled``),
/// the button is disabled — per-session override cannot bring TTS back.
struct TTSToggleButton: View {
    @Binding var isEnabled: Bool
    let language: String

    private var silentModeOn: Bool {
        AppSettings.shared.effectiveIsTTSDisabled
    }

    private var label: String {
        if silentModeOn {
            return language == "de" ? "Stumm (Einstellungen)" : "Silent (Settings)"
        }
        return isEnabled
            ? (language == "de" ? "Sprache aus" : "Mute Barbara")
            : (language == "de" ? "Sprache an" : "Unmute Barbara")
    }

    private var systemImage: String {
        if silentModeOn { return "speaker.slash.fill" }
        return isEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill"
    }

    var body: some View {
        Button {
            isEnabled.toggle()
        } label: {
            Label(label, systemImage: systemImage)
        }
        .disabled(silentModeOn)
        .accessibilityHint(
            silentModeOn
                ? (language == "de"
                    ? "Stummmodus ist in den Einstellungen aktiviert."
                    : "Silent mode is enabled in Settings.")
                : ""
        )
        .accessibilityIdentifier("ttsToggle")
    }
}

#Preview("TTS On") {
    NavigationStack {
        Text("Session")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    TTSToggleButton(isEnabled: .constant(true), language: "en")
                }
            }
    }
}

#Preview("TTS Off") {
    NavigationStack {
        Text("Session")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    TTSToggleButton(isEnabled: .constant(false), language: "en")
                }
            }
    }
}
