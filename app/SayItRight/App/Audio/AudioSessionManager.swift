import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif

// MARK: - Audio Session State

/// Tracks which voice features are currently active.
enum AudioUsageMode: Sendable, Equatable {
    /// No voice features active — audio session should be deactivated.
    case idle
    /// TTS playback only (no microphone needed).
    case playbackOnly
    /// STT recording only.
    case recordOnly
    /// Both TTS and STT active (e.g. conversation mode).
    case playAndRecord
}

/// Events published by the audio session manager for consumers to react to.
enum AudioSessionEvent: Sendable, Equatable {
    /// An interruption began (phone call, Siri, etc.). Voice features should pause.
    case interruptionBegan
    /// An interruption ended. If `shouldResume` is true, voice features may restart.
    case interruptionEnded(shouldResume: Bool)
    /// The audio route changed (AirPods connected/disconnected, etc.).
    case routeChanged(reason: RouteChangeReason)
}

/// Simplified route change reasons for consumers.
enum RouteChangeReason: Sendable, Equatable {
    case newDeviceAvailable
    case oldDeviceUnavailable
    case categoryChange
    case other
}

// MARK: - AudioSessionManager

/// Coordinates AVAudioSession configuration for TTS and STT voice features.
///
/// Responsibilities:
/// - Sets the correct audio category based on active voice features and platform
/// - Handles interruptions (phone calls, Siri) gracefully
/// - Handles route changes (AirPods connect/disconnect) smoothly
/// - Activates audio session only when voice features are in use
///
/// On macOS, AVAudioSession is unavailable, so this manager provides a no-op
/// implementation that still tracks usage mode for coordination purposes.
@Observable
final class AudioSessionManager: @unchecked Sendable {

    // MARK: - Published State

    /// The current usage mode reflecting active voice features.
    private(set) var currentMode: AudioUsageMode = .idle

    /// Whether the audio session is currently active.
    private(set) var isSessionActive: Bool = false

    /// Whether an interruption is currently in progress.
    private(set) var isInterrupted: Bool = false

    /// The most recent event, for consumers to observe.
    private(set) var lastEvent: AudioSessionEvent?

    // MARK: - Private

    /// The mode that was active before an interruption, so we can restore it.
    private var modeBeforeInterruption: AudioUsageMode = .idle

    #if os(iOS)
    private var interruptionObserver: (any NSObjectProtocol)?
    private var routeChangeObserver: (any NSObjectProtocol)?
    #endif

    // MARK: - Init / Deinit

    init() {
        #if os(iOS)
        registerNotifications()
        #endif
    }

    deinit {
        #if os(iOS)
        removeNotifications()
        #endif
    }

    // MARK: - Public API

    /// Call when TTS playback begins.
    func activateForPlayback() {
        updateMode(addingPlayback: true, addingRecord: currentMode == .playAndRecord || currentMode == .recordOnly)
    }

    /// Call when TTS playback ends.
    func deactivatePlayback() {
        updateMode(addingPlayback: false, addingRecord: currentMode == .playAndRecord || currentMode == .recordOnly)
    }

    /// Call when STT recording begins.
    func activateForRecording() {
        updateMode(addingPlayback: currentMode == .playAndRecord || currentMode == .playbackOnly, addingRecord: true)
    }

    /// Call when STT recording ends.
    func deactivateRecording() {
        updateMode(addingPlayback: currentMode == .playAndRecord || currentMode == .playbackOnly, addingRecord: false)
    }

    /// Deactivate the audio session entirely. Call when leaving a voice session.
    func deactivateSession() {
        currentMode = .idle
        configureAndActivate(for: .idle)
    }

    // MARK: - Mode Resolution

    private func updateMode(addingPlayback: Bool, addingRecord: Bool) {
        let newMode: AudioUsageMode
        switch (addingPlayback, addingRecord) {
        case (true, true):
            newMode = .playAndRecord
        case (true, false):
            newMode = .playbackOnly
        case (false, true):
            newMode = .recordOnly
        case (false, false):
            newMode = .idle
        }

        guard newMode != currentMode else { return }
        currentMode = newMode
        configureAndActivate(for: newMode)
    }

    // MARK: - Platform-Specific Configuration

