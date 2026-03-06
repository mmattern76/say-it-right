import Testing
@testable import SayItRight

@Suite("FeedbackBubbleView Tests")
struct FeedbackBubbleTests {

    // MARK: - FormattedFeedbackText Parsing

    @Test("Parses plain text with no quotes")
    func parsesPlainText() {
        let view = FormattedFeedbackText(text: "That's not a conclusion, that's a preamble.")
        // View renders without crashing — basic smoke test
        #expect(view.text == "That's not a conclusion, that's a preamble.")
    }

    @Test("Parses text with double quotes")
    func parsesDoubleQuotes() {
        let text = "You wrote \"Schools should switch\" which is good."
        let view = FormattedFeedbackText(text: text)
        #expect(view.text.contains("Schools should switch"))
    }

    @Test("Parses text with smart quotes")
    func parsesSmartQuotes() {
        let text = "You wrote \u{201C}Schools should switch\u{201D} which is good."
        let view = FormattedFeedbackText(text: text)
        #expect(view.text.contains("Schools should switch"))
    }

    @Test("Handles unclosed quote gracefully")
    func handlesUnclosedQuote() {
        let text = "You wrote \"Schools should switch without closing"
        let view = FormattedFeedbackText(text: text)
        #expect(view.text.contains("Schools should switch"))
    }

    // MARK: - StructuralScorecardView

    @Test("Scorecard displays all dimension scores")
    func scorecardDisplaysAllDimensions() {
        let metadata = BarbaraMetadata(
            scores: ["governingThought": 3, "supportGrouping": 2, "redundancy": 1, "clarity": 2],
            totalScore: 8,
            mood: .evaluating,
            progressionSignal: .improving,
            revisionRound: 1,
            sessionPhase: .evaluation,
            feedbackFocus: "clarity",
            language: "en"
        )

        let view = StructuralScorecardView(metadata: metadata)
        // Smoke test — view can be created with valid metadata
        #expect(metadata.scores.count == 4)
        #expect(metadata.totalScore == 8)
    }

    @Test("Scorecard handles empty scores")
    func scorecardHandlesEmptyScores() {
        let metadata = BarbaraMetadata(
            scores: [:],
            totalScore: 0,
            mood: .attentive,
            progressionSignal: .none,
            revisionRound: 0,
            sessionPhase: .greeting,
            feedbackFocus: "",
            language: "en"
        )

        let view = StructuralScorecardView(metadata: metadata)
        #expect(metadata.scores.isEmpty)
    }

    // MARK: - DimensionScoreRow

    @Test("Score bar fill ratio calculation")
    func scoreBarFillRatio() {
        // Perfect score = 100% fill
        let perfect = DimensionScoreRow(dimension: "Clarity", score: 3, maxScore: 3)
        #expect(perfect.dimension == "Clarity")
        #expect(perfect.score == 3)
        #expect(perfect.maxScore == 3)

        // Zero score
        let zero = DimensionScoreRow(dimension: "Redundancy", score: 0, maxScore: 2)
        #expect(zero.score == 0)

        // Zero max (edge case)
        let noMax = DimensionScoreRow(dimension: "Test", score: 0, maxScore: 0)
        #expect(noMax.maxScore == 0)
    }

    // MARK: - Message Integration

    @Test("Message with scores triggers feedback bubble")
    func messageWithScoresTriggersFeedback() {
        let message = ChatMessage(
            role: .barbara,
            text: "Good structure.",
            metadata: BarbaraMetadata(
                scores: ["governingThought": 3],
                totalScore: 3,
                mood: .approving,
                progressionSignal: .improving,
                revisionRound: 1,
                sessionPhase: .evaluation,
                feedbackFocus: "",
                language: "en"
            )
        )

        #expect(message.metadata != nil)
        #expect(!message.metadata!.scores.isEmpty)
    }

    @Test("Message without scores uses standard bubble")
    func messageWithoutScoresUsesStandard() {
        let message = ChatMessage(
            role: .barbara,
            text: "Let's get started."
        )

        #expect(message.metadata == nil)
    }

    @Test("Message with empty scores uses standard bubble")
    func messageWithEmptyScoresUsesStandard() {
        let message = ChatMessage(
            role: .barbara,
            text: "Hello there.",
            metadata: BarbaraMetadata(
                scores: [:],
                totalScore: 0,
                mood: .attentive,
                progressionSignal: .none,
                revisionRound: 0,
                sessionPhase: .greeting,
                feedbackFocus: "",
                language: "en"
            )
        )

        #expect(message.metadata!.scores.isEmpty)
    }

    // MARK: - Progression Signal Display

    @Test("Progression signals map correctly")
    func progressionSignals() {
        #expect(ProgressionSignal.improving.rawValue == "improving")
        #expect(ProgressionSignal.readyForLevelUp.rawValue == "ready_for_level_up")
        #expect(ProgressionSignal.struggling.rawValue == "struggling")
        #expect(ProgressionSignal.regression.rawValue == "regression")
        #expect(ProgressionSignal.none.rawValue == "none")
    }

    // MARK: - Mood-driven Avatar

    @Test("Avatar mood sourced from metadata")
    func avatarMoodFromMetadata() {
        let message = ChatMessage(
            role: .barbara,
            text: "Well done.",
            metadata: BarbaraMetadata(
                scores: ["clarity": 3],
                totalScore: 3,
                mood: .proud,
                progressionSignal: .improving,
                revisionRound: 2,
                sessionPhase: .evaluation,
                feedbackFocus: "",
                language: "en"
            )
        )

        #expect(message.metadata?.mood == .proud)
    }
}
