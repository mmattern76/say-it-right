import SwiftUI

/// Full-screen view for a "Say it clearly" session.
///
/// Integrates topic selection, chat interface, and session lifecycle.
/// On appearance, selects a topic and starts the session. The chat
/// interface handles the rest of the interaction with Barbara.
///
/// Platform behavior:
/// - **iPhone**: Full-width chat, compact input bar.
/// - **iPad**: Centered chat with generous spacing.
/// - **Mac**: Keyboard-focused, Enter to send.
struct SayItClearlyView: View {
    let sessionManager: SessionManager
    let coordinator: SayItClearlyCoordinator
    let profile: LearnerProfile
    let language: String
    var onDismiss: (() -> Void)?

    @State private var viewModel: ChatViewModel
    @State private var sessionStarted = false
    @State private var noTopicsAvailable = false

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
    }

    var body: some View {
        Group {
            if noTopicsAvailable {
                noTopicsView
            } else {
                ChatView(viewModel: viewModel)
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
            let topic = await coordinator.startSession(
                sessionManager: sessionManager,
                profile: profile,
                language: language
            )
            if topic == nil {
                noTopicsAvailable = true
            }
        }
    }

    // MARK: - No Topics Available

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
        sessionManager.endSession()
        onDismiss?()
    }
}

// MARK: - Previews

#Preview("Say it clearly — Loading") {
    NavigationStack {
        SayItClearlyView(
            sessionManager: SessionManager(),
            coordinator: SayItClearlyCoordinator(topics: [
                Topic(
                    id: "preview-1",
                    titleEN: "Four-day school week",
                    titleDE: "Vier-Tage-Schulwoche",
                    promptEN: "Should schools switch to a four-day week? Tell me what you think — conclusion first.",
                    promptDE: "Sollte die Schule auf eine Vier-Tage-Woche umstellen? Sag mir was du denkst — Fazit zuerst.",
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
        SayItClearlyView(
            sessionManager: SessionManager(),
            coordinator: SayItClearlyCoordinator(topics: []),
            profile: .createDefault(displayName: "Alex"),
            language: "en"
        )
    }
}

#Preview("German") {
    NavigationStack {
        SayItClearlyView(
            sessionManager: SessionManager(),
            coordinator: SayItClearlyCoordinator(topics: [
                Topic(
                    id: "preview-de",
                    titleEN: "Homework",
                    titleDE: "Hausaufgaben",
                    promptEN: "Should homework be abolished?",
                    promptDE: "Sollten Hausaufgaben abgeschafft werden? Sag mir was du denkst — Fazit zuerst.",
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

#Preview("iPad") {
    NavigationStack {
        SayItClearlyView(
            sessionManager: SessionManager(),
            coordinator: SayItClearlyCoordinator(topics: [
                Topic(
                    id: "preview-ipad",
                    titleEN: "Social media age limit",
                    titleDE: "Altersgrenze f\u{00FC}r Social Media",
                    promptEN: "Should there be a minimum age for social media? Tell me what you think.",
                    promptDE: "Sollte es ein Mindestalter f\u{00FC}r Social Media geben?",
                    domain: .society,
                    level: 1,
                    barbaraFavorite: true
                )
            ]),
            profile: .createDefault(displayName: "Alex"),
            language: "en"
        )
    }
    .environment(\.horizontalSizeClass, .regular)
}
