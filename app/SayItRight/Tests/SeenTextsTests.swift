import Testing
import Foundation
@testable import SayItRight

// MARK: - Test Helpers

private func makeText(id: String, level: Int = 1, language: String = "en", quality: QualityLevel = .wellStructured, domain: String = "general") -> PracticeText {
    PracticeText(
        id: id,
        text: "Sample text for \(id)",
        answerKey: AnswerKey(
            governingThought: "Main point",
            supports: [SupportGroup(label: "Support", evidence: ["Evidence"])],
            structuralAssessment: "Good structure"
        ),
        metadata: PracticeTextMetadata(
            qualityLevel: quality,
            difficultyRating: 1,
            topicDomain: domain,
            language: language,
            wordCount: 100,
            targetLevel: level
        )
    )
}

private func makeLibrary(_ texts: [PracticeText]) -> PracticeTextLibrary {
    PracticeTextLibrary(texts: texts)
}

// MARK: - SeenTextsRecord Tests

@Suite("SeenTextsRecord")
struct SeenTextsRecordTests {

    @Test func markSeenAddsEntry() {
        var record = SeenTextsRecord()
        record.markSeen(textID: "pt-001", sessionType: "find-the-point")
        let seen = record.seenIDs(for: "find-the-point")
        #expect(seen.contains("pt-001"))
        #expect(seen.count == 1)
    }

    @Test func markSeenMultipleTexts() {
        var record = SeenTextsRecord()
        record.markSeen(textID: "pt-001", sessionType: "find-the-point")
        record.markSeen(textID: "pt-002", sessionType: "find-the-point")
        record.markSeen(textID: "pt-003", sessionType: "find-the-point")
        let seen = record.seenIDs(for: "find-the-point")
        #expect(seen.count == 3)
        #expect(seen == Set(["pt-001", "pt-002", "pt-003"]))
    }

    @Test func seenIDsPerSessionType() {
        var record = SeenTextsRecord()
        record.markSeen(textID: "pt-001", sessionType: "find-the-point")
        record.markSeen(textID: "pt-002", sessionType: "fix-this-mess")

        let findSeen = record.seenIDs(for: "find-the-point")
        let fixSeen = record.seenIDs(for: "fix-this-mess")

        #expect(findSeen == Set(["pt-001"]))
        #expect(fixSeen == Set(["pt-002"]))
    }

    @Test func sameTextDifferentSessionTypes() {
        var record = SeenTextsRecord()
        record.markSeen(textID: "pt-001", sessionType: "find-the-point")

        // Same text NOT marked as seen for different session type
        let fixSeen = record.seenIDs(for: "fix-this-mess")
        #expect(!fixSeen.contains("pt-001"))

        // Mark it for the other session type too
        record.markSeen(textID: "pt-001", sessionType: "fix-this-mess")
        #expect(record.seenIDs(for: "fix-this-mess").contains("pt-001"))
    }

    @Test func seenIDsEmptyForUnknownSessionType() {
        let record = SeenTextsRecord()
        #expect(record.seenIDs(for: "nonexistent").isEmpty)
    }

    @Test func markSeenRecordsDate() {
        var record = SeenTextsRecord()
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        record.markSeen(textID: "pt-001", sessionType: "find-the-point", date: fixedDate)

        let storedDate = record.entries["find-the-point"]?["pt-001"]
        #expect(storedDate == fixedDate)
    }

    @Test func markSeenUpdatesDate() {
        var record = SeenTextsRecord()
        let date1 = Date(timeIntervalSince1970: 1_700_000_000)
        let date2 = Date(timeIntervalSince1970: 1_700_100_000)

        record.markSeen(textID: "pt-001", sessionType: "find-the-point", date: date1)
        record.markSeen(textID: "pt-001", sessionType: "find-the-point", date: date2)

        let storedDate = record.entries["find-the-point"]?["pt-001"]
        #expect(storedDate == date2)
        #expect(record.seenIDs(for: "find-the-point").count == 1)
    }

    @Test func unseenTextsReturnsOnlyUnseen() {
        let texts = [
            makeText(id: "pt-001", level: 1),
            makeText(id: "pt-002", level: 1),
            makeText(id: "pt-003", level: 1),
        ]
        let library = makeLibrary(texts)

        var record = SeenTextsRecord()
        record.markSeen(textID: "pt-001", sessionType: "find-the-point")

        let unseen = record.unseenTexts(
            sessionType: "find-the-point",
            level: 1,
            language: "en",
            library: library
        )
        #expect(unseen != nil)
        #expect(unseen!.count == 2)
        #expect(unseen!.map(\.id).sorted() == ["pt-002", "pt-003"])
    }

