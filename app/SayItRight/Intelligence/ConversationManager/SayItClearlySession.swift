import Foundation

/// Tracks the state of a "Say it clearly" session.
///
/// Captures the selected topic, the learner's response attempts, and timestamps
/// for the session lifecycle. Supports a revision loop where the learner
/// revises their response after Barbara's structural feedback.
struct SayItClearlySession: Sendable {

    /// The topic Barbara selected for this session.
    let topic: Topic

    /// When the session was started (topic presented).
    let startedAt: Date

    /// All response attempts, in order. Index 0 is the first draft.
    private(set) var attempts: [Attempt] = []

    /// Maximum number of revisions allowed (not counting the first draft).
    let maxRevisions: Int

    /// Whether the session summary has been requested.
    private(set) var summaryRequested: Bool = false

    /// The session type identifier for downstream processing.
    let sessionTypeID: String = "say-it-clearly"

    init(topic: Topic, startedAt: Date = .now, maxRevisions: Int = 2) {
        self.topic = topic
        self.startedAt = startedAt
        self.maxRevisions = maxRevisions
    }

    /// A single learner attempt (first draft or revision).
    struct Attempt: Sendable, Equatable {
        let text: String
        let submittedAt: Date
    }

    /// Record a learner response attempt.
    mutating func recordAttempt(_ text: String, at date: Date = .now) {
        attempts.append(Attempt(text: text, submittedAt: date))
    }

    /// The learner's first submitted response text, if any.
    var responseText: String? {
        attempts.first?.text
    }

    /// When the learner submitted their first response.
    var respondedAt: Date? {
        attempts.first?.submittedAt
    }

    /// Whether the learner has submitted at least one response.
    var hasResponse: Bool {
        !attempts.isEmpty
    }

    /// The current revision round (0 = first draft, 1 = first revision, etc.).
    var currentRevisionRound: Int {
        max(0, attempts.count - 1)
    }

    /// Whether more revisions are allowed.
    var canRevise: Bool {
        hasResponse && currentRevisionRound < maxRevisions
    }

    /// Whether the revision loop is complete (max revisions reached).
    var isRevisionComplete: Bool {
        currentRevisionRound >= maxRevisions
    }

    /// The most recent attempt text.
    var latestAttemptText: String? {
        attempts.last?.text
    }

    /// Whether the latest attempt is unchanged from the previous one
    /// (whitespace-normalised comparison).
    var isLatestAttemptUnchanged: Bool {
        guard attempts.count >= 2 else { return false }
        let prev = normalise(attempts[attempts.count - 2].text)
        let curr = normalise(attempts[attempts.count - 1].text)
        return prev == curr
    }

    /// Mark that the session summary has been requested.
    mutating func markSummaryRequested() {
        summaryRequested = true
    }

    // MARK: - Backward Compatibility

    /// Record the learner's response (delegates to recordAttempt).
    mutating func recordResponse(_ text: String, at date: Date = .now) {
        recordAttempt(text, at: date)
    }

    // MARK: - Private

    private func normalise(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
