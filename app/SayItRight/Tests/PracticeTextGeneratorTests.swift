import Foundation
import Testing
@testable import SayItRight

@Suite("PracticeText Model Tests")
struct PracticeTextModelTests {

    // MARK: - QualityLevel

    @Test("QualityLevel raw values match expected strings")
    func qualityLevelRawValues() {
        #expect(QualityLevel.wellStructured.rawValue == "well-structured")
        #expect(QualityLevel.buriedLead.rawValue == "buried-lead")
        #expect(QualityLevel.rambling.rawValue == "rambling")
        #expect(QualityLevel.adversarial.rawValue == "adversarial")
    }

    @Test("QualityLevel has exactly four cases")
    func qualityLevelCaseCount() {
        #expect(QualityLevel.allCases.count == 4)
    }

    @Test("QualityLevel round-trips through JSON encoding")
    func qualityLevelCodable() throws {
        for level in QualityLevel.allCases {
            let data = try JSONEncoder().encode(level)
            let decoded = try JSONDecoder().decode(QualityLevel.self, from: data)
            #expect(decoded == level)
        }
    }

    // MARK: - StructuralFlaw

    @Test("StructuralFlaw encodes and decodes correctly")
    func structuralFlawCodable() throws {
        let flaw = StructuralFlaw(
            type: "false_dichotomy",
            description: "Presents only two options when more exist",
            location: "paragraph 2"
        )
        let data = try JSONEncoder().encode(flaw)
        let decoded = try JSONDecoder().decode(StructuralFlaw.self, from: data)
        #expect(decoded == flaw)
        #expect(decoded.type == "false_dichotomy")
        #expect(decoded.location == "paragraph 2")
    }

    // MARK: - SupportGroup

    @Test("SupportGroup encodes with label and evidence")
    func supportGroupCodable() throws {
        let group = SupportGroup(
            label: "Health impact",
            evidence: ["Reduces stress by 30%", "Improves sleep quality"]
        )
        let data = try JSONEncoder().encode(group)
        let decoded = try JSONDecoder().decode(SupportGroup.self, from: data)
        #expect(decoded == group)
        #expect(decoded.evidence.count == 2)
    }

    // MARK: - AnswerKey

    @Test("AnswerKey with structural flaw for adversarial texts")
    func answerKeyWithFlaw() throws {
        let key = AnswerKey(
            governingThought: "Social media improves democracy",
            supports: [
                SupportGroup(label: "Access", evidence: ["Everyone can participate"]),
                SupportGroup(label: "Speed", evidence: ["Instant information sharing"])
            ],
            structuralAssessment: "Appears well-structured but contains a false equivalence",
            structuralFlaw: StructuralFlaw(
                type: "false_equivalence",
                description: "Treats online engagement as equal to meaningful political participation",
                location: "support pillar 1"
            )
        )

        let data = try JSONEncoder().encode(key)
        let decoded = try JSONDecoder().decode(AnswerKey.self, from: data)
        #expect(decoded.governingThought == key.governingThought)
        #expect(decoded.structuralFlaw != nil)
        #expect(decoded.structuralFlaw?.type == "false_equivalence")
        #expect(decoded.proposedRestructure == nil)
    }

    @Test("AnswerKey with proposed restructure for rambling texts")
    func answerKeyWithRestructure() throws {
        let key = AnswerKey(
            governingThought: "Fast fashion is harmful",
            supports: [
                SupportGroup(label: "Environment", evidence: ["Pollution", "Waste"])
            ],
            structuralAssessment: "No clear organizing principle",
            proposedRestructure: "Lead with thesis, then group by environment, workers, economics"
        )

        let data = try JSONEncoder().encode(key)
        let decoded = try JSONDecoder().decode(AnswerKey.self, from: data)
        #expect(decoded.proposedRestructure != nil)
        #expect(decoded.structuralFlaw == nil)
    }

    // MARK: - PracticeTextMetadata

    @Test("PracticeTextMetadata encodes all fields")
    func metadataCodable() throws {
        let meta = PracticeTextMetadata(
            qualityLevel: .adversarial,
            difficultyRating: 3,
            topicDomain: "technology",
            language: "de",
            wordCount: 250,
            targetLevel: 2
        )

        let data = try JSONEncoder().encode(meta)
        let decoded = try JSONDecoder().decode(PracticeTextMetadata.self, from: data)
        #expect(decoded == meta)
        #expect(decoded.qualityLevel == .adversarial)
        #expect(decoded.language == "de")
    }

    // MARK: - PracticeText (full model)

