import XCTest
@testable import SayItRight

final class AnswerKeyComparisonTests: XCTestCase {

    // MARK: - Test Fixtures

    private let samplePracticeText = PracticeText(
        id: "pt-test-001",
        text: "Remote work has transformed the modern workplace. Studies show productivity increases of 13% among remote workers. Companies save an average of $11,000 per remote employee annually. However, collaboration suffers without in-person interaction, and junior employees miss mentoring opportunities.",
        answerKey: AnswerKey(
            governingThought: "Remote work offers significant productivity and cost benefits but creates challenges for collaboration and professional development.",
            supports: [
                SupportGroup(
                    label: "Productivity gains",
                    evidence: ["13% productivity increase in studies"]
                ),
                SupportGroup(
                    label: "Cost savings",
                    evidence: ["$11,000 saved per remote employee annually"]
                ),
                SupportGroup(
                    label: "Collaboration challenges",
                    evidence: [
                        "Collaboration suffers without in-person interaction",
                        "Junior employees miss mentoring opportunities"
                    ]
                )
            ],
            structuralAssessment: "Well-structured argument with clear governing thought and three support pillars balancing benefits against drawbacks."
        ),
        metadata: PracticeTextMetadata(
            qualityLevel: .wellStructured,
            difficultyRating: 2,
            topicDomain: "workplace",
            language: "en",
            wordCount: 48,
            targetLevel: 1
        )
    )

    private let adversarialPracticeText = PracticeText(
        id: "pt-test-002",
        text: "Electric cars are better because they are electric. They use electricity instead of gas, which makes them superior. Since they run on batteries, they are the future of transportation.",
        answerKey: AnswerKey(
            governingThought: "Electric cars are better than gas cars.",
            supports: [
                SupportGroup(
                    label: "Electric power",
                    evidence: ["They use electricity instead of gas"]
                ),
                SupportGroup(
                    label: "Battery technology",
                    evidence: ["They run on batteries"]
                )
            ],
            structuralAssessment: "Circular reasoning — the conclusion restates the premise without independent evidence.",
            structuralFlaw: StructuralFlaw(
                type: "circular_reasoning",
                description: "The argument that electric cars are better because they are electric is circular — it restates the premise as the conclusion.",
                location: "paragraph 1, sentence 1"
            )
        ),
        metadata: PracticeTextMetadata(
            qualityLevel: .adversarial,
            difficultyRating: 3,
            topicDomain: "technology",
            language: "en",
            wordCount: 35,
            targetLevel: 2
        )
    )

    // MARK: - ComparisonResponseParser Tests

    private let parser = ComparisonResponseParser()

    func testParseHighMatchFindThePoint() {
        let response = """
        Excellent! You've identified the governing thought precisely. The text argues that remote work has trade-offs, and you captured both the benefits and the challenges.

        <!-- COMPARISON_META: {"matchQuality":"high","dimensionScores":{"governingThoughtAccuracy":3,"specificity":3,"supportAwareness":2},"mood":"approving","progressionSignal":"improving","sessionPhase":"evaluation","feedbackFocus":"Strong extraction — now work on identifying all support pillars.","language":"en"} -->
        """

        let result = parser.parse(fullResponse: response)

        XCTAssertNotNil(result)
        XCTAssertEqual(result!.matchQuality, .high)
        XCTAssertEqual(result!.dimensionScores["governingThoughtAccuracy"], 3)
        XCTAssertEqual(result!.dimensionScores["specificity"], 3)
        XCTAssertEqual(result!.dimensionScores["supportAwareness"], 2)
        XCTAssertEqual(result!.metadata.mood, "approving")
        XCTAssertEqual(result!.metadata.progressionSignal, "improving")
        XCTAssertFalse(result!.feedback.contains("COMPARISON_META"))
        XCTAssertTrue(result!.feedback.contains("Excellent"))
    }

    func testParsePartialMatchFixThisMess() {
        let response = """
        You've found a governing thought, but your grouping needs work. The three support pillars aren't clearly separated — productivity and cost savings are lumped together.

        <!-- COMPARISON_META: {"matchQuality":"partial","dimensionScores":{"pyramidValidity":2,"groupingQuality":1,"orderingLogic":2,"completeness":3},"mood":"teaching","progressionSignal":"none","sessionPhase":"evaluation","feedbackFocus":"Focus on MECE grouping.","language":"en"} -->
        """

        let result = parser.parse(fullResponse: response)

        XCTAssertNotNil(result)
        XCTAssertEqual(result!.matchQuality, .partial)
        XCTAssertEqual(result!.dimensionScores["pyramidValidity"], 2)
        XCTAssertEqual(result!.dimensionScores["groupingQuality"], 1)
        XCTAssertEqual(result!.dimensionScores["orderingLogic"], 2)
        XCTAssertEqual(result!.dimensionScores["completeness"], 3)
        XCTAssertEqual(result!.metadata.mood, "teaching")
    }

