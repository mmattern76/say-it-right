import XCTest
@testable import SayItRight

// MARK: - MockTTSPlaybackService

/// Test double for TTSPlaybackService that records calls and allows
/// controlled event emission without requiring AVSpeechSynthesizer.
final class MockTTSPlaybackService: TTSPlaybackService, @unchecked Sendable {

    private let lock = NSLock()

    // MARK: - Recorded State

    private var _state: TTSPlaybackState = .idle
    var state: TTSPlaybackState {
        lock.lock()
        defer { lock.unlock() }
        return _state
    }

    var isAutoPlayEnabled: Bool = true
    var configuration: TTSConfiguration = .default

    private(set) var spokenTexts: [String] = []
    private(set) var spokenLanguages: [String] = []
    private(set) var pauseCount = 0
    private(set) var resumeCount = 0
    private(set) var stopCount = 0
    private(set) var replayCount = 0
    private(set) var prewarmCount = 0

    private var _lastText: String?
    private var _lastLanguage: String?
    private var _onEvent: (@Sendable (TTSEvent) -> Void)?

    // MARK: - TTSPlaybackService

    func speak(
        _ text: String,
        language: String,
        onEvent: (@Sendable (TTSEvent) -> Void)?
    ) {
        lock.lock()
        spokenTexts.append(text)
        spokenLanguages.append(language)
        _lastText = text
        _lastLanguage = language
        _onEvent = onEvent
        _state = .speaking
        lock.unlock()

        onEvent?(.started)
    }

    func pause() {
        lock.lock()
        pauseCount += 1
        _state = .paused
        lock.unlock()
    }

    func resume() {
        lock.lock()
        resumeCount += 1
        _state = .speaking
        lock.unlock()
    }

    func stop() {
        lock.lock()
        stopCount += 1
        _state = .idle
        lock.unlock()
    }

    func replayLast(onEvent: (@Sendable (TTSEvent) -> Void)?) {
        lock.lock()
        replayCount += 1
        let text = _lastText
        let language = _lastLanguage
        lock.unlock()

        guard let text, let language else { return }
        speak(text, language: language, onEvent: onEvent)
    }

    func prewarm() {
        lock.lock()
        prewarmCount += 1
        lock.unlock()
    }

    // MARK: - Test Helpers

    /// Simulate finishing speech to trigger the callback.
    func simulateFinished() {
        lock.lock()
        _state = .idle
        let callback = _onEvent
        lock.unlock()
        callback?(.finished)
    }

    /// Simulate an interruption event.
    func simulateInterrupted() {
        lock.lock()
        _state = .paused
        let callback = _onEvent
        lock.unlock()
        callback?(.interrupted)
    }
}

// MARK: - Tests

final class TTSPlaybackServiceTests: XCTestCase {

    // MARK: - Mock Service Tests (queue management & configuration)

    func testSpeakRecordsTextAndLanguage() {
        let service = MockTTSPlaybackService()

        service.speak("Hello, world!", language: "en", onEvent: nil)

        XCTAssertEqual(service.spokenTexts, ["Hello, world!"])
        XCTAssertEqual(service.spokenLanguages, ["en"])
        XCTAssertEqual(service.state, .speaking)
    }

    func testSpeakGermanText() {
        let service = MockTTSPlaybackService()

        service.speak("Das ist nicht schlecht.", language: "de", onEvent: nil)

        XCTAssertEqual(service.spokenTexts, ["Das ist nicht schlecht."])
        XCTAssertEqual(service.spokenLanguages, ["de"])
    }

    func testMultipleSpeakCallsQueue() {
        let service = MockTTSPlaybackService()

        service.speak("First sentence.", language: "en", onEvent: nil)
        service.speak("Second sentence.", language: "en", onEvent: nil)

        XCTAssertEqual(service.spokenTexts.count, 2)
        XCTAssertEqual(service.spokenTexts[0], "First sentence.")
        XCTAssertEqual(service.spokenTexts[1], "Second sentence.")
    }

    func testPauseAndResume() {
        let service = MockTTSPlaybackService()

        service.speak("Speaking now.", language: "en", onEvent: nil)
        XCTAssertEqual(service.state, .speaking)

        service.pause()
        XCTAssertEqual(service.state, .paused)
        XCTAssertEqual(service.pauseCount, 1)

        service.resume()
        XCTAssertEqual(service.state, .speaking)
        XCTAssertEqual(service.resumeCount, 1)
    }

    func testStop() {
        let service = MockTTSPlaybackService()

        service.speak("Speaking now.", language: "en", onEvent: nil)
        service.stop()

        XCTAssertEqual(service.state, .idle)
        XCTAssertEqual(service.stopCount, 1)
    }

    func testReplayLast() {
        let service = MockTTSPlaybackService()

        service.speak("Original text.", language: "de", onEvent: nil)
        service.simulateFinished()

        service.replayLast(onEvent: nil)

        XCTAssertEqual(service.replayCount, 1)
        // Replay re-speaks the same text
        XCTAssertEqual(service.spokenTexts.last, "Original text.")
        XCTAssertEqual(service.spokenLanguages.last, "de")
    }

