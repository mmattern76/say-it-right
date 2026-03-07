import Foundation
import Testing
@testable import SayItRight

@Suite("SpotTheGapSession")
struct SpotTheGapSessionTests {

    private static func makePracticeText() -> PracticeText {
        PracticeText(
            id: "pt-adversarial",
            text: "Renewable energy is the future. Solar costs have dropped. Wind power creates jobs. Therefore, we should ban all fossil fuels immediately.",
            answerKey: AnswerKey(
                governingThought: "Renewable energy is the future.",
                supports: [
                    SupportGroup(label: "Cost", evidence: ["Solar costs have dropped"]),
                    SupportGroup(label: "Jobs", evidence: ["Wind power creates jobs"]),
                ],
                structuralAssessment: "The conclusion (ban all fossil fuels) does not follow from the evidence (costs and jobs).",
                structuralFlaw: StructuralFlaw(
                    type: "unsupported_conclusion",
                    description: "The conclusion to ban fossil fuels is not supported by the evidence about costs and jobs.",
                    location: "conclusion"
                )
            ),
            metadata: PracticeTextMetadata(
                qualityLevel: .adversarial,
                difficultyRating: 4,
                topicDomain: "society",
                language: "en",
                wordCount: 25,
                targetLevel: 2
            )
        )
    }

    @Test("Session initialises with practice text")
    func initialisation() {
        let text = Self.makePracticeText()
        let session = SpotTheGapSession(practiceText: text)

        #expect(session.sessionTypeID == "spot-the-gap")
        #expect(!session.hasResponse)
        #expect(session.attemptCount == 0)
        #expect(session.canAttempt)
        #expect(!session.isExhausted)
        #expect(session.hasKnownFlaw)
        #expect(session.structuralFlaw?.type == "unsupported_conclusion")
        #expect(session.maxAttempts == 3)
    }

    @Test("Record attempts up to maximum")
    func attemptTracking() {
        let text = Self.makePracticeText()
        var session = SpotTheGapSession(practiceText: text)

        session.recordAttempt("The evidence doesn't support the conclusion")
        #expect(session.attemptCount == 1)
        #expect(session.canAttempt)

        session.recordAttempt("The groups aren't MECE")
        #expect(session.attemptCount == 2)
        #expect(session.canAttempt)

        session.recordAttempt("Final attempt")
        #expect(session.attemptCount == 3)
        #expect(!session.canAttempt)
        #expect(session.isExhausted)
    }

    @Test("Original text accessible")
    func originalText() {
        let text = Self.makePracticeText()
        let session = SpotTheGapSession(practiceText: text)
        #expect(session.originalText.contains("Renewable energy"))
    }
}

@Suite("SessionType — Spot The Gap")
struct SessionTypeSpotTheGapTests {

    @Test("spotTheGap raw value")
    func rawValue() {
        #expect(SessionType.spotTheGap.rawValue == "spot-the-gap")
    }

    @Test("English display name")
    func displayNameEN() {
        #expect(SessionType.spotTheGap.displayName(language: "en") == "Spot the gap")
    }

    @Test("German display name")
    func displayNameDE() {
        #expect(SessionType.spotTheGap.displayName(language: "de") == "Finde die Lücke")
    }

    @Test("CaseIterable includes spotTheGap")
    func allCases() {
        #expect(SessionType.allCases.contains(.spotTheGap))
    }
}
