import Foundation
import Testing
@testable import SayItRight

@Suite("SpotTheGapSession — Hints")
struct SpotTheGapHintTests {

    private static func makeFlawWithHints() -> StructuralFlaw {
        StructuralFlaw(
            type: "misaligned_evidence",
            description: "Support B's evidence doesn't support Support B's claim.",
            location: "support group B",
            hints: HintTiers(
                tier1: "The problem isn't in the conclusion. Look at the supporting evidence.",
                tier2: "Compare the evidence under Support B to its label. Does the evidence actually support that claim?",
                tier3: "Support B claims 'wind creates jobs' but the evidence talks about solar panel manufacturing costs. The evidence is misaligned — it belongs under a different support group."
            )
        )
    }

    private static func makeText(withHints: Bool = true) -> PracticeText {
        PracticeText(
            id: "pt-hint-test",
            text: "Renewable energy is the future. Solar is cheap. Wind creates jobs. Therefore we should switch.",
            answerKey: AnswerKey(
                governingThought: "Renewable energy is the future.",
                supports: [
                    SupportGroup(label: "Cost", evidence: ["Solar is cheap"]),
                    SupportGroup(label: "Jobs", evidence: ["Wind creates jobs"]),
                ],
                structuralAssessment: "Misaligned evidence in support B.",
                structuralFlaw: withHints ? makeFlawWithHints() : StructuralFlaw(
                    type: "misaligned_evidence",
                    description: "Evidence misaligned.",
                    location: "support B"
                )
            ),
            metadata: PracticeTextMetadata(
                qualityLevel: .adversarial,
                difficultyRating: 4,
                topicDomain: "society",
                language: "en",
                wordCount: 18,
                targetLevel: 2
            )
        )
    }

    @Test("Hint tier advances with attempts")
    func hintTierProgression() {
        var session = SpotTheGapSession(practiceText: Self.makeText())

        #expect(session.currentHintTier == 0)

        session.recordAttempt("Wrong guess 1")
        #expect(session.currentHintTier == 1)
        #expect(session.currentHint?.contains("conclusion") == true)

        session.recordAttempt("Wrong guess 2")
        #expect(session.currentHintTier == 2)
        #expect(session.currentHint?.contains("Support B") == true)

        session.recordAttempt("Wrong guess 3")
        #expect(session.currentHintTier == 3)
        #expect(session.isFlawRevealed)
        #expect(session.currentHint?.contains("misaligned") == true)
    }

    @Test("Session without pre-generated hints returns nil")
    func noPreGeneratedHints() {
        var session = SpotTheGapSession(practiceText: Self.makeText(withHints: false))
        #expect(!session.hasPreGeneratedHints)

        session.recordAttempt("Guess")
        #expect(session.currentHint == nil)
    }

    @Test("Has pre-generated hints flag")
    func hasHintsFlag() {
        let session = SpotTheGapSession(practiceText: Self.makeText(withHints: true))
        #expect(session.hasPreGeneratedHints)
    }

    @Test("Flaw not revealed until tier 3")
    func flawNotRevealedEarly() {
        var session = SpotTheGapSession(practiceText: Self.makeText())
        #expect(!session.isFlawRevealed)

        session.recordAttempt("Attempt 1")
        #expect(!session.isFlawRevealed)

        session.recordAttempt("Attempt 2")
        #expect(!session.isFlawRevealed)

        session.recordAttempt("Attempt 3")
        #expect(session.isFlawRevealed)
    }
}

@Suite("HintTiers")
struct HintTiersTests {

    @Test("HintTiers is Codable")
    func codableRoundTrip() throws {
        let hints = HintTiers(
            tier1: "Look at the grouping.",
            tier2: "Compare groups B and C.",
            tier3: "Groups B and C overlap — they're not MECE."
        )
        let data = try JSONEncoder().encode(hints)
        let decoded = try JSONDecoder().decode(HintTiers.self, from: data)
        #expect(decoded == hints)
    }

    @Test("StructuralFlaw with hints is Codable")
    func flawWithHintsCodable() throws {
        let flaw = StructuralFlaw(
            type: "missing_group",
            description: "A key support group is missing.",
            location: "overall structure",
            hints: HintTiers(
                tier1: "Something is missing.",
                tier2: "Count the support groups.",
                tier3: "The economic argument has no support group."
            )
        )
        let data = try JSONEncoder().encode(flaw)
        let decoded = try JSONDecoder().decode(StructuralFlaw.self, from: data)
        #expect(decoded == flaw)
        #expect(decoded.hints?.tier1 == "Something is missing.")
    }

    @Test("StructuralFlaw without hints is backward compatible")
    func flawWithoutHints() throws {
        let json = """
        {"type":"gap","description":"A gap","location":"here"}
        """
        let flaw = try JSONDecoder().decode(StructuralFlaw.self, from: Data(json.utf8))
        #expect(flaw.hints == nil)
        #expect(flaw.type == "gap")
    }
}
