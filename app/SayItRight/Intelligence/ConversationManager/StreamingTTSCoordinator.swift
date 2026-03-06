import Foundation

// MARK: - StreamingTTSState

/// Observable state of the streaming TTS pipeline.
enum StreamingTTSState: Sendable, Equatable {
    /// No streaming in progress.
    case idle
    /// Waiting for the first sentence from the API.
    case waitingForFirstSentence
    /// Barbara is speaking (first or subsequent sentence).
    case speaking
    /// Stream complete, TTS finishing remaining utterances.
    case finishing
}

// MARK: - LatencyMeasurement

/// Latency data for a single streaming TTS interaction.
struct LatencyMeasurement: Sendable {
    /// Time from request start to first TTS utterance beginning.
    let timeToFirstSpeechMs: Int
    /// Total time from request start to final TTS utterance finishing.
    let totalDurationMs: Int
    /// Number of sentences spoken.
    let sentenceCount: Int
}

// MARK: - StreamingTTSCoordinator

/// Orchestrates the streaming TTS pipeline: API stream -> sentence detection -> TTS queue.
///
/// This coordinator connects three components:
/// 1. `AnthropicService` — streams text deltas from the API
/// 2. `StreamingSentenceDetector` — accumulates deltas and emits complete sentences
/// 3. `TTSPlaybackService` — queues sentences as utterances for immediate playback
///
/// The result is that Barbara begins speaking the first sentence while remaining
/// sentences are still streaming from the API. Target latency: median < 3s on WiFi.
///
/// **Latency logging**: Each interaction records the time from stream start to
/// first TTS utterance, logged via `DebugLogger`.
actor StreamingTTSCoordinator {

    // MARK: - Dependencies

    private let ttsService: TTSPlaybackService
    private let sentenceDetector: StreamingSentenceDetector

    // MARK: - State

    private var _state: StreamingTTSState = .idle
    var state: StreamingTTSState { _state }

    /// Accumulated full response text (for ResponseParser after stream completes).
    private var fullResponseText: String = ""

    /// Buffer for sentence detection.
    private var buffer: String = ""
    private var metadataStarted: Bool = false

    /// Latency tracking.
    private var streamStartTime: Date?
    private var firstSpeechTime: Date?
    private var sentenceCount: Int = 0

    // MARK: - Init

    init(
        ttsService: TTSPlaybackService,
        sentenceDetector: StreamingSentenceDetector = StreamingSentenceDetector()
    ) {
        self.ttsService = ttsService
        self.sentenceDetector = sentenceDetector
    }

    // MARK: - Public API

    /// Process a streaming API response, feeding sentences to TTS as they arrive.
    ///
    /// - Parameters:
    ///   - stream: The `AsyncThrowingStream` of text deltas from `AnthropicService`.
    ///   - language: BCP 47 language tag for TTS voice selection (e.g. "en", "de").
    ///   - onFirstSentence: Called when the first sentence begins speaking.
    ///   - onVisibleText: Called with each sentence's text for UI display.
    ///   - onComplete: Called with the full response text and latency measurement.
    /// - Throws: Re-throws any errors from the API stream.
    func processStream(
        _ stream: AsyncThrowingStream<String, Error>,
        language: String,
        onFirstSentence: (@Sendable () -> Void)? = nil,
        onVisibleText: (@Sendable (String) -> Void)? = nil,
        onComplete: (@Sendable (String, LatencyMeasurement?) -> Void)? = nil
    ) async throws {
        // Reset state
        reset()
        _state = .waitingForFirstSentence
        streamStartTime = Date()

        do {
            for try await chunk in stream {
                fullResponseText.append(chunk)

                let sentences = sentenceDetector.feed(
                    chunk,
                    into: &buffer,
                    metadataStarted: &metadataStarted
                )

                for sentence in sentences {
                    enqueueSentence(sentence, language: language)
                    onVisibleText?(sentence.text)

                    if sentenceCount == 1 {
                        onFirstSentence?()
                    }
                }
            }

            // Stream finished — flush remaining buffer
            if let finalSentence = sentenceDetector.flush(
                buffer: &buffer,
                metadataStarted: metadataStarted
            ) {
                enqueueSentence(finalSentence, language: language)
                onVisibleText?(finalSentence.text)

                if sentenceCount == 1 {
                    onFirstSentence?()
                }
            }

            _state = .finishing

            let measurement = buildMeasurement()
            await logLatency(measurement)

            onComplete?(fullResponseText, measurement)

        } catch {
            _state = .idle
            ttsService.stop()
            throw error
        }
    }

    /// Stop the current streaming TTS session.
    func cancel() {
        ttsService.stop()
        reset()
    }

    // MARK: - Private

    private func reset() {
        _state = .idle
        fullResponseText = ""
        buffer = ""
        metadataStarted = false
        streamStartTime = nil
        firstSpeechTime = nil
        sentenceCount = 0
    }

    private func enqueueSentence(
        _ sentence: StreamingSentenceDetector.Sentence,
        language: String
    ) {
        sentenceCount += 1
        _state = .speaking

        if firstSpeechTime == nil {
            firstSpeechTime = Date()
        }

        // TTS speak() queues utterances — they play sequentially with no gap.
        ttsService.speak(sentence.text, language: language, onEvent: nil)
    }

    private func buildMeasurement() -> LatencyMeasurement? {
        guard let start = streamStartTime else { return nil }

        let now = Date()
        let totalMs = Int(now.timeIntervalSince(start) * 1000)
        let firstSpeechMs: Int
        if let firstSpeech = firstSpeechTime {
            firstSpeechMs = Int(firstSpeech.timeIntervalSince(start) * 1000)
        } else {
            firstSpeechMs = totalMs
        }

        return LatencyMeasurement(
            timeToFirstSpeechMs: firstSpeechMs,
            totalDurationMs: totalMs,
            sentenceCount: sentenceCount
        )
    }

    private func logLatency(_ measurement: LatencyMeasurement?) async {
        guard let measurement else { return }

        await DebugLogger.shared.log(.sessionEvent, data: [
            "event": "streaming_tts_latency",
            "time_to_first_speech_ms": "\(measurement.timeToFirstSpeechMs)",
            "total_duration_ms": "\(measurement.totalDurationMs)",
            "sentence_count": "\(measurement.sentenceCount)"
        ])
    }
}
