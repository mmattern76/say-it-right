import Foundation
import Testing
@testable import SayItRight

@Suite("Break Mode Profile Integration")
struct BreakModeProfileTests {

    // MARK: - Dimension Definitions

    @Test("Break mode dimensions defined in ProfileUpdater")
    func breakDimensionsDefined() {
        let breakDims = ProfileUpdater.breakDimensions
        #expect(breakDims.contains("extractionAccuracy"))
        #expect(breakDims.contains("flawIdentification"))
        #expect(breakDims.contains("restructuringQuality"))
        #expect(breakDims.count == 3)
    }

    @Test("Break dimensions have max scores")
    func breakDimensionMaxScores() {
        for dim in ProfileUpdater.breakDimensions {
            let maxScore = ProfileUpdater.maxScores[dim]
            #expect(maxScore != nil, "Missing max score for \(dim)")
            #expect(maxScore! > 0, "Max score for \(dim) must be > 0")
        }
    }

    @Test("Build dimensions defined in ProfileUpdater")
    func buildDimensionsDefined() {
        #expect(ProfileUpdater.buildDimensionsL1.count == 4)
        #expect(ProfileUpdater.buildDimensionsL2.count == 5)
    }

    // MARK: - Profile Updates with Break Scores

    @Test("Break dimension scores recorded in profile")
    func breakScoresRecorded() {
        var profile = LearnerProfile.createDefault(displayName: "Test")

        profile.recordScore(2, for: "extractionAccuracy")
        profile.recordScore(3, for: "flawIdentification")
        profile.recordScore(1, for: "restructuringQuality")

        #expect(profile.dimensionScores["extractionAccuracy"] == [2])
        #expect(profile.dimensionScores["flawIdentification"] == [3])
        #expect(profile.dimensionScores["restructuringQuality"] == [1])
    }

    @Test("Rolling averages work for Break dimensions")
    func breakRollingAverages() {
        var profile = LearnerProfile.createDefault(displayName: "Test")

        for score in [1, 2, 3, 2, 3] {
            profile.recordScore(score, for: "extractionAccuracy")
        }

        let avg = profile.rollingAverage(for: "extractionAccuracy")
        #expect(avg == 2.2)
    }

    @Test("ProfileUpdater handles Break dimension scores")
    func profileUpdaterBreakScores() {
        let updater = ProfileUpdater()
        var profile = LearnerProfile.createDefault(displayName: "Test")

        let metadata = BarbaraMetadata(
            scores: [
                "extractionAccuracy": 3,
                "flawIdentification": 2,
            ],
            totalScore: 5,
            mood: .evaluating,
            progressionSignal: .improving,
            revisionRound: 0,
            sessionPhase: .evaluation,
            feedbackFocus: "extraction",
            language: "en"
        )

        updater.updateProfile(&profile, from: metadata, sessionType: "find-the-point")
        #expect(profile.dimensionScores["extractionAccuracy"] == [3])
        #expect(profile.dimensionScores["flawIdentification"] == [2])
        #expect(profile.sessionCount == 1)
    }

    @Test("Strengths and weaknesses include Break dimensions")
    func strengthsAndWeaknessesIncludeBreak() {
        let updater = ProfileUpdater()
        var profile = LearnerProfile.createDefault(displayName: "Test")

        // Strong extraction (max 3, scores avg 3.0 → 100%)
        for _ in 0..<5 {
            profile.recordScore(3, for: "extractionAccuracy")
        }

        // Weak flaw identification (max 3, scores avg 1.0 → 33%)
        for _ in 0..<5 {
            profile.recordScore(1, for: "flawIdentification")
        }

        // Trigger strength recalculation
        let metadata = BarbaraMetadata(
            scores: ["extractionAccuracy": 3],
            totalScore: 3,
            mood: .evaluating,
            progressionSignal: .none,
            revisionRound: 0,
            sessionPhase: .evaluation,
            feedbackFocus: "extraction",
            language: "en"
        )
        updater.updateProfile(&profile, from: metadata, sessionType: "find-the-point")

        #expect(profile.structuralStrengths.contains("extractionAccuracy"))
        #expect(profile.developmentAreas.contains("flawIdentification"))
    }

    // MARK: - Adaptive Difficulty

    @Test("L2 dimensions include Break mode")
    func l2DimensionsIncludeBreak() {
        let dims = AdaptiveDifficultyEngine.dimensionsForLevel(2)
        #expect(dims.contains("extractionAccuracy"))
        #expect(dims.contains("flawIdentification"))
        #expect(dims.contains("restructuringQuality"))
        // Also includes Build dimensions
        #expect(dims.contains("meceQuality"))
    }

    @Test("L1 dimensions do not include Break mode")
    func l1DimensionsExcludeBreak() {
        let dims = AdaptiveDifficultyEngine.dimensionsForLevel(1)
        #expect(!dims.contains("extractionAccuracy"))
        #expect(!dims.contains("flawIdentification"))
        #expect(!dims.contains("restructuringQuality"))
    }

    // MARK: - Level Transition

    @Test("L2 progression requires Break dimensions")
    func l2ProgressionRequiresBreak() {
        let criteria = ProgressionCriteria.default.criteria(fromLevel: 2)
        #expect(criteria != nil)
        #expect(criteria!.requiredDimensions.contains("extractionAccuracy"))
        #expect(criteria!.requiredDimensions.contains("flawIdentification"))
        #expect(criteria!.requiredDimensions.contains("restructuringQuality"))
    }

    @Test("L1 progression does not require Break dimensions")
    func l1ProgressionNoBreak() {
        let criteria = ProgressionCriteria.default.criteria(fromLevel: 1)
        #expect(criteria != nil)
        #expect(!criteria!.requiredDimensions.contains("extractionAccuracy"))
    }

    // MARK: - Dashboard Display Names

    @Test("Break dimensions have display names in English")
    func breakDimensionDisplayNamesEN() {
        let name = DimensionBarChartView.displayName(for: "extractionAccuracy", language: "en")
        #expect(name == "Extracting structure")

        let name2 = DimensionBarChartView.displayName(for: "flawIdentification", language: "en")
        #expect(name2 == "Finding structural flaws")

        let name3 = DimensionBarChartView.displayName(for: "restructuringQuality", language: "en")
        #expect(name3 == "Restructuring quality")
    }

    @Test("Break dimensions have display names in German")
    func breakDimensionDisplayNamesDE() {
        let name = DimensionBarChartView.displayName(for: "extractionAccuracy", language: "de")
        #expect(name == "Struktur erkennen")
    }

    @Test("Break dimensions have max scores in bar chart")
    func breakDimensionMaxScoresChart() {
        let max1 = DimensionBarChartView.maxScoreFor("extractionAccuracy")
        #expect(max1 == 3)

        let max2 = DimensionBarChartView.maxScoreFor("flawIdentification")
        #expect(max2 == 3)
    }

    // MARK: - TextDifficultyCalibrator

    @Test("TextDifficultyCalibrator uses ProfileUpdater break dimensions")
    func calibratorBreakDimensions() {
        #expect(TextDifficultyCalibrator.breakDimensions == ProfileUpdater.breakDimensions)
    }
}
