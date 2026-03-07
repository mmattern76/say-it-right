import Foundation
import Testing
@testable import SayItRight

@Suite("DimensionBarChartView")
struct DimensionBarChartTests {

    @Test("Display name for governingThought in English")
    func displayNameEN() {
        let name = DimensionBarChartView.displayName(for: "governingThought", language: "en")
        #expect(name == "Leading with your point")
    }

    @Test("Display name for governingThought in German")
    func displayNameDE() {
        let name = DimensionBarChartView.displayName(for: "governingThought", language: "de")
        #expect(name == "Mit dem Kerngedanken führen")
    }

    @Test("Display name for unknown dimension returns raw key")
    func displayNameUnknown() {
        let name = DimensionBarChartView.displayName(for: "unknownDimension", language: "en")
        #expect(name == "unknownDimension")
    }

    @Test("All known dimensions have display names")
    func allDimensionsHaveNames() {
        let dimensions = [
            "governingThought", "supportGrouping", "redundancy", "clarity",
            "l1Gate", "meceQuality", "orderingLogic", "scqApplication", "horizontalLogic"
        ]
        for dim in dimensions {
            let nameEN = DimensionBarChartView.displayName(for: dim, language: "en")
            let nameDE = DimensionBarChartView.displayName(for: dim, language: "de")
            #expect(nameEN != dim, "Missing EN name for \(dim)")
            #expect(nameDE != dim, "Missing DE name for \(dim)")
        }
    }

    @Test("maxScoreFor returns expected values")
    func maxScores() {
        #expect(DimensionBarChartView.maxScoreFor("governingThought") == 3)
        #expect(DimensionBarChartView.maxScoreFor("supportGrouping") == 2)
        #expect(DimensionBarChartView.maxScoreFor("redundancy") == 2)
        #expect(DimensionBarChartView.maxScoreFor("clarity") == 3)
        #expect(DimensionBarChartView.maxScoreFor("unknownDimension") == 3)
    }
}

@Suite("ProgressDashboard — Preview Data")
struct ProgressDashboardPreviewTests {

    @Test("Preview populated profile has expected values")
    func previewPopulated() {
        let profile = LearnerProfile.previewPopulated
        #expect(profile.sessionCount == 12)
        #expect(profile.currentStreak == 3)
        #expect(profile.longestStreak == 7)
        #expect(profile.currentLevel == 1)
        #expect(!profile.dimensionScores.isEmpty)
        #expect(profile.structuralStrengths.contains("governingThought"))
        #expect(profile.developmentAreas.contains("supportGrouping"))
    }

    @Test("Empty profile has zero sessions")
    func emptyProfile() {
        let profile = LearnerProfile.createDefault(displayName: "Test")
        #expect(profile.sessionCount == 0)
        #expect(profile.dimensionScores.isEmpty)
    }
}