    private func configureAndActivate(for mode: AudioUsageMode) {
        #if os(iOS)
        configureIOSSession(for: mode)
        #else
        // macOS: AVAudioSession not available. Track state only.
        isSessionActive = mode != .idle
        #endif
    }

    #if os(iOS)
    private func configureIOSSession(for mode: AudioUsageMode) {
        let session = AVAudioSession.sharedInstance()

        guard mode != .idle else {
            deactivateIOSSession()
            return
        }

        do {
            let category: AVAudioSession.Category
            let categoryOptions: AVAudioSession.CategoryOptions
            let sessionMode: AVAudioSession.Mode

            let isPhone = UIDevice.current.userInterfaceIdiom == .phone

            switch mode {
            case .playbackOnly:
                if isPhone {
                    // iPhone always uses .playAndRecord to allow quick switch to STT
                    category = .playAndRecord
                    categoryOptions = [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
                } else {
                    // iPad uses .playback when only doing TTS
                    category = .playback
                    categoryOptions = [.mixWithOthers]
                }
                sessionMode = .default

            case .recordOnly, .playAndRecord:
                category = .playAndRecord
                categoryOptions = [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
                sessionMode = .default

            case .idle:
                return // handled above
            }

            try session.setCategory(category, mode: sessionMode, options: categoryOptions)
            try session.setActive(true, options: [])
            isSessionActive = true

            #if DEBUG
            print("[AudioSessionManager] Activated: category=\(category.rawValue), mode=\(mode)")
            #endif
        } catch {
            #if DEBUG
            print("[AudioSessionManager] Configuration failed: \(error)")
            #endif
        }
    }

    private func deactivateIOSSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false, options: [.notifyOthersOnDeactivation])
            isSessionActive = false
            #if DEBUG
            print("[AudioSessionManager] Deactivated")
            #endif
        } catch {
            #if DEBUG
            print("[AudioSessionManager] Deactivation failed: \(error)")
            #endif
        }
    }
    #endif

    // MARK: - Notification Handling (iOS)

    #if os(iOS)
    private func registerNotifications() {
        let center = NotificationCenter.default

        interruptionObserver = center.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }

        routeChangeObserver = center.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            self?.handleRouteChange(notification)
        }
    }

    private func removeNotifications() {
        let center = NotificationCenter.default
        if let observer = interruptionObserver {
            center.removeObserver(observer)
        }
        if let observer = routeChangeObserver {
            center.removeObserver(observer)
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeRaw = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeRaw)
        else { return }

        switch type {
        case .began:
            modeBeforeInterruption = currentMode
            isInterrupted = true
            lastEvent = .interruptionBegan
            #if DEBUG
            print("[AudioSessionManager] Interruption began (was \(currentMode))")
            #endif

        case .ended:
            isInterrupted = false
            let shouldResume: Bool
            if let optionsRaw = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsRaw)
                shouldResume = options.contains(.shouldResume)
            } else {
                shouldResume = false
            }

            if shouldResume && modeBeforeInterruption != .idle {
                // Re-activate with the previous mode
                currentMode = modeBeforeInterruption
                configureAndActivate(for: modeBeforeInterruption)
            }

            lastEvent = .interruptionEnded(shouldResume: shouldResume)
            modeBeforeInterruption = .idle

            #if DEBUG
            print("[AudioSessionManager] Interruption ended (shouldResume=\(shouldResume))")
            #endif

        @unknown default:
            break
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonRaw = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let avReason = AVAudioSession.RouteChangeReason(rawValue: reasonRaw)
        else { return }

        let reason: RouteChangeReason
        switch avReason {
        case .newDeviceAvailable:
            reason = .newDeviceAvailable
        case .oldDeviceUnavailable:
            reason = .oldDeviceUnavailable
            // When a device is removed, reconfigure to ensure audio continues
            if currentMode != .idle {
                configureAndActivate(for: currentMode)
            }
        case .categoryChange:
            reason = .categoryChange
        default:
            reason = .other
        }

        lastEvent = .routeChanged(reason: reason)

        #if DEBUG
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        let outputs = currentRoute.outputs.map(\.portName).joined(separator: ", ")
        let inputs = currentRoute.inputs.map(\.portName).joined(separator: ", ")
        print("[AudioSessionManager] Route changed: \(avReason.rawValue) → out=[\(outputs)] in=[\(inputs)]")
        #endif
    }
    #endif
}
