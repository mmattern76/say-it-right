import Foundation

/// Orchestrates "Fix this mess" session flow.
///
/// Selects poorly structured practice texts (rambling or buried-lead)
/// appropriate for the learner's level.
@MainActor
@Observable
final class FixThisMessCoordinator {

    var recentTextIDs: Set<String> = []

    private let library: PracticeTextLibrary
    private let maxRecentTexts = 10

    init(library: PracticeTextLibrary = .loadFromBundle()) {
        self.library = library
    }

    /// Select a practice text for restructuring.
    ///
    /// Filters for rambling and buried-lead texts at the learner's level.
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
