import SwiftUI

/// Full-screen view for a "Fix this mess" session.
///
/// Platform behavior:
/// - **iPhone**: Original text shown above chat, scrollable.
/// - **iPad/Mac**: Split view with original text on left, chat on right.
struct FixThisMessView: View {
    let sessionManager: SessionManager
    let coordinator: FixThisMessCoordinator
    let profile: LearnerProfile
    let language: String
    var onDismiss: (() -> Void)?

    @State private var viewModel: ChatViewModel
    @State private var sessionStarted = false
    @State private var selectedText: PracticeText?
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
        coordinator: FixThisMessCoordinator,
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
            if isWide {
                splitLayout
            } else {
                compactLayout
            }
        }
        .navigationTitle(SessionType.fixThisMess.displayName(language: language))
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

            guard let text = coordinator.selectText(for: profile) else { return }
            selectedText = text

            await sessionManager.startFixThisMessSession(
                practiceText: text,
                profile: profile,
                language: language
            )
        }
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

    // MARK: - Original Text Panel

    private func originalTextPanel(_ text: PracticeText) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Label(
                    language == "de" ? "Originaltext" : "Original Text",
                    systemImage: "doc.text"
                )
                .font(.headline)
                .foregroundStyle(.secondary)

                Text(text.text)
                    .font(.body)
                    .lineSpacing(4)

                HStack {
                    Text("\(text.metadata.wordCount) \(language == "de" ? "Wörter" : "words")")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
            }
            .padding(20)
        }
    }

    // MARK: - Actions

    private func endSessionAndDismiss() {
        sessionManager.endSession()
        onDismiss?()
    }
}

// MARK: - Previews

#Preview("Fix This Mess") {
    NavigationStack {
        FixThisMessView(
            sessionManager: SessionManager(),
            coordinator: FixThisMessCoordinator(),
            profile: .createDefault(displayName: "Alex"),
            language: "en"
        )
    }
}

#Preview("German") {
    NavigationStack {
        FixThisMessView(
            sessionManager: SessionManager(),
            coordinator: FixThisMessCoordinator(),
            profile: .createDefault(displayName: "Maxi", language: "de"),
            language: "de"
        )
    }
}
