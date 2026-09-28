import Foundation

/// Box type that wraps any TTSPlaybackService for use with @State.
///
/// SwiftUI @State requires a concrete type. This box wraps the protocol
/// existential so the voice views can use either Apple or ElevenLabs TTS
/// without knowing which implementation is active.
final class TTSServiceBox: NSObject, TTSPlaybackService, @unchecked Sendable {
    private let wrapped: any TTSPlaybackService

    init(wrapping service: any TTSPlaybackService) {
        self.wrapped = service
    }

    var state: TTSPlaybackState {
        wrapped.state
    }

    var isAutoPlayEnabled: Bool {
        get { wrapped.isAutoPlayEnabled }
        set { wrapped.isAutoPlayEnabled = newValue }
    }

    var configuration: TTSConfiguration {
        get { wrapped.configuration }
        set { wrapped.configuration = newValue }
    }

    func speak(_ text: String, language: String, onEvent: (@Sendable (TTSEvent) -> Void)?) {
        wrapped.speak(text, language: language, onEvent: onEvent)
    }

    func pause() {
        wrapped.pause()
    }

    func resume() {
        wrapped.resume()
    }

    func stop() {
        wrapped.stop()
    }

    func replayLast(onEvent: (@Sendable (TTSEvent) -> Void)?) {
        wrapped.replayLast(onEvent: onEvent)
    }

    func prewarm() {
        wrapped.prewarm()
    }
}

/// Creates the appropriate TTS service based on user settings.
enum TTSServiceFactory {
    /// Returns a boxed TTS service:
    /// - ``NoOpTTSService`` when Silent Mode is active (settings or
    ///   `SIR_TTS_DISABLED` launch-environment variable)
    /// - ``ElevenLabsTTSService`` when the engine is set to ElevenLabs and
    ///   a key is available
    /// - ``AppleTTSPlaybackService`` otherwise
    ///
    /// The ElevenLabs service includes automatic fallback to Apple TTS
    /// when the API is unreachable, so this is safe to call unconditionally.
    static func makeService() -> TTSServiceBox {
        let settings = AppSettings.shared
        if settings.effectiveIsTTSDisabled {
            return TTSServiceBox(wrapping: NoOpTTSService())
        }
        if settings.isElevenLabsEnabled, settings.elevenLabsAPIKey != nil {
            return TTSServiceBox(wrapping: ElevenLabsTTSService())
        }
        return TTSServiceBox(wrapping: AppleTTSPlaybackService())
    }
}
