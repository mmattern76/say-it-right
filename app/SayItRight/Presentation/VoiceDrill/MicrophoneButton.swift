import SwiftUI

// MARK: - MicrophoneButton

/// A reusable microphone button with clear tap-to-start / tap-to-stop states.
///
/// Displays a pulsing animation while recording and provides haptic feedback
/// on state transitions. The button adapts its appearance based on the
/// current `VoiceInputState`.
struct MicrophoneButton: View {

    /// The current voice input state driving the button's appearance.
    let state: VoiceInputState

    /// Audio level (0.0-1.0) for the pulsing ring intensity during recording.
    var audioLevel: Float = 0.0

    /// Action triggered when the button is tapped.
    let action: () -> Void

    // MARK: - Private State

    @State private var isPulsing = false
    @State private var pulseScale: CGFloat = 1.0

    // MARK: - Constants

    private let buttonSize: CGFloat = 72
    private let iconSize: CGFloat = 28

    var body: some View {
        Button(action: performAction) {
            ZStack {
                // Outer pulsing rings (recording state only)
                if state == .recording {
                    pulsingRings
                }

                // Main circle
                Circle()
                    .fill(backgroundColor)
                    .frame(width: buttonSize, height: buttonSize)
                    .shadow(
                        color: shadowColor,
                        radius: state == .recording ? 8 : 4,
                        y: 2
                    )

                // Icon
                Image(systemName: iconName)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .onChange(of: state) { _, newState in
            withAnimation(.easeInOut(duration: 0.3)) {
                isPulsing = newState == .recording
            }
        }
    }

    // MARK: - Pulsing Rings

    private var pulsingRings: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color.red.opacity(0.2), lineWidth: 2)
                .frame(
                    width: buttonSize + 24 + CGFloat(audioLevel) * 16,
                    height: buttonSize + 24 + CGFloat(audioLevel) * 16
                )
                .scaleEffect(pulseScale)

            // Inner ring
            Circle()
                .stroke(Color.red.opacity(0.3), lineWidth: 2.5)
                .frame(
                    width: buttonSize + 12 + CGFloat(audioLevel) * 8,
                    height: buttonSize + 12 + CGFloat(audioLevel) * 8
                )
                .scaleEffect(pulseScale)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true)
            ) {
                pulseScale = 1.15
            }
        }
        .onDisappear {
            pulseScale = 1.0
        }
    }

    // MARK: - Appearance

    private var backgroundColor: Color {
        switch state {
        case .idle:
            return .accentColor
        case .recording:
            return .red
        case .review:
            return .accentColor.opacity(0.8)
        case .error:
            return .orange
        }
    }

    private var shadowColor: Color {
        switch state {
        case .recording:
            return .red.opacity(0.4)
        default:
            return .black.opacity(0.15)
        }
    }

    private var iconName: String {
        switch state {
        case .idle:
            return "mic.fill"
        case .recording:
            return "stop.fill"
        case .review:
            return "mic.fill"
        case .error:
            return "mic.slash.fill"
        }
    }

    private var iconColor: Color {
        .white
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        switch state {
        case .idle:
            return "Start recording"
        case .recording:
            return "Stop recording"
        case .review:
            return "Record again"
        case .error:
            return "Retry recording"
        }
    }

    private var accessibilityHint: String {
        switch state {
        case .idle:
            return "Tap to start voice input"
        case .recording:
            return "Tap to stop recording"
        case .review:
            return "Tap to discard and record again"
        case .error:
            return "Tap to try recording again"
        }
    }

    // MARK: - Actions

    private func performAction() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: state == .recording ? .medium : .light)
        generator.impactOccurred()
        #endif
        action()
    }
}

// MARK: - Previews

#Preview("Idle") {
    MicrophoneButton(state: .idle) { }
        .padding()
}

#Preview("Recording") {
    MicrophoneButton(state: .recording, audioLevel: 0.6) { }
        .padding()
}

#Preview("Review") {
    MicrophoneButton(state: .review) { }
        .padding()
}

#Preview("Error") {
    MicrophoneButton(state: .error(.noSpeechDetected)) { }
        .padding()
}

#Preview("All States") {
    VStack(spacing: 32) {
        MicrophoneButton(state: .idle) { }
        MicrophoneButton(state: .recording, audioLevel: 0.7) { }
        MicrophoneButton(state: .review) { }
        MicrophoneButton(state: .error(.microphonePermissionDenied)) { }
    }
    .padding()
}
