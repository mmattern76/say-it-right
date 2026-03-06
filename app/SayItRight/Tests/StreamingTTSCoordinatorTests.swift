import Foundation
import Testing
@testable import SayItRight

// MARK: - Thread-safe collector for test assertions

/// A simple thread-safe collector for use in @Sendable callbacks.
private final class SendableBox<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: T

    init(_ value: T) {
        _value = value
    }

    var value: T {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    func set(_ newValue: T) {
        lock.lock()
        _value = newValue
        lock.unlock()
    }
}

private final class SendableArray<Element: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var _items: [Element] = []

    var items: [Element] {
        lock.lock()
        defer { lock.unlock() }
        return _items
    }

    func append(_ element: Element) {
        lock.lock()
        _items.append(element)
        lock.unlock()
    }
}

// MARK: - Streaming Mock TTS Service

private final class StreamingMockTTS: TTSPlaybackService, @unchecked Sendable {
    private let lock = NSLock()

    var state: TTSPlaybackState = .idle
    var isAutoPlayEnabled: Bool = true
    var configuration: TTSConfiguration = .default

    private var _spokenTexts: [String] = []
    var spokenTexts: [String] {
        lock.lock()
        defer { lock.unlock() }
        return _spokenTexts
    }

    func speak(
        _ text: String,
        language: String,
        onEvent: (@Sendable (TTSEvent) -> Void)?
    ) {
        lock.lock()
        _spokenTexts.append(text)
        state = .speaking
        lock.unlock()
    }

    func pause() { state = .paused }
    func resume() { state = .speaking }
    func stop() {
        lock.lock()
        state = .idle
        _spokenTexts.removeAll()
        lock.unlock()
    }
    func replayLast(onEvent: (@Sendable (TTSEvent) -> Void)?) {}
    func prewarm() {}
}

// MARK: - Tests

@Suite("StreamingTTSCoordinator")
struct StreamingTTSCoordinatorTests {

    @Test("Processes stream and feeds sentences to TTS incrementally")
    func processStreamFeedsSentences() async throws {
        let mockTTS = StreamingMockTTS()
        let coordinator = StreamingTTSCoordinator(ttsService: mockTTS)

        let stream = AsyncThrowingStream<String, Error> { continuation in
            continuation.yield("First sentence. ")
            continuation.yield("Second sentence. ")
            continuation.yield("Third.")
            continuation.finish()
        }

        try await coordinator.processStream(
            stream,
            language: "en"
        )

        let spoken = mockTTS.spokenTexts
        #expect(spoken.count >= 2)
        #expect(spoken.contains("First sentence."))
        #expect(spoken.contains("Second sentence."))
    }

    @Test("Filters out BARBARA_META from TTS")
    func filtersMetadata() async throws {
        let mockTTS = StreamingMockTTS()
        let coordinator = StreamingTTSCoordinator(ttsService: mockTTS)

        let stream = AsyncThrowingStream<String, Error> { continuation in
            continuation.yield("Good job! ")
            continuation.yield("<!-- BARBARA_META: {\"scores\":{}} -->")
            continuation.finish()
        }

        try await coordinator.processStream(
            stream,
            language: "en"
        )

        let spoken = mockTTS.spokenTexts
        #expect(spoken.count == 1)
        #expect(spoken[0] == "Good job!")
        for text in spoken {
            #expect(!text.contains("BARBARA_META"))
        }
    }

    @Test("Calls onVisibleText for each sentence")
    func onVisibleTextCallback() async throws {
        let mockTTS = StreamingMockTTS()
        let coordinator = StreamingTTSCoordinator(ttsService: mockTTS)

        let stream = AsyncThrowingStream<String, Error> { continuation in
            continuation.yield("Hello. World. ")
            continuation.finish()
        }

        let visibleTexts = SendableArray<String>()

        try await coordinator.processStream(
            stream,
            language: "en",
            onVisibleText: { text in
                visibleTexts.append(text)
            }
        )

        #expect(visibleTexts.items.count >= 2)
    }

    @Test("Calls onComplete with full response text")
    func onCompleteWithFullText() async throws {
        let mockTTS = StreamingMockTTS()
        let coordinator = StreamingTTSCoordinator(ttsService: mockTTS)

        let stream = AsyncThrowingStream<String, Error> { continuation in
            continuation.yield("Part one. ")
            continuation.yield("Part two.")
            continuation.finish()
        }

        let completedText = SendableBox<String?>(nil)
        let completedMeasurement = SendableBox<LatencyMeasurement?>(nil)

        try await coordinator.processStream(
            stream,
            language: "en",
            onComplete: { text, measurement in
                completedText.set(text)
                completedMeasurement.set(measurement)
            }
        )

        #expect(completedText.value == "Part one. Part two.")
        #expect(completedMeasurement.value != nil)
        #expect(completedMeasurement.value!.sentenceCount >= 1)
        #expect(completedMeasurement.value!.timeToFirstSpeechMs >= 0)
    }

    @Test("State transitions through pipeline lifecycle")
    func stateTransitions() async throws {
        let mockTTS = StreamingMockTTS()
        let coordinator = StreamingTTSCoordinator(ttsService: mockTTS)

        let initialState = await coordinator.state
        #expect(initialState == .idle)

        let stream = AsyncThrowingStream<String, Error> { continuation in
            continuation.yield("Hello. ")
            continuation.finish()
        }

        try await coordinator.processStream(stream, language: "en")

        let finalState = await coordinator.state
        #expect(finalState == .finishing)
    }

    @Test("Cancel stops TTS and resets state")
    func cancelResetsState() async throws {
        let mockTTS = StreamingMockTTS()
        let coordinator = StreamingTTSCoordinator(ttsService: mockTTS)

        await coordinator.cancel()

        let state = await coordinator.state
        #expect(state == .idle)
    }

    @Test("Latency measurement captures timing data")
    func latencyMeasurement() async throws {
        let mockTTS = StreamingMockTTS()
        let coordinator = StreamingTTSCoordinator(ttsService: mockTTS)

        let stream = AsyncThrowingStream<String, Error> { continuation in
            continuation.yield("Test sentence. ")
            continuation.finish()
        }

        let box = SendableBox<LatencyMeasurement?>(nil)

        try await coordinator.processStream(
            stream,
            language: "en",
            onComplete: { _, m in
                box.set(m)
            }
        )

        let m = box.value
        #expect(m != nil)
        #expect(m!.timeToFirstSpeechMs >= 0)
        #expect(m!.totalDurationMs >= m!.timeToFirstSpeechMs)
        #expect(m!.sentenceCount >= 1)
    }
}
