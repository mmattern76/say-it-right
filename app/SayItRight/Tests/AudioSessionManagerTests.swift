import Testing
import Foundation
@testable import SayItRight

@Suite("AudioSessionManager")
struct AudioSessionManagerTests {

    // MARK: - Initial State

    @Test func initialStateIsIdle() {
        let manager = AudioSessionManager()
        #expect(manager.currentMode == .idle)
        #expect(manager.isSessionActive == false)
        #expect(manager.isInterrupted == false)
        #expect(manager.lastEvent == nil)
    }

    // MARK: - Mode Transitions

    @Test func activateForPlaybackSetsPlaybackOnly() {
        let manager = AudioSessionManager()
        manager.activateForPlayback()
        #expect(manager.currentMode == .playbackOnly)
        // On macOS, session is active when not idle
        #if os(macOS)
        #expect(manager.isSessionActive == true)
        #endif
    }

    @Test func activateForRecordingSetsRecordOnly() {
        let manager = AudioSessionManager()
        manager.activateForRecording()
        #expect(manager.currentMode == .recordOnly)
        #if os(macOS)
        #expect(manager.isSessionActive == true)
        #endif
    }

    @Test func activateBothSetsPlayAndRecord() {
        let manager = AudioSessionManager()
        manager.activateForPlayback()
        manager.activateForRecording()
        #expect(manager.currentMode == .playAndRecord)
    }

    @Test func deactivatePlaybackWhileRecordingKeepsRecordOnly() {
        let manager = AudioSessionManager()
        manager.activateForPlayback()
        manager.activateForRecording()
        #expect(manager.currentMode == .playAndRecord)

        manager.deactivatePlayback()
        #expect(manager.currentMode == .recordOnly)
    }

    @Test func deactivateRecordingWhilePlayingKeepsPlaybackOnly() {
        let manager = AudioSessionManager()
        manager.activateForPlayback()
        manager.activateForRecording()
        #expect(manager.currentMode == .playAndRecord)

        manager.deactivateRecording()
        #expect(manager.currentMode == .playbackOnly)
    }

    @Test func deactivateBothReturnsToIdle() {
        let manager = AudioSessionManager()
        manager.activateForPlayback()
        manager.activateForRecording()
        manager.deactivatePlayback()
        manager.deactivateRecording()
        #expect(manager.currentMode == .idle)
        #if os(macOS)
        #expect(manager.isSessionActive == false)
        #endif
    }

    @Test func deactivateSessionForcesIdle() {
        let manager = AudioSessionManager()
        manager.activateForPlayback()
        manager.activateForRecording()
        #expect(manager.currentMode == .playAndRecord)

        manager.deactivateSession()
        #expect(manager.currentMode == .idle)
        #if os(macOS)
        #expect(manager.isSessionActive == false)
        #endif
    }

    // MARK: - Idempotent Activation

    @Test func doubleActivatePlaybackIsIdempotent() {
        let manager = AudioSessionManager()
        manager.activateForPlayback()
        let mode1 = manager.currentMode
        manager.activateForPlayback()
        #expect(manager.currentMode == mode1)
    }

    @Test func doubleActivateRecordingIsIdempotent() {
        let manager = AudioSessionManager()
        manager.activateForRecording()
        let mode1 = manager.currentMode
        manager.activateForRecording()
        #expect(manager.currentMode == mode1)
    }

    // MARK: - Deactivate from Idle is Safe

    @Test func deactivateFromIdleIsSafe() {
        let manager = AudioSessionManager()
        manager.deactivatePlayback()
        #expect(manager.currentMode == .idle)
        manager.deactivateRecording()
        #expect(manager.currentMode == .idle)
        manager.deactivateSession()
        #expect(manager.currentMode == .idle)
    }

    // MARK: - AudioUsageMode Equatable

    @Test func audioUsageModeEquality() {
        #expect(AudioUsageMode.idle == AudioUsageMode.idle)
        #expect(AudioUsageMode.playbackOnly == AudioUsageMode.playbackOnly)
        #expect(AudioUsageMode.recordOnly == AudioUsageMode.recordOnly)
        #expect(AudioUsageMode.playAndRecord == AudioUsageMode.playAndRecord)
        #expect(AudioUsageMode.idle != AudioUsageMode.playbackOnly)
    }

    // MARK: - AudioSessionEvent Equatable

    @Test func audioSessionEventEquality() {
        #expect(AudioSessionEvent.interruptionBegan == AudioSessionEvent.interruptionBegan)
        #expect(AudioSessionEvent.interruptionEnded(shouldResume: true) == AudioSessionEvent.interruptionEnded(shouldResume: true))
        #expect(AudioSessionEvent.interruptionEnded(shouldResume: true) != AudioSessionEvent.interruptionEnded(shouldResume: false))
        #expect(AudioSessionEvent.routeChanged(reason: .newDeviceAvailable) == AudioSessionEvent.routeChanged(reason: .newDeviceAvailable))
        #expect(AudioSessionEvent.routeChanged(reason: .newDeviceAvailable) != AudioSessionEvent.routeChanged(reason: .oldDeviceUnavailable))
    }

    // MARK: - RouteChangeReason Equatable

    @Test func routeChangeReasonEquality() {
        #expect(RouteChangeReason.newDeviceAvailable == RouteChangeReason.newDeviceAvailable)
        #expect(RouteChangeReason.oldDeviceUnavailable != RouteChangeReason.newDeviceAvailable)
        #expect(RouteChangeReason.categoryChange == RouteChangeReason.categoryChange)
        #expect(RouteChangeReason.other == RouteChangeReason.other)
    }
}
