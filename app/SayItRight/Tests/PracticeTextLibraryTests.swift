import Foundation
import Testing
@testable import SayItRight

@Suite("PracticeTextLibrary Tests")
struct PracticeTextLibraryTests {

    // MARK: - JSON Parsing (Container Format)

    @Test("English practice texts parse from container format")
    func englishTextsParse() throws {
        let container = try loadContainer(filename: "PracticeTextLibrary_en")
        #expect(container.texts.count >= 20, "Expected at least 20 English texts, got \(container.texts.count)")
    }

    @Test("German practice texts parse from container format")
    func germanTextsParse() throws {
        let container = try loadContainer(filename: "PracticeTextLibrary_de")
        #expect(container.texts.count >= 20, "Expected at least 20 German texts, got \(container.texts.count)")
    }

    @Test("Total practice text count is at least 40")
    func totalTextCount() throws {
        let en = try loadContainer(filename: "PracticeTextLibrary_en")
        let de = try loadContainer(filename: "PracticeTextLibrary_de")
        let total = en.texts.count + de.texts.count
        #expect(total >= 40, "Expected at least 40 total texts, got \(total)")
    }

    // MARK: - Container Metadata

    @Test("English container has valid content version")
    func englishContentVersion() throws {
        let container = try loadContainer(filename: "PracticeTextLibrary_en")
        let parts = container.contentVersion.split(separator: ".")
        #expect(parts.count == 3, "Content version should be semver, got '\(container.contentVersion)'")
        #expect(parts.allSatisfy { Int($0) != nil }, "Content version parts should be numeric")
    }

    @Test("German container has valid content version")
    func germanContentVersion() throws {
        let container = try loadContainer(filename: "PracticeTextLibrary_de")
        let parts = container.contentVersion.split(separator: ".")
        #expect(parts.count == 3, "Content version should be semver, got '\(container.contentVersion)'")
    }

    @Test("Containers have valid generated date")
    func containerGeneratedDate() throws {
        let en = try loadContainer(filename: "PracticeTextLibrary_en")
        let de = try loadContainer(filename: "PracticeTextLibrary_de")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        #expect(formatter.date(from: en.generatedDate) != nil, "EN generated date invalid: \(en.generatedDate)")
        #expect(formatter.date(from: de.generatedDate) != nil, "DE generated date invalid: \(de.generatedDate)")
    }

    // MARK: - ID Uniqueness

    @Test("All text IDs are unique across both languages")
    func uniqueIDs() throws {
        let allTexts = try loadAllTexts()
        let ids = allTexts.map(\.id)
        let uniqueIDs = Set(ids)
        #expect(ids.count == uniqueIDs.count, "Found duplicate IDs")
    }

    // MARK: - Quality Level Distribution

    @Test("At least 10 well-structured texts total")
    func wellStructuredDistribution() throws {
        let allTexts = try loadAllTexts()
        let count = allTexts.filter { $0.metadata.qualityLevel == .wellStructured }.count
        #expect(count >= 10, "Expected at least 10 well-structured, got \(count)")
    }

    @Test("At least 10 buried-lead texts total")
    func buriedLeadDistribution() throws {
        let allTexts = try loadAllTexts()
        let count = allTexts.filter { $0.metadata.qualityLevel == .buriedLead }.count
        #expect(count >= 10, "Expected at least 10 buried-lead, got \(count)")
    }

    @Test("At least 8 rambling texts total")
    func ramblingDistribution() throws {
        let allTexts = try loadAllTexts()
        let count = allTexts.filter { $0.metadata.qualityLevel == .rambling }.count
        #expect(count >= 8, "Expected at least 8 rambling, got \(count)")
    }

    @Test("At least 8 adversarial texts total")
    func adversarialDistribution() throws {
        let allTexts = try loadAllTexts()
        let count = allTexts.filter { $0.metadata.qualityLevel == .adversarial }.count
        #expect(count >= 8, "Expected at least 8 adversarial, got \(count)")
    }

    // MARK: - Domain Coverage

