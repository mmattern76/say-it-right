import AVFoundation

/// ElevenLabs TTS implementation for Barbara's voice.
///
/// Calls the ElevenLabs text-to-speech streaming API and plays the
/// returned audio via AVAudioPlayer. Falls back to Apple TTS if the
/// API call fails (network error, invalid key, etc.).
final class ElevenLabsTTSService: NSObject, TTSPlaybackService, @unchecked Sendable {
    // MARK: - Configuration

    /// Default voice IDs per language.
    static let defaultVoiceIDs: [String: String] = [
        "de": "8wPhfH9uUzEMHTmRkoAR",
        "en": "H1GhCI6GEKiSXZcwmUkc",
    ]

    // MARK: - Properties

    private let lock = NSLock()
    private var _state: TTSPlaybackState = .idle
    private var _isAutoPlayEnabled = true
    private var _configuration: TTSConfiguration = .default
    private var _lastText: String?
    private var _lastLanguage: String?
    private var _onEvent: (@Sendable (TTSEvent) -> Void)?
    private var audioPlayer: AVAudioPlayer?
    private var currentTask: Task<Void, Never>?

    /// Fallback to Apple TTS when ElevenLabs is unavailable.
    private let appleFallback = AppleTTSPlaybackService()

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
            appleFallback.isAutoPlayEnabled = newValue
        }
    }

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
            appleFallback.configuration = newValue
        }
    }

    // MARK: - Init

    override init() {
        super.init()
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
        lock.unlock()

        // Cancel any in-flight request
        currentTask?.cancel()

        currentTask = Task { [weak self] in
            guard let self else { return }

            let settings = AppSettings.shared
            guard let apiKey = settings.elevenLabsAPIKey, !apiKey.isEmpty else {
                // No API key — fall back to Apple TTS
                appleFallback.speak(text, language: language, onEvent: onEvent)
                return
            }

            let langCode = language.hasPrefix("de") ? "de" : "en"
            let voiceID = Self.defaultVoiceIDs[langCode] ?? Self.defaultVoiceIDs["en"]!

            do {
                let audioData = try await fetchAudio(
                    text: text,
                    voiceID: voiceID,
                    apiKey: apiKey
                )

                if Task.isCancelled { return }

                await MainActor.run {
                    self.playAudio(audioData, onEvent: onEvent)
                }
            } catch {
                // Fall back to Apple TTS on any error
                appleFallback.speak(text, language: language, onEvent: onEvent)
            }
        }
    }

    func pause() {
        lock.lock()
        let player = audioPlayer
        lock.unlock()

        if let player, player.isPlaying {
            player.pause()
            lock.lock()
            _state = .paused
            lock.unlock()
        } else {
            appleFallback.pause()
        }
    }

    func resume() {
        lock.lock()
        let player = audioPlayer
        lock.unlock()

        if let player, !player.isPlaying {
            player.play()
            lock.lock()
            _state = .speaking
            lock.unlock()
        } else {
            appleFallback.resume()
        }
    }

    func stop() {
        currentTask?.cancel()
        lock.lock()
        audioPlayer?.stop()
        audioPlayer = nil
        _state = .idle
        lock.unlock()
        appleFallback.stop()
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
        // No prewarm needed for ElevenLabs
        appleFallback.prewarm()
    }

    // MARK: - ElevenLabs API

    private func fetchAudio(
        text: String,
        voiceID: String,
        apiKey: String
    ) async throws -> Data {
        let urlString = "https://api.elevenlabs.io/v1/text-to-speech/\(voiceID)"
        guard let url = URL(string: urlString) else {
            throw ElevenLabsError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        let body: [String: Any] = [
            "text": text,
            "model_id": "eleven_multilingual_v2",
            "voice_settings": [
                "stability": 0.6,
                "similarity_boost": 0.8,
                "style": 0.35,
                "use_speaker_boost": true,
            ],
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ElevenLabsError.unexpectedResponse
        }

        guard http.statusCode == 200 else {
            throw ElevenLabsError.apiError(statusCode: http.statusCode)
        }

        guard !data.isEmpty else {
            throw ElevenLabsError.emptyResponse
        }

        return data
    }

    // MARK: - Audio Playback

    @MainActor
    private func playAudio(_ data: Data, onEvent: (@Sendable (TTSEvent) -> Void)?) {
        do {
            let player = try AVAudioPlayer(data: data)
            player.delegate = self

            lock.lock()
            audioPlayer = player
            _state = .speaking
            _onEvent = onEvent
            lock.unlock()

            onEvent?(.started)
            player.play()
        } catch {
            // Fall back to Apple TTS
            lock.lock()
            let text = _lastText
            let language = _lastLanguage
            lock.unlock()

            if let text, let language {
                appleFallback.speak(text, language: language, onEvent: onEvent)
            }
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension ElevenLabsTTSService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) {
        lock.lock()
        _state = .idle
        audioPlayer = nil
        let callback = _onEvent
        lock.unlock()
        callback?(.finished)
    }

    func audioPlayerDecodeErrorDidOccur(_: AVAudioPlayer, error _: (any Error)?) {
        lock.lock()
        _state = .idle
        audioPlayer = nil
        lock.unlock()
    }
}

// MARK: - Errors

private enum ElevenLabsError: Error {
    case invalidURL
    case unexpectedResponse
    case apiError(statusCode: Int)
    case emptyResponse
}
