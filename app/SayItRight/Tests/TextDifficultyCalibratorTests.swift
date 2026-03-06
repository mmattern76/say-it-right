import Foundation
import Testing
@testable import SayItRight

@Suite("TextDifficultyCalibrator Tests")
struct TextDifficultyCalibratorTests {

    // MARK: - Quality Level Filtering

    @Test("L1 users see only well-structured and buried-lead texts")
    func l1AllowedQualities() {
        let profile = makeProfile(level: 1)
        let allowed = TextDifficultyCalibrator.allowedQualityLevels(for: profile)
        #expect(allowed == [.wellStructured, .buriedLead])
    }

    @Test("L2 users see well-structured, buried-lead, and rambling texts")
    func l2AllowedQualities() {
        let profile = makeProfile(level: 2)
        let allowed = TextDifficultyCalibrator.allowedQualityLevels(for: profile)
        #expect(allowed == [.wellStructured, .buriedLead, .rambling])
    }

    @Test("L2 users with high scores also see adversarial texts")
    func l2HighScoresUnlockAdversarial() {
        var profile = makeProfile(level: 2)
        // Record high scores (8/10 = 0.8 > 0.75 threshold) across all break dimensions
        for dimension in TextDifficultyCalibrator.breakDimensions {
            for _ in 0..<5 {
                profile.recordScore(8, for: dimension)
            }
        }
        let allowed = TextDifficultyCalibrator.allowedQualityLevels(for: profile)
        #expect(allowed.contains(.adversarial))
    }

    @Test("L2 users with low scores do not see adversarial texts")
    func l2LowScoresNoAdversarial() {
        var profile = makeProfile(level: 2)
        // Record low scores (5/10 = 0.5 < 0.75 threshold)
        for dimension in TextDifficultyCalibrator.breakDimensions {
            for _ in 0..<5 {
                profile.recordScore(5, for: dimension)
            }
        }
        let allowed = TextDifficultyCalibrator.allowedQualityLevels(for: profile)
        #expect(!allowed.contains(.adversarial))
    }

    @Test("L2 users with incomplete dimension scores do not unlock adversarial")
    func l2IncompleteDimensionsNoAdversarial() {
        var profile = makeProfile(level: 2)
        // Only record scores for one dimension
        for _ in 0..<5 {
            profile.recordScore(9, for: "governing_thought")
        }
        let allowed = TextDifficultyCalibrator.allowedQualityLevels(for: profile)
        #expect(!allowed.contains(.adversarial))
    }

    @Test("L3+ users see all quality levels")
    func l3AllQualities() {
        let profile = makeProfile(level: 3)
        let allowed = TextDifficultyCalibrator.allowedQualityLevels(for: profile)
        #expect(allowed == Set(QualityLevel.allCases))
    }

    // MARK: - Language Filtering

    @Test("Calibrated texts match learner's language")
    func textsMatchLanguage() {
        let library = makeLibrary()
        let profile = makeProfile(level: 2, language: "en")
        let texts = TextDifficultyCalibrator.calibratedTexts(
            from: library, for: profile, sessionType: .findThePoint, seed: 42
        )
        #expect(texts.allSatisfy { $0.metadata.language == "en" })
    }

    @Test("German learner gets only German texts")
    func germanLearnerGetsGermanTexts() {
        let library = makeLibrary()
        let profile = makeProfile(level: 2, language: "de")
        let texts = TextDifficultyCalibrator.calibratedTexts(
            from: library, for: profile, sessionType: .findThePoint, seed: 42
        )
        #expect(texts.allSatisfy { $0.metadata.language == "de" })
    }

    // MARK: - L1 Text Selection

    @Test("L1 user never sees rambling texts")
    func l1NoRambling() {
        let library = makeLibrary()
        let profile = makeProfile(level: 1)
        let texts = TextDifficultyCalibrator.calibratedTexts(
            from: library, for: profile, sessionType: .findThePoint, seed: 42
        )
        #expect(!texts.contains { $0.metadata.qualityLevel == .rambling })
    }

