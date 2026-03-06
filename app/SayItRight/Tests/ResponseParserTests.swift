import XCTest
@testable import SayItRight

final class ResponseParserTests: XCTestCase {

    private let parser = ResponseParser()

    // MARK: - Helpers

    /// Builds a valid BARBARA_META comment block from individual fields.
    private func metaBlock(
        scores: [String: Int] = ["clarity": 3, "structure": 4],
        totalScore: Int = 7,
        mood: String = "approving",
        progressionSignal: String = "improving",
        revisionRound: Int = 1,
        sessionPhase: String = "evaluation",
        feedbackFocus: String = "Lead with your conclusion.",
        language: String = "en"
    ) -> String {
        """
        <!-- BARBARA_META: {"scores":{"clarity":\(scores["clarity"]!),"structure":\(scores["structure"]!)},"totalScore":\(totalScore),"mood":"\(mood)","progressionSignal":"\(progressionSignal)","revisionRound":\(revisionRound),"sessionPhase":"\(sessionPhase)","feedbackFocus":"\(feedbackFocus)","language":"\(language)"} -->
        """
    }

    // MARK: - 1. Clean extraction of visible text and valid metadata

    func testCleanExtraction() {
        let visiblePart = "Good structure! Your conclusion leads clearly."
        let fullResponse = "\(visiblePart)\n\n\(metaBlock())"

        let result = parser.parse(fullResponse: fullResponse)

        XCTAssertEqual(result.visibleText, visiblePart)
        XCTAssertNotNil(result.metadata)

        let meta = result.metadata!
        XCTAssertEqual(meta.scores["clarity"], 3)
        XCTAssertEqual(meta.scores["structure"], 4)
        XCTAssertEqual(meta.totalScore, 7)
        XCTAssertEqual(meta.mood, .approving)
        XCTAssertEqual(meta.progressionSignal, .improving)
        XCTAssertEqual(meta.revisionRound, 1)
        XCTAssertEqual(meta.sessionPhase, .evaluation)
        XCTAssertEqual(meta.feedbackFocus, "Lead with your conclusion.")
        XCTAssertEqual(meta.language, "en")
    }

    // MARK: - 2. Missing metadata block

    func testMissingMetadataBlock() {
        let plainText = "That's not a conclusion, that's a preamble. Start over."

        let result = parser.parse(fullResponse: plainText)

        XCTAssertEqual(result.visibleText, plainText)
        XCTAssertNil(result.metadata)
    }

    // MARK: - 3. Malformed JSON

    func testMalformedJSON() {
        let fullResponse = "Nice try.\n\n<!-- BARBARA_META: {not valid json} -->"

        let result = parser.parse(fullResponse: fullResponse)

        XCTAssertEqual(result.visibleText, "Nice try.")
        XCTAssertNil(result.metadata)
    }

    // MARK: - 4. Multiple metadata blocks (uses last one)

    func testMultipleMetadataBlocksUsesLast() {
        let firstBlock = metaBlock(totalScore: 3, mood: "skeptical")
        let secondBlock = metaBlock(totalScore: 8, mood: "proud")
        let fullResponse = "First reply.\n\n\(firstBlock)\n\nSecond reply.\n\n\(secondBlock)"

        let result = parser.parse(fullResponse: fullResponse)

        // Both blocks stripped from visible text
        XCTAssertFalse(result.visibleText.contains("BARBARA_META"))
        XCTAssertTrue(result.visibleText.contains("First reply."))
        XCTAssertTrue(result.visibleText.contains("Second reply."))

        // Metadata comes from the last block
        XCTAssertNotNil(result.metadata)
        XCTAssertEqual(result.metadata!.totalScore, 8)
        XCTAssertEqual(result.metadata!.mood, .proud)
    }

    // MARK: - 5. Metadata in middle of text

    func testMetadataInMiddleOfText() {
        let fullResponse = "Before the block.\n\n\(metaBlock())\n\nAfter the block."

        let result = parser.parse(fullResponse: fullResponse)

        XCTAssertFalse(result.visibleText.contains("BARBARA_META"))
        XCTAssertTrue(result.visibleText.contains("Before the block."))
        XCTAssertTrue(result.visibleText.contains("After the block."))
        XCTAssertNotNil(result.metadata)
        XCTAssertEqual(result.metadata!.mood, .approving)
    }

    // MARK: - Edge cases

    func testEmptyInput() {
        let result = parser.parse(fullResponse: "")
        XCTAssertEqual(result.visibleText, "")
        XCTAssertNil(result.metadata)
    }

    func testWhitespaceOnlyInput() {
        let result = parser.parse(fullResponse: "   \n\n  ")
        XCTAssertEqual(result.visibleText, "")
        XCTAssertNil(result.metadata)
    }

    func testMetadataBlockOnly() {
        let fullResponse = metaBlock()
        let result = parser.parse(fullResponse: fullResponse)

        XCTAssertEqual(result.visibleText, "")
        XCTAssertNotNil(result.metadata)
    }
}
