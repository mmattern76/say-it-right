import Foundation

/// Orchestrates "Decode and rebuild" session flow.
///
/// Selects buried-lead or rambling practice texts (not well-structured,
/// since the learner needs structural work to do). Requires L2+ and
/// at least 3 completed Break and 3 completed Build sessions.
@MainActor
@Observable
final class DecodeAndRebuildCoordinator {

    var recentTextIDs: Set<String> = []

    private let library: PracticeTextLibrary
    private let maxRecentTexts = 10

    /// Minimum completed Break sessions required to unlock.
    static let minBreakSessions = 3
    /// Minimum completed Build sessions required to unlock.
    static let minBuildSessions = 3

    init(library: PracticeTextLibrary = .loadFromBundle()) {
        self.library = library
    }

    /// Whether the learner meets the unlock requirements.
    ///
    /// Requires L2+ and at least 3 Break + 3 Build completed sessions.
    func isUnlocked(for profile: LearnerProfile) -> Bool {
        guard profile.currentLevel >= 2 else { return false }
        return profile.sessionCount >= (Self.minBreakSessions + Self.minBuildSessions)
    }

    /// Select a practice text for the decode-and-rebuild exercise.
    ///
    /// Filters for buried-lead and rambling texts at the learner's level.
    func selectText(for profile: LearnerProfile) -> PracticeText? {
        let language = profile.language
        let allowedQualities: Set<QualityLevel> = [.buriedLead, .rambling]

        var candidates = library.texts.filter { text in
            text.metadata.language == language
                && allowedQualities.contains(text.metadata.qualityLevel)
                && text.metadata.targetLevel <= profile.currentLevel
        }

        // Exclude recently seen
        let unseen = candidates.filter { !recentTextIDs.contains($0.id) }
        if !unseen.isEmpty {
            candidates = unseen
        } else {
            recentTextIDs.removeAll()
        }

        guard let selected = candidates.randomElement() else { return nil }
        trackSeen(selected)
        return selected
    }

    private func trackSeen(_ text: PracticeText) {
        recentTextIDs.insert(text.id)
        if recentTextIDs.count > maxRecentTexts {
            recentTextIDs.removeAll()
            recentTextIDs.insert(text.id)
        }
    }

    func clearRecentTexts() {
        recentTextIDs.removeAll()
    }
}