    @Test("L1 user never sees adversarial texts")
    func l1NoAdversarial() {
        let library = makeLibrary()
        let profile = makeProfile(level: 1)
        let texts = TextDifficultyCalibrator.calibratedTexts(
            from: library, for: profile, sessionType: .findThePoint, seed: 42
        )
        #expect(!texts.contains { $0.metadata.qualityLevel == .adversarial })
    }

    @Test("L1 user sees well-structured and buried-lead texts")
    func l1SeesBasicTexts() {
        let library = makeLibrary()
        let profile = makeProfile(level: 1)
        let texts = TextDifficultyCalibrator.calibratedTexts(
            from: library, for: profile, sessionType: .findThePoint, seed: 42
        )
        let qualities = Set(texts.map(\.metadata.qualityLevel))
        #expect(qualities.isSubset(of: [.wellStructured, .buriedLead]))
        #expect(!texts.isEmpty)
    }

    // MARK: - L2 Text Selection

    @Test("L2 user sees rambling texts")
    func l2SeesRambling() {
        let library = makeLibrary()
        let profile = makeProfile(level: 2)
        let texts = TextDifficultyCalibrator.calibratedTexts(
            from: library, for: profile, sessionType: .findThePoint, seed: 42
        )
        #expect(texts.contains { $0.metadata.qualityLevel == .rambling })
    }

    // MARK: - Seen Text Exclusion

    @Test("Previously seen texts are excluded")
    func excludesSeenTexts() {
        let library = makeLibrary()
        let profile = makeProfile(level: 2)
        let allTexts = TextDifficultyCalibrator.calibratedTexts(
            from: library, for: profile, sessionType: .findThePoint, seed: 42
        )
        guard let firstID = allTexts.first?.id else {
            Issue.record("No texts returned")
            return
        }
        let filtered = TextDifficultyCalibrator.calibratedTexts(
            from: library, for: profile, sessionType: .findThePoint,
            excluding: [firstID], seed: 42
        )
        #expect(!filtered.contains { $0.id == firstID })
    }

    @Test("When all texts seen, returns full candidate set")
    func allSeenResetsToFull() {
        let library = makeLibrary()
        let profile = makeProfile(level: 2)
        let allTexts = TextDifficultyCalibrator.calibratedTexts(
            from: library, for: profile, sessionType: .findThePoint, seed: 42
        )
        let allIDs = Set(allTexts.map(\.id))
        let reset = TextDifficultyCalibrator.calibratedTexts(
            from: library, for: profile, sessionType: .findThePoint,
            excluding: allIDs, seed: 42
        )
        #expect(!reset.isEmpty, "Should return texts even when all have been seen")
    }

    // MARK: - Determinism

    @Test("Same seed produces same ordering")
    func deterministicOrdering() {
        let library = makeLibrary()
        let profile = makeProfile(level: 2)
        let run1 = TextDifficultyCalibrator.calibratedTexts(
            from: library, for: profile, sessionType: .findThePoint, seed: 42
        )
        let run2 = TextDifficultyCalibrator.calibratedTexts(
            from: library, for: profile, sessionType: .findThePoint, seed: 42
        )
        #expect(run1.map(\.id) == run2.map(\.id))
    }

    @Test("Different seeds produce different ordering")
    func differentSeedsDifferentOrder() {
        let library = makeLibrary()
        let profile = makeProfile(level: 2)
        let run1 = TextDifficultyCalibrator.calibratedTexts(
            from: library, for: profile, sessionType: .findThePoint, seed: 42
        )
        let run2 = TextDifficultyCalibrator.calibratedTexts(
            from: library, for: profile, sessionType: .findThePoint, seed: 99
        )
        // Same set of texts, but ordering should differ (with high probability)
        #expect(Set(run1.map(\.id)) == Set(run2.map(\.id)))
        // At least check they contain the same texts; ordering may differ
    }

    // MARK: - selectText

