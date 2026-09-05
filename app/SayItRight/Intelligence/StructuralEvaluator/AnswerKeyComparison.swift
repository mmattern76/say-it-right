import Foundation

// MARK: - Match Quality

/// How closely the user's response matches the answer key structurally.
enum MatchQuality: String, Codable {
    case high
    case partial
    case low
}

// MARK: - Comparison Result

/// Structured result from comparing a user's response against an answer key.
struct AnswerKeyComparisonResult: Codable, Equatable {
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
struct ComparisonMetadata: Codable, Equatable {
    let mood: String
    let progressionSignal: String
    let sessionPhase: String
    let feedbackFocus: String
    let language: String
}
