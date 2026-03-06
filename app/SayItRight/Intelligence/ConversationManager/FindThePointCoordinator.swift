import Foundation

/// Orchestrates the "Find the point" session flow.
///
/// Responsibilities:
/// 1. Select a practice text from the library (filtered by language, level, seen texts).
/// 2. Start the session via `SessionManager` with the selected text.
/// 3. Track seen texts via `SeenTextsStore` to avoid repetition.
///
/// This coordinator is the single entry point for starting a "Find the point"
/// session from the UI layer.
@MainActor
@Observable
final class FindThePointCoordinator {

    /// The practice text library used for selection.
    private let library: PracticeTextLibrary

    /// Persistence for seen text tracking.
    private let seenTextsStore: SeenTextsStore

    /// The session type key used for seen-texts tracking.
    static let sessionTypeKey = "find_the_point"

    init(
        library: PracticeTextLibrary = .loadFromBundle(),
        seenTextsStore: SeenTextsStore = SeenTextsStore()
    ) {
        self.library = library
        self.seenTextsStore = seenTextsStore
    }

    /// Convenience initialiser for testing with an explicit text list.
    init(texts: [PracticeText], seenTextsStore: SeenTextsStore = SeenTextsStore()) {
        self.library = PracticeTextLibrary(texts: texts)
        self.seenTextsStore = seenTextsStore
    }

    /// Start a "Find the point" session.
    ///
    /// Selects a level-appropriate practice text and starts the session
    /// on the provided `SessionManager`.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager to start the session on.
    ///   - profile: The learner's current profile.
    ///   - language: Language code ("en" or "de").
    /// - Returns: The selected practice text, or `nil` if none available.
    @discardableResult
    func startSession(
        sessionManager: SessionManager,
        profile: LearnerProfile,
        language: String
    ) async -> PracticeText? {
        // Select quality type based on learner level
        let quality = qualityForLevel(profile.currentLevel)

        guard let selection = try? await seenTextsStore.selectUnseenText(
            sessionType: Self.sessionTypeKey,
            level: profile.currentLevel,
            language: language,
            library: library,
            quality: quality
        ) else {
            return nil
        }

        // Mark text as seen
        try? await seenTextsStore.markSeen(
            textID: selection.text.id,
            sessionType: Self.sessionTypeKey
        )

        // Start the session on SessionManager
        await sessionManager.startFindThePointSession(
            practiceText: selection.text,
            profile: profile,
            language: language
        )

        return selection.text
    }

    /// Determine the appropriate text quality for the learner's level.
    ///
    /// - Level 1: well-structured texts (governing thought is obvious)
    /// - Level 1-2 transition: buried-lead texts
    /// - Level 2+: mix including rambling texts
    private func qualityForLevel(_ level: Int) -> QualityLevel? {
        switch level {
        case 1:
            return .wellStructured
        case 2:
            // Level 2 can handle buried-lead; nil = any quality
            return nil
        default:
            return nil
        }
    }
}
