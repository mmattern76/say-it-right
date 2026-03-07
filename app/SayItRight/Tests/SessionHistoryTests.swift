import Foundation
import Testing
@testable import SayItRight

@Suite("SessionSummary")
struct SessionSummaryTests {

    @Test("Summary initialises with defaults")
    func initialisation() {
        let summary = SessionSummary(
            sessionType: "say-it-clearly",
            topicTitle: "Test Topic"
        )

        #expect(!summary.id.isEmpty)
        #expect(summary.sessionType == "say-it-clearly")
        #expect(summary.topicTitle == "Test Topic")
        #expect(summary.attemptCount == 1)
        #expect(summary.dimensionScores.isEmpty)
        #expect(summary.overallAssessment.isEmpty)
        #expect(summary.barbaraSummary.isEmpty)
        #expect(summary.levelAtSession == 1)
        #expect(summary.language == "en")
    }

    @Test("Summary is Codable")
    func codableRoundTrip() throws {
        let original = SessionSummary(
            sessionType: "find-the-point",
            topicTitle: "Climate policy",
            language: "de",
            attemptCount: 3,
            dimensionScores: ["governingThought": 2, "clarity": 3],
            overallAssessment: "Good work",
            barbaraSummary: "Strong lead.",
            levelAtSession: 2
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SessionSummary.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.sessionType == original.sessionType)
        #expect(decoded.topicTitle == original.topicTitle)
        #expect(decoded.language == "de")
        #expect(decoded.attemptCount == 3)
        #expect(decoded.dimensionScores["governingThought"] == 2)
        #expect(decoded.dimensionScores["clarity"] == 3)
        #expect(decoded.overallAssessment == "Good work")
        #expect(decoded.barbaraSummary == "Strong lead.")
        #expect(decoded.levelAtSession == 2)
    }
}

@Suite("SessionHistoryStore")
struct SessionHistoryStoreTests {

    private func makeTempDir() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("session-history-test-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test("Store starts empty")
    func emptyStore() async {
        let store = await SessionHistoryStore(directory: makeTempDir())
        let count = await store.count
        #expect(count == 0)
    }

    @Test("Append and read session")
    func appendAndRead() async throws {
        let dir = makeTempDir()
        let store = await SessionHistoryStore(directory: dir)

        let summary = SessionSummary(
            sessionType: "say-it-clearly",
            topicTitle: "School uniforms"
        )

        try await store.append(summary)

        let count = await store.count
        #expect(count == 1)

        let all = await store.allSessions
        #expect(all.first?.topicTitle == "School uniforms")
    }

    @Test("Recent sessions returns newest first")
    func recentOrder() async throws {
        let dir = makeTempDir()
        let store = await SessionHistoryStore(directory: dir)

        let older = SessionSummary(
            date: Date.now.addingTimeInterval(-3600),
            sessionType: "say-it-clearly",
            topicTitle: "Older"
        )
        let newer = SessionSummary(
            date: .now,
            sessionType: "find-the-point",
            topicTitle: "Newer"
        )

        try await store.append(older)
        try await store.append(newer)

        let recent = await store.recentSessions(5)
        #expect(recent.count == 2)
        #expect(recent[0].topicTitle == "Newer")
        #expect(recent[1].topicTitle == "Older")
    }

    @Test("Persistence round-trip")
    func persistence() async throws {
        let dir = makeTempDir()

        let store1 = await SessionHistoryStore(directory: dir)
        try await store1.append(SessionSummary(
            sessionType: "elevator-pitch",
            topicTitle: "Persisted Topic"
        ))

        // Create a new store reading from same directory
        let store2 = await SessionHistoryStore(directory: dir)
        let count = await store2.count
        #expect(count == 1)

        let all = await store2.allSessions
        #expect(all.first?.topicTitle == "Persisted Topic")
    }

    @Test("Prunes oldest when over 200 limit")
    func pruning() async throws {
        let dir = makeTempDir()
        let store = await SessionHistoryStore(directory: dir)

        for i in 0..<205 {
            try await store.append(SessionSummary(
                date: Date.now.addingTimeInterval(Double(i)),
                sessionType: "say-it-clearly",
                topicTitle: "Session \(i)"
            ))
        }

        let count = await store.count
        #expect(count == 200)
    }

    @Test("Remove all clears history")
    func removeAll() async throws {
        let dir = makeTempDir()
        let store = await SessionHistoryStore(directory: dir)

        try await store.append(SessionSummary(
            sessionType: "say-it-clearly",
            topicTitle: "To be removed"
        ))

        try await store.removeAll()
        let count = await store.count
        #expect(count == 0)
    }
}
