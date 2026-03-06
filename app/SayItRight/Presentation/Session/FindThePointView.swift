import SwiftUI

/// Full-screen view for a "Find the point" session.
///
/// Integrates practice text display, chat interface, and session lifecycle.
/// On appearance, selects a practice text and starts the session. The chat
/// interface handles the interaction with Barbara for extraction evaluation.
///
/// Platform behavior:
/// - **iPhone**: Text displayed above chat in a single scrollable column.
/// - **iPad/Mac**: Text in left panel, chat in right panel (side-by-side).
struct FindThePointView: View {
    let sessionManager: SessionManager
    let coordinator: FindThePointCoordinator
    let profile: LearnerProfile
    let language: String
    var onDismiss: (() -> Void)?

    @State private var viewModel: ChatViewModel
    @State private var sessionStarted = false
    @State private var noTextsAvailable = false
    @State private var selectedText: PracticeText?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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
    }

    var body: some View {
        Group {
            if noTextsAvailable {
                noTextsView
            } else if selectedText != nil {
                sessionContent
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
            let text = await coordinator.startSession(
                sessionManager: sessionManager,
                profile: profile,
                language: language
            )
            if let text {
                selectedText = text
            } else {
                noTextsAvailable = true
            }
        }
    }

    // MARK: - Session Content

    @ViewBuilder
    private var sessionContent: some View {
        #if os(macOS)
        splitLayout
        #else
        if horizontalSizeClass == .regular {
            splitLayout
        } else {
            compactLayout
        }
        #endif
    }

    /// Side-by-side layout for iPad and Mac: text left, chat right.
    private var splitLayout: some View {
        HStack(spacing: 0) {
            // Left panel: practice text
            ScrollView {
                if let text = selectedText {
                    PracticeTextView(text: text.text, language: language)
                        .padding(20)
                }
            }
            .frame(maxWidth: .infinity)

            Divider()

            // Right panel: chat
            ChatView(viewModel: viewModel)
                .frame(maxWidth: .infinity)
        }
    }

    /// Stacked layout for iPhone: text above, chat below.
    private var compactLayout: some View {
        VStack(spacing: 0) {
            // Collapsible text panel at top
            if let text = selectedText {
                ScrollView {
                    PracticeTextView(text: text.text, language: language)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .frame(maxHeight: 200)

                Divider()
            }

            // Chat below
            ChatView(viewModel: viewModel)
        }
    }

    // MARK: - No Texts Available

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
        sessionManager.endSession()
        onDismiss?()
    }
}

// MARK: - Previews

private let previewText = PracticeText(
    id: "preview-001",
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

#Preview("Find the Point -- Loading") {
    NavigationStack {
        FindThePointView(
            sessionManager: SessionManager(),
            coordinator: FindThePointCoordinator(texts: [previewText]),
            profile: .createDefault(displayName: "Alex"),
            language: "en"
        )
    }
}

#Preview("No Texts") {
    NavigationStack {
        FindThePointView(
            sessionManager: SessionManager(),
            coordinator: FindThePointCoordinator(texts: []),
            profile: .createDefault(displayName: "Alex"),
            language: "en"
        )
    }
}

#Preview("German") {
    NavigationStack {
        FindThePointView(
            sessionManager: SessionManager(),
            coordinator: FindThePointCoordinator(texts: [previewText]),
            profile: .createDefault(displayName: "Maxi", language: "de"),
            language: "de"
        )
    }
}

#Preview("iPad") {
    NavigationStack {
        FindThePointView(
            sessionManager: SessionManager(),
            coordinator: FindThePointCoordinator(texts: [previewText]),
            profile: .createDefault(displayName: "Alex"),
            language: "en"
        )
    }
    .environment(\.horizontalSizeClass, .regular)
}
