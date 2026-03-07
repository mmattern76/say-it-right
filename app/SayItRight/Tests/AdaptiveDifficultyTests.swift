import Foundation
import Testing
@testable import SayItRight

@Suite("AdaptiveDifficultyEngine")
struct AdaptiveDifficultyTests {

    // MARK: - Helpers

    private func makeProfile(
        level: Int = 1,
        sessionCount: Int = 0,
        scores: [String: [Int]] = [:]
    ) -> LearnerProfile {
        var profile = LearnerProfile.createDefault(displayName: "Test")
        profile.currentLevel = level
        profile.sessionCount = sessionCount
        for (dim, values) in scores {
            for v in values {
                profile.recordScore(v, for: dim)
            }
        }
        return profile
    }

    // MARK: - Difficulty State

    @Test("New profile is consolidating")
    func newProfileConsolidating() {
        let profile = makeProfile()
        let state = AdaptiveDifficultyEngine.difficultyState(for: profile)
        #expect(state == .consolidating)
    }

    @Test("Profile with few sessions is consolidating even with good scores")
    func fewSessionsConsolidating() {
        let profile = makeProfile(sessionCount: 3, scores: [
            "governingThought": [3, 3, 3],
            "supportGrouping": [2, 2, 2],
            "redundancy": [2, 2, 2],
            "clarity": [3, 3, 3],
        ])
        let state = AdaptiveDifficultyEngine.difficultyState(for: profile)
        #expect(state == .consolidating)
    }

    @Test("Profile with enough sessions and strong scores is stretching")
    func stretchingState() {
        // 3/4 dimensions strong (75% > 60% threshold)
        let profile = makeProfile(sessionCount: 6, scores: [
            "governingThought": [3, 3, 3, 3, 3],
            "supportGrouping": [2, 2, 2, 2, 2],
            "redundancy": [2, 2, 2, 2, 2],
            "clarity": [1, 1, 1, 1, 1], // weak
        ])
        let state = AdaptiveDifficultyEngine.difficultyState(for: profile)
        #expect(state == .stretching)
    }

    @Test("Profile with all dimensions strong and enough sessions is ready for promotion")
    func readyForPromotion() {
        let profile = makeProfile(sessionCount: 12, scores: [
            "governingThought": [3, 3, 3, 3, 3],
            "supportGrouping": [2, 2, 2, 2, 2],
            "redundancy": [2, 2, 2, 2, 2],
            "clarity": [3, 3, 3, 3, 3],
        ])
        let state = AdaptiveDifficultyEngine.difficultyState(for: profile)
        #expect(state == .readyForPromotion)
    }

    @Test("Profile with one weak dimension is not ready for promotion")
    func notReadyWithWeakDimension() {
        let profile = makeProfile(sessionCount: 12, scores: [
            "governingThought": [3, 3, 3, 3, 3],
            "supportGrouping": [0, 0, 0, 0, 0], // weak
            "redundancy": [2, 2, 2, 2, 2],
            "clarity": [3, 3, 3, 3, 3],
        ])
        let state = AdaptiveDifficultyEngine.difficultyState(for: profile)
        #expect(state != .readyForPromotion)
    }

    // MARK: - Topic Level Selection

    @Test("Consolidating profile gets current level topics")
    func topicLevelConsolidating() {
        let profile = makeProfile(level: 1, sessionCount: 2)
        let level = AdaptiveDifficultyEngine.topicLevel(for: profile)
        #expect(level == 1)
    }

    @Test("Stretching profile gets mix of current and next level")
    func topicLevelStretching() {
        let profile = makeProfile(level: 1, sessionCount: 6, scores: [
            "governingThought": [3, 3, 3, 3, 3],
            "supportGrouping": [2, 2, 2, 2, 2],
            "redundancy": [2, 2, 2, 2, 2],
            "clarity": [1, 1, 1, 1, 1],
        ])
        // 70% current (index 0-6), 30% stretch (index 7-9)
        let currentLevel = AdaptiveDifficultyEngine.topicLevel(for: profile, sessionIndex: 0)
        let stretchLevel = AdaptiveDifficultyEngine.topicLevel(for: profile, sessionIndex: 8)
        #expect(currentLevel == 1)
        #expect(stretchLevel == 2)
    }

    @Test("Topic level never exceeds 4")
    func topicLevelCapped() {
        let profile = makeProfile(level: 4, sessionCount: 6, scores: [
            "l1Gate": [3, 3, 3, 3, 3],
            "meceQuality": [3, 3, 3, 3, 3],
            "orderingLogic": [3, 3, 3, 3, 3],
            "scqApplication": [2, 2, 2, 2, 2],
            "horizontalLogic": [0, 0, 0, 0, 0],
        ])
        let level = AdaptiveDifficultyEngine.topicLevel(for: profile, sessionIndex: 8)
        #expect(level <= 4)
    }

    // MARK: - Weak/Strong Dimensions

    @Test("Weak dimensions identified correctly")
    func weakDimensions() {
        let profile = makeProfile(level: 1, scores: [
            "governingThought": [3, 3, 3],
            "supportGrouping": [0, 0, 0], // weak
            "redundancy": [0, 0, 0], // weak
            "clarity": [3, 3, 3],
        ])
        let weak = AdaptiveDifficultyEngine.weakDimensions(for: profile)
        #expect(weak.contains("supportGrouping"))
        #expect(weak.contains("redundancy"))
        #expect(!weak.contains("governingThought"))
    }

    @Test("Strong dimensions identified correctly")
    func strongDimensions() {
        let profile = makeProfile(level: 1, scores: [
            "governingThought": [3, 3, 3],
            "supportGrouping": [0, 0, 0],
            "clarity": [3, 3, 3],
        ])
        let strong = AdaptiveDifficultyEngine.strongDimensions(for: profile)
        #expect(strong.contains("governingThought"))
        #expect(strong.contains("clarity"))
        #expect(!strong.contains("supportGrouping"))
    }

    // MARK: - Difficulty Context

    @Test("Difficulty context includes state and dimensions")
    func difficultyContext() {
        let profile = makeProfile(level: 1, sessionCount: 6, scores: [
            "governingThought": [3, 3, 3, 3, 3],
            "supportGrouping": [2, 2, 2, 2, 2],
            "redundancy": [2, 2, 2, 2, 2],
            "clarity": [0, 0, 0, 0, 0],
        ])
        let context = AdaptiveDifficultyEngine.difficultyContext(for: profile)
        #expect(context.contains("stretching"))
        #expect(context.contains("clarity"))
        #expect(context.contains("More demanding"))
    }

    @Test("New user context says consolidating with patient approach")
    func newUserContext() {
        let profile = makeProfile()
        let context = AdaptiveDifficultyEngine.difficultyContext(for: profile)
        #expect(context.contains("consolidating"))
        #expect(context.contains("Patient"))
    }

    // MARK: - Level Dimensions

    @Test("L1 has 4 dimensions")
    func l1Dimensions() {
        let dims = AdaptiveDifficultyEngine.dimensionsForLevel(1)
        #expect(dims.count == 4)
        #expect(dims.contains("governingThought"))
        #expect(dims.contains("clarity"))
    }

    @Test("L2 has 8 dimensions (5 Build + 3 Break)")
    func l2Dimensions() {
        let dims = AdaptiveDifficultyEngine.dimensionsForLevel(2)
        #expect(dims.count == 8)
        #expect(dims.contains("meceQuality"))
        #expect(dims.contains("horizontalLogic"))
        #expect(dims.contains("extractionAccuracy"))
        #expect(dims.contains("flawIdentification"))
        #expect(dims.contains("restructuringQuality"))
    }
}
