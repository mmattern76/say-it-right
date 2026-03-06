import Foundation
import SwiftUI

// MARK: - Voice Input State

/// The current state of the voice input flow.
enum VoiceInputState: Sendable, Equatable {
    /// Ready to record. Microphone button is idle.
    case idle
    /// Actively listening and transcribing speech.
    case recording
    /// Recording stopped; user can review/edit before submitting.
    case review
    /// An error occurred during recording or recognition.
    case error(VoiceInputError)
}

/// Errors surfaced to the voice input UI.
enum VoiceInputError: Sendable, Equatable {
    case microphonePermissionDenied
    case speechPermissionDenied
    case recognizerUnavailable
    case noSpeechDetected
    case recognitionFailed

    var localizedTitle: String {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone Access Denied"
        case .speechPermissionDenied:
            return "Speech Recognition Denied"
        case .recognizerUnavailable:
            return "Speech Recognizer Unavailable"
        case .noSpeechDetected:
            return "No Speech Detected"
        case .recognitionFailed:
            return "Recognition Failed"
        }
    }

    var localizedMessage: String {
        switch self {
        case .microphonePermissionDenied:
            return "Please enable microphone access in Settings to use voice input."
        case .speechPermissionDenied:
            return "Please enable speech recognition in Settings to use voice input."
        case .recognizerUnavailable:
            return "Speech recognition is not available right now. Please try again later."
        case .noSpeechDetected:
            return "No speech was detected. Tap the microphone and try speaking again."
        case .recognitionFailed:
            return "Something went wrong with speech recognition. Please try again."
        }
    }

    var localizedTitleDE: String {
        switch self {
        case .microphonePermissionDenied:
            return "Mikrofonzugriff verweigert"
        case .speechPermissionDenied:
            return "Spracherkennung verweigert"
        case .recognizerUnavailable:
            return "Spracherkennung nicht verfügbar"
        case .noSpeechDetected:
            return "Keine Sprache erkannt"
        case .recognitionFailed:
            return "Erkennung fehlgeschlagen"
        }
    }

    var localizedMessageDE: String {
        switch self {
        case .microphonePermissionDenied:
            return "Bitte aktiviere den Mikrofonzugriff in den Einstellungen."
        case .speechPermissionDenied:
            return "Bitte aktiviere die Spracherkennung in den Einstellungen."
        case .recognizerUnavailable:
            return "Die Spracherkennung ist gerade nicht verfügbar. Bitte versuche es später."
        case .noSpeechDetected:
            return "Es wurde keine Sprache erkannt. Tippe auf das Mikrofon und sprich erneut."
        case .recognitionFailed:
            return "Bei der Spracherkennung ist etwas schiefgelaufen. Bitte versuche es erneut."
        }
    }
}

// MARK: - VoiceInputViewModel

/// Manages the voice input recording lifecycle, STT integration, and silence detection.
///
/// This view model coordinates between the `SpeechRecognitionServiceProtocol` and
/// the `AudioSessionManager` to provide a clean state machine for the voice input UI.
///
/// State flow: idle -> recording -> review -> (submit or discard back to idle)
///                                  -> error -> idle
@Observable
@MainActor
final class VoiceInputViewModel {

    // MARK: - Published State

    /// Current state of the voice input flow.
    private(set) var state: VoiceInputState = .idle

    /// The live transcription text, updated as the user speaks.
    private(set) var transcriptionText: String = ""

    /// Editable text for review phase. User can correct before submitting.
    var editableText: String = ""

    /// Audio level for visual feedback (0.0-1.0), updated during recording.
    private(set) var audioLevel: Float = 0.0

    // MARK: - Configuration

    /// Duration of silence before auto-stopping (in seconds).
    var silenceTimeoutDuration: TimeInterval = 2.0

    // MARK: - Dependencies

    private let speechService: SpeechRecognitionServiceProtocol
    private let audioSessionManager: AudioSessionManager?

    // MARK: - Private State

    private var recognitionTask: Task<Void, Never>?
    private var silenceTimer: Task<Void, Never>?
    private var lastTranscriptionTime: Date = .now

    // MARK: - Init

    init(
        speechService: SpeechRecognitionServiceProtocol,
        audioSessionManager: AudioSessionManager? = nil
    ) {
        self.speechService = speechService
        self.audioSessionManager = audioSessionManager
    }

    // MARK: - Public API

    /// Toggle recording on/off. Main entry point for the microphone button.
    func toggleRecording() {
        switch state {
        case .idle, .error:
            Task { await startRecording() }
        case .recording:
            stopRecording()
        case .review:
            // In review state, tapping mic starts a new recording
            discardAndRestart()
        }
    }

