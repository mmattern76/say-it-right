import AVFoundation

// MARK: - TTSPlaybackState

/// Observable state of the TTS playback engine.
enum TTSPlaybackState: Sendable, Equatable {
    case idle
    case speaking
    case paused
}

// MARK: - TTSEvent

/// Events emitted by the TTS engine during speech synthesis.
enum TTSEvent: Sendable, Equatable {
    /// Speech started for an utterance.
    case started
    /// Speech finished for an utterance.
    case finished
    /// A word boundary was reached — used for text highlighting.
    case wordBoundary(range: Range<String.Index>)
    /// Speech was interrupted (e.g. audio route change, app backgrounding).
    case interrupted
}

// MARK: - TTSConfiguration

/// Voice tuning parameters for Barbara's speech.
struct TTSConfiguration: Sendable, Equatable {
    /// Speech rate (0.0–1.0). Default is AVSpeechUtteranceDefaultSpeechRate.
    var rate: Float = AVSpeechUtteranceDefaultSpeechRate

    /// Pitch multiplier (0.5–2.0). 1.0 is normal.
    var pitchMultiplier: Float = 1.0

    /// Volume (0.0–1.0). 1.0 is maximum.
    var volume: Float = 1.0

    /// Specific voice identifier, if any. When nil, uses default for language.
    var voiceIdentifier: String?

    static let `default` = TTSConfiguration()
}

// MARK: - TTSPlaybackService Protocol

/// Protocol for text-to-speech playback, enabling DI and testability.
///
/// The service manages an utterance queue and provides callbacks for
/// speech events (started, finished, word boundary) to enable
/// synchronized text highlighting in the chat UI.
protocol TTSPlaybackService: AnyObject, Sendable {

    /// Current playback state.
    var state: TTSPlaybackState { get }

    /// Whether Barbara speaks immediately when a response arrives.
    var isAutoPlayEnabled: Bool { get set }

    /// Voice tuning configuration.
    var configuration: TTSConfiguration { get set }

    /// Speak the given text aloud.
    ///
    /// Queues the text as one or more utterances. If already speaking,
    /// the new text is appended to the queue.
    ///
    /// - Parameters:
    ///   - text: The text to speak.
    ///   - language: BCP 47 language tag (e.g. "en" or "de").
    ///   - onEvent: Callback for speech events.
    func speak(
        _ text: String,
        language: String,
        onEvent: (@Sendable (TTSEvent) -> Void)?
    )

    /// Pause current speech. Can be resumed with `resume()`.
    func pause()

    /// Resume paused speech.
    func resume()

    /// Stop all speech and clear the queue.
    func stop()

    /// Replay the last utterance that was spoken.
    ///
    /// - Parameter onEvent: Callback for speech events.
    func replayLast(onEvent: (@Sendable (TTSEvent) -> Void)?)

    /// Pre-warm the synthesizer to reduce first-utterance latency.
    func prewarm()
}

// MARK: - AppleTTSPlaybackService

/// Production implementation using AVSpeechSynthesizer.
///
/// This class wraps AVSpeechSynthesizer with an async-friendly API,
/// manages utterance queuing, and bridges delegate callbacks into
/// the `TTSEvent` callback pattern.
final class AppleTTSPlaybackService: NSObject, TTSPlaybackService, @unchecked Sendable {

    // MARK: - Properties

    private let synthesizer = AVSpeechSynthesizer()
    private let lock = NSLock()

    private var _state: TTSPlaybackState = .idle
    var state: TTSPlaybackState {
        lock.lock()
        defer { lock.unlock() }
        return _state
    }

