import SwiftUI

/// Full-screen view for an "Analyse my text" session.
///
/// The learner pastes or types their own text for structural analysis.
/// No topic selection — the text IS the input. Barbara evaluates the
/// structure and the learner can revise based on feedback.
///
/// Platform behavior:
/// - **iPhone**: Full-width chat, text input area.
/// - **iPad/Mac**: Centered layout with generous text input area.
struct AnalyseMyTextView: View {
    let sessionManager: SessionManager
    let profile: LearnerProfile
    let language: String
    var onDismiss: (() -> Void)?

    @State private var viewModel: ChatViewModel
    @State private var sessionStarted = false

    init(
        sessionManager: SessionManager,
        profile: LearnerProfile,
        language: String,
        onDismiss: (() -> Void)? = nil
    ) {
        self.sessionManager = sessionManager
        self.profile = profile
        self.language = language
        self.onDismiss = onDismiss
        self._viewModel = State(initialValue: ChatViewModel(sessionManager: sessionManager))
    }

    var body: some View {
        ChatView(viewModel: viewModel)
            .navigationTitle(SessionType.analyseMyText.displayName(language: language))
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
                await sessionManager.startAnalyseMyTextSession(
                    profile: profile,
                    language: language
                )
            }
    }

    // MARK: - Actions

    private func endSessionAndDismiss() {
        sessionManager.endSession()
        onDismiss?()
    }
}

// MARK: - Previews

#Preview("Analyse My Text — Loading") {
    NavigationStack {
        AnalyseMyTextView(
            sessionManager: SessionManager(),
            profile: .createDefault(displayName: "Alex"),
            language: "en"
        )
    }
}

#Preview("German") {
    NavigationStack {
        AnalyseMyTextView(
            sessionManager: SessionManager(),
            profile: .createDefault(displayName: "Maxi", language: "de"),
            language: "de"
        )
    }
}

#Preview("iPad") {
    NavigationStack {
        AnalyseMyTextView(
            sessionManager: SessionManager(),
            profile: .createDefault(displayName: "Alex"),
            language: "en"
        )
    }
    .environment(\.horizontalSizeClass, .regular)
}
