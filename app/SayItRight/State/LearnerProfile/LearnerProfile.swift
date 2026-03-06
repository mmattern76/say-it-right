import Foundation

/// The learner's structural thinking profile — drives Barbara's coaching behavior.
struct LearnerProfile: Codable, Sendable {
    var schemaVersion: Int = 1
    var id: String
    var displayName: String
    var currentLevel: Int
    var language: String
    var structuralStrengths: [String]
    var developmentAreas: [String]
    var sessionCount: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastSessionDate: Date?
    var levelHistory: [LevelTransition]
    var dimensionScores: [String: [Int]]

    struct LevelTransition: Codable, Sendable {
        let fromLevel: Int
        let toLevel: Int
        let date: Date
    }

    /// Create a new default profile for first launch.
    static func createDefault(displayName: String = "", language: String = "en") -> LearnerProfile {
        LearnerProfile(
            id: UUID().uuidString,
            displayName: displayName,
            currentLevel: 1,
            language: language,
            structuralStrengths: [],
            developmentAreas: ["governing_thought", "lead_position", "clarity"],
            sessionCount: 0,
            currentStreak: 0,
            longestStreak: 0,
            lastSessionDate: nil,
            levelHistory: [],
            dimensionScores: [:]
        )
    }

    /// Rolling average for a dimension (last 10 scores).
    func rollingAverage(for dimension: String) -> Double? {
        guard let scores = dimensionScores[dimension], !scores.isEmpty else { return nil }
        let recent = scores.suffix(10)
        return Double(recent.reduce(0, +)) / Double(recent.count)
    }

    /// Record a new score for a dimension (keeps last 10).
    mutating func recordScore(_ score: Int, for dimension: String) {
        var scores = dimensionScores[dimension] ?? []
        scores.append(score)
        if scores.count > 10 {
            scores = Array(scores.suffix(10))
        }
        dimensionScores[dimension] = scores
    }

    /// Update streak based on current date.
    mutating func updateStreak(now: Date = .now) {
        let calendar = Calendar.current
        if let lastDate = lastSessionDate {
            let daysSince = calendar.dateComponents([.day], from: lastDate, to: now).day ?? 0
            if daysSince <= 1 {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }
        longestStreak = max(longestStreak, currentStreak)
        lastSessionDate = now
    }

    /// JSON representation for system prompt injection.
    func toPromptJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(PromptProfile(from: self)),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }
}

/// Simplified profile for prompt injection (excludes internal tracking data).
private struct PromptProfile: Codable {
    let displayName: String
    let currentLevel: Int
    let strengths: [String]
    let developmentAreas: [String]
    let sessionsCompleted: Int
    let streakDays: Int
    let recentScores: [String: [Int]]
    let notes: String

    init(from profile: LearnerProfile) {
        displayName = profile.displayName
        currentLevel = profile.currentLevel
        strengths = profile.structuralStrengths
        developmentAreas = profile.developmentAreas
        sessionsCompleted = profile.sessionCount
        streakDays = profile.currentStreak
        recentScores = profile.dimensionScores
        notes = ""
    }
}
