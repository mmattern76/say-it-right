import Foundation
import Testing
@testable import SayItRight

@Suite("LevelTransitionEngine")
struct LevelTransitionTests {

    private let engine = LevelTransitionEngine()

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

    @Test("New profile is not ready for promotion")
    func newProfileNotReady() {
        let profile = makeProfile()
        #expect(!engine.isReadyForPromotion(profile))
    }

    @Test("Profile with insufficient sessions is not ready")
    func insufficientSessions() {
        let profile = makeProfile(sessionCount: 5, scores: [
            "governingThought": [3, 3, 3, 3, 3],
            "supportGrouping": [2, 2, 2, 2, 2],
            "redundancy": [2, 2, 2, 2, 2],
            "clarity": [3, 3, 3, 3, 3],
        ])
        #expect(!engine.isReadyForPromotion(profile))
    }

    @Test("Profile with all dimensions strong and enough sessions is ready")
    func readyForPromotion() {
        let profile = makeProfile(sessionCount: 12, scores: [
            "governingThought": [3, 3, 3, 3, 3],
            "supportGrouping": [2, 2, 2, 2, 2],
            "redundancy": [2, 2, 2, 2, 2],
            "clarity": [3, 3, 3, 3, 3],
        ])
        #expect(engine.isReadyForPromotion(profile))
    }

    @Test("Profile with one weak dimension is not ready")
    func oneWeakDimension() {
        let profile = makeProfile(sessionCount: 12, scores: [
            "governingThought": [3, 3, 3, 3, 3],
            "supportGrouping": [0, 0, 0, 0, 0],
            "redundancy": [2, 2, 2, 2, 2],
            "clarity": [3, 3, 3, 3, 3],
        ])
        #expect(!engine.isReadyForPromotion(profile))
    }

    @Test("Profile missing dimension data is not ready")
    func missingDimension() {
        let profile = makeProfile(sessionCount: 12, scores: [
            "governingThought": [3, 3, 3, 3, 3],
            "clarity": [3, 3, 3, 3, 3],
        ])
        #expect(!engine.isReadyForPromotion(profile))
    }

    @Test("Promote increments level and adds history entry")
    func promoteLevelUp() {
        var profile = makeProfile(level: 1, sessionCount: 12)
        let transition = engine.promote(&profile)

        #expect(profile.currentLevel == 2)
        #expect(profile.levelHistory.count == 1)
        #expect(profile.levelHistory[0].fromLevel == 1)
        #expect(profile.levelHistory[0].toLevel == 2)
        #expect(transition != nil)
        #expect(transition?.fromLevel == 1)
        #expect(transition?.toLevel == 2)
    }

    @Test("Cannot promote beyond level 4")
    func cannotPromoteBeyond4() {
        var profile = makeProfile(level: 4, sessionCount: 20)
        let transition = engine.promote(&profile)
        #expect(transition == nil)
        #expect(profile.currentLevel == 4)
    }

    @Test("Level 4 profile has no criteria, not ready")
    func level4NotReady() {
        let profile = makeProfile(level: 4, sessionCount: 100, scores: [
            "l1Gate": [3, 3, 3],
            "meceQuality": [3, 3, 3],
        ])
        #expect(!engine.isReadyForPromotion(profile))
    }

    @Test("Barbara quotes differ by language")
    func barbaraQuotes() {
        let transition = LevelTransitionEngine.LevelTransition(
            fromLevel: 1, toLevel: 2, date: .now
        )
        let en = transition.barbaraQuote(language: "en")
        let de = transition.barbaraQuote(language: "de")
        #expect(en.contains("foundations"))
        #expect(de.contains("Grundlagen"))
    }

    @Test("Level names are correct")
    func levelNames() {
        let names = LevelTransitionEngine.LevelTransition.levelName(1)
        #expect(names.en == "Plain Talk")
        #expect(names.de == "Klartext")

        let l4 = LevelTransitionEngine.LevelTransition.levelName(4)
        #expect(l4.en == "Mastery")
    }
}

@Suite("ProgressionCriteria")
struct ProgressionCriteriaTests {

    @Test("Default criteria exist for L1, L2, L3")
    func defaultCriteria() {
        let criteria = ProgressionCriteria.default
        #expect(criteria.criteria(fromLevel: 1) != nil)
        #expect(criteria.criteria(fromLevel: 2) != nil)
        #expect(criteria.criteria(fromLevel: 3) != nil)
        #expect(criteria.criteria(fromLevel: 4) == nil) // No L4→L5
    }

    @Test("L1 criteria require 4 dimensions")
    func l1Dimensions() {
        let c = ProgressionCriteria.default.criteria(fromLevel: 1)!
        #expect(c.requiredDimensions.count == 4)
        #expect(c.minTotalSessions == 10)
        #expect(c.minDimensionAverage == 0.75)
    }
}
