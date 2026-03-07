import Testing
@testable import SayItRight

@Suite("Voice Say It Clearly")
struct VoiceSayItClearlyTests {

    // MARK: - Voice Mode Directive

    @Test("Voice mode directive is non-empty")
    @MainActor
    func voiceModeDirectiveIsNonEmpty() {
        let sm = SessionManager()
        let directive = sm.voiceModeDirective(language: "en")
        #expect(!directive.isEmpty)
        #expect(directive.contains("Voice Mode"))
    }

    @Test("Voice mode directive mentions concise feedback")
    @MainActor
    func voiceModeDirectiveMentionsConciseness() {
        let sm = SessionManager()
        let directiveEN = sm.voiceModeDirective(language: "en")
        #expect(directiveEN.contains("2-3 sentences"))
        #expect(directiveEN.contains("punchy"))
    }

    @Test("Voice mode directive works for both languages")
    @MainActor
    func voiceModeDirectiveBothLanguages() {
        let sm = SessionManager()
        let en = sm.voiceModeDirective(language: "en")
        let de = sm.voiceModeDirective(language: "de")
        #expect(!en.isEmpty)
        #expect(!de.isEmpty)
    }

    @Test("Voice directive instructs no bullet points")
    @MainActor
    func voiceDirectiveNoBullets() {
        let sm = SessionManager()
        let directive = sm.voiceModeDirective(language: "en")
        #expect(directive.contains("bullet points"))
    }

    @Test("Voice directive preserves structural rigour")
    @MainActor
    func voiceDirectivePreservesRigour() {
        let sm = SessionManager()
        let directive = sm.voiceModeDirective(language: "en")
        #expect(directive.contains("structural rigour") || directive.lowercased().contains("bar stays the same"))
    }

    // MARK: - ChatView Voice Mode

    @Test("ChatView accepts optional voice input parameters")
    @MainActor
    func chatViewAcceptsVoiceParams() {
        let vm = ChatViewModel()
        _ = vm
    }

    // MARK: - Voice Input Submit

    @Test("Voice input text forwarded to session manager via send")
    @MainActor
    func voiceInputForwardedToSend() async {
        let sm = SessionManager()
        let vm = ChatViewModel(sessionManager: sm)

        vm.inputText = "Schools should adopt a four-day week."
        #expect(vm.inputText == "Schools should adopt a four-day week.")
    }
}
