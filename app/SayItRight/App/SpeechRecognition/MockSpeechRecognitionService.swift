import Foundation

/// Mock implementation of SpeechRecognitionServiceProtocol for testing and SwiftUI previews.
///
/// Configure the mock's behavior by setting properties before use:
/// ```
/// let mock = MockSpeechRecognitionService()
/// mock.stubbedAuthorizationStatus = .denied
/// // Now calls to startRecognition() will throw .permissionDenied
/// ```
final class MockSpeechRecognitionService: SpeechRecognitionServiceProtocol, @unchecked Sendable {

    // MARK: - Stubbed values

    var stubbedAuthorizationStatus: SpeechAuthorizationStatus = .authorized
    var stubbedIsAvailable: Bool = true
    var stubbedTranscriptions: [SpeechTranscription] = []
    var stubbedError: SpeechRecognitionError?

    // MARK: - Call tracking

    private(set) var requestAuthorizationCallCount = 0
    private(set) var startRecognitionCallCount = 0
    private(set) var stopRecognitionCallCount = 0
    private(set) var setLocaleCallCount = 0
    private(set) var lastSetLocale: SpeechLocale?

    // MARK: - Protocol

    var authorizationStatus: SpeechAuthorizationStatus {
        stubbedAuthorizationStatus
    }

    func requestAuthorization() async -> SpeechAuthorizationStatus {
        requestAuthorizationCallCount += 1
        return stubbedAuthorizationStatus
    }

    var isAvailable: Bool {
        stubbedIsAvailable
    }

    func startRecognition() async throws -> AsyncStream<SpeechTranscription> {
        startRecognitionCallCount += 1

        if let error = stubbedError {
            throw error
        }

        if stubbedAuthorizationStatus != .authorized {
            throw SpeechRecognitionError.permissionDenied
        }

        if !stubbedIsAvailable {
            throw SpeechRecognitionError.recognizerUnavailable
        }

        let transcriptions = stubbedTranscriptions
        return AsyncStream { continuation in
            for transcription in transcriptions {
                continuation.yield(transcription)
            }
            continuation.finish()
        }
    }

    func stopRecognition() {
        stopRecognitionCallCount += 1
    }

    func setLocale(_ locale: SpeechLocale) {
        setLocaleCallCount += 1
        lastSetLocale = locale
    }
}