    var isAutoPlayEnabled: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _isAutoPlayEnabled
        }
        set {
            lock.lock()
            _isAutoPlayEnabled = newValue
            lock.unlock()
        }
    }
    private var _isAutoPlayEnabled: Bool = true

    var configuration: TTSConfiguration {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _configuration
        }
        set {
            lock.lock()
            _configuration = newValue
            lock.unlock()
        }
    }
    private var _configuration: TTSConfiguration = .default

    /// The last text+language pair that was spoken, for replay.
    private var _lastText: String?
    private var _lastLanguage: String?

    /// Maps AVSpeechUtterance to its original text for word boundary calculations.
    private var utteranceTextMap: [AVSpeechUtterance: String] = [:]

    /// Current event callback (set per speak/replay call).
    private var _onEvent: (@Sendable (TTSEvent) -> Void)?

    // MARK: - Init

    override init() {
        super.init()
        synthesizer.delegate = self
        registerForInterruptionNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - TTSPlaybackService

    func speak(
        _ text: String,
        language: String,
        onEvent: (@Sendable (TTSEvent) -> Void)?
    ) {
        lock.lock()
        _lastText = text
        _lastLanguage = language
        _onEvent = onEvent
        let config = _configuration
        lock.unlock()

        let sentences = splitIntoSentences(text)
        guard !sentences.isEmpty else { return }

        for sentence in sentences {
            let utterance = makeUtterance(
                text: sentence,
                language: language,
                configuration: config
            )
            lock.lock()
            utteranceTextMap[utterance] = sentence
            lock.unlock()
            synthesizer.speak(utterance)
        }
    }

    func pause() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.pauseSpeaking(at: .word)
        lock.lock()
        _state = .paused
        lock.unlock()
    }

    func resume() {
        guard synthesizer.isPaused else { return }
        synthesizer.continueSpeaking()
        lock.lock()
        _state = .speaking
        lock.unlock()
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        lock.lock()
        _state = .idle
        utteranceTextMap.removeAll()
        lock.unlock()
    }

    func replayLast(onEvent: (@Sendable (TTSEvent) -> Void)?) {
        lock.lock()
        let text = _lastText
        let language = _lastLanguage
        lock.unlock()

        guard let text, let language else { return }

        stop()
        speak(text, language: language, onEvent: onEvent)
    }

    func prewarm() {
        // Speak an empty utterance to initialize the synthesizer pipeline.
        // This reduces latency on the first real utterance.
        let utterance = AVSpeechUtterance(string: " ")
        utterance.volume = 0
        synthesizer.speak(utterance)
    }

    // MARK: - Private Helpers

    private func makeUtterance(
        text: String,
        language: String,
        configuration: TTSConfiguration
    ) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)

        // Voice selection: prefer explicit identifier, fall back to language default.
        if let identifier = configuration.voiceIdentifier {
            utterance.voice = AVSpeechSynthesisVoice(identifier: identifier)
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: language)
        }

        utterance.rate = configuration.rate
        utterance.pitchMultiplier = configuration.pitchMultiplier
        utterance.volume = configuration.volume

        // Minimal pre/post delay for smooth sentence-to-sentence flow.
        utterance.preUtteranceDelay = 0.05
        utterance.postUtteranceDelay = 0.1

        return utterance
    }

    /// Splits text into sentences for gap-free utterance queuing.
    ///
    /// Uses NSLinguisticTagger-style sentence boundary detection via
    /// the Foundation string enumerateSubstrings API.
    func splitIntoSentences(_ text: String) -> [String] {
        var sentences: [String] = []
        text.enumerateSubstrings(
            in: text.startIndex..<text.endIndex,
            options: [.bySentences, .localized]
        ) { substring, _, _, _ in
            if let sentence = substring?.trimmingCharacters(in: .whitespacesAndNewlines),
               !sentence.isEmpty {
                sentences.append(sentence)
            }
        }
        // Fallback: if enumeration yields nothing, use the full text.
        if sentences.isEmpty && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sentences.append(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return sentences
    }

    // MARK: - Interruption Handling

    private func registerForInterruptionNotifications() {
        #if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        #endif
    }

    #if os(iOS)
    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            lock.lock()
            let callback = _onEvent
            _state = .paused
            lock.unlock()
            callback?(.interrupted)
        case .ended:
            // Optionally resume, but safer to let the user manually resume.
            break
        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
        else { return }

        if reason == .oldDeviceUnavailable {
            // Headphones unplugged — pause speech.
            pause()
            lock.lock()
            let callback = _onEvent
            lock.unlock()
            callback?(.interrupted)
        }
    }
    #endif
}

// MARK: - AVSpeechSynthesizerDelegate

extension AppleTTSPlaybackService: AVSpeechSynthesizerDelegate {

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didStart utterance: AVSpeechUtterance
    ) {
        lock.lock()
        _state = .speaking
        let callback = _onEvent
        lock.unlock()
        callback?(.started)
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        lock.lock()
        utteranceTextMap.removeValue(forKey: utterance)
        // Only go idle if no more utterances are queued.
        if !synthesizer.isSpeaking {
            _state = .idle
        }
        let callback = _onEvent
        lock.unlock()
        callback?(.finished)
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        lock.lock()
        utteranceTextMap.removeValue(forKey: utterance)
        if !synthesizer.isSpeaking {
            _state = .idle
        }
        lock.unlock()
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        lock.lock()
        let originalText = utteranceTextMap[utterance] ?? utterance.speechString
        let callback = _onEvent
        lock.unlock()

        // Convert NSRange to Range<String.Index> using the original text.
        guard let swiftRange = Range(characterRange, in: originalText) else { return }
        callback?(.wordBoundary(range: swiftRange))
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didPause utterance: AVSpeechUtterance
    ) {
        lock.lock()
        _state = .paused
        lock.unlock()
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didContinue utterance: AVSpeechUtterance
    ) {
        lock.lock()
        _state = .speaking
        lock.unlock()
    }
}
