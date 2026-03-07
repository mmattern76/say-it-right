import Foundation

/// Matches practice text difficulty to a learner's demonstrated level.
///
/// Ensures Break mode exercises are challenging but not overwhelming by filtering
/// texts based on the learner's current level, scores, and the session type.
struct TextDifficultyCalibrator: Sendable {

    // MARK: - Configuration

    /// Rolling average threshold above which L2 users unlock adversarial texts.
    static let highScoreThreshold: Double = 0.75

    /// Break-mode dimension keys used to compute the rolling average.
    static let breakDimensions: [String] = [
        "governing_thought", "support_grouping", "clarity"
    ]

    /// Fraction of results that should be at the learner's current difficulty band.
    static let currentDifficultyWeight: Double = 0.60

    /// Fraction of results that should stretch the learner slightly.
    static let stretchDifficultyWeight: Double = 0.40

    // MARK: - Public API

    /// Returns practice texts appropriate for the given learner and session type.
    ///
    /// Algorithm:
    /// 1. Filter by language
    /// 2. Filter by allowed quality levels (based on learner level + scores)
    /// 3. Apply session-type constraints
    /// 4. Exclude previously seen texts (reset if all seen)
    /// 5. Apply weighted difficulty distribution
    ///
    /// The selection is deterministic for a given profile state and seed.
    ///
    /// - Parameters:
    ///   - library: The full practice text library.
    ///   - profile: The learner's current profile.
    ///   - sessionType: The session type being played.
    ///   - seen: IDs of texts the learner has already seen.
    ///   - seed: Random seed for deterministic selection. Defaults to profile's session count.
    /// - Returns: A sorted array of candidate texts in weighted order.
    static func calibratedTexts(
        from library: PracticeTextLibrary,
        for profile: LearnerProfile,
        sessionType: SessionType,
        excluding seen: Set<String> = [],
        seed: UInt64? = nil
    ) -> [PracticeText] {
        let language = profile.language
        let allowedQualities = allowedQualityLevels(for: profile)

        // 1. Filter by language and allowed quality levels
        var candidates = library.texts.filter { text in
            text.metadata.language == language
                && allowedQualities.contains(text.metadata.qualityLevel)
        }

        // 2. Apply session-type constraints
        candidates = applySessionConstraints(candidates, sessionType: sessionType)

        // 3. Exclude seen texts; reset if all appropriate texts have been seen
        let unseenCandidates = candidates.filter { !seen.contains($0.id) }
        if unseenCandidates.isEmpty && !candidates.isEmpty {
            // All texts seen — use full candidate set (edge case from issue)
        } else {
            candidates = unseenCandidates
        }

        // 4. Apply weighted difficulty distribution
        let effectiveSeed = seed ?? UInt64(profile.sessionCount)
        candidates = applyDifficultyWeighting(
            candidates,
            profile: profile,
            seed: effectiveSeed
        )

        return candidates
    }

    /// Selects a single practice text matching the calibration criteria.
    ///
    /// Returns `nil` only if the library contains no texts for this language at all.
    static func selectText(
        from library: PracticeTextLibrary,
        for profile: LearnerProfile,
        sessionType: SessionType,
        excluding seen: Set<String> = [],
        seed: UInt64? = nil
    ) -> PracticeText? {
        let texts = calibratedTexts(
            from: library,
            for: profile,
            sessionType: sessionType,
            excluding: seen,
            seed: seed
        )
        return texts.first
    }

    // MARK: - Quality Level Filtering

    /// Determines which quality levels a learner is allowed to see.
    static func allowedQualityLevels(for profile: LearnerProfile) -> Set<QualityLevel> {
        switch profile.currentLevel {
        case 1:
            // L1: well-structured and buried-lead only
            return [.wellStructured, .buriedLead]
        case 2:
            // L2: add rambling; adversarial only if high scores
            var levels: Set<QualityLevel> = [.wellStructured, .buriedLead, .rambling]
            if hasHighBreakScores(profile) {
                levels.insert(.adversarial)
            }
            return levels
        default:
            // L3+: all quality levels
            return Set(QualityLevel.allCases)
        }
    }

