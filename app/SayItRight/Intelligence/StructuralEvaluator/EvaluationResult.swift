import Foundation

/// The result of a structural evaluation of the learner's response.
///
/// Contains Barbara's visible feedback text and the parsed scoring data
/// extracted from the hidden `BARBARA_META` block. The scoring data maps
/// to the L1/L2 rubric dimensions defined in the prompt blocks.
struct EvaluationResult: Sendable {

    /// Barbara's visible feedback text (metadata stripped).
    let feedbackText: String

    /// Parsed hidden metadata with scores and progression signals.
    let metadata: BarbaraMetadata?

    /// Dimension-level scores extracted from metadata for convenience.
    var dimensionScores: [String: Int] {
        metadata?.scores ?? [:]
    }

    /// The total score across all rubric dimensions.
    var totalScore: Int {
        metadata?.totalScore ?? 0
    }

    /// Whether the evaluation contains valid scoring data.
    var hasScores: Bool {
        metadata != nil && !(metadata!.scores.isEmpty)
    }

    /// The progression signal from this evaluation.
    var progressionSignal: ProgressionSignal {
        metadata?.progressionSignal ?? .none
    }

    /// Barbara's mood based on the evaluation.
    var mood: BarbaraMood {
        metadata?.mood ?? .evaluating
    }

    /// Which structural element Barbara is focusing feedback on.
    var feedbackFocus: String {
        metadata?.feedbackFocus ?? ""
    }
}
