import Foundation
@testable import SayItRight
import Testing

/// Break mode's structural evaluation, derived from the metadata Barbara already
/// sends rather than from a second scoring call.
struct AnswerKeyComparisonTests {
    // MARK: - Match Quality Derivation

    @Test("Strong scores read as a high-quality match")
    func highMatch() {
        // governingThought 3/3, supportGrouping 2/2, clarity 3/3 → 1.0
        let quality = SessionManager.matchQuality(for: [
            "governingThought": 3,
            "supportGrouping": 2,
            "clarity": 3,
        ])
        #expect(quality == .high)
    }

    @Test("Middling scores read as a partial match")
    func partialMatch() {
        // governingThought 2/3, supportGrouping 1/2, clarity 2/3 → 0.61
        let quality = SessionManager.matchQuality(for: [
            "governingThought": 2,
            "supportGrouping": 1,
            "clarity": 2,
        ])
        #expect(quality == .partial)
    }

    @Test("Weak scores read as a low-quality match")
    func lowMatch() {
        // governingThought 1/3, supportGrouping 0/2, clarity 1/3 → 0.22
        let quality = SessionManager.matchQuality(for: [
            "governingThought": 1,
            "supportGrouping": 0,
            "clarity": 1,
        ])
        #expect(quality == .low)
    }

    @Test("The 0.75 boundary matches the promotion threshold")
    func thresholdBoundary() {
        // 0.75 exactly — the same bar ProgressionCriteria uses for "strong".
        #expect(SessionManager.matchQuality(for: ["clarity": 3, "governingThought": 2]) == .high)
        // Just under it.
        #expect(SessionManager.matchQuality(for: ["clarity": 2, "governingThought": 2]) == .partial)
    }

    @Test("Unknown dimensions are ignored, empty scores read low")
    func unknownDimensions() {
        #expect(SessionManager.matchQuality(for: [:]) == .low)
        #expect(SessionManager.matchQuality(for: ["notADimension": 99]) == .low)
        // A known dimension still decides it when mixed with an unknown one.
        #expect(SessionManager.matchQuality(for: ["clarity": 3, "notADimension": 0]) == .high)
    }

    // MARK: - Result Model

    @Test("MatchQuality raw values are stable")
    func matchQualityRawValues() {
        #expect(MatchQuality.high.rawValue == "high")
        #expect(MatchQuality.partial.rawValue == "partial")
        #expect(MatchQuality.low.rawValue == "low")
    }

    @Test("AnswerKeyComparisonResult round-trips through JSON")
    func resultCodable() throws {
        let result = AnswerKeyComparisonResult(
            matchQuality: .high,
            feedback: "That is the governing thought.",
            dimensionScores: ["governingThought": 3, "clarity": 3],
            metadata: ComparisonMetadata(
                mood: "approving",
                progressionSignal: "improving",
                sessionPhase: "evaluation",
                feedbackFocus: "Lead with the claim.",
                language: "en"
            )
        )

        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(AnswerKeyComparisonResult.self, from: data)

        #expect(decoded == result)
    }
}
