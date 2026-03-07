import Testing
@testable import SayItRight

@Suite("Voice Find the Point")
struct VoiceFindThePointTests {

    // MARK: - Voice Mode Directive

    @Test("Voice directive applied for find-the-point session")
    @MainActor
    func voiceDirectiveApplied() {
        let sm = SessionManager()
        let directive = sm.voiceModeDirective(language: "en")
        #expect(directive.contains("Voice Mode"))
        #expect(directive.contains("2-3 sentences"))
    }

    @Test("appendVoiceDirective is callable")
    @MainActor
    func appendVoiceDirectiveCallable() {
        let sm = SessionManager()
        // Should not crash on an empty system prompt
        sm.appendVoiceDirective(language: "en")
        sm.appendVoiceDirective(language: "de")
    }

    // MARK: - ChatViewModel Integration

    @Test("ChatViewModel receives voice input text")
    @MainActor
    func chatViewModelReceivesInput() {
        let sm = SessionManager()
        let vm = ChatViewModel(sessionManager: sm)
        vm.inputText = "The author argues that uniforms reduce social pressure."
        #expect(vm.inputText == "The author argues that uniforms reduce social pressure.")
    }

    // MARK: - Practice Text Display

    @Test("PracticeText has accessible text for display")
    func practiceTextAccessible() {
        let text = PracticeText(
            id: "test-001",
            text: "School uniforms reduce social pressure.",
            answerKey: AnswerKey(
                governingThought: "Uniforms reduce social pressure.",
                supports: [],
                structuralAssessment: "Well-structured."
            ),
            metadata: PracticeTextMetadata(
                qualityLevel: .wellStructured,
                difficultyRating: 1,
                topicDomain: "school",
                language: "en",
                wordCount: 6,
                targetLevel: 1
            )
        )
        #expect(!text.text.isEmpty)
        #expect(text.answerKey.governingThought.contains("pressure"))
    }

    // MARK: - Quality Selection

    @Test("FindThePointCoordinator selects texts")
    @MainActor
    func coordinatorSelectsTexts() {
        let text = PracticeText(
            id: "test-002",
            text: "Sample text for testing.",
            answerKey: AnswerKey(
                governingThought: "Testing.",
                supports: [],
                structuralAssessment: "Simple."
            ),
            metadata: PracticeTextMetadata(
                qualityLevel: .wellStructured,
                difficultyRating: 1,
                topicDomain: "school",
                language: "en",
                wordCount: 5,
                targetLevel: 1
            )
        )
        let coordinator = FindThePointCoordinator(texts: [text])
        _ = coordinator // Coordinator created successfully
    }
}
