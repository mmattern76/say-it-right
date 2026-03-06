import Foundation

/// Tracks the state of a "Find the point" session.
///
/// Captures the selected practice text, the learner's extraction attempts,
/// and evaluation results. This is the Break mode counterpart to
/// `SayItClearlySession` — the learner reads a text and extracts
/// the governing thought rather than formulating an original response.
struct FindThePointSession: Sendable {

    /// The practice text Barbara selected for this session.
    let practiceText: PracticeText

    /// When the session was started (text presented).
    let startedAt: Date

    /// The learner's extraction attempts (max 2: initial + one retry).
    private(set) var attempts: [ExtractionAttempt] = []

    /// The evaluation result from the answer key comparer, if available.
    private(set) var evaluationResult: AnswerKeyComparisonResult?

    /// The session type identifier for downstream processing.
    let sessionTypeID: String = "find-the-point"

    init(practiceText: PracticeText, startedAt: Date = .now) {
        self.practiceText = practiceText
        self.startedAt = startedAt
    }

    /// Record a new extraction attempt from the learner.
    mutating func recordAttempt(_ text: String, at date: Date = .now) {
        attempts.append(ExtractionAttempt(text: text, attemptedAt: date))
    }

    /// Record the evaluation result from the answer key comparer.
    mutating func recordEvaluation(_ result: AnswerKeyComparisonResult) {
        evaluationResult = result
    }

    /// The number of extraction attempts so far.
    var attemptCount: Int { attempts.count }

    /// Whether the learner has submitted at least one extraction.
    var hasAttempt: Bool { !attempts.isEmpty }

    /// Whether the learner has used their retry (max 2 attempts).
    var hasUsedRetry: Bool { attempts.count >= 2 }

    /// The most recent extraction text, if any.
    var latestExtractionText: String? { attempts.last?.text }

    /// Whether the governing thought was correctly identified.
    var wasCorrect: Bool {
        evaluationResult?.matchQuality == .high
    }
}

/// A single extraction attempt by the learner.
struct ExtractionAttempt: Sendable {
    let text: String
    let attemptedAt: Date
}