    /// Start a new recording session.
    func startRecording() async {
        // Check authorization first
        let authStatus = speechService.authorizationStatus
        if authStatus == .notDetermined {
            let result = await speechService.requestAuthorization()
            if result != .authorized {
                state = .error(mapAuthError(result))
                return
            }
        } else if authStatus != .authorized {
            state = .error(mapAuthError(authStatus))
            return
        }

        guard speechService.isAvailable else {
            state = .error(.recognizerUnavailable)
            return
        }

        // Activate audio session for recording
        audioSessionManager?.activateForRecording()

        // Reset state
        transcriptionText = ""
        editableText = ""
        audioLevel = 0.0
        state = .recording
        lastTranscriptionTime = .now

        // Start recognition
        recognitionTask = Task { [weak self] in
            guard let self else { return }
            do {
                let stream = try await speechService.startRecognition()
                for await transcription in stream {
                    guard !Task.isCancelled else { break }
                    await self.handleTranscription(transcription)
                }
                // Stream ended naturally
                await self.handleStreamEnd()
            } catch {
                await self.handleRecognitionError(error)
            }
        }

        // Start silence detection
        startSilenceDetection()
    }

    /// Stop the current recording manually.
    func stopRecording() {
        guard state == .recording else { return }

        cancelSilenceTimer()
        speechService.stopRecognition()
        recognitionTask?.cancel()
        recognitionTask = nil
        audioLevel = 0.0

        // Deactivate recording audio session
        audioSessionManager?.deactivateRecording()

        if transcriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            state = .error(.noSpeechDetected)
        } else {
            editableText = transcriptionText
            state = .review
        }
    }

    /// Submit the current transcription (after optional editing).
    /// Returns the final text to send to the conversation.
    func submitTranscription() -> String? {
        guard state == .review else { return nil }
        let text = editableText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        reset()
        return text
    }

    /// Discard the current transcription and return to idle.
    func discardTranscription() {
        reset()
    }

    /// Discard current and immediately start a new recording.
    func discardAndRestart() {
        reset()
        Task { await startRecording() }
    }

    /// Reset everything to idle state.
    func reset() {
        cancelSilenceTimer()
        speechService.stopRecognition()
        recognitionTask?.cancel()
        recognitionTask = nil
        audioSessionManager?.deactivateRecording()

        transcriptionText = ""
        editableText = ""
        audioLevel = 0.0
        state = .idle
    }

    // MARK: - Private

    private func handleTranscription(_ transcription: SpeechTranscription) async {
        transcriptionText = transcription.text
        lastTranscriptionTime = .now

        // Simulate audio level from confidence for visual feedback
        if let confidence = transcription.confidence {
            audioLevel = max(0.3, confidence)
        } else {
            audioLevel = 0.6
        }

        if transcription.isFinal {
            stopRecording()
        }
    }

    private func handleStreamEnd() async {
        guard state == .recording else { return }
        stopRecording()
    }

    private func handleRecognitionError(_ error: Error) async {
        cancelSilenceTimer()
        recognitionTask = nil
        audioLevel = 0.0
        audioSessionManager?.deactivateRecording()

        if let sttError = error as? SpeechRecognitionError {
            switch sttError {
            case .permissionDenied:
                state = .error(.speechPermissionDenied)
            case .recognizerUnavailable:
                state = .error(.recognizerUnavailable)
            case .noSpeechDetected:
                state = .error(.noSpeechDetected)
            case .recognitionFailed:
                state = .error(.recognitionFailed)
            case .audioEngineError:
                state = .error(.recognitionFailed)
            }
        } else {
            state = .error(.recognitionFailed)
        }
    }

    private func mapAuthError(_ status: SpeechAuthorizationStatus) -> VoiceInputError {
        switch status {
        case .denied, .restricted:
            return .speechPermissionDenied
        case .notDetermined:
            return .speechPermissionDenied
        case .authorized:
            return .recognitionFailed // Should not happen
        }
    }

    // MARK: - Silence Detection

    private func startSilenceDetection() {
        cancelSilenceTimer()
        silenceTimer = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { break }
                let elapsed = Date.now.timeIntervalSince(self.lastTranscriptionTime)
                if elapsed >= self.silenceTimeoutDuration && self.state == .recording {
                    // Only auto-stop if we have some transcription
                    if !self.transcriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        self.stopRecording()
                        break
                    }
                }
            }
        }
    }

    private func cancelSilenceTimer() {
        silenceTimer?.cancel()
        silenceTimer = nil
    }
}
