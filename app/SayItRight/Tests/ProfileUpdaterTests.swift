import Testing
import Foundation
@testable import SayItRight

@Suite("ProfileUpdater")
struct ProfileUpdaterTests {

    private static func makeMetadata(
        scores: [String: Int] = ["governingThought": 2, "clarity": 2, "supportGrouping": 1, "redundancy": 1],
        totalScore: Int = 6,
        mood: BarbaraMood = .evaluating,
        progressionSignal: ProgressionSignal = .none,
        revisionRound: Int = 0,
        sessionPhase: SessionPhase = .evaluation
    ) -> BarbaraMetadata {
        BarbaraMetadata(
            scores: scores,
            totalScore: totalScore,
            mood: mood,
            progressionSignal: progressionSignal,
            revisionRound: revisionRound,
            sessionPhase: sessionPhase,
            feedbackFocus: "clarity",
            language: "en"
        )
    }

    @Test("Updates dimension scores from metadata")
    func recordsScores() {
        let updater = ProfileUpdater()
        var profile = LearnerProfile.createDefault()
        let metadata = Self.makeMetadata()

        updater.updateProfile(&profile, from: metadata, sessionType: "say-it-clearly")

        #expect(profile.dimensionScores["governingThought"] == [2])
        #expect(profile.dimensionScores["clarity"] == [2])
        #expect(profile.dimensionScores["supportGrouping"] == [1])
        #expect(profile.dimensionScores["redundancy"] == [1])
    }

    @Test("Increments session count")
    func incrementsSessionCount() {
        let updater = ProfileUpdater()
        var profile = LearnerProfile.createDefault()

        updater.updateProfile(&profile, from: Self.makeMetadata(), sessionType: "say-it-clearly")

        #expect(profile.sessionCount == 1)
    }

    @Test("Updates streak")
    func updatesStreak() {
        let updater = ProfileUpdater()
        var profile = LearnerProfile.createDefault()

        updater.updateProfile(&profile, from: Self.makeMetadata(), sessionType: "say-it-clearly")

        #expect(profile.currentStreak == 1)
        #expect(profile.lastSessionDate != nil)
    }

    @Test("Identifies strengths from high rolling averages")
    func identifiesStrengths() {
        let updater = ProfileUpdater()
        var profile = LearnerProfile.createDefault()

        // Record high scores for governingThought (max 3) — need ≥ 0.8 * 3 = 2.4
        let highMetadata = Self.makeMetadata(scores: ["governingThought": 3, "clarity": 3])
        for _ in 0..<5 {
            updater.updateProfile(&profile, from: highMetadata, sessionType: "say-it-clearly")
        }

        #expect(profile.structuralStrengths.contains("governingThought"))
        #expect(profile.structuralStrengths.contains("clarity"))
    }

    @Test("Identifies development areas from low rolling averages")
    func identifiesDevelopmentAreas() {
        let updater = ProfileUpdater()
        var profile = LearnerProfile.createDefault()

        // Record low scores for supportGrouping (max 2) — need < 0.5 * 2 = 1.0
        let lowMetadata = Self.makeMetadata(scores: ["supportGrouping": 0, "redundancy": 0])
        for _ in 0..<3 {
            updater.updateProfile(&profile, from: lowMetadata, sessionType: "say-it-clearly")
        }

        #expect(profile.developmentAreas.contains("supportGrouping"))
        #expect(profile.developmentAreas.contains("redundancy"))
    }

    @Test("Does not corrupt profile when metadata has no scores")
    func noScoresNoCorruption() {
        let updater = ProfileUpdater()
        var profile = LearnerProfile.createDefault()
        profile.sessionCount = 5

        let emptyMetadata = Self.makeMetadata(scores: [:], totalScore: 0)
        updater.updateProfile(&profile, from: [emptyMetadata], sessionType: "say-it-clearly")

        // Should not change since metadata is filtered
        #expect(profile.sessionCount == 5)
    }

    @Test("Multiple metadata blocks from same session all contribute scores")
    func multipleMetadataBlocks() {
        let updater = ProfileUpdater()
        var profile = LearnerProfile.createDefault()

        let meta1 = Self.makeMetadata(scores: ["governingThought": 1, "clarity": 1])
        let meta2 = Self.makeMetadata(scores: ["governingThought": 3, "clarity": 3])

        updater.updateProfile(&profile, from: [meta1, meta2], sessionType: "say-it-clearly")

        // Both scores recorded
        #expect(profile.dimensionScores["governingThought"] == [1, 3])
        #expect(profile.dimensionScores["clarity"] == [1, 3])
        // Session count only incremented once
        #expect(profile.sessionCount == 1)
    }

    @Test("Rolling average correctly determines threshold membership")
    func rollingAverageThresholds() {
        let updater = ProfileUpdater()
        var profile = LearnerProfile.createDefault()

        // governingThought: max 3, threshold 0.8 → needs avg ≥ 2.4
        // Give score of 2 (avg = 2/3 = 0.67) — should be neither strength nor weakness
        let midMetadata = Self.makeMetadata(scores: ["governingThought": 2])
        updater.updateProfile(&profile, from: midMetadata, sessionType: "say-it-clearly")

        #expect(!profile.structuralStrengths.contains("governingThought"))
        #expect(!profile.developmentAreas.contains("governingThought"))
    }

    @Test("Revision improvement tracked via multiple metadata blocks")
    func revisionImprovement() {
        let updater = ProfileUpdater()
        var profile = LearnerProfile.createDefault()

        let firstDraft = Self.makeMetadata(
            scores: ["governingThought": 1, "clarity": 1],
            revisionRound: 0
        )
        let revision = Self.makeMetadata(
            scores: ["governingThought": 3, "clarity": 2],
            revisionRound: 1
        )

        updater.updateProfile(&profile, from: [firstDraft, revision], sessionType: "say-it-clearly")

        // Both scores recorded — profile shows improvement trajectory
        #expect(profile.dimensionScores["governingThought"] == [1, 3])
        #expect(profile.dimensionScores["clarity"] == [1, 2])
    }

    @Test("applySessionResults saves to store")
    func appliesViaStore() async throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let store = await LearnerProfileStore(directory: tmpDir)
        let updater = ProfileUpdater()

        try await updater.applySessionResults(
            store: store,
            metadataList: [Self.makeMetadata()],
            sessionType: "say-it-clearly"
        )

        let profile = await store.current
        #expect(profile.sessionCount == 1)
        #expect(profile.dimensionScores["governingThought"] == [2])
    }
}
