import Foundation

/// Tracks the state of an "Analyse my text" session.
///
/// The user pastes their own text (essay, email, article draft) and Barbara
/// provides structural feedback. Supports a revision loop — the user can
/// revise their text based on feedback.
struct AnalyseMyTextSession: Sendable {

    /// When the session was started.
    let startedAt: Date

    /// All text submissions, in order. Index 0 is the original text.
    private(set) var submissions: [Submission] = []

    /// Maximum number of revisions allowed.
    let maxRevisions: Int

    /// Whether a content flag was raised for the submitted text.
    private(set) var contentFlagged: Bool = false

    /// The session type identifier.
    let sessionTypeID: String = "analyse-my-text"

    /// Minimum sentence count for analysis.
    static let minimumSentences = 2

    /// Maximum word count for analysis.
    static let maximumWords = 2000

    init(startedAt: Date = .now, maxRevisions: Int = 2) {
        self.startedAt = startedAt
        self.maxRevisions = maxRevisions
    }

    /// A single text submission.
    struct Submission: Sendable, Equatable {
        let text: String
        let submittedAt: Date
        let wordCount: Int
    }

    /// Record a text submission.
    mutating func recordSubmission(_ text: String, at date: Date = .now) {
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
        submissions.append(Submission(text: text, submittedAt: date, wordCount: wordCount))
    }

    /// Mark that content was flagged.
    mutating func markContentFlagged() {
        contentFlagged = true
    }

    /// The original submitted text.
    var originalText: String? {
        submissions.first?.text
    }

    /// The latest submitted text.
    var latestText: String? {
        submissions.last?.text
    }

    /// Whether the user has submitted text.
    var hasSubmission: Bool {
        !submissions.isEmpty
    }

    /// Current revision round (0 = first submission).
    var currentRevisionRound: Int {
        max(0, submissions.count - 1)
    }

    /// Whether more revisions are allowed.
    var canRevise: Bool {
        hasSubmission && currentRevisionRound < maxRevisions
    }

    /// Validate text length before submission.
    static func validate(_ text: String) -> TextValidationResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return .empty
        }

        // Count sentences (rough: split by .!?)
        let sentenceCount = trimmed.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .count
        if sentenceCount < minimumSentences {
            return .tooShort
        }

        // Count words
        let wordCount = trimmed.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
        if wordCount > maximumWords {
            return .tooLong(wordCount: wordCount)
        }

        return .valid
    }

    /// Text validation result.
    enum TextValidationResult: Equatable {
        case valid
        case empty
        case tooShort
        case tooLong(wordCount: Int)
    }
}
