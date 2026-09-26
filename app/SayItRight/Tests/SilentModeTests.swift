import Foundation
@testable import SayItRight
import Testing

/// Tests for SIR-076: Silent Mode Toggle.
///
/// Covers the full silent-mode chain:
/// - `AppSettings.isTTSDisabled` persistence + `effectiveIsTTSDisabled`
/// - Launch-env override parsing
/// - `TTSServiceFactory` returns `NoOpTTSService` when silent
/// - `NoOpTTSService` protocol conformance and no side effects
struct SilentModeTests {
    // MARK: - AppSettings

    @Test("Default isTTSDisabled is false")
    func defaultIsFalse() {
        UserDefaults.standard.removeObject(forKey: "isTTSDisabled")
        let settings = AppSettings()
        #expect(settings.isTTSDisabled == false)
    }

    @Test("isTTSDisabled persists across instances")
    func persistsAcrossInstances() {
        let key = "isTTSDisabled"
        let original = UserDefaults.standard.object(forKey: key)
        defer {
            if let original {
                UserDefaults.standard.set(original, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }

        let writer = AppSettings()
        writer.isTTSDisabled = true

        let reader = AppSettings()
        #expect(reader.isTTSDisabled == true)

        writer.isTTSDisabled = false
        let reader2 = AppSettings()
        #expect(reader2.isTTSDisabled == false)
    }

    @Test("effectiveIsTTSDisabled mirrors stored value when env unset")
    func effectiveMirrorsStored() {
        let settings = AppSettings()
        settings.isTTSDisabled = false
        // envForceTTSDisabled depends on the test runner's environment, so we
        // only assert when the override is absent — most CI/dev runs.
        if !AppSettings.envForceTTSDisabled {
            #expect(settings.effectiveIsTTSDisabled == false)
            settings.isTTSDisabled = true
            #expect(settings.effectiveIsTTSDisabled == true)
        }
    }

    // MARK: - Env Var Parsing

    @Test("parseEnvDisabledFlag accepts truthy values")
    func envParsingTruthy() {
        #expect(AppSettings.parseEnvDisabledFlag("1") == true)
        #expect(AppSettings.parseEnvDisabledFlag("true") == true)
        #expect(AppSettings.parseEnvDisabledFlag("TRUE") == true)
        #expect(AppSettings.parseEnvDisabledFlag("yes") == true)
        #expect(AppSettings.parseEnvDisabledFlag("Yes") == true)
    }

    @Test("parseEnvDisabledFlag rejects falsy and unknown values")
    func envParsingFalsy() {
        #expect(AppSettings.parseEnvDisabledFlag(nil) == false)
        #expect(AppSettings.parseEnvDisabledFlag("") == false)
        #expect(AppSettings.parseEnvDisabledFlag("0") == false)
        #expect(AppSettings.parseEnvDisabledFlag("false") == false)
        #expect(AppSettings.parseEnvDisabledFlag("no") == false)
        #expect(AppSettings.parseEnvDisabledFlag("maybe") == false)
    }

    // MARK: - NoOpTTSService

    @Test("NoOpTTSService is idle and emits no events")
    func noOpServiceQuiet() {
        let service = NoOpTTSService()
        #expect(service.state == .idle)

        // Capture any events that fire — none should.
        final class Counter: @unchecked Sendable {
            private let lock = NSLock()
            private var _count = 0
            var count: Int {
                lock.lock()
                defer { lock.unlock() }
                return _count
            }

            func bump() {
                lock.lock()
                _count += 1
                lock.unlock()
            }
        }
        let counter = Counter()

        service.speak("Hello", language: "en") { _ in counter.bump() }
        service.replayLast { _ in counter.bump() }

        #expect(counter.count == 0)
        #expect(service.state == .idle)
    }

    @Test("NoOpTTSService all control methods are safe no-ops")
    func noOpServiceControlMethods() {
        let service = NoOpTTSService()
        // None of these should throw, change state, or emit events.
        service.pause()
        service.resume()
        service.stop()
        service.prewarm()
        #expect(service.state == .idle)
    }

    // MARK: - TTSServiceFactory

    @Test("TTSServiceFactory returns NoOpTTSService when silent mode is on")
    func factoryReturnsNoOpWhenSilent() {
        let settings = AppSettings.shared
        let originalDisabled = settings.isTTSDisabled
        defer { settings.isTTSDisabled = originalDisabled }

        settings.isTTSDisabled = true
        let service = TTSServiceFactory.makeService()
        // The box wraps the underlying service; with silent on it must be NoOp.
        let mirror = Mirror(reflecting: service)
        let wrapped = mirror.children.first { $0.label == "wrapped" }?.value
        #expect(wrapped is NoOpTTSService)

        // And it should behave as a no-op.
        service.speak("test", language: "en", onEvent: nil)
        #expect(service.state == .idle)
    }

    @Test("TTSServiceFactory returns Apple TTS when silent mode is off")
    func factoryReturnsAppleWhenAudible() {
        let settings = AppSettings.shared

        // Skip if env var is forcing silent mode (CI/automation contexts).
        guard !AppSettings.envForceTTSDisabled else { return }

        let originalDisabled = settings.isTTSDisabled
        let originalProvider = settings.ttsProvider
        defer {
            settings.isTTSDisabled = originalDisabled
            settings.ttsProvider = originalProvider
        }

        settings.isTTSDisabled = false
        settings.ttsProvider = "apple"

        let service = TTSServiceFactory.makeService()
        let mirror = Mirror(reflecting: service)
        let wrapped = mirror.children.first { $0.label == "wrapped" }?.value
        #expect(wrapped is AppleTTSPlaybackService)
    }
}
