import SwiftUI

/// Voice-first "Say it clearly" session view for iPhone.
///
/// This is the flagship voice experience: Barbara asks a question aloud,
/// the user responds by speaking, Barbara evaluates and speaks her feedback.
/// Text is always visible alongside voice — voice is additive, not exclusive.
///
/// Flow:
/// 1. Session starts → Barbara speaks the topic prompt (TTS)
/// 2. After TTS finishes → mic auto-activates (or user taps)
/// 3. User speaks → transcription displayed live → review → submit
/// 4. Barbara evaluates → feedback displayed AND spoken (TTS)
/// 5. Revision loop: user speaks revised version → Barbara re-evaluates
struct VoiceSayItClearlyView: View {
    let sessionManager: SessionManager
    let coordinator: SayItClearlyCoordinator
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

    init(
        sessionManager: SessionManager,
        coordinator: SayItClearlyCoordinator,
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
                    ChatView(
                        viewModel: viewModel,
                        voiceInputViewModel: voiceInputVM,
                        onVoiceSubmit: { text in
                            handleVoiceSubmit(text)
                        }
                    )

                    if viewModel.isRevisionComplete && !viewModel.isSummaryRequested {
                        summaryPromptBar
                    }
                }
            }
        }
        .navigationTitle(SessionType.sayItClearly.displayName(language: language))
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

            // Prewarm TTS for lower first-utterance latency
            ttsService.prewarm()
            configureTTSVoice()

            let topic = await coordinator.startSession(
                sessionManager: sessionManager,
                profile: profile,
                language: language
            )
            if topic == nil {
                noTopicsAvailable = true
            }
        }
        .onChange(of: viewModel.messages.count) { oldCount, newCount in
            // When a new Barbara message arrives, speak it
            speakLatestBarbaraMessage()
        }
        .onChange(of: viewModel.messages.last?.isStreaming) { _, isStreaming in
            // When streaming finishes, speak the complete message
            if isStreaming == false {
                speakLatestBarbaraMessage()
            }
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

        // Only speak if this is a new message we haven't spoken yet
        let currentCount = viewModel.messages.count
        guard currentCount > lastSpokenMessageCount else { return }
        lastSpokenMessageCount = currentCount

        let textToSpeak = lastMessage.text
        isTTSSpeaking = true

        ttsService.speak(textToSpeak, language: language) { [self] event in
            if event == .finished {
                Task { @MainActor in
                    isTTSSpeaking = false
                }
            }
        }
    }

    // MARK: - Voice Submit

    private func handleVoiceSubmit(_ text: String) {
        viewModel.inputText = text
        viewModel.send()
    }

    // MARK: - Summary Prompt

    private var summaryPromptBar: some View {
        VStack(spacing: 8) {
            Divider()
            Text(language == "de"
                 ? "Revision abgeschlossen"
                 : "Revision complete")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button(action: { viewModel.requestSummary() }) {
                Label(
                    language == "de" ? "Zusammenfassung anzeigen" : "Show Session Summary",
                    systemImage: "doc.text"
                )
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 16)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - No Topics Available

    private var noTopicsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(language == "de"
                 ? "Keine Themen verfügbar"
                 : "No topics available")
                .font(.title3)
                .fontWeight(.semibold)

            Text(language == "de"
                 ? "Es gibt aktuell keine passenden Themen für dein Level."
                 : "There are no matching topics for your current level.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let onDismiss {
                Button(language == "de" ? "Zurück" : "Go Back") {
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
        ttsService.stop()
        voiceInputVM.reset()
        audioSessionManager.deactivateSession()
        sessionManager.endSession()
        onDismiss?()
    }
}

// MARK: - Previews

#Preview("Voice Say it clearly") {
    NavigationStack {
        VoiceSayItClearlyView(
            sessionManager: SessionManager(),
            coordinator: SayItClearlyCoordinator(topics: [
                Topic(
                    id: "preview-voice",
                    titleEN: "Four-day school week",
                    titleDE: "Vier-Tage-Schulwoche",
                    promptEN: "Should schools switch to a four-day week?",
                    promptDE: "Sollte die Schule auf eine Vier-Tage-Woche umstellen?",
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
