import Foundation

/// Defines criteria for advancing from one level to the next.
struct LevelCriteria: Codable, Sendable {
    /// The level being graduated FROM (e.g., 1 means L1→L2).
    let fromLevel: Int
    /// Minimum normalised rolling average (0-1) per dimension to qualify.
    let minDimensionAverage: Double
    /// Dimensions that must all meet the threshold.
    let requiredDimensions: [String]
    /// Minimum consecutive qualifying sessions.
    let minConsecutiveQualifying: Int
    /// Minimum total sessions at this level before promotion.
    let minTotalSessions: Int
}

/// All progression criteria, loaded from bundle or defaults.
struct ProgressionCriteria: Sendable {

    let criteria: [LevelCriteria]

    /// Default criteria for all levels.
    static let `default` = ProgressionCriteria(criteria: [
        LevelCriteria(
            fromLevel: 1,
            minDimensionAverage: 0.75,
            requiredDimensions: ["governingThought", "supportGrouping", "redundancy", "clarity"],
            minConsecutiveQualifying: 5,
            minTotalSessions: 10
        ),
        LevelCriteria(
            fromLevel: 2,
            minDimensionAverage: 0.75,
            requiredDimensions: ["l1Gate", "meceQuality", "orderingLogic", "scqApplication", "horizontalLogic",
                                 "extractionAccuracy", "flawIdentification", "restructuringQuality"],
            minConsecutiveQualifying: 5,
            minTotalSessions: 10
        ),
        LevelCriteria(
            fromLevel: 3,
            minDimensionAverage: 0.80,
            requiredDimensions: ["l1Gate", "meceQuality", "orderingLogic", "scqApplication", "horizontalLogic",
                                 "extractionAccuracy", "flawIdentification", "restructuringQuality"],
            minConsecutiveQualifying: 7,
            minTotalSessions: 15
        ),
    ])

    /// Get criteria for transitioning FROM a specific level.
    func criteria(fromLevel: Int) -> LevelCriteria? {
        criteria.first { $0.fromLevel == fromLevel }
    }
}