    @Test func unseenTextsReturnsNilWhenExhausted() {
        let texts = [
            makeText(id: "pt-001", level: 1),
            makeText(id: "pt-002", level: 1),
        ]
        let library = makeLibrary(texts)

        var record = SeenTextsRecord()
        record.markSeen(textID: "pt-001", sessionType: "find-the-point")
        record.markSeen(textID: "pt-002", sessionType: "find-the-point")

        let unseen = record.unseenTexts(
            sessionType: "find-the-point",
            level: 1,
            language: "en",
            library: library
        )
        #expect(unseen == nil)
    }

    @Test func unseenTextsFiltersbyLanguage() {
        let texts = [
            makeText(id: "pt-001-en", level: 1, language: "en"),
            makeText(id: "pt-001-de", level: 1, language: "de"),
        ]
        let library = makeLibrary(texts)

        var record = SeenTextsRecord()
        record.markSeen(textID: "pt-001-en", sessionType: "find-the-point")

        let unseenEN = record.unseenTexts(
            sessionType: "find-the-point",
            level: 1,
            language: "en",
            library: library
        )
        #expect(unseenEN == nil) // only EN text was seen, and only EN text exists

        let unseenDE = record.unseenTexts(
            sessionType: "find-the-point",
            level: 1,
            language: "de",
            library: library
        )
        #expect(unseenDE != nil)
        #expect(unseenDE!.count == 1)
    }

    @Test func unseenTextsFiltersByLevel() {
        let texts = [
            makeText(id: "pt-001", level: 1),
            makeText(id: "pt-002", level: 2),
        ]
        let library = makeLibrary(texts)

        var record = SeenTextsRecord()
        record.markSeen(textID: "pt-001", sessionType: "find-the-point")

        // Level 1: exhausted
        let unseenL1 = record.unseenTexts(
            sessionType: "find-the-point",
            level: 1,
            language: "en",
            library: library
        )
        #expect(unseenL1 == nil)

        // Level 2: still has unseen
        let unseenL2 = record.unseenTexts(
            sessionType: "find-the-point",
            level: 2,
            language: "en",
            library: library
        )
        #expect(unseenL2 != nil)
        #expect(unseenL2!.count == 1)
    }

    @Test func resetForLevelClearsOnlyThatLevel() {
        let texts = [
            makeText(id: "pt-001", level: 1),
            makeText(id: "pt-002", level: 1),
            makeText(id: "pt-003", level: 2),
        ]
        let library = makeLibrary(texts)

        var record = SeenTextsRecord()
        record.markSeen(textID: "pt-001", sessionType: "find-the-point")
        record.markSeen(textID: "pt-002", sessionType: "find-the-point")
        record.markSeen(textID: "pt-003", sessionType: "find-the-point")

        record.resetForLevel(sessionType: "find-the-point", level: 1, language: "en", library: library)

        let seen = record.seenIDs(for: "find-the-point")
        #expect(!seen.contains("pt-001"))
        #expect(!seen.contains("pt-002"))
        #expect(seen.contains("pt-003")) // Level 2 not reset
    }

    @Test func resetForLevelDoesNotAffectOtherSessionTypes() {
        let texts = [makeText(id: "pt-001", level: 1)]
        let library = makeLibrary(texts)

        var record = SeenTextsRecord()
        record.markSeen(textID: "pt-001", sessionType: "find-the-point")
        record.markSeen(textID: "pt-001", sessionType: "fix-this-mess")

        record.resetForLevel(sessionType: "find-the-point", level: 1, language: "en", library: library)

        #expect(record.seenIDs(for: "find-the-point").isEmpty)
        #expect(record.seenIDs(for: "fix-this-mess").contains("pt-001"))
    }

    @Test func emptyLibraryUnseenTextsReturnsEmptyArray() {
        let library = makeLibrary([])
        let record = SeenTextsRecord()

        let unseen = record.unseenTexts(
            sessionType: "find-the-point",
            level: 1,
            language: "en",
            library: library
        )
        #expect(unseen != nil)
        #expect(unseen!.isEmpty)
    }

    @Test func codableRoundTrip() throws {
        var record = SeenTextsRecord()
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        record.markSeen(textID: "pt-001", sessionType: "find-the-point", date: date)
        record.markSeen(textID: "pt-002", sessionType: "fix-this-mess", date: date)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(record)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SeenTextsRecord.self, from: data)

