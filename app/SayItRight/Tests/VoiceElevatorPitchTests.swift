import Testing
@testable import SayItRight

@Suite("Voice Elevator Pitch")
struct VoiceElevatorPitchTests {

    // MARK: - Voice Mode Directive

    @Test("Voice mode directive appended for elevator pitch")
    @MainActor
    func voiceModeDirectiveExists() {
        let sm = SessionManager()
        let directive = sm.voiceModeDirective(language: "en")
        #expect(!directive.isEmpty)
        #expect(directive.contains("Voice Mode"))
        #expect(directive.contains("2-3 sentences"))
    }

    // MARK: - Timer Duration by Level

    @Test("Timer duration is 60s for level 1")
    func timerDurationLevel1() {
        let duration = ElevatorPitchSession.duration(for: 1)
        #expect(duration == 60)
    }

    @Test("Timer duration is 30s for level 2+")
    func timerDurationLevel2() {
        let duration = ElevatorPitchSession.duration(for: 2)
        #expect(duration == 30)
        let duration3 = ElevatorPitchSession.duration(for: 3)
        #expect(duration3 == 30)
    }

    // MARK: - Session Recording

    @Test("ElevatorPitchSession records response and timeout status")
    func sessionRecordsResponse() {
        var session = ElevatorPitchSession(
            topic: Topic(
                id: "test",
                titleEN: "Test",
                titleDE: "Test",
                promptEN: "Test prompt",
                promptDE: "Testfrage",
                domain: .school,
                level: 1,
                barbaraFavorite: false
            ),
            durationSeconds: 30
        )
        #expect(!session.hasResponse)

        session.recordResponse("My structured response", timedOut: false)
        #expect(session.hasResponse)
        #expect(session.responseText == "My structured response")
        #expect(!session.timedOut)
    }

    @Test("ElevatorPitchSession records timeout")
    func sessionRecordsTimeout() {
        var session = ElevatorPitchSession(
            topic: Topic(
                id: "test",
                titleEN: "Test",
                titleDE: "Test",
                promptEN: "Test prompt",
                promptDE: "Testfrage",
                domain: .school,
                level: 1,
                barbaraFavorite: false
            ),
            durationSeconds: 60
        )

        session.recordResponse("Partial response", timedOut: true)
        #expect(session.hasResponse)
        #expect(session.timedOut)
    }

    // MARK: - ChatViewModel Integration

    @Test("ChatViewModel can be created for voice elevator pitch")
    @MainActor
    func chatViewModelCreation() {
        let sm = SessionManager()
        let vm = ChatViewModel(sessionManager: sm)
        #expect(vm.inputText.isEmpty)
    }

    // MARK: - Voice Directive Both Languages

    @Test("Voice mode directive works for both languages")
    @MainActor
    func voiceDirectiveBothLanguages() {
        let sm = SessionManager()
        let en = sm.voiceModeDirective(language: "en")
        let de = sm.voiceModeDirective(language: "de")
        #expect(!en.isEmpty)
        #expect(!de.isEmpty)
    }
}
