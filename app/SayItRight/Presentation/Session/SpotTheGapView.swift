import SwiftUI

/// Full-screen view for a "Spot the gap" session.
///
/// Presents a convincing-looking argument and asks the learner to find
/// the hidden structural weakness. Available for L2+ learners only.
struct SpotTheGapView: View {
    let sessionManager: SessionManager
    let coordinator: SpotTheGapCoordinator
    let profile: LearnerProfile
    let language: String
    var onDismiss: (() -> Void)?

    @State private var viewModel: ChatViewModel
    @State private var sessionStarted = false
    @State private var selectedText: PracticeText?
    @State private var noTextsAvailable = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isWide: Bool {
        #if os(macOS)
        true
        #else
        horizontalSizeClass == .regular
        #endif
    }

    init(
        sessionManager: SessionManager,
        coordinator: SpotTheGapCoordinator,
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
            if noTextsAvailable {
                noTextsView
            } else if isWide {
                splitLayout
            } else {
                compactLayout
            }
        }
        .navigationTitle(SessionType.spotTheGap.displayName(language: language))
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

            guard let text = coordinator.selectText(for: profile) else {
                noTextsAvailable = true
                return
            }
            selectedText = text

            await sessionManager.startSpotTheGapSession(
                practiceText: text,
                profile: profile,
                language: language
            )
        }
    }

    // MARK: - No Texts Available

    private var noTextsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text(language == "de"
                ? "Keine passenden Texte verfügbar"
                : "No matching texts available")
                .font(.headline)

            Text(language == "de"
                ? "Dieses Übungsformat erfordert Level 2 oder höher."
                : "This exercise requires Level 2 or higher.")
                .font(.body)
                .foregroundStyle(.secondary)

            Button(action: endSessionAndDismiss) {
                Text(language == "de" ? "Zurück" : "Go Back")
            }
            .buttonStyle(.bordered)
        }
        .padding(40)
    }

    // MARK: - Layouts

    private var splitLayout: some View {
        HStack(spacing: 0) {
            if let text = selectedText {
                originalTextPanel(text)
                    .frame(maxWidth: .infinity)
                Divider()
            }
            ChatView(viewModel: viewModel)
                .frame(maxWidth: .infinity)
        }
    }

    private var compactLayout: some View {
        ChatView(viewModel: viewModel)
    }

    private func originalTextPanel(_ text: PracticeText) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Label(
                    language == "de" ? "Das Argument" : "The Argument",
                    systemImage: "doc.text"
                )
                .font(.headline)
                .foregroundStyle(.secondary)

                Text(text.text)
                    .font(.body)
                    .lineSpacing(4)
            }
            .padding(20)
        }
    }

    private func endSessionAndDismiss() {
        sessionManager.endSession()
        onDismiss?()
    }
}

// MARK: - Previews

#Preview("Spot The Gap") {
    NavigationStack {
        SpotTheGapView(
            sessionManager: SessionManager(),
            coordinator: SpotTheGapCoordinator(),
            profile: .createDefault(displayName: "Alex"),
            language: "en"
        )
    }
}
