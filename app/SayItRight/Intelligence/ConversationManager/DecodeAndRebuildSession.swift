import Foundation

/// Tracks the state of a "Decode and rebuild" session.
///
/// This is a two-phase capstone exercise:
/// - Phase 1 (Break): Extract the pyramid structure from a text
/// - Phase 2 (Build): Rewrite the argument with better structure
struct DecodeAndRebuildSession: Sendable {
    /// The practice text to analyse and rebuild.
    let practiceText: PracticeText

    let startedAt: Date

    let sessionTypeID: String = "decode-and-rebuild"

    /// Current phase of the session.
    private(set) var phase: Phase = .extraction

    /// Phase 1: extraction attempts (governing thought + supports).
    private(set) var extractionAttempts: [Attempt] = []

    /// Phase 2: rebuild attempts.
    private(set) var rebuildAttempts: [Attempt] = []

    /// Maximum rebuild revisions allowed.
    let maxRevisions: Int

    init(practiceText: PracticeText, startedAt: Date = .now, maxRevisions: Int = 1) {
        self.practiceText = practiceText
        self.startedAt = startedAt
        self.maxRevisions = maxRevisions
    }

    /// Session phases.
    enum Phase: String, Sendable {
        /// Phase 1: user extracts the structure.
        case extraction
        /// Transition: Barbara gives Phase 1 feedback and prompts Phase 2.
        case transition
        /// Phase 2: user rebuilds the argument.
        case rebuild
        /// Session complete.
        case summary
    }

    struct Attempt: Sendable {
        let text: String
        let submittedAt: Date
    }

    // MARK: - Phase 1 (Extraction)

    mutating func recordExtractionAttempt(_ text: String, at date: Date = .now) {
        extractionAttempts.append(Attempt(text: text, submittedAt: date))
    }

    var hasExtraction: Bool { !extractionAttempts.isEmpty }

    var extractionText: String? { extractionAttempts.last?.text }

    // MARK: - Phase Transition

    mutating func advanceToTransition() {
        phase = .transition
    }

    mutating func advanceToRebuild() {
        phase = .rebuild
    }

    mutating func advanceToSummary() {
        phase = .summary
    }

    // MARK: - Phase 2 (Rebuild)

    mutating func recordRebuildAttempt(_ text: String, at date: Date = .now) {
        rebuildAttempts.append(Attempt(text: text, submittedAt: date))
    }

    var hasRebuild: Bool { !rebuildAttempts.isEmpty }

    var rebuildText: String? { rebuildAttempts.last?.text }

    var currentRebuildRevision: Int { max(0, rebuildAttempts.count - 1) }

    var canReviseRebuild: Bool { hasRebuild && currentRebuildRevision < maxRevisions }

    // MARK: - Convenience

    /// The original text to analyse.
    var originalText: String { practiceText.text }

    /// The governing thought from the answer key.
    var expectedGoverningThought: String { practiceText.answerKey.governingThought }

    /// The support groups from the answer key.
    var expectedSupports: [SupportGroup] { practiceText.answerKey.supports }

    /// Word count of the original text.
    var originalWordCount: Int { practiceText.metadata.wordCount }

    /// Whether the session is in its Break phase.
    var isBreakPhase: Bool { phase == .extraction || phase == .transition }

    /// Whether the session is in its Build phase.
    var isBuildPhase: Bool { phase == .rebuild || phase == .summary }

    /// Total attempt count across both phases.
    var totalAttemptCount: Int { extractionAttempts.count + rebuildAttempts.count }
}
