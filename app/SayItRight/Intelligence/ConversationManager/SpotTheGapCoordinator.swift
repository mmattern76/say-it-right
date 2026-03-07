import Foundation

/// Orchestrates "Spot the gap" session flow.
///
/// Selects adversarial practice texts with hidden structural flaws.
/// Only available for L2+ learners.
@MainActor
@Observable
final class SpotTheGapCoordinator {

    var recentTextIDs: Set<String> = []

    private let library: PracticeTextLibrary
    private let maxRecentTexts = 10

    init(library: PracticeTextLibrary = PracticeTextLibrary()) {
        self.library = library
    }

    /// Select an adversarial practice text with a structural flaw.
    ///
    /// Returns `nil` if no adversarial texts are available for the learner's
    /// language and level, or if the learner is below L2.
    func selectText(for profile: LearnerProfile) -> PracticeText? {
        guard profile.currentLevel >= 2 else { return nil }

        let language = profile.language

        var candidates = library.texts.filter { text in
            text.metadata.language == language
                && text.metadata.qualityLevel == .adversarial
                && text.answerKey.structuralFlaw != nil
        }

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
