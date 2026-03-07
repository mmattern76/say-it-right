import Foundation

/// Tracks the state of a "Spot the gap" session.
///
/// The learner receives a seemingly solid argument with a hidden structural
/// flaw and must identify it. Maximum 3 attempts before the answer is revealed.
struct SpotTheGapSession: Sendable {
    /// The practice text with the hidden structural flaw.
    let practiceText: PracticeText

    let startedAt: Date

    /// The learner's identification attempts.
    private(set) var attempts: [Attempt] = []

    /// Maximum attempts before the answer is revealed.
    let maxAttempts: Int

    let sessionTypeID: String = "spot-the-gap"

    init(practiceText: PracticeText, startedAt: Date = .now, maxAttempts: Int = 3) {
        self.practiceText = practiceText
        self.startedAt = startedAt
        self.maxAttempts = maxAttempts
    }

    struct Attempt: Sendable {
        let text: String
        let submittedAt: Date
    }

    mutating func recordAttempt(_ text: String, at date: Date = .now) {
        attempts.append(Attempt(text: text, submittedAt: date))
    }

    var hasResponse: Bool { !attempts.isEmpty }

    var attemptCount: Int { attempts.count }

    var canAttempt: Bool { attemptCount < maxAttempts }

    var isExhausted: Bool { attemptCount >= maxAttempts }

    /// The structural flaw the learner must find.
    var structuralFlaw: StructuralFlaw? { practiceText.answerKey.structuralFlaw }

    /// The original text to analyse.
    var originalText: String { practiceText.text }

    /// Whether this text has a known structural flaw.
    var hasKnownFlaw: Bool { structuralFlaw != nil }
}
