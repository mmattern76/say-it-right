import Foundation

// MARK: - Comparison Session Types

/// Break-mode session types that require answer key comparison.
enum ComparisonSessionType: String, Sendable {
    case findThePoint = "find_the_point"
    case fixThisMess = "fix_this_mess"
    case spotTheGap = "spot_the_gap"
}

// MARK: - Match Quality

/// How closely the user's response matches the answer key structurally.
enum MatchQuality: String, Codable, Sendable {
    case high
    case partial
    case low
}

// MARK: - Comparison Result

/// Structured result from comparing a user's response against an answer key.
struct AnswerKeyComparisonResult: Codable, Sendable, Equatable {
    /// Overall structural match quality.
    let matchQuality: MatchQuality
    /// Barbara's visible feedback text for the user.
    let feedback: String
    /// Per-dimension scores specific to the session type.
    let dimensionScores: [String: Int]
    /// Hidden metadata for learner profile and session tracking.
    let metadata: ComparisonMetadata
}

/// Hidden metadata attached to every comparison result.
struct ComparisonMetadata: Codable, Sendable, Equatable {
    let mood: String
    let progressionSignal: String
    let sessionPhase: String
    let feedbackFocus: String
    let language: String
}

// MARK: - Comparison Input

/// All inputs needed for an answer key comparison request.
struct ComparisonInput: Sendable {
    let userResponse: String
    let practiceText: PracticeText
    let sessionType: ComparisonSessionType
    let language: String
    let learnerLevel: Int
}
