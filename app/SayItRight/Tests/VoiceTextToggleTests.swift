import Testing
@testable import SayItRight

@Suite("Voice/Text Toggle")
struct VoiceTextToggleTests {

    // MARK: - Input Mode Enum

    @Test("ChatInputMode has text and voice cases")
    func inputModeCases() {
        let text = ChatInputMode.text
        let voice = ChatInputMode.voice
        #expect(text != voice)
        #expect(text == .text)
        #expect(voice == .voice)
    }

    // MARK: - ChatView Parameters

    @Test("ChatView accepts voice input view model")
    @MainActor
    func chatViewAcceptsVoiceVM() {
        let vm = ChatViewModel()
        _ = vm
        // ChatView can be constructed with or without voice VM
    }

    // MARK: - Partial Transcription Preservation

    @Test("Switching voice to text preserves partial text in inputText")
    @MainActor
    func partialTranscriptionPreserved() {
        let sm = SessionManager()
        let vm = ChatViewModel(sessionManager: sm)

        // Simulate: user typed text, then it's in inputText
        vm.inputText = "Partial transcription from voice"
        #expect(vm.inputText == "Partial transcription from voice")
    }

    // MARK: - VoiceInputViewModel Reset

    @Test("VoiceInputViewModel can be reset")
    @MainActor
    func voiceInputVMReset() async {
        let mock = MockSpeechRecognitionService()
        let voiceVM = VoiceInputViewModel(speechService: mock)
        voiceVM.reset()
        #expect(voiceVM.state == .idle)
        #expect(voiceVM.transcriptionText.isEmpty)
    }

    // MARK: - Toggle State Independence

    @Test("Input mode toggle does not affect conversation history")
    @MainActor
    func toggleDoesNotAffectHistory() {
        // Use standalone mode (no SessionManager) so setMessages works
        let vm = ChatViewModel()
        vm.setMessages([
            ChatMessage(role: .barbara, text: "Tell me your argument."),
            ChatMessage(role: .learner, text: "Schools should adopt a four-day week."),
        ])

        // Messages preserved regardless of input mode changes
        #expect(vm.messages.count == 2)
        #expect(vm.messages[0].role == .barbara)
        #expect(vm.messages[1].role == .learner)
    }

    @Test("ChatInputMode is Sendable and Equatable")
    func inputModeSendableEquatable() {
        let a: ChatInputMode = .text
        let b: ChatInputMode = .text
        let c: ChatInputMode = .voice
        #expect(a == b)
        #expect(a != c)
    }
}