    /// Whether the learner has a rolling average above the high-score threshold
    /// across all Break-mode dimensions.
    static func hasHighBreakScores(_ profile: LearnerProfile) -> Bool {
        let averages = breakDimensions.compactMap { profile.rollingAverage(for: $0) }
        // Must have scores in all dimensions to qualify
        guard averages.count == breakDimensions.count else { return false }
        let overallAverage = averages.reduce(0.0, +) / Double(averages.count)
        // Normalise: dimension scores are 0-10 integers, threshold is 0-1
        return (overallAverage / 10.0) >= highScoreThreshold
    }

    // MARK: - Session Constraints

    /// Filters candidates by session-type specific rules.
    static func applySessionConstraints(
        _ texts: [PracticeText],
        sessionType: SessionType
    ) -> [PracticeText] {
        switch sessionType {
        case .findThePoint:
            // "Find the point" works with all allowed quality levels
            return texts
        case .fixThisMess:
            // Only rambling and buried-lead texts
            return texts.filter { [.buriedLead, .rambling].contains($0.metadata.qualityLevel) }
        case .sayItClearly, .elevatorPitch, .analyseMyText:
            // Build mode — no text selection needed, but if called, return all
            return texts
        }
    }

    // MARK: - Difficulty Weighting

    /// Sorts and weights candidates so ~60% are at current difficulty, ~40% stretch.
    ///
    /// "Current difficulty" = difficulty ratings the learner has been working at.
    /// "Stretch" = the next difficulty rating up from current.
    ///
    /// Uses a seeded RNG for deterministic ordering.
    static func applyDifficultyWeighting(
        _ texts: [PracticeText],
        profile: LearnerProfile,
        seed: UInt64
    ) -> [PracticeText] {
        guard !texts.isEmpty else { return [] }

        let currentMax = currentDifficultyMax(for: profile)
        let stretchMin = currentMax + 1

        var currentTexts = texts.filter { $0.metadata.difficultyRating <= currentMax }
        var stretchTexts = texts.filter { $0.metadata.difficultyRating >= stretchMin }

        // If no stretch texts available, use all as current
        if stretchTexts.isEmpty {
            currentTexts = texts
        }
        // If no current texts (e.g., session constrains to harder texts), use all as stretch
        if currentTexts.isEmpty {
            currentTexts = stretchTexts
            stretchTexts = []
        }

        // Deterministic shuffle
        var rng = SeededRandomNumberGenerator(seed: seed)
        currentTexts.shuffle(using: &rng)
        stretchTexts.shuffle(using: &rng)

        // Interleave at 60/40 ratio
        return interleave(
            primary: currentTexts,
            secondary: stretchTexts,
            primaryRatio: currentDifficultyWeight
        )
    }

    /// The maximum difficulty rating considered "current" for this learner.
    static func currentDifficultyMax(for profile: LearnerProfile) -> Int {
        switch profile.currentLevel {
        case 1: return 2   // well-structured territory
        case 2: return 3   // buried-lead territory
        default: return 4  // rambling territory
        }
    }

    // MARK: - Interleaving

    /// Interleaves two arrays at the given ratio.
    ///
    /// For ratio 0.6 with 10 items: 6 primary, 4 secondary, interleaved so that
    /// at any prefix the ratio is approximately maintained.
    static func interleave<T>(
        primary: [T],
        secondary: [T],
        primaryRatio: Double
    ) -> [T] {
        guard !secondary.isEmpty else { return primary }
        guard !primary.isEmpty else { return secondary }

        var result: [T] = []
        var pIdx = 0
        var sIdx = 0

        while pIdx < primary.count || sIdx < secondary.count {
            // How many primary items should we have placed by now?
            let placed = pIdx + sIdx + 1
            let targetPrimary = Int((Double(placed) * primaryRatio).rounded())

            if pIdx < primary.count && (pIdx < targetPrimary || sIdx >= secondary.count) {
                result.append(primary[pIdx])
                pIdx += 1
            } else if sIdx < secondary.count {
                result.append(secondary[sIdx])
                sIdx += 1
            } else {
                result.append(primary[pIdx])
                pIdx += 1
            }
        }

        return result
    }
}

// MARK: - Seeded RNG

/// A simple deterministic random number generator for testable selection.
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed  // Avoid zero state
    }

    mutating func next() -> UInt64 {
        // xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
