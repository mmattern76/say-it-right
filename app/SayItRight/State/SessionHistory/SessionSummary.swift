import Foundation

/// Summary of a completed coaching session, stored for history and progress tracking.
struct SessionSummary: Codable, Sendable, Identifiable {
    let id: String
    let date: Date
    let sessionType: String
    let topicTitle: String
    let language: String
    let attemptCount: Int
    let dimensionScores: [String: Int]
    let overallAssessment: String
    let barbaraSummary: String
    let levelAtSession: Int

    init(
        id: String = UUID().uuidString,
        date: Date = .now,
        sessionType: String,
        topicTitle: String,
        language: String = "en",
        attemptCount: Int = 1,
        dimensionScores: [String: Int] = [:],
        overallAssessment: String = "",
        barbaraSummary: String = "",
        levelAtSession: Int = 1
    ) {
        self.id = id
        self.date = date
        self.sessionType = sessionType
        self.topicTitle = topicTitle
        self.language = language
        self.attemptCount = attemptCount
        self.dimensionScores = dimensionScores
        self.overallAssessment = overallAssessment
        self.barbaraSummary = barbaraSummary
        self.levelAtSession = levelAtSession
    }
}
