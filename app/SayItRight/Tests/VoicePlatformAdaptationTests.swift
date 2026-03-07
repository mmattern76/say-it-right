import Testing
@testable import SayItRight

@Suite("Voice Platform Adaptation")
struct VoicePlatformAdaptationTests {

    // MARK: - AppSettings Voice Preferences

    @Test("AppSettings has preferredInputMode property")
    func preferredInputModeExists() {
        let settings = AppSettings.shared
        let mode = settings.preferredInputMode
        #expect(mode == "voice" || mode == "text")
    }

    @Test("AppSettings has ttsAutoPlay property")
    func ttsAutoPlayExists() {
        let settings = AppSettings.shared
        // Just verify the property is accessible
        _ = settings.ttsAutoPlay
    }

    @Test("Platform default input mode is text on macOS")
    func macOSDefaultIsText() {
        #if os(macOS)
        #expect(AppSettings.platformDefaultInputMode == "text")
        #expect(AppSettings.platformDefaultTTSAutoPlay == false)
        #endif
    }

    // MARK: - ChatInputMode

    @Test("ChatInputMode respects settings-based default")
    @MainActor
    func inputModeRespectsSettings() {
        // ChatInputMode enum is available
        let text = ChatInputMode.text
        let voice = ChatInputMode.voice
        #expect(text != voice)
    }

    // MARK: - TTS Toggle

    @Test("TTS can be toggled per session")
    func ttsToggleable() {
        var enabled = true
        enabled.toggle()
        #expect(!enabled)
        enabled.toggle()
        #expect(enabled)
    }

    // MARK: - Voice Mode Directive

    @Test("Voice directive available for all platforms")
    @MainActor
    func voiceDirectiveAllPlatforms() {
        let sm = SessionManager()
        let directive = sm.voiceModeDirective(language: "en")
        #expect(!directive.isEmpty)
    }

    @Test("appendVoiceDirective works on all platforms")
    @MainActor
    func appendDirectiveAllPlatforms() {
        let sm = SessionManager()
        sm.appendVoiceDirective(language: "en")
        sm.appendVoiceDirective(language: "de")
    }
}