        #expect(decoded == record)
        #expect(decoded.seenIDs(for: "find-the-point") == Set(["pt-001"]))
        #expect(decoded.seenIDs(for: "fix-this-mess") == Set(["pt-002"]))
    }
}

// MARK: - SeenTextsStore Tests

@Suite("SeenTextsStore")
struct SeenTextsStoreTests {

    @Test func createWithEmptyState() async {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let store = SeenTextsStore(directory: tmpDir)
        let record = await store.current
        #expect(record.entries.isEmpty)
    }

    @Test func markSeenPersists() async throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let store1 = SeenTextsStore(directory: tmpDir)
        try await store1.markSeen(textID: "pt-001", sessionType: "find-the-point")

        // Reload from disk
        let store2 = SeenTextsStore(directory: tmpDir)
        let seen = await store2.seenIDs(for: "find-the-point")
        #expect(seen.contains("pt-001"))
    }

    @Test func resetClearsAllData() async throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let store = SeenTextsStore(directory: tmpDir)
        try await store.markSeen(textID: "pt-001", sessionType: "find-the-point")
        try await store.reset()

        let record = await store.current
        #expect(record.entries.isEmpty)
    }

    @Test func selectUnseenTextReturnsText() async throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let texts = [
            makeText(id: "pt-001", level: 1),
            makeText(id: "pt-002", level: 1),
        ]
        let library = makeLibrary(texts)

        let store = SeenTextsStore(directory: tmpDir)
        try await store.markSeen(textID: "pt-001", sessionType: "find-the-point")

        let result = try await store.selectUnseenText(
            sessionType: "find-the-point",
            level: 1,
            language: "en",
            library: library
        )
        #expect(result != nil)
        #expect(result!.text.id == "pt-002")
        #expect(result!.didReset == false)
    }

    @Test func selectUnseenTextResetsWhenExhausted() async throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let texts = [
            makeText(id: "pt-001", level: 1),
            makeText(id: "pt-002", level: 1),
        ]
        let library = makeLibrary(texts)

        let store = SeenTextsStore(directory: tmpDir)
        try await store.markSeen(textID: "pt-001", sessionType: "find-the-point")
        try await store.markSeen(textID: "pt-002", sessionType: "find-the-point")

        let result = try await store.selectUnseenText(
            sessionType: "find-the-point",
            level: 1,
            language: "en",
            library: library
        )
        #expect(result != nil)
        #expect(result!.didReset == true)
        #expect(["pt-001", "pt-002"].contains(result!.text.id))

        // After reset, seen IDs for level 1 should be cleared
        let seen = await store.seenIDs(for: "find-the-point")
        #expect(seen.isEmpty)
    }

    @Test func selectUnseenTextReturnsNilForEmptyLibrary() async throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let library = makeLibrary([])
        let store = SeenTextsStore(directory: tmpDir)

        let result = try await store.selectUnseenText(
            sessionType: "find-the-point",
            level: 1,
            language: "en",
            library: library
        )
        #expect(result == nil)
    }

    @Test func exhaustionMessageEnglish() {
        let msg = SeenTextsStore.exhaustionMessage(language: "en")
        #expect(msg.contains("entire collection"))
        #expect(msg.contains("revisit"))
    }

    @Test func exhaustionMessageGerman() {
        let msg = SeenTextsStore.exhaustionMessage(language: "de")
        #expect(msg.contains("gesamte Sammlung"))
        #expect(msg.contains("nochmal"))
    }

    @Test func persistenceRoundTrip() async throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let store1 = SeenTextsStore(directory: tmpDir)
        try await store1.markSeen(textID: "pt-001", sessionType: "find-the-point")
        try await store1.markSeen(textID: "pt-002", sessionType: "fix-this-mess")
        try await store1.markSeen(textID: "pt-003", sessionType: "find-the-point")

        // Verify JSON file exists
        let fileURL = tmpDir.appendingPathComponent("seen-texts.json")
        #expect(FileManager.default.fileExists(atPath: fileURL.path))

        // Reload and verify
        let store2 = SeenTextsStore(directory: tmpDir)
        let findSeen = await store2.seenIDs(for: "find-the-point")
        let fixSeen = await store2.seenIDs(for: "fix-this-mess")

        #expect(findSeen == Set(["pt-001", "pt-003"]))
        #expect(fixSeen == Set(["pt-002"]))
    }
}
