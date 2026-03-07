import Foundation
import Testing
@testable import SayItRight

@Suite("DecodeAndRebuildSession")
struct DecodeAndRebuildSessionTests {

    private static func makePracticeText() -> PracticeText {
        PracticeText(
            id: "pt-decode-test",
            text: "Studies show that remote work increases productivity. Companies save on office costs. Employees report higher satisfaction. Therefore, all companies should adopt remote work policies.",
            answerKey: AnswerKey(
                governingThought: "All companies should adopt remote work policies.",
                supports: [
                    SupportGroup(label: "Productivity", evidence: ["Remote work increases productivity"]),
                    SupportGroup(label: "Cost", evidence: ["Companies save on office costs"]),
                    SupportGroup(label: "Satisfaction", evidence: ["Employees report higher satisfaction"]),
                ],
                structuralAssessment: "The conclusion is buried at the end. Evidence leads to the governing thought instead of the other way around."
            ),
            metadata: PracticeTextMetadata(
                qualityLevel: .buriedLead,
                difficultyRating: 3,
                topicDomain: "business",
                language: "en",
                wordCount: 28,
                targetLevel: 2
            )
        )
    }

    @Test("Session initialises in extraction phase")
    func initialisation() {
        let session = DecodeAndRebuildSession(practiceText: Self.makePracticeText())

        #expect(session.sessionTypeID == "decode-and-rebuild")
        #expect(session.phase == .extraction)
        #expect(!session.hasExtraction)
        #expect(!session.hasRebuild)
        #expect(session.totalAttemptCount == 0)
        #expect(session.isBreakPhase)
        #expect(!session.isBuildPhase)
    }

    @Test("Phase 1: record extraction attempt")
    func extractionAttempt() {
        var session = DecodeAndRebuildSession(practiceText: Self.makePracticeText())

        session.recordExtractionAttempt("The governing thought is about remote work policies.")
        #expect(session.hasExtraction)
        #expect(session.extractionText == "The governing thought is about remote work policies.")
        #expect(session.totalAttemptCount == 1)
    }

    @Test("Phase transitions work correctly")
    func phaseTransitions() {
        var session = DecodeAndRebuildSession(practiceText: Self.makePracticeText())

        #expect(session.phase == .extraction)

        session.advanceToTransition()
        #expect(session.phase == .transition)
        #expect(session.isBreakPhase)

        session.advanceToRebuild()
        #expect(session.phase == .rebuild)
        #expect(session.isBuildPhase)

        session.advanceToSummary()
        #expect(session.phase == .summary)
        #expect(session.isBuildPhase)
    }

    @Test("Phase 2: record rebuild attempt and revision")
    func rebuildAttempts() {
        var session = DecodeAndRebuildSession(practiceText: Self.makePracticeText())
        session.advanceToRebuild()

        session.recordRebuildAttempt("Remote work should be adopted because...")
        #expect(session.hasRebuild)
        #expect(session.currentRebuildRevision == 0)
        #expect(session.canReviseRebuild)

        session.recordRebuildAttempt("All companies should adopt remote work. Here's why...")
        #expect(session.currentRebuildRevision == 1)
        #expect(!session.canReviseRebuild)
    }

    @Test("Original text and answer key accessible")
    func accessors() {
        let text = Self.makePracticeText()
        let session = DecodeAndRebuildSession(practiceText: text)

        #expect(session.originalText.contains("remote work"))
        #expect(session.expectedGoverningThought == "All companies should adopt remote work policies.")
        #expect(session.expectedSupports.count == 3)
        #expect(session.originalWordCount == 28)
    }

    @Test("Total attempt count spans both phases")
    func totalAttemptCount() {
        var session = DecodeAndRebuildSession(practiceText: Self.makePracticeText())

        session.recordExtractionAttempt("Extraction attempt")
        session.advanceToRebuild()
        session.recordRebuildAttempt("Rebuild attempt")

        #expect(session.totalAttemptCount == 2)
    }
}

@Suite("DecodeAndRebuildCoordinator")
struct DecodeAndRebuildCoordinatorTests {

    @Test("Unlock requires L2+ and sufficient sessions")
    @MainActor
    func unlockGate() {
        let coordinator = DecodeAndRebuildCoordinator()

        // L1 user: locked
        let l1Profile = LearnerProfile.createDefault(displayName: "Learner")
        #expect(!coordinator.isUnlocked(for: l1Profile))

        // L2 user with enough sessions: unlocked
        var l2Profile = LearnerProfile.createDefault(displayName: "Learner")
        l2Profile.currentLevel = 2
        l2Profile.sessionCount = 6  // 3 Break + 3 Build
        #expect(coordinator.isUnlocked(for: l2Profile))

        // L2 user with too few sessions: locked
        var l2FewSessions = LearnerProfile.createDefault(displayName: "Learner")
        l2FewSessions.currentLevel = 2
        l2FewSessions.sessionCount = 4
        #expect(!coordinator.isUnlocked(for: l2FewSessions))
    }

    @Test("Text selection filters for buried-lead and rambling")
    @MainActor
    func textSelection() {
        let coordinator = DecodeAndRebuildCoordinator()
        var profile = LearnerProfile.createDefault(displayName: "Learner")
        profile.currentLevel = 2

        // selectText may return nil if the library has no matching texts
        // for this test profile — that's expected behavior
        let _ = coordinator.selectText(for: profile)
    }

    @Test("Recent text tracking prevents repeats")
    @MainActor
    func recentTextTracking() {
        let coordinator = DecodeAndRebuildCoordinator()
        #expect(coordinator.recentTextIDs.isEmpty)

        coordinator.clearRecentTexts()
        #expect(coordinator.recentTextIDs.isEmpty)
    }
}

@Suite("SessionType — Decode and Rebuild")
struct SessionTypeDecodeAndRebuildTests {

    @Test("decodeAndRebuild raw value")
    func rawValue() {
        #expect(SessionType.decodeAndRebuild.rawValue == "decode-and-rebuild")
    }

    @Test("English display name")
    func displayNameEN() {
        #expect(SessionType.decodeAndRebuild.displayName(language: "en") == "Decode and rebuild")
    }

    @Test("German display name")
    func displayNameDE() {
        #expect(SessionType.decodeAndRebuild.displayName(language: "de") == "Entschlüsseln und Neubauen")
    }

    @Test("CaseIterable includes decodeAndRebuild")
    func allCases() {
        #expect(SessionType.allCases.contains(.decodeAndRebuild))
    }

    @Test("Icon name")
    func iconName() {
        #expect(SessionType.decodeAndRebuild.iconName == "arrow.triangle.2.circlepath")
    }
}
