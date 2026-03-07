import Foundation
import Testing
@testable import SayItRight

@Suite("FixThisMessSession")
struct FixThisMessSessionTests {

    private static func makePracticeText() -> PracticeText {
        PracticeText(
            id: "pt-test",
            text: "There are many reasons for uniforms. Students like them. Schools want them. Parents support them. The main point is equality.",
            answerKey: AnswerKey(
                governingThought: "School uniforms promote equality among students.",
                supports: [
                    SupportGroup(label: "Student perspective", evidence: ["Students like them"]),
                    SupportGroup(label: "Institutional support", evidence: ["Schools want them", "Parents support them"]),
                ],
                structuralAssessment: "Buried lead — conclusion is at the end.",
                proposedRestructure: "School uniforms promote equality. Students, schools, and parents all support them for different reasons."
            ),
            metadata: PracticeTextMetadata(
                qualityLevel: .buriedLead,
                difficultyRating: 2,
                topicDomain: "school",
                language: "en",
                wordCount: 22,
                targetLevel: 1
            )
        )
    }

    @Test("Session initialises with practice text")
    func initialisation() {
        let text = Self.makePracticeText()
        let session = FixThisMessSession(practiceText: text)

        #expect(session.sessionTypeID == "fix-this-mess")
        #expect(!session.hasResponse)
        #expect(session.originalText == text.text)
        #expect(session.originalWordCount == 22)
        #expect(session.expectedGoverningThought.contains("equality"))
        #expect(session.maxRevisions == 1)
    }

    @Test("Record attempt captures text")
    func recordAttempt() {
        let text = Self.makePracticeText()
        var session = FixThisMessSession(practiceText: text)

        session.recordAttempt("School uniforms promote equality. They reduce social pressure.")

        #expect(session.hasResponse)
        #expect(session.responseText?.contains("equality") == true)
        #expect(session.currentRevisionRound == 0)
        #expect(session.canRevise)
    }

    @Test("Revision tracking with one allowed revision")
    func revisionTracking() {
        let text = Self.makePracticeText()
        var session = FixThisMessSession(practiceText: text)

        session.recordAttempt("First attempt")
        #expect(session.canRevise)

        session.recordAttempt("Revised attempt")
        #expect(!session.canRevise)
        #expect(session.isRevisionComplete)
        #expect(session.currentRevisionRound == 1)
        #expect(session.latestAttemptText == "Revised attempt")
    }

    @Test("Proposed restructure from answer key")
    func proposedRestructure() {
        let text = Self.makePracticeText()
        let session = FixThisMessSession(practiceText: text)
        #expect(session.proposedRestructure != nil)
        #expect(session.proposedRestructure!.contains("equality"))
    }
}

@Suite("SessionType — Fix This Mess")
struct SessionTypeFixThisMessTests {

    @Test("fixThisMess raw value")
    func rawValue() {
        #expect(SessionType.fixThisMess.rawValue == "fix-this-mess")
    }

    @Test("English display name")
    func displayNameEN() {
        #expect(SessionType.fixThisMess.displayName(language: "en") == "Fix this mess")
    }

    @Test("German display name")
    func displayNameDE() {
        #expect(SessionType.fixThisMess.displayName(language: "de") == "Räum das auf")
    }

    @Test("Icon is arrow.up.and.down.text.horizontal")
    func iconName() {
        #expect(SessionType.fixThisMess.iconName == "arrow.up.and.down.text.horizontal")
    }

    @Test("CaseIterable includes fixThisMess")
    func allCases() {
        #expect(SessionType.allCases.contains(.fixThisMess))
    }
}
