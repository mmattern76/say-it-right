import SwiftUI

/// Toolbar button to toggle TTS (Barbara speaking) on/off during a session.
///
/// Shows a speaker icon that toggles between enabled and disabled states.
/// Reads the default from AppSettings but allows per-session override.
struct TTSToggleButton: View {
    @Binding var isEnabled: Bool
    let language: String

    var body: some View {
        Button {
            isEnabled.toggle()
        } label: {
            Label(
                isEnabled
                    ? (language == "de" ? "Sprache aus" : "Mute Barbara")
                    : (language == "de" ? "Sprache an" : "Unmute Barbara"),
                systemImage: isEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill"
            )
        }
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
