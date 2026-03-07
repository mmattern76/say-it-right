import SwiftUI

/// Voice-first "Elevator Pitch" / "30 Sekunden" session view for iPhone.
///
/// Combines the timed pressure of ElevatorPitchView with voice input/output:
/// 1. Barbara speaks the topic and says "You have N seconds. Go." (TTS)
/// 2. Timer starts after TTS finishes → mic auto-activates
/// 3. STT captures the spoken response during the timed window
/// 4. Recording stops when timer expires (or user taps early)
/// 5. Barbara evaluates and speaks her feedback
struct VoiceElevatorPitchView: View {
    let sessionManager: SessionManager
    let coordinator: ElevatorPitchCoordinator
    let profile: LearnerProfile
    let language: String
    var onDismiss: (() -> Void)?

    @State private var viewModel: ChatViewModel
    @State private var voiceInputVM: VoiceInputViewModel
    @State private var ttsService: AppleTTSPlaybackService
    @State private var audioSessionManager = AudioSessionManager()
    @State private var sessionStarted = false
    @State private var noTopicsAvailable = false
    @State private var isTTSSpeaking = false
    @State private var lastSpokenMessageCount = 0
    @State private var timerState = VoiceTimerState()
    @State private var timerStartedAfterTTS = false

    init(
        sessionManager: SessionManager,
        coordinator: ElevatorPitchCoordinator,
        profile: LearnerProfile,
        language: String,
        onDismiss: (() -> Void)? = nil
    ) {
        self.sessionManager = sessionManager
        self.coordinator = coordinator
        self.profile = profile
        self.language = language
        self.onDismiss = onDismiss
        self._viewModel = State(initialValue: ChatViewModel(sessionManager: sessionManager))

        let speechService = LiveSpeechRecognitionService(
            locale: language == "de" ? .german : .english
        )
        let audioMgr = AudioSessionManager()
        self._audioSessionManager = State(initialValue: audioMgr)
        self._voiceInputVM = State(initialValue: VoiceInputViewModel(
            speechService: speechService,
            audioSessionManager: audioMgr
        ))
        self._ttsService = State(initialValue: AppleTTSPlaybackService())
    }

