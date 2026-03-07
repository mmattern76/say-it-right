import Foundation

/// Tracks the state of a "Fix this mess" session.
///
/// The learner receives a poorly structured text and rewrites it with proper
/// pyramid structure. Barbara evaluates the restructuring against the answer key.
struct FixThisMessSession: Sendable {
    /// The practice text to restructure.
    let practiceText: PracticeText

    /// When the session started.
    let startedAt: Date

    /// The learner's restructuring attempts.
    private(set) var attempts: [Attempt] = []

    /// Maximum revisions allowed (not counting first attempt).
    let maxRevisions: Int

    let sessionTypeID: String = "fix-this-mess"

    init(practiceText: PracticeText, startedAt: Date = .now, maxRevisions: Int = 1) {
        self.practiceText = practiceText
        self.startedAt = startedAt
        self.maxRevisions = maxRevisions
    }

    struct Attempt: Sendable {
        let text: String
        let submittedAt: Date
    }

    mutating func recordAttempt(_ text: String, at date: Date = .now) {
        attempts.append(Attempt(text: text, submittedAt: date))
    }

    var hasResponse: Bool { !attempts.isEmpty }

    var responseText: String? { attempts.first?.text }

    var latestAttemptText: String? { attempts.last?.text }

    var currentRevisionRound: Int { max(0, attempts.count - 1) }

    var canRevise: Bool { hasResponse && currentRevisionRound < maxRevisions }

    var isRevisionComplete: Bool { currentRevisionRound >= maxRevisions }

    /// The original text the learner must restructure.
    var originalText: String { practiceText.text }

    /// The answer key's proposed restructure, if available.
    var proposedRestructure: String? { practiceText.answerKey.proposedRestructure }

    /// The governing thought from the answer key.
    var expectedGoverningThought: String { practiceText.answerKey.governingThought }

    /// Word count of the original text (guides expected restructuring length).
    var originalWordCount: Int { practiceText.metadata.wordCount }
}
