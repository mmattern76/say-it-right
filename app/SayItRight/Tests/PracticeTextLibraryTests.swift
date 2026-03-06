import Foundation
import Testing
@testable import SayItRight

@Suite("PracticeTextLibrary Tests")
struct PracticeTextLibraryTests {

    // MARK: - JSON Parsing

    @Test("English practice texts parse without error")
    func englishTextsParse() throws {
        let data = try loadTestJSON(filename: "PracticeTextLibrary_en")
        let texts = try JSONDecoder().decode([PracticeText].self, from: data)
        #expect(texts.count >= 20, "Expected at least 20 English texts, got \(texts.count)")
    }

    @Test("German practice texts parse without error")
    func germanTextsParse() throws {
        let data = try loadTestJSON(filename: "PracticeTextLibrary_de")
        let texts = try JSONDecoder().decode([PracticeText].self, from: data)
        #expect(texts.count >= 20, "Expected at least 20 German texts, got \(texts.count)")
    }

    @Test("Total practice text count is at least 40")
    func totalTextCount() throws {
        let en = try JSONDecoder().decode([PracticeText].self, from: loadTestJSON(filename: "PracticeTextLibrary_en"))
        let de = try JSONDecoder().decode([PracticeText].self, from: loadTestJSON(filename: "PracticeTextLibrary_de"))
        let total = en.count + de.count
        #expect(total >= 40, "Expected at least 40 total texts, got \(total)")
    }

    // MARK: - ID Uniqueness

    @Test("All text IDs are unique across both languages")
    func uniqueIDs() throws {
        let en = try JSONDecoder().decode([PracticeText].self, from: loadTestJSON(filename: "PracticeTextLibrary_en"))
        let de = try JSONDecoder().decode([PracticeText].self, from: loadTestJSON(filename: "PracticeTextLibrary_de"))
        let allTexts = en + de
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
        let en = try JSONDecoder().decode([PracticeText].self, from: loadTestJSON(filename: "PracticeTextLibrary_en"))
        for text in en {
            #expect(text.metadata.language == "en", "Text \(text.id) in EN file has language \(text.metadata.language)")
        }
    }

    @Test("German texts have language set to de")
    func germanLanguageField() throws {
        let de = try JSONDecoder().decode([PracticeText].self, from: loadTestJSON(filename: "PracticeTextLibrary_de"))
        for text in de {
            #expect(text.metadata.language == "de", "Text \(text.id) in DE file has language \(text.metadata.language)")
        }
    }

    // MARK: - Library Filtering

    @Test("PracticeTextLibrary filters by language")
    func libraryFilterByLanguage() {
        let texts = makeSampleLibrary()
        let en = texts.texts(for: "en")
        let de = texts.texts(for: "de")
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

    // MARK: - Helpers

    private func loadTestJSON(filename: String) throws -> Data {
        // Load from source directory since bundle resources aren't available in tests
        let basePath = #filePath
            .components(separatedBy: "/Tests/")
            .first ?? ""
        let path = "\(basePath)/Content/PracticeTexts/\(filename).json"
        return try Data(contentsOf: URL(fileURLWithPath: path))
    }

    private func loadAllTexts() throws -> [PracticeText] {
        let en = try JSONDecoder().decode([PracticeText].self, from: loadTestJSON(filename: "PracticeTextLibrary_en"))
        let de = try JSONDecoder().decode([PracticeText].self, from: loadTestJSON(filename: "PracticeTextLibrary_de"))
        return en + de
    }

    private func makeSampleLibrary() -> PracticeTextLibrary {
        let texts = [
            PracticeText(
                id: "test-1-en",
                text: "Sample text",
                answerKey: AnswerKey(
                    governingThought: "Test thought",
                    supports: [SupportGroup(label: "Support", evidence: [])],
                    structuralAssessment: "Assessment"
                ),
                metadata: PracticeTextMetadata(
                    qualityLevel: .wellStructured,
                    difficultyRating: 1,
                    topicDomain: "technology",
                    language: "en",
                    wordCount: 10,
                    targetLevel: 1
                )
            ),
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
        ]
        return PracticeTextLibrary(texts: texts)
    }
}
