import Foundation

/// TTS service used when Silent Mode is active.
///
/// Conforms to ``TTSPlaybackService`` but ignores every call. No audio is
/// produced, no events are emitted, no audio session is activated. This lets
/// callers stay protocol-typed and avoid sprinkling silent-mode checks
/// throughout the voice and chat layers.
final class NoOpTTSService: TTSPlaybackService, @unchecked Sendable {
    var state: TTSPlaybackState {
        .idle
    }

    var isAutoPlayEnabled = false
    var configuration: TTSConfiguration = .default

    func speak(
        _: String,
        language _: String,
        onEvent _: (@Sendable (TTSEvent) -> Void)?
    ) {
    }

    func pause() {
    }

    func resume() {
    }

    func stop() {
    }

    func replayLast(onEvent _: (@Sendable (TTSEvent) -> Void)?) {
    }

    func prewarm() {
    }
}