    func testParseLowMatchSpotTheGap() {
        let response = """
        That's not the structural flaw. You identified a content disagreement, not a reasoning error. Look again: the argument's conclusion restates its own premise.

        <!-- COMPARISON_META: {"matchQuality":"low","dimensionScores":{"flawIdentification":0,"locationAccuracy":1,"explanationClarity":1},"mood":"disappointed","progressionSignal":"struggling","sessionPhase":"evaluation","feedbackFocus":"Distinguish content critique from structural critique.","language":"en"} -->
        """

        let result = parser.parse(fullResponse: response)

        XCTAssertNotNil(result)
        XCTAssertEqual(result!.matchQuality, .low)
        XCTAssertEqual(result!.dimensionScores["flawIdentification"], 0)
        XCTAssertEqual(result!.metadata.mood, "disappointed")
        XCTAssertEqual(result!.metadata.progressionSignal, "struggling")
    }

    func testParseGermanResponse() {
        let response = """
        Gut erkannt! Der Kerngedanke ist klar formuliert. Arbeite jetzt daran, die Stützpfeiler sauber zu benennen.

        <!-- COMPARISON_META: {"matchQuality":"high","dimensionScores":{"governingThoughtAccuracy":3,"specificity":2,"supportAwareness":2},"mood":"approving","progressionSignal":"improving","sessionPhase":"evaluation","feedbackFocus":"Stützpfeiler benennen.","language":"de"} -->
        """

        let result = parser.parse(fullResponse: response)

        XCTAssertNotNil(result)
        XCTAssertEqual(result!.matchQuality, .high)
        XCTAssertEqual(result!.metadata.language, "de")
        XCTAssertTrue(result!.feedback.contains("Gut erkannt"))
    }

    func testParseMissingMetadataReturnsNil() {
        let response = "Just some plain text without metadata."
        let result = parser.parse(fullResponse: response)
        XCTAssertNil(result)
    }

    func testParseMalformedJSONReturnsNil() {
        let response = """
        Good work.

        <!-- COMPARISON_META: {not valid json at all} -->
        """
        let result = parser.parse(fullResponse: response)
        XCTAssertNil(result)
    }

    func testParseInvalidMatchQualityReturnsNil() {
        let response = """
        Good work.

        <!-- COMPARISON_META: {"matchQuality":"excellent","dimensionScores":{"a":1},"mood":"approving","progressionSignal":"none","sessionPhase":"evaluation","feedbackFocus":"x","language":"en"} -->
        """
        let result = parser.parse(fullResponse: response)
        XCTAssertNil(result)
    }

    func testParseMultipleMetaBlocksUsesLast() {
        let response = """
        First attempt feedback.

        <!-- COMPARISON_META: {"matchQuality":"low","dimensionScores":{"governingThoughtAccuracy":1},"mood":"skeptical","progressionSignal":"none","sessionPhase":"evaluation","feedbackFocus":"x","language":"en"} -->

        Revised feedback after reconsideration.

        <!-- COMPARISON_META: {"matchQuality":"partial","dimensionScores":{"governingThoughtAccuracy":2},"mood":"teaching","progressionSignal":"improving","sessionPhase":"evaluation","feedbackFocus":"y","language":"en"} -->
        """

        let result = parser.parse(fullResponse: response)

        XCTAssertNotNil(result)
        XCTAssertEqual(result!.matchQuality, .partial)
        XCTAssertEqual(result!.dimensionScores["governingThoughtAccuracy"], 2)
        XCTAssertEqual(result!.metadata.mood, "teaching")
        XCTAssertFalse(result!.feedback.contains("COMPARISON_META"))
    }

    // MARK: - ComparisonPromptBuilder Tests

    private let promptBuilder = ComparisonPromptBuilder()

    func testFindThePointPromptContainsDimensions() {
        let input = ComparisonInput(
            userResponse: "The text argues remote work has trade-offs.",
            practiceText: samplePracticeText,
            sessionType: .findThePoint,
            language: "en",
            learnerLevel: 1
        )

        let systemPrompt = promptBuilder.systemPrompt(for: input)

        XCTAssertTrue(systemPrompt.contains("governingThoughtAccuracy"))
        XCTAssertTrue(systemPrompt.contains("specificity"))
        XCTAssertTrue(systemPrompt.contains("supportAwareness"))
        XCTAssertTrue(systemPrompt.contains("Find the Point"))
        XCTAssertFalse(systemPrompt.contains("pyramidValidity"))
    }

