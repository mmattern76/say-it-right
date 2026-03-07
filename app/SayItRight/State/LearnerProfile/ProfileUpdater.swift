import Foundation

/// Updates the learner profile from session evaluation metadata.
///
/// Bridges individual session results to long-term skill tracking by
/// extracting dimension scores from Barbara's hidden metadata, computing
/// rolling averages, and identifying structural strengths and development areas.
struct ProfileUpdater: Sendable {

    // MARK: - Thresholds

    /// Rolling average above this marks a dimension as a strength.
    static let strengthThreshold: Double = 0.8

    /// Rolling average below this marks a dimension as a development area.
    static let developmentThreshold: Double = 0.5

    /// Maximum scores per dimension (L1 rubric).
    static let maxScores: [String: Int] = [
        "governingThought": 3,
        "supportGrouping": 2,
        "redundancy": 2,
        "clarity": 3,
        "l1Gate": 3,
        "meceQuality": 3,
        "orderingLogic": 3,
        "scqApplication": 2,
        "horizontalLogic": 2
    ]

    // MARK: - Public API

    /// Update a profile with scores from session metadata.
    ///
    /// - Parameters:
    ///   - profile: The profile to update (mutated in place).
    ///   - metadataList: All metadata blocks from the session.
    ///   - sessionType: The type of session completed.
    func updateProfile(
        _ profile: inout LearnerProfile,
        from metadataList: [BarbaraMetadata],
        sessionType: String
    ) {
        // Extract the last evaluation metadata with scores
        let scoredMetadata = metadataList.filter { !$0.scores.isEmpty }
        guard !scoredMetadata.isEmpty else { return }

        // Record dimension scores from each evaluation
        for metadata in scoredMetadata {
            for (dimension, score) in metadata.scores {
                profile.recordScore(score, for: dimension)
            }
        }

        // Update session count
        profile.sessionCount += 1

        // Update streak
        profile.updateStreak()

        // Recalculate strengths and development areas
        updateStrengthsAndWeaknesses(&profile)
    }

    /// Update a profile from a single metadata block (convenience).
    func updateProfile(
        _ profile: inout LearnerProfile,
        from metadata: BarbaraMetadata,
        sessionType: String
    ) {
        updateProfile(&profile, from: [metadata], sessionType: sessionType)
    }

    /// Apply profile update via the store (async, saves to disk).
    func applySessionResults(
        store: LearnerProfileStore,
        metadataList: [BarbaraMetadata],
        sessionType: String
    ) async throws {
        let scoredMetadata = metadataList.filter { !$0.scores.isEmpty }
        guard !scoredMetadata.isEmpty else { return }

        try await store.update { profile in
            self.updateProfile(&profile, from: scoredMetadata, sessionType: sessionType)
        }
    }

    // MARK: - Private

    /// Recalculate structural strengths and development areas from rolling averages.
    private func updateStrengthsAndWeaknesses(_ profile: inout LearnerProfile) {
        var strengths: [String] = []
        var weaknesses: [String] = []

        for (dimension, scores) in profile.dimensionScores where !scores.isEmpty {
            guard let maxScore = Self.maxScores[dimension], maxScore > 0 else { continue }

            let avg = profile.rollingAverage(for: dimension) ?? 0
            let normalised = avg / Double(maxScore)

            if normalised >= Self.strengthThreshold {
                strengths.append(dimension)
            } else if normalised < Self.developmentThreshold {
                weaknesses.append(dimension)
            }
        }

        profile.structuralStrengths = strengths.sorted()
        profile.developmentAreas = weaknesses.sorted()
    }
}
