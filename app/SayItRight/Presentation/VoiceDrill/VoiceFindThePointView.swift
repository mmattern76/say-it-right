import SwiftUI

/// Voice-first "Find the Point" session view for iPhone.
///
/// Displays a practice text for reading, then the user speaks their
/// one-sentence governing thought extraction. Barbara evaluates via
/// TTS + text. The practice text remains visible throughout.
///
/// Flow:
/// 1. Practice text displayed at top (scrollable)
/// 2. Barbara speaks introduction via TTS
/// 3. User taps mic and speaks their extraction
/// 4. Barbara evaluates and speaks feedback
struct VoiceFindThePointView: View {
    let sessionManager: SessionManager
    let coordinator: FindThePointCoordinator
    let profile: LearnerProfile
    let language: String
    var onDismiss: (() -> Void)?

    @State private var viewModel: ChatViewModel
    @State private var voiceInputVM: VoiceInputViewModel
    @State private var ttsService: AppleTTSPlaybackService
    @State private var audioSessionManager = AudioSessionManager()
    @State private var sessionStarted = false
    @State private var noTextsAvailable = false
    @State private var selectedText: PracticeText?
    @State private var isTTSSpeaking = false
    @State private var ttsEnabled: Bool = AppSettings.shared.ttsAutoPlay
    @State private var lastSpokenMessageCount = 0

    init(
        sessionManager: SessionManager,
        coordinator: FindThePointCoordinator,
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
            if noTextsAvailable {
                noTextsView
            } else if selectedText != nil {
                VStack(spacing: 0) {
                    // Practice text at top, always visible
                    if let text = selectedText {
                        ScrollView {
                            PracticeTextView(text: text.text, language: language)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .frame(maxHeight: 200)

                        Divider()
                    }

                    // Chat with voice input below
                    ChatView(
                        viewModel: viewModel,
                        voiceInputViewModel: voiceInputVM,
                        onVoiceSubmit: { text in
                            handleVoiceSubmit(text)
                        }
                    )
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(SessionType.findThePoint.displayName(language: language))
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .automatic) {
                TTSToggleButton(isEnabled: $ttsEnabled, language: language)
            }
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

            let text = await coordinator.startSession(
                sessionManager: sessionManager,
                profile: profile,
                language: language
            )
            if let text {
                selectedText = text
                // Append voice mode directive
                sessionManager.appendVoiceDirective(language: language)
            } else {
                noTextsAvailable = true
            }
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

    // MARK: - Voice Submit

    private func handleVoiceSubmit(_ text: String) {
        viewModel.inputText = text
        viewModel.send()
    }

    // MARK: - TTS

    private func configureTTSVoice() {
        let voiceProfile: BarbaraVoiceProfile = language == "de" ? .german : .english
        ttsService.configuration = voiceProfile.ttsConfiguration(for: .observation)
    }

    private func speakLatestBarbaraMessage() {
        guard ttsEnabled,
              let lastMessage = viewModel.messages.last,
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
                }
            }
        }
    }

    // MARK: - No Texts

    private var noTextsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(language == "de"
                 ? "Keine Texte verf\u{00FC}gbar"
                 : "No texts available")
                .font(.title3)
                .fontWeight(.semibold)

            Text(language == "de"
                 ? "Es gibt aktuell keine passenden Texte f\u{00FC}r dein Level."
                 : "There are no matching texts for your current level.")
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
        ttsService.stop()
        voiceInputVM.reset()
        audioSessionManager.deactivateSession()
        sessionManager.endSession()
        onDismiss?()
    }
}

// MARK: - Previews

private let voicePreviewText = PracticeText(
    id: "preview-voice-ftp",
    text: "School uniforms reduce social pressure by eliminating visible economic differences among students. When everyone wears the same clothes, students focus more on learning and less on fashion. Studies in three US states found a 23% reduction in bullying incidents after uniform adoption. However, critics argue that uniforms suppress individual expression, which is a core developmental need for teenagers.",
    answerKey: AnswerKey(
        governingThought: "School uniforms reduce social pressure but at the cost of individual expression.",
        supports: [
            SupportGroup(label: "Social equaliser", evidence: ["Eliminates visible economic differences", "23% reduction in bullying"]),
            SupportGroup(label: "Critics counter", evidence: ["Suppresses individual expression", "Core developmental need"]),
        ],
        structuralAssessment: "Well-structured with a clear governing thought in the opening sentence."
    ),
    metadata: PracticeTextMetadata(
        qualityLevel: .wellStructured,
        difficultyRating: 1,
        topicDomain: "school",
        language: "en",
        wordCount: 62,
        targetLevel: 1
    )
)

#Preview("Voice Find the Point") {
    NavigationStack {
        VoiceFindThePointView(
            sessionManager: SessionManager(),
            coordinator: FindThePointCoordinator(texts: [voicePreviewText]),
            profile: .createDefault(displayName: "Alex"),
            language: "en"
        )
    }
    .environment(AppSettings.shared)
}

#Preview("No Texts") {
    NavigationStack {
        VoiceFindThePointView(
            sessionManager: SessionManager(),
            coordinator: FindThePointCoordinator(texts: []),
            profile: .createDefault(displayName: "Alex"),
            language: "en"
        )
    }
    .environment(AppSettings.shared)
}