    func testFixThisMessPromptContainsDimensions() {
        let input = ComparisonInput(
            userResponse: "Restructured version here.",
            practiceText: samplePracticeText,
            sessionType: .fixThisMess,
            language: "en",
            learnerLevel: 1
        )

        let systemPrompt = promptBuilder.systemPrompt(for: input)

        XCTAssertTrue(systemPrompt.contains("pyramidValidity"))
        XCTAssertTrue(systemPrompt.contains("groupingQuality"))
        XCTAssertTrue(systemPrompt.contains("orderingLogic"))
        XCTAssertTrue(systemPrompt.contains("completeness"))
        XCTAssertTrue(systemPrompt.contains("Fix This Mess"))
    }

    func testSpotTheGapPromptContainsDimensions() {
        let input = ComparisonInput(
            userResponse: "The argument is circular.",
            practiceText: adversarialPracticeText,
            sessionType: .spotTheGap,
            language: "en",
            learnerLevel: 2
        )

        let systemPrompt = promptBuilder.systemPrompt(for: input)

        XCTAssertTrue(systemPrompt.contains("flawIdentification"))
        XCTAssertTrue(systemPrompt.contains("locationAccuracy"))
        XCTAssertTrue(systemPrompt.contains("explanationClarity"))
        XCTAssertTrue(systemPrompt.contains("Spot the Gap"))
    }

    func testGermanPromptUsesGerman() {
        let input = ComparisonInput(
            userResponse: "Der Kerngedanke ist...",
            practiceText: samplePracticeText,
            sessionType: .findThePoint,
            language: "de",
            learnerLevel: 1
        )

        let systemPrompt = promptBuilder.systemPrompt(for: input)

        XCTAssertTrue(systemPrompt.contains("Bewertungskriterien"))
        XCTAssertTrue(systemPrompt.contains("Finde den Punkt"))
        XCTAssertTrue(systemPrompt.contains("Ausgabeformat"))
    }

    func testUserMessageContainsPracticeTextAndAnswerKey() {
        let input = ComparisonInput(
            userResponse: "My analysis of the text.",
            practiceText: samplePracticeText,
            sessionType: .findThePoint,
            language: "en",
            learnerLevel: 1
        )

        let userMessage = promptBuilder.userMessage(for: input)

        XCTAssertTrue(userMessage.contains("## Practice Text"))
        XCTAssertTrue(userMessage.contains("Remote work has transformed"))
        XCTAssertTrue(userMessage.contains("## Answer Key"))
        XCTAssertTrue(userMessage.contains("Governing Thought"))
        XCTAssertTrue(userMessage.contains("## User's Response"))
        XCTAssertTrue(userMessage.contains("My analysis of the text."))
    }

    func testUserMessageIncludesStructuralFlaw() {
        let input = ComparisonInput(
            userResponse: "The argument is circular.",
            practiceText: adversarialPracticeText,
            sessionType: .spotTheGap,
            language: "en",
            learnerLevel: 2
        )

        let userMessage = promptBuilder.userMessage(for: input)

        XCTAssertTrue(userMessage.contains("Structural Flaw"))
        XCTAssertTrue(userMessage.contains("circular_reasoning"))
    }

    // MARK: - ComparisonInput and Result model tests

    func testMatchQualityRawValues() {
        XCTAssertEqual(MatchQuality(rawValue: "high"), .high)
        XCTAssertEqual(MatchQuality(rawValue: "partial"), .partial)
        XCTAssertEqual(MatchQuality(rawValue: "low"), .low)
        XCTAssertNil(MatchQuality(rawValue: "medium"))
    }

    func testComparisonSessionTypeRawValues() {
        XCTAssertEqual(ComparisonSessionType(rawValue: "find_the_point"), .findThePoint)
        XCTAssertEqual(ComparisonSessionType(rawValue: "fix_this_mess"), .fixThisMess)
        XCTAssertEqual(ComparisonSessionType(rawValue: "spot_the_gap"), .spotTheGap)
    }

    func testAnswerKeyComparisonResultCodable() throws {
        let result = AnswerKeyComparisonResult(
            matchQuality: .high,
            feedback: "Well done!",
            dimensionScores: ["governingThoughtAccuracy": 3, "specificity": 2],
            metadata: ComparisonMetadata(
                mood: "approving",
                progressionSignal: "improving",
                sessionPhase: "evaluation",
                feedbackFocus: "Keep it up.",
                language: "en"
            )
        )

        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(AnswerKeyComparisonResult.self, from: data)

        XCTAssertEqual(decoded, result)
    }

    // MARK: - Prompt builder: output format includes correct COMPARISON_META tag

    func testOutputFormatSpecifiesComparisonMetaTag() {
        let input = ComparisonInput(
            userResponse: "test",
            practiceText: samplePracticeText,
            sessionType: .findThePoint,
            language: "en",
            learnerLevel: 1
        )

        let systemPrompt = promptBuilder.systemPrompt(for: input)
        XCTAssertTrue(systemPrompt.contains("COMPARISON_META"))
        XCTAssertTrue(systemPrompt.contains("matchQuality"))
    }
}
