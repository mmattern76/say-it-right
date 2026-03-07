import SwiftUI

/// Full-screen view for an "Elevator pitch" / "30 Sekunden" session.
///
/// Presents a topic with a countdown timer. The learner writes under time
/// pressure; auto-submits when the timer expires. No revision loop.
///
/// Platform behavior:
/// - **iPhone**: Full-width, compact timer above input.
/// - **iPad/Mac**: Centered layout with prominent timer.
struct ElevatorPitchView: View {
    let sessionManager: SessionManager
    let coordinator: ElevatorPitchCoordinator
    let profile: LearnerProfile
    let language: String
    var onDismiss: (() -> Void)?

    @State private var viewModel: ChatViewModel
    @State private var sessionStarted = false
    @State private var noTopicsAvailable = false
    @State private var timerState = TimerState()

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
    }

    var body: some View {
        Group {
            if noTopicsAvailable {
                noTopicsView
            } else {
                VStack(spacing: 0) {
                    if timerState.isRunning {
                        timerBar
                    }
                    ChatView(viewModel: viewModel)
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
            let topic = await coordinator.startSession(
                sessionManager: sessionManager,
                profile: profile,
                language: language
            )
            if topic == nil {
                noTopicsAvailable = true
            }
        }
        .onChange(of: sessionManager.sessionState) { _, newState in
            // Start timer when Barbara's greeting completes (session becomes active)
            if case .active = newState,
               !timerState.hasStarted,
               let session = sessionManager.elevatorPitchSession {
                startTimer(duration: session.durationSeconds)
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
                if timerState.isRunning && !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button(action: submitEarly) {
                        Label(
                            language == "de" ? "Abgeben" : "Submit",
                            systemImage: "arrow.up.circle.fill"
                        )
                        .font(.caption.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }

            // Progress bar
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

        timerState.timerTask = Task { @MainActor in
            while timerState.remainingSeconds > 0 && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                timerState.remainingSeconds -= 1

                #if os(iOS)
                // Haptic feedback at 10 and 5 seconds
                if timerState.remainingSeconds == 10 || timerState.remainingSeconds == 5 {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
                #endif
            }

            if !Task.isCancelled && timerState.remainingSeconds <= 0 {
                timerState.isRunning = false
                await autoSubmit()
            }
        }
    }

    private func autoSubmit() async {
        let text = viewModel.inputText
        viewModel.inputText = ""
        timerState.isRunning = false
        timerState.timerTask?.cancel()
        await sessionManager.submitElevatorPitch(text: text, timedOut: true)
    }

    private func submitEarly() {
        let text = viewModel.inputText
        viewModel.inputText = ""
        timerState.isRunning = false
        timerState.timerTask?.cancel()
        Task {
            await sessionManager.submitElevatorPitch(text: text, timedOut: false)
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
        sessionManager.endSession()
        onDismiss?()
    }
}

// MARK: - Timer State

/// Mutable timer state for the elevator pitch countdown.
@MainActor
private struct TimerState {
    var totalSeconds: Int = 0
    var remainingSeconds: Int = 0
    var isRunning: Bool = false
    var hasStarted: Bool = false
    var timerTask: Task<Void, Never>?
}

// MARK: - Previews

#Preview("Elevator Pitch — Loading") {
    NavigationStack {
        ElevatorPitchView(
            sessionManager: SessionManager(),
            coordinator: ElevatorPitchCoordinator(topics: [
                Topic(
                    id: "preview-ep",
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
}

#Preview("No Topics") {
    NavigationStack {
        ElevatorPitchView(
            sessionManager: SessionManager(),
            coordinator: ElevatorPitchCoordinator(topics: []),
            profile: .createDefault(displayName: "Alex"),
            language: "en"
        )
    }
}

#Preview("German") {
    NavigationStack {
        ElevatorPitchView(
            sessionManager: SessionManager(),
            coordinator: ElevatorPitchCoordinator(topics: [
                Topic(
                    id: "preview-ep-de",
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
}
