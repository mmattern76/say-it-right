import SwiftUI

// MARK: - VoiceInputView

/// The complete voice input interface: microphone button, live transcription,
/// editable review, and submit/discard controls.
///
/// This is the primary input method on iPhone. Users tap to start recording,
/// see their words appear live, then review and submit.
///
/// Usage:
/// ```swift
/// VoiceInputView(viewModel: voiceInputVM) { finalText in
///     // Send finalText to conversation manager
/// }
/// ```
struct VoiceInputView: View {

    @Bindable var viewModel: VoiceInputViewModel
    @Environment(AppSettings.self) private var settings

    /// Called when the user submits their transcription.
    var onSubmit: ((String) -> Void)?

    @FocusState private var isEditing: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Transcription display / editor
            transcriptionArea

            // Error display
            if case .error(let error) = viewModel.state {
                errorBanner(for: error)
            }

            // Bottom controls: mic button + submit
            controlBar
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Transcription Area

    @ViewBuilder
    private var transcriptionArea: some View {
        switch viewModel.state {
        case .idle:
            // Show hint text
            Text(isGerman ? "Tippe auf das Mikrofon und sprich" : "Tap the microphone and speak")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 60)

        case .recording:
            // Live transcription with recording indicator
            VStack(spacing: 8) {
                recordingIndicator

                if viewModel.transcriptionText.isEmpty {
                    Text(isGerman ? "Ich höre zu ..." : "Listening ...")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    Text(viewModel.transcriptionText)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(minHeight: 60)
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

        case .review:
            // Editable text field for corrections
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(isGerman ? "Überprüfe deinen Text" : "Review your text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        isEditing.toggle()
                    } label: {
                        Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle")
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isEditing
                        ? (isGerman ? "Bearbeitung beenden" : "Done editing")
                        : (isGerman ? "Text bearbeiten" : "Edit text"))
                }

                if isEditing {
                    TextField(
                        isGerman ? "Text bearbeiten..." : "Edit text...",
                        text: $viewModel.editableText,
                        axis: .vertical
                    )
                    .textFieldStyle(.plain)
                    .font(.body)
                    .lineLimit(1...10)
                    .focused($isEditing)
                } else {
                    Text(viewModel.editableText)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .onTapGesture {
                            isEditing = true
                        }
                }
            }
            .frame(minHeight: 60)
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

        case .error:
            EmptyView()
        }
    }

    // MARK: - Recording Indicator

    private var recordingIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
                .modifier(PulsingModifier())

            Text(isGerman ? "Aufnahme" : "Recording")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.red)
        }
    }

    // MARK: - Error Banner

    private func errorBanner(for error: VoiceInputError) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(isGerman ? error.localizedTitleDE : error.localizedTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            Text(isGerman ? error.localizedMessageDE : error.localizedMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        HStack(spacing: 20) {
            // Discard button (review state only)
            if viewModel.state == .review {
                Button {
                    viewModel.discardTranscription()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isGerman ? "Verwerfen" : "Discard")
                .transition(.scale.combined(with: .opacity))
            }

            Spacer()

            // Microphone button (always visible)
            MicrophoneButton(
                state: viewModel.state,
                audioLevel: viewModel.audioLevel,
                action: { viewModel.toggleRecording() }
            )

            Spacer()

            // Submit button (review state only)
            if viewModel.state == .review {
                Button {
                    if let text = viewModel.submitTranscription() {
                        onSubmit?(text)
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isGerman ? "Absenden" : "Submit")
                .disabled(viewModel.editableText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.state)
        .padding(.horizontal, 8)
    }

    // MARK: - Helpers

    private var isGerman: Bool {
        settings.language == "de"
    }
}

// MARK: - PulsingModifier

/// A simple pulsing opacity animation for the recording dot indicator.
private struct PulsingModifier: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 0.3 : 1.0)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Previews

/// A wrapper that lets us set the ViewModel to a specific state for previews.
private struct PreviewWrapper: View {
    let previewState: VoiceInputState
    let transcription: String
    let audioLevel: Float

    @State private var viewModel: VoiceInputViewModel?

    var body: some View {
        Group {
            if let viewModel {
                VoiceInputView(viewModel: viewModel) { text in
                    print("Submitted: \(text)")
                }
            } else {
                ProgressView()
            }
        }
        .environment(AppSettings.shared)
        .task {
            let mock = MockSpeechRecognitionService()
            let vm = VoiceInputViewModel(speechService: mock)
            viewModel = vm
        }
    }
}

#Preview("Idle State") {
    PreviewWrapper(previewState: .idle, transcription: "", audioLevel: 0)
}

#Preview("Recording State") {
    VoiceInputRecordingPreview()
        .environment(AppSettings.shared)
}

#Preview("Review State") {
    VoiceInputReviewPreview()
        .environment(AppSettings.shared)
}

#Preview("Error State") {
    VoiceInputErrorPreview()
        .environment(AppSettings.shared)
}

// MARK: - Stateful Preview Helpers

/// Preview showing the recording state with live transcription text.
private struct VoiceInputRecordingPreview: View {
    @State private var viewModel: VoiceInputViewModel?

    var body: some View {
        Group {
            if let viewModel {
                VoiceInputView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .task {
            let mock = MockSpeechRecognitionService()
            mock.stubbedTranscriptions = [
                SpeechTranscription(text: "I think the main", isFinal: false, confidence: 0.5),
                SpeechTranscription(text: "I think the main reason is", isFinal: false, confidence: 0.7),
            ]
            let vm = VoiceInputViewModel(speechService: mock)
            viewModel = vm
            await vm.startRecording()
        }
    }
}

/// Preview showing the review state with editable text.
private struct VoiceInputReviewPreview: View {
    @State private var viewModel: VoiceInputViewModel?

    var body: some View {
        Group {
            if let viewModel {
                VoiceInputView(viewModel: viewModel) { text in
                    print("Submitted: \(text)")
                }
            } else {
                ProgressView()
            }
        }
        .task {
            let mock = MockSpeechRecognitionService()
            mock.stubbedTranscriptions = [
                SpeechTranscription(
                    text: "The main reason we should restructure the team is improved efficiency.",
                    isFinal: true,
                    confidence: 0.9
                )
            ]
            let vm = VoiceInputViewModel(speechService: mock)
            viewModel = vm
            // Start and let it auto-finish to get into review state
            await vm.startRecording()
            // Give time for the stream to complete
            try? await Task.sleep(for: .milliseconds(100))
        }
    }
}

/// Preview showing the error state.
private struct VoiceInputErrorPreview: View {
    @State private var viewModel: VoiceInputViewModel?

    var body: some View {
        Group {
            if let viewModel {
                VoiceInputView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .task {
            let mock = MockSpeechRecognitionService()
            mock.stubbedAuthorizationStatus = .denied
            let vm = VoiceInputViewModel(speechService: mock)
            viewModel = vm
            await vm.startRecording()
        }
    }
}