    @Test("PracticeText full round-trip encoding")
    func practiceTextCodable() throws {
        let text = PracticeText(
            id: "pt-042-en",
            text: "Smartphones should be banned from classrooms.",
            answerKey: AnswerKey(
                governingThought: "Ban smartphones from classrooms",
                supports: [
                    SupportGroup(label: "Distraction", evidence: ["Students check phones every 3 minutes"]),
                    SupportGroup(label: "Cognitive drain", evidence: ["Brain drain effect reduces capacity"])
                ],
                structuralAssessment: "Clean pyramid with conclusion first"
            ),
            metadata: PracticeTextMetadata(
                qualityLevel: .wellStructured,
                difficultyRating: 1,
                topicDomain: "technology",
                language: "en",
                wordCount: 8,
                targetLevel: 1
            )
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(text)
        let decoded = try JSONDecoder().decode(PracticeText.self, from: data)

        #expect(decoded.id == "pt-042-en")
        #expect(decoded.answerKey.supports.count == 2)
        #expect(decoded.metadata.qualityLevel == .wellStructured)
        #expect(decoded.metadata.wordCount == 8)
    }
}

@Suite("PracticeTextGenerator Prompt Tests")
struct PracticeTextGeneratorPromptTests {

    private func makeGenerator() -> PracticeTextGenerator {
        PracticeTextGenerator(apiKey: "test-key")
    }

    @Test("System prompt includes language specification")
    func systemPromptLanguage() {
        let generator = makeGenerator()

        let enConfig = GenerationConfig(qualityLevel: .wellStructured, language: "en")
        let enPrompt = generator.systemPrompt(for: enConfig)
        #expect(enPrompt.contains("English"))
        #expect(!enPrompt.contains("German"))

        let deConfig = GenerationConfig(qualityLevel: .wellStructured, language: "de")
        let dePrompt = generator.systemPrompt(for: deConfig)
        #expect(dePrompt.contains("German"))
    }

    @Test("System prompt includes word count range")
    func systemPromptWordCount() {
        let generator = makeGenerator()
        let config = GenerationConfig(qualityLevel: .wellStructured, targetWordCount: 150...350)
        let prompt = generator.systemPrompt(for: config)
        #expect(prompt.contains("150"))
        #expect(prompt.contains("350"))
    }

    @Test("Build prompt includes quality level instructions")
    func buildPromptQualityLevel() {
        let generator = makeGenerator()

        for quality in QualityLevel.allCases {
            let config = GenerationConfig(qualityLevel: quality)
            let prompt = generator.buildPrompt(for: config)
            #expect(prompt.contains(quality.rawValue))
        }
    }

    @Test("Adversarial prompt requests structural_flaw field")
    func adversarialPromptIncludesFlaw() {
        let generator = makeGenerator()
        let config = GenerationConfig(qualityLevel: .adversarial)
        let prompt = generator.buildPrompt(for: config)
        #expect(prompt.contains("structural_flaw"))
        #expect(prompt.contains("flaw type"))
    }

    @Test("Rambling prompt requests proposed_restructure field")
    func ramblingPromptIncludesRestructure() {
        let generator = makeGenerator()
        let config = GenerationConfig(qualityLevel: .rambling)
        let prompt = generator.buildPrompt(for: config)
        #expect(prompt.contains("proposed_restructure"))
    }

    @Test("Well-structured prompt does not request flaw or restructure")
    func wellStructuredPromptNoExtras() {
        let generator = makeGenerator()
        let config = GenerationConfig(qualityLevel: .wellStructured)
        let prompt = generator.buildPrompt(for: config)
        #expect(!prompt.contains("structural_flaw"))
        #expect(!prompt.contains("proposed_restructure"))
    }

    @Test("Prompt includes topic domain")
    func promptIncludesDomain() {
        let generator = makeGenerator()
        let config = GenerationConfig(qualityLevel: .wellStructured, topicDomain: "school")
        let prompt = generator.buildPrompt(for: config)
        #expect(prompt.contains("school"))
    }

    @Test("Prompt includes target level context")
    func promptIncludesLevel() {
        let generator = makeGenerator()

        let l1 = GenerationConfig(qualityLevel: .wellStructured, targetLevel: 1)
        #expect(generator.buildPrompt(for: l1).contains("Plain Talk"))

        let l2 = GenerationConfig(qualityLevel: .wellStructured, targetLevel: 2)
        #expect(generator.buildPrompt(for: l2).contains("Order"))

        let l3 = GenerationConfig(qualityLevel: .wellStructured, targetLevel: 3)
        #expect(generator.buildPrompt(for: l3).contains("Architecture"))

        let l4 = GenerationConfig(qualityLevel: .wellStructured, targetLevel: 4)
        #expect(generator.buildPrompt(for: l4).contains("Mastery"))
    }
}

@Suite("GenerationConfig Tests")
struct GenerationConfigTests {

    @Test("Default config has sensible defaults")
    func defaultConfig() {
        let config = GenerationConfig(qualityLevel: .wellStructured)
        #expect(config.language == "en")
        #expect(config.targetLevel == 1)
        #expect(config.topicDomain == "technology")
        #expect(config.targetWordCount == 100...400)
        #expect(config.count == 1)
    }

    @Test("Custom config preserves all values")
    func customConfig() {
        let config = GenerationConfig(
            qualityLevel: .adversarial,
            language: "de",
            targetLevel: 3,
            topicDomain: "society",
            targetWordCount: 200...300,
            count: 5
        )
        #expect(config.qualityLevel == .adversarial)
        #expect(config.language == "de")
        #expect(config.targetLevel == 3)
        #expect(config.topicDomain == "society")
        #expect(config.targetWordCount == 200...300)
        #expect(config.count == 5)
    }
}