    func testReplayLastWithNoHistory() {
        let service = MockTTSPlaybackService()

        // Should not crash or speak when there's nothing to replay.
        service.replayLast(onEvent: nil)

        XCTAssertEqual(service.replayCount, 1)
        XCTAssertTrue(service.spokenTexts.isEmpty)
    }

    func testPrewarm() {
        let service = MockTTSPlaybackService()

        service.prewarm()

        XCTAssertEqual(service.prewarmCount, 1)
    }

    // MARK: - Event Callback Tests

    func testStartedEventFired() {
        let service = MockTTSPlaybackService()
        let expectation = expectation(description: "started event")

        service.speak("Test.", language: "en") { event in
            if event == .started {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testFinishedEventFired() {
        let service = MockTTSPlaybackService()
        let expectation = expectation(description: "finished event")

        service.speak("Test.", language: "en") { event in
            if event == .finished {
                expectation.fulfill()
            }
        }

        service.simulateFinished()

        wait(for: [expectation], timeout: 1.0)
    }

    func testInterruptedEventFired() {
        let service = MockTTSPlaybackService()
        let expectation = expectation(description: "interrupted event")

        service.speak("Test.", language: "en") { event in
            if event == .interrupted {
                expectation.fulfill()
            }
        }

        service.simulateInterrupted()

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Configuration Tests

    func testDefaultConfiguration() {
        let config = TTSConfiguration.default
        XCTAssertEqual(config.pitchMultiplier, 1.0)
        XCTAssertEqual(config.volume, 1.0)
        XCTAssertNil(config.voiceIdentifier)
    }

    func testCustomConfiguration() {
        let service = MockTTSPlaybackService()
        var config = TTSConfiguration()
        config.rate = 0.4
        config.pitchMultiplier = 1.2
        config.volume = 0.8
        config.voiceIdentifier = "com.apple.speech.synthesis.voice.Anna"

        service.configuration = config

        XCTAssertEqual(service.configuration.rate, 0.4)
        XCTAssertEqual(service.configuration.pitchMultiplier, 1.2)
        XCTAssertEqual(service.configuration.volume, 0.8)
        XCTAssertEqual(service.configuration.voiceIdentifier, "com.apple.speech.synthesis.voice.Anna")
    }

    func testAutoPlayToggle() {
        let service = MockTTSPlaybackService()
        XCTAssertTrue(service.isAutoPlayEnabled) // default

        service.isAutoPlayEnabled = false
        XCTAssertFalse(service.isAutoPlayEnabled)
    }

    // MARK: - Sentence Splitting Tests (AppleTTSPlaybackService)

    func testSplitIntoSentencesSingleSentence() {
        let service = AppleTTSPlaybackService()
        let result = service.splitIntoSentences("Hello, world!")
        XCTAssertEqual(result, ["Hello, world!"])
    }

    func testSplitIntoSentencesMultipleSentences() {
        let service = AppleTTSPlaybackService()
        let result = service.splitIntoSentences(
            "First sentence. Second sentence. Third sentence."
        )
        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(result[0].contains("First"))
        XCTAssertTrue(result[1].contains("Second"))
        XCTAssertTrue(result[2].contains("Third"))
    }

    func testSplitIntoSentencesEmptyText() {
        let service = AppleTTSPlaybackService()
        let result = service.splitIntoSentences("")
        XCTAssertTrue(result.isEmpty)
    }

    func testSplitIntoSentencesWhitespaceOnly() {
        let service = AppleTTSPlaybackService()
        let result = service.splitIntoSentences("   \n  ")
        XCTAssertTrue(result.isEmpty)
    }

    func testSplitIntoSentencesGermanText() {
        let service = AppleTTSPlaybackService()
        let result = service.splitIntoSentences(
            "Das ist gut. Das ist schlecht. Versuch es nochmal."
        )
        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(result[0].contains("gut"))
        XCTAssertTrue(result[1].contains("schlecht"))
        XCTAssertTrue(result[2].contains("nochmal"))
    }

    // MARK: - State Transition Tests

    func testInitialStateIsIdle() {
        let service = MockTTSPlaybackService()
        XCTAssertEqual(service.state, .idle)
    }

    func testStateTransitionIdleToSpeaking() {
        let service = MockTTSPlaybackService()
        service.speak("Test.", language: "en", onEvent: nil)
        XCTAssertEqual(service.state, .speaking)
    }

    func testStateTransitionSpeakingToPaused() {
        let service = MockTTSPlaybackService()
        service.speak("Test.", language: "en", onEvent: nil)
        service.pause()
        XCTAssertEqual(service.state, .paused)
    }

    func testStateTransitionPausedToSpeaking() {
        let service = MockTTSPlaybackService()
        service.speak("Test.", language: "en", onEvent: nil)
        service.pause()
        service.resume()
        XCTAssertEqual(service.state, .speaking)
    }

    func testStateTransitionSpeakingToIdle() {
        let service = MockTTSPlaybackService()
        service.speak("Test.", language: "en", onEvent: nil)
        service.stop()
        XCTAssertEqual(service.state, .idle)
    }

    func testStateTransitionSpeakingToIdleOnFinish() {
        let service = MockTTSPlaybackService()
        service.speak("Test.", language: "en", onEvent: nil)
        service.simulateFinished()
        XCTAssertEqual(service.state, .idle)
    }
}