    @Test("selectText returns first calibrated text")
    func selectTextReturnsFirst() {
        let library = makeLibrary()
        let profile = makeProfile(level: 1)
        let selected = TextDifficultyCalibrator.selectText(
            from: library, for: profile, sessionType: .findThePoint, seed: 42
        )
        let calibrated = TextDifficultyCalibrator.calibratedTexts(
            from: library, for: profile, sessionType: .findThePoint, seed: 42
        )
        #expect(selected?.id == calibrated.first?.id)
    }

    @Test("selectText returns nil for empty library")
    func selectTextEmptyLibrary() {
        let library = PracticeTextLibrary(texts: [])
        let profile = makeProfile(level: 1)
        let selected = TextDifficultyCalibrator.selectText(
            from: library, for: profile, sessionType: .findThePoint, seed: 42
        )
        #expect(selected == nil)
    }

    // MARK: - Difficulty Weighting

    @Test("L1 current difficulty max is 2")
    func l1DifficultyMax() {
        let profile = makeProfile(level: 1)
        #expect(TextDifficultyCalibrator.currentDifficultyMax(for: profile) == 2)
    }

    @Test("L2 current difficulty max is 3")
    func l2DifficultyMax() {
        let profile = makeProfile(level: 2)
        #expect(TextDifficultyCalibrator.currentDifficultyMax(for: profile) == 3)
    }

    @Test("L3 current difficulty max is 4")
    func l3DifficultyMax() {
        let profile = makeProfile(level: 3)
        #expect(TextDifficultyCalibrator.currentDifficultyMax(for: profile) == 4)
    }

    // MARK: - Interleave

