import Foundation
import Testing

@testable import SayItRight

// MARK: - SpeechLocale Tests

@Suite("SpeechLocale")
struct SpeechLocaleTests {

    @Test("German language maps to de-DE locale")
    func germanLocale() {
        let locale = SpeechLocale(appLanguage: "de")
        #expect(locale == .german)
        #expect(locale.rawValue == "de-DE")
        #expect(locale.locale.identifier == "de-DE")
    }

    @Test("English language maps to en-US locale")
    func englishLocale() {
        let locale = SpeechLocale(appLanguage: "en")
        #expect(locale == .english)
        #expect(locale.rawValue == "en-US")
        #expect(locale.locale.identifier == "en-US")
    }

    @Test("Unknown language defaults to English")
    func unknownLanguageDefaultsToEnglish() {
        let locale = SpeechLocale(appLanguage: "fr")
        #expect(locale == .english)
    }
}

// MARK: - Mock Service Tests

@Suite("MockSpeechRecognitionService")
struct MockSpeechRecognitionServiceTests {

    @Test("Default mock is authorized and available")
    func defaultState() {
        let mock = MockSpeechRecognitionService()
        #expect(mock.authorizationStatus == .authorized)
        #expect(mock.isAvailable)
    }

    @Test("Request authorization increments call count")
    func requestAuthorizationTracking() async {
        let mock = MockSpeechRecognitionService()
        let status = await mock.requestAuthorization()
        #expect(status == .authorized)
        #expect(mock.requestAuthorizationCallCount == 1)
    }

    @Test("Start recognition throws when permission denied")
    func startRecognitionPermissionDenied() async {
        let mock = MockSpeechRecognitionService()
        mock.stubbedAuthorizationStatus = .denied

        do {
            _ = try await mock.startRecognition()
            Issue.record("Expected permissionDenied error")
        } catch let error as SpeechRecognitionError {
            #expect(error == .permissionDenied)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Start recognition throws when recognizer unavailable")
    func startRecognitionUnavailable() async {
        let mock = MockSpeechRecognitionService()
        mock.stubbedIsAvailable = false

        do {
            _ = try await mock.startRecognition()
            Issue.record("Expected recognizerUnavailable error")
        } catch let error as SpeechRecognitionError {
            #expect(error == .recognizerUnavailable)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Start recognition throws stubbed error")
    func startRecognitionStubbedError() async {
        let mock = MockSpeechRecognitionService()
        mock.stubbedError = .noSpeechDetected

        do {
            _ = try await mock.startRecognition()
            Issue.record("Expected noSpeechDetected error")
        } catch let error as SpeechRecognitionError {
            #expect(error == .noSpeechDetected)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Start recognition streams stubbed transcriptions")
    func startRecognitionStreamsResults() async throws {
        let mock = MockSpeechRecognitionService()
        mock.stubbedTranscriptions = [
            SpeechTranscription(text: "Hello", isFinal: false, confidence: 0.5),
            SpeechTranscription(text: "Hello world", isFinal: true, confidence: 0.9),
        ]

        let stream = try await mock.startRecognition()
        var results: [SpeechTranscription] = []
        for await transcription in stream {
            results.append(transcription)
        }

        #expect(results.count == 2)
        #expect(results[0].text == "Hello")
        #expect(results[0].isFinal == false)
        #expect(results[1].text == "Hello world")
        #expect(results[1].isFinal == true)
        #expect(mock.startRecognitionCallCount == 1)
    }

    @Test("Stop recognition increments call count")
    func stopRecognitionTracking() {
        let mock = MockSpeechRecognitionService()
        mock.stopRecognition()
        mock.stopRecognition()
        #expect(mock.stopRecognitionCallCount == 2)
    }

    @Test("Set locale updates tracked locale")
    func setLocaleTracking() {
        let mock = MockSpeechRecognitionService()
        mock.setLocale(.german)
        #expect(mock.setLocaleCallCount == 1)
        #expect(mock.lastSetLocale == .german)

        mock.setLocale(.english)
        #expect(mock.setLocaleCallCount == 2)
        #expect(mock.lastSetLocale == .english)
    }

    @Test("Language switching from app language string")
    func languageSwitching() {
        let mock = MockSpeechRecognitionService()

        // Simulate what happens when learner profile language changes
        let germanLanguage = "de"
        mock.setLocale(SpeechLocale(appLanguage: germanLanguage))
        #expect(mock.lastSetLocale == .german)

        let englishLanguage = "en"
        mock.setLocale(SpeechLocale(appLanguage: englishLanguage))
        #expect(mock.lastSetLocale == .english)
    }
}

// MARK: - SpeechRecognitionError Tests

@Suite("SpeechRecognitionError")
struct SpeechRecognitionErrorTests {

    @Test("Errors are equatable")
    func errorsAreEquatable() {
        #expect(SpeechRecognitionError.permissionDenied == .permissionDenied)
        #expect(SpeechRecognitionError.recognizerUnavailable == .recognizerUnavailable)
        #expect(SpeechRecognitionError.noSpeechDetected == .noSpeechDetected)
        #expect(SpeechRecognitionError.recognitionFailed("x") == .recognitionFailed("x"))
        #expect(SpeechRecognitionError.recognitionFailed("x") != .recognitionFailed("y"))
        #expect(SpeechRecognitionError.audioEngineError("e") == .audioEngineError("e"))
        #expect(SpeechRecognitionError.permissionDenied != .noSpeechDetected)
    }
}

// MARK: - SpeechTranscription Tests

@Suite("SpeechTranscription")
struct SpeechTranscriptionTests {

    @Test("Transcription stores all fields")
    func transcriptionFields() {
        let t = SpeechTranscription(text: "Test", isFinal: true, confidence: 0.95)
        #expect(t.text == "Test")
        #expect(t.isFinal == true)
        #expect(t.confidence == 0.95)
    }

    @Test("Transcription with nil confidence")
    func nilConfidence() {
        let t = SpeechTranscription(text: "Partial", isFinal: false, confidence: nil)
        #expect(t.confidence == nil)
    }
}
