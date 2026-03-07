import SwiftUI

/// Full-screen view for a "Decode and rebuild" session.
///
/// Platform behavior:
/// - **iPhone**: Original text shown above chat, scrollable.
/// - **iPad/Mac**: Split view with original text on left, chat on right.
struct DecodeAndRebuildView: View {
    let sessionManager: SessionManager
    let coordinator: DecodeAndRebuildCoordinator
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
        coordinator: DecodeAndRebuildCoordinator,
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
            if !coordinator.isUnlocked(for: profile) {
                lockedView
            } else if isWide {
                splitLayout
            } else {
                compactLayout
            }
        }
        .navigationTitle(SessionType.decodeAndRebuild.displayName(language: language))
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
            guard !sessionStarted, coordinator.isUnlocked(for: profile) else { return }
            sessionStarted = true

            guard let text = coordinator.selectText(for: profile) else { return }
            selectedText = text

            await sessionManager.startDecodeAndRebuildSession(
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

    // MARK: - Locked View

    private var lockedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(language == "de"
                ? "Diese Übung wird freigeschaltet, wenn du mindestens 3 Break- und 3 Build-Sitzungen abgeschlossen hast."
                : "This exercise unlocks after completing at least 3 Break and 3 Build sessions."
            )
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 40)

            Button(action: { onDismiss?() }) {
                Text(language == "de" ? "Zurück" : "Go Back")
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

                if let phase = sessionManager.decodeAndRebuildSession?.phase {
                    phaseIndicator(phase)
                }

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

    private func phaseIndicator(_ phase: DecodeAndRebuildSession.Phase) -> some View {
        HStack(spacing: 8) {
            let isPhase1 = phase == .extraction || phase == .transition
            let phase1Label = language == "de" ? "1. Struktur erkennen" : "1. Extract Structure"
            let phase2Label = language == "de" ? "2. Neu aufbauen" : "2. Rebuild"

            Label(phase1Label, systemImage: isPhase1 ? "1.circle.fill" : "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(isPhase1 ? .blue : .green)

            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Label(phase2Label, systemImage: phase == .rebuild ? "2.circle.fill" : "2.circle")
                .font(.caption)
                .foregroundStyle(phase == .rebuild || phase == .summary ? .blue : .secondary)
        }
    }

    // MARK: - Actions

    private func endSessionAndDismiss() {
        sessionManager.endSession()
        onDismiss?()
    }
}

// MARK: - Previews

#Preview("Decode and Rebuild") {
    NavigationStack {
        DecodeAndRebuildView(
            sessionManager: SessionManager(),
            coordinator: DecodeAndRebuildCoordinator(),
            profile: .createDefault(displayName: "Alex"),
            language: "en"
        )
    }
}

#Preview("German") {
    NavigationStack {
        DecodeAndRebuildView(
            sessionManager: SessionManager(),
            coordinator: DecodeAndRebuildCoordinator(),
            profile: .createDefault(displayName: "Maxi", language: "de"),
            language: "de"
        )
    }
}
