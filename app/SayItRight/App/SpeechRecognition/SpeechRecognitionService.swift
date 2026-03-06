import Foundation
#if canImport(Speech)
import Speech
#endif

// MARK: - Protocol

/// Errors that can occur during speech recognition.
enum SpeechRecognitionError: Error, Sendable, Equatable {
    case permissionDenied
    case recognizerUnavailable
    case noSpeechDetected
    case recognitionFailed(String)
    case audioEngineError(String)
}

/// Authorization status for speech recognition.
enum SpeechAuthorizationStatus: Sendable {
    case notDetermined
    case denied
    case restricted
    case authorized
}

/// A partial transcription result from the recognizer.
struct SpeechTranscription: Sendable {
    /// The current best transcription text.
    let text: String
    /// Whether the recognizer considers this result final.
    let isFinal: Bool
    /// Confidence score (0.0-1.0), if available.
    let confidence: Float?
}

/// Protocol for speech recognition, enabling testability via mock implementations.
protocol SpeechRecognitionServiceProtocol: Sendable {
    /// Current authorization status.
    var authorizationStatus: SpeechAuthorizationStatus { get }

    /// Request speech recognition authorization from the user.
    /// Returns the resulting authorization status.
    func requestAuthorization() async -> SpeechAuthorizationStatus

    /// Whether the recognizer is currently available for the configured locale.
    var isAvailable: Bool { get }

    /// Start recognition and return an AsyncStream of partial results.
    /// Throws if permissions are denied or the recognizer is unavailable.
    func startRecognition() async throws -> AsyncStream<SpeechTranscription>

    /// Stop the current recognition session.
    func stopRecognition()

    /// Update the recognition locale (e.g. when the learner switches language).
    func setLocale(_ locale: SpeechLocale)
}

/// Supported speech recognition locales.
enum SpeechLocale: String, Sendable {
    case german = "de-DE"
    case english = "en-US"

    init(appLanguage: String) {
        self = appLanguage == "de" ? .german : .english
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }
}

// MARK: - Live Implementation

#if canImport(Speech)

/// Live speech recognition service using SFSpeechRecognizer.
///
/// Placed in the App layer as a service object for dependency injection.
/// Not owned by any view — injected via the DI container.
///
/// Thread safety is achieved via `os_unfair_lock` (through `NSLock`) for
/// synchronous property access, while the async `startRecognition` method
/// delegates to a nonisolated helper that sets up the recognition pipeline.
final class LiveSpeechRecognitionService: SpeechRecognitionServiceProtocol, @unchecked Sendable {

    // MARK: - State

    /// Internal mutable state protected by the Mutex-like pattern below.
    /// All reads/writes go through `withState`.
    private struct State {
        var locale: SpeechLocale
        var recognizer: SFSpeechRecognizer?
        var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
        var recognitionTask: SFSpeechRecognitionTask?
        var audioEngine: AVAudioEngine?
        var isRecognizing: Bool = false
    }

    private let stateLock = NSLock()
    private var state: State

    // MARK: - Init

    init(locale: SpeechLocale = .english) {
        let recognizer = SFSpeechRecognizer(locale: locale.locale)
        recognizer?.defaultTaskHint = .dictation
        self.state = State(locale: locale, recognizer: recognizer)
    }

    // MARK: - Synchronized state access (non-async only)

    private func withState<T>(_ body: (inout State) -> T) -> T {
        stateLock.lock()
        defer { stateLock.unlock() }
        return body(&state)
    }

    private func withStateThrowing<T>(_ body: (inout State) throws -> T) throws -> T {
        stateLock.lock()
        defer { stateLock.unlock() }
        return try body(&state)
    }

    // MARK: - Protocol

    var authorizationStatus: SpeechAuthorizationStatus {
        Self.mapStatus(SFSpeechRecognizer.authorizationStatus())
    }

    func requestAuthorization() async -> SpeechAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: Self.mapStatus(status))
            }
        }
    }

    var isAvailable: Bool {
        withState { $0.recognizer?.isAvailable ?? false }
    }

    func startRecognition() async throws -> AsyncStream<SpeechTranscription> {
        // Pre-check authorization (this property access is synchronous)
        let status = authorizationStatus
        guard status == .authorized else {
            throw SpeechRecognitionError.permissionDenied
        }

        // Prepare synchronously under the lock
        let recognizer: SFSpeechRecognizer = try withStateThrowing { state in
            guard let rec = state.recognizer, rec.isAvailable else {
                throw SpeechRecognitionError.recognizerUnavailable
            }
            // Clean up any existing session
            Self.cleanupState(&state)
            return rec
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }

        // Set up audio engine
        let audioEngine = AVAudioEngine()
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            throw SpeechRecognitionError.audioEngineError(error.localizedDescription)
        }

        // Store references synchronously
        withState { state in
            state.recognitionRequest = request
            state.audioEngine = audioEngine
            state.isRecognizing = true
        }

        // Build and return the stream
        return buildStream(recognizer: recognizer, request: request)
    }

    func stopRecognition() {
        withState { state in
            Self.cleanupState(&state)
        }
    }

    func setLocale(_ locale: SpeechLocale) {
        withState { state in
            Self.cleanupState(&state)
            state.locale = locale
            let recognizer = SFSpeechRecognizer(locale: locale.locale)
            recognizer?.defaultTaskHint = .dictation
            state.recognizer = recognizer
        }
    }

    // MARK: - Private

    /// Build the AsyncStream that drives partial results to the caller.
    /// This is nonisolated and synchronous — safe to call from async context.
    private nonisolated func buildStream(
        recognizer: SFSpeechRecognizer,
        request: SFSpeechAudioBufferRecognitionRequest
    ) -> AsyncStream<SpeechTranscription> {
        AsyncStream { [weak self] continuation in
            let task = recognizer.recognitionTask(with: request) { result, error in
                if let result {
                    let transcription = SpeechTranscription(
                        text: result.bestTranscription.formattedString,
                        isFinal: result.isFinal,
                        confidence: result.bestTranscription.segments.last
                            .map { Float($0.confidence) }
                    )
                    continuation.yield(transcription)

                    if result.isFinal {
                        self?.stopRecognition()
                        continuation.finish()
                    }
                }

                if let error {
                    #if DEBUG
                    let nsError = error as NSError
                    print("[SpeechRecognition] Error: \(nsError.domain) \(nsError.code)")
                    #endif
                    self?.stopRecognition()
                    continuation.finish()
                }
            }

            self?.withState { state in
                state.recognitionTask = task
            }

            let service = self
            continuation.onTermination = { @Sendable _ in
                service?.stopRecognition()
            }
        }
    }

    /// Clean up all recognition resources. Must be called while holding the lock
    /// (i.e. inside `withState`).
    private static func cleanupState(_ state: inout State) {
        state.recognitionTask?.cancel()
        state.recognitionTask = nil

        state.recognitionRequest?.endAudio()
        state.recognitionRequest = nil

        if let engine = state.audioEngine, engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        state.audioEngine = nil

        state.isRecognizing = false
    }

    private static func mapStatus(
        _ status: SFSpeechRecognizerAuthorizationStatus
    ) -> SpeechAuthorizationStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .denied: .denied
        case .restricted: .restricted
        case .authorized: .authorized
        @unknown default: .denied
        }
    }
}

#endif