    @Test("At least 3 texts per domain per language")
    func domainCoverage() throws {
        let allTexts = try loadAllTexts()
        let domains = ["everyday", "school", "society", "technology"]
        let languages = ["en", "de"]

        for language in languages {
            for domain in domains {
                let count = allTexts.filter {
                    $0.metadata.topicDomain == domain && $0.metadata.language == language
                }.count
                #expect(count >= 3, "Expected at least 3 \(domain) texts for \(language), got \(count)")
            }
        }
    }

    // MARK: - Metadata Completeness

    @Test("All texts have non-empty required fields")
    func metadataCompleteness() throws {
        let allTexts = try loadAllTexts()
        for text in allTexts {
            #expect(!text.id.isEmpty, "Text has empty ID")
            #expect(!text.text.isEmpty, "Text \(text.id) has empty text content")
            #expect(!text.answerKey.governingThought.isEmpty, "Text \(text.id) has empty governing thought")
            #expect(!text.answerKey.supports.isEmpty, "Text \(text.id) has no supports")
            #expect(!text.answerKey.structuralAssessment.isEmpty, "Text \(text.id) has empty structural assessment")
            #expect(!text.metadata.topicDomain.isEmpty, "Text \(text.id) has empty topic domain")
            #expect(!text.metadata.language.isEmpty, "Text \(text.id) has empty language")
            #expect(text.metadata.wordCount > 0, "Text \(text.id) has zero word count")
            #expect(text.metadata.difficultyRating >= 1 && text.metadata.difficultyRating <= 5,
                    "Text \(text.id) has invalid difficulty rating: \(text.metadata.difficultyRating)")
            #expect(text.metadata.targetLevel >= 1 && text.metadata.targetLevel <= 4,
                    "Text \(text.id) has invalid target level: \(text.metadata.targetLevel)")
        }
    }

    @Test("Adversarial texts have structural flaws")
    func adversarialTextsHaveFlaws() throws {
        let allTexts = try loadAllTexts()
        let adversarial = allTexts.filter { $0.metadata.qualityLevel == .adversarial }
        for text in adversarial {
            #expect(text.answerKey.structuralFlaw != nil,
                    "Adversarial text \(text.id) is missing structural flaw")
        }
    }

    @Test("Rambling texts have proposed restructure")
    func ramblingTextsHaveRestructure() throws {
        let allTexts = try loadAllTexts()
        let rambling = allTexts.filter { $0.metadata.qualityLevel == .rambling }
        for text in rambling {
            #expect(text.answerKey.proposedRestructure != nil,
                    "Rambling text \(text.id) is missing proposed restructure")
        }
    }

    @Test("English texts have language set to en")
    func englishLanguageField() throws {
        let en = try loadContainer(filename: "PracticeTextLibrary_en")
        for text in en.texts {
            #expect(text.metadata.language == "en", "Text \(text.id) in EN file has language \(text.metadata.language)")
        }
    }

    @Test("German texts have language set to de")
    func germanLanguageField() throws {
        let de = try loadContainer(filename: "PracticeTextLibrary_de")
        for text in de.texts {
            #expect(text.metadata.language == "de", "Text \(text.id) in DE file has language \(text.metadata.language)")
        }
    }

    // MARK: - Library Filtering

    @Test("PracticeTextLibrary filters by language")
    func libraryFilterByLanguage() {
        let lib = makeSampleLibrary()
        let en = lib.texts(for: "en")
        let de = lib.texts(for: "de")
        #expect(en.allSatisfy { $0.metadata.language == "en" })
        #expect(de.allSatisfy { $0.metadata.language == "de" })
    }

    @Test("PracticeTextLibrary filters by quality level")
    func libraryFilterByQuality() {
        let lib = makeSampleLibrary()
        let wellStructured = lib.texts(quality: .wellStructured)
        #expect(wellStructured.allSatisfy { $0.metadata.qualityLevel == .wellStructured })
    }

    @Test("PracticeTextLibrary filters by target level")
    func libraryFilterByLevel() {
        let lib = makeSampleLibrary()
        let level1 = lib.texts(forTargetLevel: 1)
        #expect(level1.allSatisfy { $0.metadata.targetLevel <= 1 })
    }

    @Test("PracticeTextLibrary filters by domain")
    func libraryFilterByDomain() {
        let lib = makeSampleLibrary()
        let tech = lib.texts(domain: "technology")
        #expect(tech.allSatisfy { $0.metadata.topicDomain == "technology" })
    }

    @Test("PracticeTextLibrary random excludes seen IDs")
    func libraryRandomExcludesSeen() {
        let lib = makeSampleLibrary()
        let allIDs = Set(lib.texts.map(\.id))
        let result = lib.randomText(excluding: allIDs)
        #expect(result == nil, "Should return nil when all IDs are excluded")
    }

    // MARK: - Content Version Tracking

    @Test("PracticeTextLibrary tracks content version")
    func libraryContentVersion() {
        let lib = PracticeTextLibrary(texts: [], contentVersion: "1.2.3")
        #expect(lib.contentVersion == "1.2.3")
    }

    @Test("PracticeTextLibrary defaults to 0.0.0 content version")
    func libraryDefaultVersion() {
        let lib = PracticeTextLibrary()
        #expect(lib.contentVersion == "0.0.0")
    }

    // MARK: - Container Format Loading

    @Test("PracticeTextLibrary loads from container format data")
    func loadFromContainerFormat() throws {
        let json = """
        {
            "contentVersion": "2.1.0",
            "generatedDate": "2026-03-07",
            "texts": [
                {
                    "id": "pt-test-en",
                    "text": "Test text",
                    "answerKey": {
                        "governingThought": "Main point",
                        "supports": [{"label": "Support 1", "evidence": []}],
                        "structuralAssessment": "Good"
                    },
                    "metadata": {
                        "qualityLevel": "well-structured",
                        "difficultyRating": 1,
                        "topicDomain": "technology",
                        "language": "en",
                        "wordCount": 2,
                        "targetLevel": 1
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let lib = try PracticeTextLibrary.load(from: json)
        #expect(lib.contentVersion == "2.1.0")
        #expect(lib.texts.count == 1)
        #expect(lib.texts[0].id == "pt-test-en")
    }

    @Test("PracticeTextLibrary load falls back to flat array")
    func loadFromFlatArray() throws {
        let json = """
        [
            {
                "id": "pt-flat-en",
                "text": "Flat text",
                "answerKey": {
                    "governingThought": "Point",
                    "supports": [{"label": "S", "evidence": []}],
                    "structuralAssessment": "OK"
                },
                "metadata": {
                    "qualityLevel": "well-structured",
                    "difficultyRating": 1,
                    "topicDomain": "school",
                    "language": "en",
                    "wordCount": 2,
                    "targetLevel": 1
                }
            }
        ]
        """.data(using: .utf8)!

        let lib = try PracticeTextLibrary.load(from: json)
        #expect(lib.contentVersion == "0.0.0")
        #expect(lib.texts.count == 1)
    }

    // MARK: - Merging

    @Test("Merging appends new texts and skips duplicates")
    func mergingLibraries() {
        let lib1 = PracticeTextLibrary(
            texts: [makeSampleText(id: "a", language: "en")],
            contentVersion: "1.0.0"
        )
        let lib2 = PracticeTextLibrary(
            texts: [
                makeSampleText(id: "a", language: "en"),
                makeSampleText(id: "b", language: "en")
            ],
            contentVersion: "1.1.0"
        )

        let merged = lib1.merging(lib2)
        #expect(merged.texts.count == 2)
        #expect(merged.texts.map(\.id).sorted() == ["a", "b"])
        #expect(merged.contentVersion == "1.1.0")
    }

    @Test("Merging keeps higher content version")
    func mergingVersions() {
        let lib1 = PracticeTextLibrary(texts: [], contentVersion: "2.0.0")
        let lib2 = PracticeTextLibrary(texts: [], contentVersion: "1.5.0")
        let merged = lib1.merging(lib2)
        #expect(merged.contentVersion == "2.0.0")
    }

    // MARK: - ID Validation

    @Test("validateUniqueIDs returns empty for unique IDs")
    func validateUniqueIDsNoCollisions() {
        let lib = makeSampleLibrary()
        let duplicates = lib.validateUniqueIDs()
        #expect(duplicates.isEmpty)
    }

    @Test("validateUniqueIDs detects duplicates")
    func validateUniqueIDsWithDuplicates() {
        let lib = PracticeTextLibrary(texts: [
            makeSampleText(id: "dup-1", language: "en"),
            makeSampleText(id: "dup-1", language: "en"),
            makeSampleText(id: "unique", language: "en")
        ])
        let duplicates = lib.validateUniqueIDs()
        #expect(duplicates == ["dup-1"])
    }

    // MARK: - Container Model

    @Test("PracticeTextLibraryContainer round-trips through JSON")
    func containerCodable() throws {
        let container = PracticeTextLibraryContainer(
            contentVersion: "1.0.0",
            generatedDate: "2026-03-07",
            texts: [makeSampleText(id: "ct-1", language: "en")]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(container)
        let decoded = try JSONDecoder().decode(PracticeTextLibraryContainer.self, from: data)

        #expect(decoded.contentVersion == "1.0.0")
        #expect(decoded.generatedDate == "2026-03-07")
        #expect(decoded.texts.count == 1)
        #expect(decoded.texts[0].id == "ct-1")
    }

    // MARK: - Smoke Test: Adding Texts

    @Test("Adding new texts to library does not break existing functionality")
    func smokeTestAddNewTexts() throws {
        let allTexts = try loadAllTexts()
        let originalCount = allTexts.count

        let newTexts = [
            makeSampleText(id: "pt-new-001-en", language: "en"),
            makeSampleText(id: "pt-new-002-en", language: "en"),
            makeSampleText(id: "pt-new-003-de", language: "de")
        ]

        let original = PracticeTextLibrary(texts: allTexts, contentVersion: "1.0.0")
        let batch = PracticeTextLibrary(texts: newTexts, contentVersion: "1.1.0")
        let merged = original.merging(batch)

        #expect(merged.texts.count == originalCount + 3)

        let enTexts = merged.texts(for: "en")
        #expect(enTexts.allSatisfy { $0.metadata.language == "en" })

        let random = merged.randomText(language: "en")
        #expect(random != nil)

        let duplicates = merged.validateUniqueIDs()
        #expect(duplicates.isEmpty)
    }

    // MARK: - Helpers

    private func loadTestJSON(filename: String) throws -> Data {
        let basePath = #filePath
            .components(separatedBy: "/Tests/")
            .first ?? ""
        let path = "\(basePath)/Content/PracticeTexts/\(filename).json"
        return try Data(contentsOf: URL(fileURLWithPath: path))
    }

    private func loadContainer(filename: String) throws -> PracticeTextLibraryContainer {
        let data = try loadTestJSON(filename: filename)
        return try JSONDecoder().decode(PracticeTextLibraryContainer.self, from: data)
    }

    private func loadAllTexts() throws -> [PracticeText] {
        let en = try loadContainer(filename: "PracticeTextLibrary_en")
        let de = try loadContainer(filename: "PracticeTextLibrary_de")
        return en.texts + de.texts
    }

    private func makeSampleText(id: String, language: String) -> PracticeText {
        PracticeText(
            id: id,
            text: "Sample text for \(id)",
            answerKey: AnswerKey(
                governingThought: "Test thought",
                supports: [SupportGroup(label: "Support", evidence: [])],
                structuralAssessment: "Assessment"
            ),
            metadata: PracticeTextMetadata(
                qualityLevel: .wellStructured,
                difficultyRating: 1,
                topicDomain: "technology",
                language: language,
                wordCount: 4,
                targetLevel: 1
            )
        )
    }

    private func makeSampleLibrary() -> PracticeTextLibrary {
        PracticeTextLibrary(
            texts: [
                makeSampleText(id: "test-1-en", language: "en"),
                PracticeText(
                    id: "test-2-de",
                    text: "Beispieltext",
                    answerKey: AnswerKey(
                        governingThought: "Testgedanke",
                        supports: [SupportGroup(label: "Stuetze", evidence: [])],
                        structuralAssessment: "Bewertung"
                    ),
                    metadata: PracticeTextMetadata(
                        qualityLevel: .buriedLead,
                        difficultyRating: 3,
                        topicDomain: "school",
                        language: "de",
                        wordCount: 5,
                        targetLevel: 2
                    )
                )
            ],
            contentVersion: "1.0.0"
        )
    }
}