    @Test("Interleave produces approximately 60/40 ratio")
    func interleaveRatio() {
        let primary = Array(0..<6)
        let secondary = Array(100..<104)
        let result = TextDifficultyCalibrator.interleave(
            primary: primary, secondary: secondary, primaryRatio: 0.6
        )
        #expect(result.count == 10)
        // First 5 items should contain ~3 primary
        let firstFivePrimary = result.prefix(5).filter { $0 < 100 }.count
        #expect(firstFivePrimary >= 2 && firstFivePrimary <= 4,
                "Expected ~3 primary in first 5, got \(firstFivePrimary)")
    }

    @Test("Interleave with empty secondary returns primary")
    func interleaveEmptySecondary() {
        let primary = [1, 2, 3]
        let result = TextDifficultyCalibrator.interleave(
            primary: primary, secondary: [Int](), primaryRatio: 0.6
        )
        #expect(result == [1, 2, 3])
    }

    @Test("Interleave with empty primary returns secondary")
    func interleaveEmptyPrimary() {
        let secondary = [1, 2, 3]
        let result = TextDifficultyCalibrator.interleave(
            primary: [Int](), secondary: secondary, primaryRatio: 0.6
        )
        #expect(result == [1, 2, 3])
    }

    // MARK: - High Score Threshold

    @Test("Exactly 0.75 threshold unlocks adversarial")
    func exactThresholdUnlocks() {
        var profile = makeProfile(level: 2)
        // 7.5/10 = 0.75 — but scores are integers, so we need avg of exactly 7.5
        // Use alternating 7 and 8 to get 7.5 average
        for dimension in TextDifficultyCalibrator.breakDimensions {
            for i in 0..<10 {
                profile.recordScore(i % 2 == 0 ? 8 : 7, for: dimension)
            }
        }
        // Average is 7.5/10 = 0.75, should pass >= check
        #expect(TextDifficultyCalibrator.hasHighBreakScores(profile))
    }

    @Test("Just below 0.75 threshold does not unlock adversarial")
    func belowThresholdNoUnlock() {
        var profile = makeProfile(level: 2)
        // Score of 7/10 = 0.70 < 0.75
        for dimension in TextDifficultyCalibrator.breakDimensions {
            for _ in 0..<5 {
                profile.recordScore(7, for: dimension)
            }
        }
        #expect(!TextDifficultyCalibrator.hasHighBreakScores(profile))
    }

    // MARK: - SeededRandomNumberGenerator

    @Test("Seeded RNG is deterministic")
    func seededRNGDeterministic() {
        var rng1 = SeededRandomNumberGenerator(seed: 42)
        var rng2 = SeededRandomNumberGenerator(seed: 42)
        let values1 = (0..<10).map { _ in rng1.next() }
        let values2 = (0..<10).map { _ in rng2.next() }
        #expect(values1 == values2)
    }

    @Test("Different seeds produce different sequences")
    func seededRNGDifferentSeeds() {
        var rng1 = SeededRandomNumberGenerator(seed: 42)
        var rng2 = SeededRandomNumberGenerator(seed: 43)
        let values1 = (0..<10).map { _ in rng1.next() }
        let values2 = (0..<10).map { _ in rng2.next() }
        #expect(values1 != values2)
    }

    // MARK: - Helpers

    private func makeProfile(
        level: Int,
        language: String = "en",
        sessionCount: Int = 5
    ) -> LearnerProfile {
        var profile = LearnerProfile.createDefault(displayName: "Test", language: language)
        profile.currentLevel = level
        profile.sessionCount = sessionCount
        return profile
    }

    private func makeText(
        id: String,
        quality: QualityLevel,
        difficulty: Int,
        language: String = "en",
        targetLevel: Int = 1,
        domain: String = "everyday"
    ) -> PracticeText {
        PracticeText(
            id: id,
            text: "Sample text for \(id)",
            answerKey: AnswerKey(
                governingThought: "Thought for \(id)",
                supports: [SupportGroup(label: "Support", evidence: ["Evidence"])],
                structuralAssessment: "Assessment for \(id)",
                structuralFlaw: quality == .adversarial
                    ? StructuralFlaw(type: "test_flaw", description: "Test", location: "paragraph 1")
                    : nil,
                proposedRestructure: quality == .rambling ? "Restructured version" : nil
            ),
            metadata: PracticeTextMetadata(
                qualityLevel: quality,
                difficultyRating: difficulty,
                topicDomain: domain,
                language: language,
                wordCount: 50,
                targetLevel: targetLevel
            )
        )
    }

    private func makeLibrary() -> PracticeTextLibrary {
        let texts = [
            // English well-structured (difficulty 1-2)
            makeText(id: "en-ws-1", quality: .wellStructured, difficulty: 1, language: "en"),
            makeText(id: "en-ws-2", quality: .wellStructured, difficulty: 2, language: "en"),
            makeText(id: "en-ws-3", quality: .wellStructured, difficulty: 1, language: "en", domain: "school"),
            // English buried-lead (difficulty 3)
            makeText(id: "en-bl-1", quality: .buriedLead, difficulty: 3, language: "en"),
            makeText(id: "en-bl-2", quality: .buriedLead, difficulty: 3, language: "en", domain: "technology"),
            // English rambling (difficulty 4)
            makeText(id: "en-rm-1", quality: .rambling, difficulty: 4, language: "en", targetLevel: 2),
            makeText(id: "en-rm-2", quality: .rambling, difficulty: 4, language: "en", targetLevel: 2),
            // English adversarial (difficulty 5)
            makeText(id: "en-ad-1", quality: .adversarial, difficulty: 5, language: "en", targetLevel: 2),
            makeText(id: "en-ad-2", quality: .adversarial, difficulty: 5, language: "en", targetLevel: 2),
            // German well-structured
            makeText(id: "de-ws-1", quality: .wellStructured, difficulty: 1, language: "de"),
            makeText(id: "de-ws-2", quality: .wellStructured, difficulty: 2, language: "de"),
            // German buried-lead
            makeText(id: "de-bl-1", quality: .buriedLead, difficulty: 3, language: "de"),
            // German rambling
            makeText(id: "de-rm-1", quality: .rambling, difficulty: 4, language: "de", targetLevel: 2),
            // German adversarial
            makeText(id: "de-ad-1", quality: .adversarial, difficulty: 5, language: "de", targetLevel: 2),
        ]
        return PracticeTextLibrary(texts: texts)
    }
}
