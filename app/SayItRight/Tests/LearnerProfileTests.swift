import Testing
import Foundation
@testable import SayItRight

@Suite("LearnerProfile")
struct LearnerProfileTests {

    @Test func createDefault() {
        let profile = LearnerProfile.createDefault(displayName: "Test", language: "de")
        #expect(profile.currentLevel == 1)
        #expect(profile.displayName == "Test")
        #expect(profile.language == "de")
        #expect(profile.sessionCount == 0)
        #expect(profile.currentStreak == 0)
        #expect(profile.developmentAreas.contains("governing_thought"))
        #expect(profile.structuralStrengths.isEmpty)
        #expect(profile.dimensionScores.isEmpty)
    }

    @Test func recordScoreKeepsLast10() {
        var profile = LearnerProfile.createDefault()
        for i in 1...15 {
            profile.recordScore(i, for: "clarity")
        }
        let scores = profile.dimensionScores["clarity"]!
        #expect(scores.count == 10)
        #expect(scores.first == 6)
        #expect(scores.last == 15)
    }

    @Test func rollingAverage() {
        var profile = LearnerProfile.createDefault()
        profile.recordScore(4, for: "grouping_mece")
        profile.recordScore(6, for: "grouping_mece")
        let avg = profile.rollingAverage(for: "grouping_mece")
        #expect(avg == 5.0)
    }

    @Test func rollingAverageNilForMissing() {
        let profile = LearnerProfile.createDefault()
        #expect(profile.rollingAverage(for: "nonexistent") == nil)
    }

    @Test func updateStreakFirstSession() {
        var profile = LearnerProfile.createDefault()
        profile.updateStreak()
        #expect(profile.currentStreak == 1)
        #expect(profile.longestStreak == 1)
        #expect(profile.lastSessionDate != nil)
    }

    @Test func updateStreakConsecutiveDays() {
        var profile = LearnerProfile.createDefault()
        let yesterday = Calendar.current.date(byAdding: .hour, value: -20, to: .now)!
        profile.updateStreak(now: yesterday)
        #expect(profile.currentStreak == 1)
        profile.updateStreak(now: .now)
        #expect(profile.currentStreak == 2)
        #expect(profile.longestStreak == 2)
    }

    @Test func updateStreakResetsAfterGap() {
        var profile = LearnerProfile.createDefault()
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: .now)!
        profile.updateStreak(now: threeDaysAgo)
        #expect(profile.currentStreak == 1)
        profile.updateStreak(now: .now)
        #expect(profile.currentStreak == 1)
        #expect(profile.longestStreak == 1)
    }

    @Test func toPromptJSONExcludesInternalFields() throws {
        let profile = LearnerProfile.createDefault(displayName: "Alice", language: "en")
        let json = profile.toPromptJSON()
        #expect(json.contains("Alice"))
        #expect(json.contains("currentLevel"))
        #expect(!json.contains("schemaVersion"))
        #expect(!json.contains("levelHistory"))
    }

    @Test func codableRoundTrip() throws {
        var profile = LearnerProfile.createDefault(displayName: "Bob", language: "de")
        profile.recordScore(7, for: "lead_position")
        profile.updateStreak()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(profile)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(LearnerProfile.self, from: data)

        #expect(decoded.displayName == "Bob")
        #expect(decoded.language == "de")
        #expect(decoded.dimensionScores["lead_position"] == [7])
        #expect(decoded.currentStreak == 1)
    }
}

@Suite("LearnerProfileStore")
struct LearnerProfileStoreTests {

    @Test func createAndLoad() async throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let store = await LearnerProfileStore(directory: tmpDir)
        let profile = await store.current
        #expect(profile.currentLevel == 1)
        #expect(profile.sessionCount == 0)
    }

    @Test func saveAndReload() async throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let store1 = await LearnerProfileStore(directory: tmpDir)
        try await store1.update { profile in
            profile.displayName = "Saved"
            profile.recordScore(8, for: "clarity")
        }

        let store2 = await LearnerProfileStore(directory: tmpDir)
        let reloaded = await store2.current
        #expect(reloaded.displayName == "Saved")
        #expect(reloaded.dimensionScores["clarity"] == [8])
    }

    @Test func reset() async throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let store = await LearnerProfileStore(directory: tmpDir)
        try await store.update { $0.displayName = "Modified" }
        try await store.reset()
        let profile = await store.current
        #expect(profile.displayName == "")
    }
}
