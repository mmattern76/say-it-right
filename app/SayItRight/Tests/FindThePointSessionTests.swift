import Foundation
import Testing
@testable import SayItRight

// MARK: - FindThePointSession Tests

@Suite("FindThePointSession")
struct FindThePointSessionTests {

    private static func makeText(id: String = "test-text") -> PracticeText {
        PracticeText(
            id: id,
            text: "School uniforms reduce social pressure by eliminating visible economic differences.",
            answerKey: AnswerKey(
                governingThought: "School uniforms reduce social pressure.",
                supports: [
                    SupportGroup(label: "Economic equaliser", evidence: ["Eliminates visible differences"]),
                ],
                structuralAssessment: "Well-structured with clear governing thought."
            ),
            metadata: PracticeTextMetadata(
                qualityLevel: .wellStructured,
                difficultyRating: 1,
                topicDomain: "school",
                language: "en",
                wordCount: 12,
                targetLevel: 1
            )
        )
    }

    @Test("Session initialises with practice text and timestamp")
    func initialisation() {
        let text = Self.makeText()
        let session = FindThePointSession(practiceText: text)

        #expect(session.practiceText.id == "test-text")
        #expect(session.sessionTypeID == "find-the-point")
        #expect(!session.hasAttempt)
        #expect(session.attemptCount == 0)
        #expect(session.latestExtractionText == nil)
        #expect(session.evaluationResult == nil)
        #expect(!session.hasUsedRetry)
        #expect(!session.wasCorrect)
    }

    @Test("recordAttempt captures text and timestamp")
    func recordAttempt() {
        let text = Self.makeText()
        var session = FindThePointSession(practiceText: text)
        let before = Date.now

        session.recordAttempt("The text argues that uniforms reduce pressure.")

        #expect(session.hasAttempt)
        #expect(session.attemptCount == 1)
        #expect(session.latestExtractionText == "The text argues that uniforms reduce pressure.")
        #expect(!session.hasUsedRetry)
        #expect(session.attempts[0].attemptedAt >= before)
    }

    @Test("Second attempt marks retry as used")
    func secondAttemptMarksRetry() {
        let text = Self.makeText()
        var session = FindThePointSession(practiceText: text)

        session.recordAttempt("First try")
        session.recordAttempt("Second try")

        #expect(session.attemptCount == 2)
        #expect(session.hasUsedRetry)
        #expect(session.latestExtractionText == "Second try")
    }

    @Test("recordEvaluation stores the comparison result")
    func recordEvaluation() {
        let text = Self.makeText()
        var session = FindThePointSession(practiceText: text)

        let result = AnswerKeyComparisonResult(
            matchQuality: .high,
            feedback: "That's it.",
            dimensionScores: ["governingThoughtAccuracy": 3, "specificity": 2, "supportAwareness": 1],
            metadata: ComparisonMetadata(
                mood: "approving",
                progressionSignal: "improving",
                sessionPhase: "evaluation",
                feedbackFocus: "governing_thought",
                language: "en"
            )
        )

        session.recordEvaluation(result)

        #expect(session.evaluationResult != nil)
        #expect(session.wasCorrect)
        #expect(session.evaluationResult?.matchQuality == .high)
    }

    @Test("wasCorrect is false for partial match")
    func wasCorrectFalseForPartial() {
        let text = Self.makeText()
        var session = FindThePointSession(practiceText: text)

        let result = AnswerKeyComparisonResult(
            matchQuality: .partial,
            feedback: "Close.",
            dimensionScores: ["governingThoughtAccuracy": 2, "specificity": 1, "supportAwareness": 1],
            metadata: ComparisonMetadata(
                mood: "evaluating",
                progressionSignal: "none",
                sessionPhase: "evaluation",
                feedbackFocus: "specificity",
                language: "en"
            )
        )

        session.recordEvaluation(result)
        #expect(!session.wasCorrect)
    }

    @Test("wasCorrect is false for low match")
    func wasCorrectFalseForLow() {
        let text = Self.makeText()
        var session = FindThePointSession(practiceText: text)

        let result = AnswerKeyComparisonResult(
            matchQuality: .low,
            feedback: "That's not it.",
            dimensionScores: ["governingThoughtAccuracy": 0, "specificity": 0, "supportAwareness": 0],
            metadata: ComparisonMetadata(
                mood: "disappointed",
                progressionSignal: "struggling",
                sessionPhase: "evaluation",
                feedbackFocus: "governing_thought",
                language: "en"
            )
        )

        session.recordEvaluation(result)
        #expect(!session.wasCorrect)
    }
}

// MARK: - FindThePointCoordinator Tests

@Suite("FindThePointCoordinator")
struct FindThePointCoordinatorTests {

    private static func makeTexts() -> [PracticeText] {
        [
            PracticeText(
                id: "pt-001",
                text: "Text about uniforms.",
                answerKey: AnswerKey(
                    governingThought: "Uniforms reduce pressure.",
                    supports: [],
                    structuralAssessment: "Well-structured."
                ),
                metadata: PracticeTextMetadata(
                    qualityLevel: .wellStructured,
                    difficultyRating: 1,
                    topicDomain: "school",
                    language: "en",
                    wordCount: 4,
                    targetLevel: 1
                )
            ),
            PracticeText(
                id: "pt-002",
                text: "Text about technology.",
                answerKey: AnswerKey(
                    governingThought: "AI transforms education.",
                    supports: [],
                    structuralAssessment: "Buried lead."
                ),
                metadata: PracticeTextMetadata(
                    qualityLevel: .buriedLead,
                    difficultyRating: 2,
                    topicDomain: "technology",
                    language: "en",
                    wordCount: 4,
                    targetLevel: 2
                )
            ),
        ]
    }

    @Test("Coordinator initialises with text list")
    @MainActor
    func initialisation() {
        let coordinator = FindThePointCoordinator(texts: Self.makeTexts())
        // Should not crash; coordinator is ready
        #expect(FindThePointCoordinator.sessionTypeKey == "find_the_point")
    }

    @Test("Coordinator initialises with empty text list")
    @MainActor
    func emptyInitialisation() {
        let coordinator = FindThePointCoordinator(texts: [])
        #expect(FindThePointCoordinator.sessionTypeKey == "find_the_point")
        _ = coordinator // suppress unused warning
    }
}

// MARK: - SessionManager Find the Point Integration

@Suite("SessionManager -- Find the point")
struct SessionManagerFindThePointTests {

    private static func makeText() -> PracticeText {
        PracticeText(
            id: "test-pt",
            text: "Test practice text content.",
            answerKey: AnswerKey(
                governingThought: "Test governing thought.",
                supports: [],
                structuralAssessment: "Test assessment."
            ),
            metadata: PracticeTextMetadata(
                qualityLevel: .wellStructured,
                difficultyRating: 1,
                topicDomain: "test",
                language: "en",
                wordCount: 5,
                targetLevel: 1
            )
        )
    }

    @Test("Initial state has no findThePointSession")
    @MainActor
    func initialState() {
        let manager = SessionManager()
        #expect(manager.findThePointSession == nil)
    }

    @Test("endSession clears findThePointSession")
    @MainActor
    func endSessionClears() {
        let manager = SessionManager()
        manager.endSession()
        #expect(manager.findThePointSession == nil)
        #expect(manager.activeSessionType == nil)
    }

    @Test("sendMessage does nothing when session is idle")
    @MainActor
    func sendMessageWhenIdle() async {
        let manager = SessionManager()
        await manager.sendMessage(text: "The governing thought is...")
        #expect(manager.messages.isEmpty)
    }
}