    var body: some View {
        Group {
            if noTopicsAvailable {
                noTopicsView
            } else {
                VStack(spacing: 0) {
                    if timerState.isRunning || timerState.hasStarted {
                        timerBar
                    }

                    ChatView(
                        viewModel: viewModel,
                        voiceInputViewModel: voiceInputVM,
                        onVoiceSubmit: { text in
                            submitPitch(text: text, timedOut: false)
                        }
                    )
                }
            }
        }
        .navigationTitle(SessionType.elevatorPitch.displayName(language: language))
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: endSessionAndDismiss) {
                    Label(
                        language == "de" ? "Beenden" : "End Session",
                        systemImage: "xmark.circle"
                    )
                }
            }
        }
        .task {
            guard !sessionStarted else { return }
            sessionStarted = true

            ttsService.prewarm()
            configureTTSVoice()

            // Select topic via coordinator, then start voice session directly
            guard let topic = coordinator.selectTopic(
                for: profile.currentLevel,
                language: language
            ) else {
                noTopicsAvailable = true
                return
            }
            await sessionManager.startVoiceElevatorPitchSession(
                topic: topic,
                profile: profile,
                language: language
            )
        }
        .onChange(of: viewModel.messages.count) { _, _ in
            speakLatestBarbaraMessage()
        }
        .onChange(of: viewModel.messages.last?.isStreaming) { _, isStreaming in
            if isStreaming == false {
                speakLatestBarbaraMessage()
            }
        }
    }

    // MARK: - Timer Bar

    private var timerBar: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "timer")
                    .font(.caption)
                Text(timerText)
                    .font(.system(.title3, design: .monospaced).bold())
                Spacer()
                if timerState.isRunning {
                    Button(action: { stopEarlyAndSubmit() }) {
                        Label(
                            language == "de" ? "Fertig" : "Done",
                            systemImage: "stop.circle.fill"
                        )
                        .font(.caption.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(timerColor)
                        .frame(width: geo.size.width * timerProgress, height: 4)
                        .animation(.linear(duration: 1), value: timerState.remainingSeconds)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(timerColor.opacity(0.08))
    }

    private var timerText: String {
        let minutes = timerState.remainingSeconds / 60
        let seconds = timerState.remainingSeconds % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        }
        return "\(seconds)s"
    }

    private var timerProgress: CGFloat {
        guard timerState.totalSeconds > 0 else { return 0 }
        return CGFloat(timerState.remainingSeconds) / CGFloat(timerState.totalSeconds)
    }

    private var timerColor: Color {
        let ratio = timerProgress
        if ratio > 0.5 { return .green }
        if ratio > 0.17 { return .orange }
        return .red
    }

    // MARK: - Timer Logic

    private func startTimer(duration: Int) {
        timerState.totalSeconds = duration
        timerState.remainingSeconds = duration
        timerState.isRunning = true
        timerState.hasStarted = true

        // Auto-start recording when timer begins
        Task {
            await voiceInputVM.startRecording()
        }

        timerState.timerTask = Task { @MainActor in
            while timerState.remainingSeconds > 0 && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                timerState.remainingSeconds -= 1

                #if os(iOS)
                if timerState.remainingSeconds == 10 || timerState.remainingSeconds == 5 {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
                #endif
            }

            if !Task.isCancelled && timerState.remainingSeconds <= 0 {
                timerState.isRunning = false
                autoSubmitVoice()
            }
        }
    }

    private func autoSubmitVoice() {
        voiceInputVM.stopRecording()

        // Grab whatever was transcribed
        let text: String
        if voiceInputVM.state == .review {
            text = voiceInputVM.editableText
        } else {
            text = voiceInputVM.transcriptionText
        }

        voiceInputVM.reset()
        submitPitch(text: text, timedOut: true)
    }

    private func stopEarlyAndSubmit() {
        timerState.isRunning = false
        timerState.timerTask?.cancel()
        voiceInputVM.stopRecording()

        let text: String
        if voiceInputVM.state == .review {
            text = voiceInputVM.editableText
        } else {
            text = voiceInputVM.transcriptionText
        }

        voiceInputVM.reset()
        submitPitch(text: text, timedOut: false)
    }

    private func submitPitch(text: String, timedOut: Bool) {
        timerState.isRunning = false
        timerState.timerTask?.cancel()

        Task {
            await sessionManager.submitElevatorPitch(text: text, timedOut: timedOut)
        }
    }

    // MARK: - TTS

    private func configureTTSVoice() {
        let voiceProfile: BarbaraVoiceProfile = language == "de" ? .german : .english
        ttsService.configuration = voiceProfile.ttsConfiguration(for: .observation)
    }

    private func speakLatestBarbaraMessage() {
        guard let lastMessage = viewModel.messages.last,
              lastMessage.role == .barbara,
              !lastMessage.text.isEmpty,
              !lastMessage.isStreaming else { return }

        let currentCount = viewModel.messages.count
        guard currentCount > lastSpokenMessageCount else { return }
        lastSpokenMessageCount = currentCount

        let textToSpeak = lastMessage.text
        isTTSSpeaking = true

        ttsService.speak(textToSpeak, language: language) { [self] event in
            if event == .finished {
                Task { @MainActor in
                    isTTSSpeaking = false

                    // Start timer after Barbara's initial greeting finishes
                    if !timerStartedAfterTTS,
                       let session = sessionManager.elevatorPitchSession {
                        timerStartedAfterTTS = true
                        startTimer(duration: session.durationSeconds)
                    }
                }
            }
        }
    }

    // MARK: - No Topics

    private var noTopicsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(language == "de"
                 ? "Keine Themen verf\u{00FC}gbar"
                 : "No topics available")
                .font(.title3)
                .fontWeight(.semibold)

            Text(language == "de"
                 ? "Es gibt aktuell keine passenden Themen f\u{00FC}r dein Level."
                 : "There are no matching topics for your current level.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let onDismiss {
                Button(language == "de" ? "Zur\u{00FC}ck" : "Go Back") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
        }
        .padding(32)
    }

    // MARK: - Actions

    private func endSessionAndDismiss() {
        timerState.timerTask?.cancel()
        ttsService.stop()
        voiceInputVM.reset()
        audioSessionManager.deactivateSession()
        sessionManager.endSession()
        onDismiss?()
    }
}

// MARK: - Voice Timer State

@MainActor
private struct VoiceTimerState {
    var totalSeconds: Int = 0
    var remainingSeconds: Int = 0
    var isRunning: Bool = false
    var hasStarted: Bool = false
    var timerTask: Task<Void, Never>?
}

// MARK: - Previews

#Preview("Voice Elevator Pitch") {
    NavigationStack {
        VoiceElevatorPitchView(
            sessionManager: SessionManager(),
            coordinator: ElevatorPitchCoordinator(topics: [
                Topic(
                    id: "preview-vep",
                    titleEN: "School uniforms",
                    titleDE: "Schuluniformen",
                    promptEN: "Should schools require uniforms? You have 60 seconds.",
                    promptDE: "Sollten Schulen Uniformen vorschreiben? Du hast 60 Sekunden.",
                    domain: .school,
                    level: 1,
                    barbaraFavorite: true
                )
            ]),
            profile: .createDefault(displayName: "Alex"),
            language: "en"
        )
    }
    .environment(AppSettings.shared)
}

#Preview("Voice Elevator Pitch — German") {
    NavigationStack {
        VoiceElevatorPitchView(
            sessionManager: SessionManager(),
            coordinator: ElevatorPitchCoordinator(topics: [
                Topic(
                    id: "preview-vep-de",
                    titleEN: "Homework",
                    titleDE: "Hausaufgaben",
                    promptEN: "Should homework be abolished?",
                    promptDE: "Sollten Hausaufgaben abgeschafft werden? Du hast 60 Sekunden.",
                    domain: .school,
                    level: 1,
                    barbaraFavorite: false
                )
            ]),
            profile: .createDefault(displayName: "Maxi", language: "de"),
            language: "de"
        )
    }
    .environment(AppSettings.shared)
}
