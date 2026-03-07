import Foundation

/// Determines the learner's difficulty state and calibrates topic selection.
///
/// Uses the learner's rolling dimension averages to decide whether to consolidate
/// at the current level, stretch with harder topics, or signal readiness for promotion.
///
/// The state machine:
/// - **consolidating**: Stay at current level. < 60% of dimensions are strong.
/// - **stretching**: Mix in next-level topics (70/30 current/stretch). >= 60% strong.
/// - **readyForPromotion**: All key dimensions are strong. Level-up candidate.
struct AdaptiveDifficultyEngine: Sendable {

    // MARK: - Configuration

    /// Minimum rolling average (normalised 0-1) to consider a dimension "strong".
    static let strongThreshold: Double = 0.7

    /// Minimum rolling average (normalised 0-1) below which a dimension is "weak".
    static let weakThreshold: Double = 0.4

    /// Fraction of dimensions that must be strong to start stretching.
    static let stretchFraction: Double = 0.6

    /// Minimum sessions before stretch can begin.
    static let minSessionsForStretch: Int = 5

    /// Minimum sessions before promotion can be considered.
    static let minSessionsForPromotion: Int = 10

    /// Ratio of current-level topics when stretching.
    static let stretchCurrentRatio: Double = 0.7

    // MARK: - Difficulty State

    enum DifficultyState: String, Sendable {
        case consolidating
        case stretching
        case readyForPromotion
    }

    // MARK: - Public API

    /// Compute the difficulty state for a given profile.
    static func difficultyState(for profile: LearnerProfile) -> DifficultyState {
        let dimensions = dimensionsForLevel(profile.currentLevel)
        guard !dimensions.isEmpty else { return .consolidating }

        let strongCount = dimensions.filter { dim in
            isStrong(dim, in: profile)
        }.count

        let weakCount = dimensions.filter { dim in
            isWeak(dim, in: profile)
        }.count

        let strongFraction = Double(strongCount) / Double(dimensions.count)

        // Not enough sessions yet
        if profile.sessionCount < minSessionsForStretch {
            return .consolidating
        }

        // All key dimensions strong, no weak ones, enough sessions
        if strongCount == dimensions.count
            && weakCount == 0
            && profile.sessionCount >= minSessionsForPromotion {
            return .readyForPromotion
        }

        // Enough strong dimensions to start stretching
        if strongFraction >= stretchFraction {
            return .stretching
        }

        return .consolidating
    }

    /// Select the appropriate topic level for a profile.
    ///
    /// Returns the level to use for topic selection. When stretching, uses
    /// a deterministic pattern to mix current and next-level topics.
    static func topicLevel(
        for profile: LearnerProfile,
        sessionIndex: Int? = nil
    ) -> Int {
        let state = difficultyState(for: profile)
        let currentLevel = profile.currentLevel
        let index = sessionIndex ?? profile.sessionCount

        switch state {
        case .consolidating:
            return currentLevel
        case .stretching:
            // 70% current, 30% stretch — deterministic pattern
            let isStretchSlot = (index % 10) >= Int(stretchCurrentRatio * 10)
            return isStretchSlot ? min(currentLevel + 1, 4) : currentLevel
        case .readyForPromotion:
            // Mix evenly between current and next to prepare for transition
            return (index % 2 == 0) ? currentLevel : min(currentLevel + 1, 4)
        }
    }

    /// Identify the weakest dimensions that need targeted practice.
    static func weakDimensions(for profile: LearnerProfile) -> [String] {
        let dimensions = dimensionsForLevel(profile.currentLevel)
        return dimensions.filter { isWeak($0, in: profile) }.sorted()
    }

    /// Identify strong dimensions.
    static func strongDimensions(for profile: LearnerProfile) -> [String] {
        let dimensions = dimensionsForLevel(profile.currentLevel)
        return dimensions.filter { isStrong($0, in: profile) }.sorted()
    }

    /// Build a difficulty context string for system prompt injection.
    static func difficultyContext(for profile: LearnerProfile) -> String {
        let state = difficultyState(for: profile)
        let weak = weakDimensions(for: profile)
        let strong = strongDimensions(for: profile)

        var lines: [String] = []
        lines.append("Difficulty state: \(state.rawValue)")

        if !strong.isEmpty {
            lines.append("Strong dimensions: \(strong.joined(separator: ", "))")
        }
        if !weak.isEmpty {
            lines.append("Weak dimensions (focus here): \(weak.joined(separator: ", "))")
        }

        switch state {
        case .consolidating:
            lines.append("Coaching approach: Patient, encouraging. Focus on fundamentals.")
        case .stretching:
            lines.append("Coaching approach: More demanding. Introduce higher-level concepts.")
        case .readyForPromotion:
            lines.append("Coaching approach: Challenge-oriented. The learner is close to leveling up.")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Private Helpers

    /// Key dimensions evaluated at each level (Build + Break).
    static func dimensionsForLevel(_ level: Int) -> [String] {
        switch level {
        case 1:
            return ProfileUpdater.buildDimensionsL1
        case 2:
            return ProfileUpdater.buildDimensionsL2 + ProfileUpdater.breakDimensions
        default:
            // L3+ includes all L2 Build + Break dimensions
            return ProfileUpdater.buildDimensionsL2 + ProfileUpdater.breakDimensions
        }
    }

    private static func isStrong(_ dimension: String, in profile: LearnerProfile) -> Bool {
        guard let avg = profile.rollingAverage(for: dimension),
              let maxScore = ProfileUpdater.maxScores[dimension],
              maxScore > 0 else {
            return false
        }
        return (avg / Double(maxScore)) >= strongThreshold
    }

    private static func isWeak(_ dimension: String, in profile: LearnerProfile) -> Bool {
        guard let avg = profile.rollingAverage(for: dimension),
              let maxScore = ProfileUpdater.maxScores[dimension],
              maxScore > 0 else {
            // No data = weak by default (needs practice)
            return true
        }
        return (avg / Double(maxScore)) < weakThreshold
    }
}
