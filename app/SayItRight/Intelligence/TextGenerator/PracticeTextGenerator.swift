import Foundation

/// Configuration for generating a batch of practice texts.
struct GenerationConfig: Sendable {
    let qualityLevel: QualityLevel
    let language: String
    let targetLevel: Int
    let topicDomain: String
    let targetWordCount: ClosedRange<Int>
    let count: Int

    init(
        qualityLevel: QualityLevel,
        language: String = "en",
        targetLevel: Int = 1,
        topicDomain: String = "technology",
        targetWordCount: ClosedRange<Int> = 100...400,
        count: Int = 1
    ) {
        self.qualityLevel = qualityLevel
        self.language = language
        self.targetLevel = targetLevel
        self.topicDomain = topicDomain
        self.targetWordCount = targetWordCount
        self.count = count
    }
}

/// Generates practice texts by calling the Anthropic Claude API.
///
/// This is a pipeline tool for content creation — it generates texts with
/// structured answer keys that are reviewed by a human before being bundled
/// into the app. Output goes to a staging directory for review.
struct PracticeTextGenerator: Sendable {

    private let apiKey: String
    private let model: String
    private let apiURL: URL

    init(
        apiKey: String,
        model: String = "claude-sonnet-4-5-20250514",
        apiURL: URL = URL(string: "https://api.anthropic.com/v1/messages")!
    ) {
        self.apiKey = apiKey
        self.model = model
        self.apiURL = apiURL
    }

    // MARK: - Public API

    /// Generate a single practice text with the given configuration.
    func generate(config: GenerationConfig, idPrefix: String? = nil) async throws -> PracticeText {
        let idPrefix = idPrefix ?? "pt-\(UUID().uuidString.lowercased())"
        let prompt = buildPrompt(for: config)
        let responseJSON = try await callAPI(systemPrompt: systemPrompt(for: config), userPrompt: prompt)
        let practiceText = try parseResponse(responseJSON, config: config, idPrefix: idPrefix)
        return practiceText
    }

    /// Generate a batch of practice texts, respecting rate limits.
    func generateBatch(
        configs: [GenerationConfig],
        idStart: Int = 1,
        delayBetweenRequests: UInt64 = 2_000_000_000 // 2 seconds
    ) async throws -> [PracticeText] {
        var results: [PracticeText] = []
        var currentID = idStart

        for config in configs {
            for _ in 0..<config.count {
                let idPrefix = String(format: "pt-%03d", currentID)
                let text = try await generate(config: config, idPrefix: idPrefix)
                results.append(text)
                currentID += 1

                // Rate limiting: pause between requests
                try await Task.sleep(nanoseconds: delayBetweenRequests)
            }
        }

        return results
    }

    // MARK: - Prompt Construction

    /// System prompt establishing the generator's role and output format.
    func systemPrompt(for config: GenerationConfig) -> String {
        let languageName = config.language == "de" ? "German" : "English"

        return """
        You are a practice text generator for an educational app that teaches \
        structured thinking and the Pyramid Principle. Your job is to produce \
        natural-sounding texts that students will analyze for structural quality.

        CRITICAL RULES:
        1. The text must sound like it was written by a real person — NOT like \
        AI-generated content. Use natural phrasing, varied sentence lengths, \
        and occasional colloquialisms appropriate for the topic.
        2. The text must be written entirely in \(languageName).
        3. The text must be between \(config.targetWordCount.lowerBound) and \
        \(config.targetWordCount.upperBound) words.
        4. The topic should be engaging and relevant for teenagers and young adults (13+).
        5. The text must be age-appropriate — no graphic violence, explicit content, \
        or deeply disturbing themes.

        You MUST respond with ONLY a valid JSON object, no markdown formatting, \
        no code fences, no explanation. Just the raw JSON.
        """
    }

    /// Build the user prompt specifying what kind of text to generate.
    func buildPrompt(for config: GenerationConfig) -> String {
        let qualityInstructions = qualityLevelInstructions(for: config.qualityLevel)
        let levelContext = learnerLevelContext(for: config.targetLevel)
        let languageName = config.language == "de" ? "German" : "English"

        return """
        Generate a practice text with the following specifications:

        QUALITY LEVEL: \(config.qualityLevel.rawValue)
        \(qualityInstructions)

        TOPIC DOMAIN: \(config.topicDomain)
        LANGUAGE: \(languageName)
        TARGET LEARNER LEVEL: \(config.targetLevel)
        \(levelContext)

        TARGET LENGTH: \(config.targetWordCount.lowerBound)-\(config.targetWordCount.upperBound) words

        OUTPUT FORMAT (JSON only, no markdown):
        {
          "text": "<the practice text>",
          "answer_key": {
            "governing_thought": "<the main conclusion or thesis>",
            "supports": [
              {
                "label": "<short label for this support group>",
                "evidence": ["<evidence node 1>", "<evidence node 2>"]
              }
            ],
            "structural_assessment": "<explanation of the text's structural quality>"\(config.qualityLevel == .adversarial ? ",\n    \"structural_flaw\": {\n      \"type\": \"<flaw type: false_dichotomy | circular_reasoning | non_sequitur | hasty_generalization | straw_man | false_equivalence | appeal_to_authority | correlation_as_causation>\",\n      \"description\": \"<what the flaw is and why it's problematic>\",\n      \"location\": \"<where in the text the flaw occurs>\"\n    }" : "")\(config.qualityLevel == .rambling ? ",\n    \"proposed_restructure\": \"<how this text should be restructured into a proper pyramid>\"" : "")
          },
          "topic_domain": "\(config.topicDomain)",
          "difficulty_rating": <1-5 integer>
        }
        """
    }

    // MARK: - Quality Level Instructions

    private func qualityLevelInstructions(for level: QualityLevel) -> String {
        switch level {
        case .wellStructured:
            return """
            INSTRUCTIONS: Create a text with clean pyramid structure.
            - Lead with the governing thought (conclusion first)
            - Follow with 2-4 distinct support pillars, each with specific evidence
            - Each support should be mutually exclusive and collectively exhaustive (MECE)
            - The structure should be easy to extract — this is a model text
            - Include a brief counterargument that is acknowledged and dismissed
            """

        case .buriedLead:
            return """
            INSTRUCTIONS: Create a text where the conclusion EXISTS but is BURIED.
            - Start with background, context, statistics, or a story (1-2 paragraphs)
            - Place the actual governing thought in paragraph 2 or 3, often after \
            a transitional phrase like "Yet...", "However...", "The real issue is..."
            - The supporting arguments should be solid once the reader finds the thesis
            - The text should feel like a newspaper feature article or an essay that \
            "builds up" to its point instead of leading with it
            - Common real-world pattern: the writer knows their point but buries it \
            under preamble
            """

        case .rambling:
            return """
            INSTRUCTIONS: Create a text with NO clear organizing structure.
            - The text should contain good individual points but in scattered order
            - Jump between subtopics without clear transitions
            - Split related arguments across non-adjacent paragraphs
            - Include a weak or non-committal conclusion ("something needs to change")
            - Use conversational, stream-of-consciousness style
            - The reader should be able to identify THAT structure is missing
            - There IS content worth restructuring — the problem is organization, \
            not substance
            """

        case .adversarial:
            return """
            INSTRUCTIONS: Create a text that APPEARS well-structured but contains \
            a HIDDEN logical flaw.
            - Surface structure should look like a clean pyramid (conclusion first, \
            supports follow)
            - Embed ONE of these structural flaws:
              * False dichotomy: presents only two options when more exist
              * Circular reasoning: conclusion restates a premise as proof
              * Non sequitur: a support doesn't actually support the conclusion
              * Hasty generalization: one example treated as universal proof
              * Straw man: misrepresents an opposing view to dismiss it easily
              * False equivalence: treats unequal things as equal
              * Appeal to authority: uses authority instead of evidence
              * Correlation as causation: mistakes correlation for causation
            - The flaw should be subtle enough to require careful reading to spot
            - The text should be convincing on first read — the flaw reveals itself \
            on analysis
            """
        }
    }

    // MARK: - Learner Level Context

    private func learnerLevelContext(for level: Int) -> String {
        switch level {
        case 1:
            return """
            LEVEL CONTEXT (L1 "Plain Talk"): Foundations.
            - Simple, clear language. Short to medium paragraphs.
            - Focus: lead with answer, one idea per block, "so what?" test.
            - Vocabulary appropriate for 13-15 year olds.
            """
        case 2:
            return """
            LEVEL CONTEXT (L2 "Order"): Grouping & logic.
            - Moderate complexity. MECE grouping, deductive vs. inductive reasoning.
            - May include SCQ (Situation-Complication-Question) framing.
            - Vocabulary appropriate for 15-17 year olds.
            """
        case 3:
            return """
            LEVEL CONTEXT (L3 "Architecture"): Advanced structures.
            - Complex, multi-layered arguments. Issue trees, vertical/horizontal logic.
            - May include synthesis of multiple viewpoints.
            - University-level vocabulary and reasoning complexity.
            """
        case 4:
            return """
            LEVEL CONTEXT (L4 "Mastery"): Real-world application.
            - Professional-grade text complexity. Executive summaries, presentations.
            - Dense argumentation with nuanced evidence.
            - Professional vocabulary, real-world references.
            """
        default:
            return "LEVEL CONTEXT: General audience, moderate complexity."
        }
    }

    // MARK: - API Communication

    private func callAPI(systemPrompt: String, userPrompt: String) async throws -> String {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 120

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userPrompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeneratorError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "unknown"
            throw GeneratorError.apiError(statusCode: httpResponse.statusCode, body: errorBody)
        }

        // Parse the Anthropic API response to extract the text content
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String
        else {
            throw GeneratorError.unexpectedResponseFormat
        }

        return text
    }

    // MARK: - Response Parsing

    private func parseResponse(_ responseJSON: String, config: GenerationConfig, idPrefix: String) throws -> PracticeText {
        // Strip any markdown code fences if the model wrapped the JSON
        let cleaned = responseJSON
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw GeneratorError.invalidJSON(cleaned)
        }

        guard let raw = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GeneratorError.invalidJSON(cleaned)
        }

        // Extract text
        guard let text = raw["text"] as? String else {
            throw GeneratorError.missingField("text")
        }

        // Extract answer key
        guard let answerKeyRaw = raw["answer_key"] as? [String: Any] else {
            throw GeneratorError.missingField("answer_key")
        }

        guard let governingThought = answerKeyRaw["governing_thought"] as? String else {
            throw GeneratorError.missingField("answer_key.governing_thought")
        }

        guard let supportsRaw = answerKeyRaw["supports"] as? [[String: Any]] else {
            throw GeneratorError.missingField("answer_key.supports")
        }

        let supports = supportsRaw.compactMap { supportDict -> SupportGroup? in
            guard let label = supportDict["label"] as? String,
                  let evidence = supportDict["evidence"] as? [String]
            else { return nil }
            return SupportGroup(label: label, evidence: evidence)
        }

        guard !supports.isEmpty else {
            throw GeneratorError.missingField("answer_key.supports (empty)")
        }

        let structuralAssessment = answerKeyRaw["structural_assessment"] as? String ?? ""

        // Optional fields
        var structuralFlaw: StructuralFlaw?
        if let flawRaw = answerKeyRaw["structural_flaw"] as? [String: Any],
           let flawType = flawRaw["type"] as? String,
           let flawDesc = flawRaw["description"] as? String,
           let flawLoc = flawRaw["location"] as? String {
            structuralFlaw = StructuralFlaw(type: flawType, description: flawDesc, location: flawLoc)
        }

        let proposedRestructure = answerKeyRaw["proposed_restructure"] as? String

        let difficultyRating = raw["difficulty_rating"] as? Int ?? config.targetLevel
        let topicDomain = raw["topic_domain"] as? String ?? config.topicDomain

        let wordCount = text.split(separator: " ").count

        let answerKey = AnswerKey(
            governingThought: governingThought,
            supports: supports,
            structuralAssessment: structuralAssessment,
            structuralFlaw: structuralFlaw,
            proposedRestructure: proposedRestructure
        )

        let metadata = PracticeTextMetadata(
            qualityLevel: config.qualityLevel,
            difficultyRating: difficultyRating,
            topicDomain: topicDomain,
            language: config.language,
            wordCount: wordCount,
            targetLevel: config.targetLevel
        )

        return PracticeText(
            id: "\(idPrefix)-\(config.language)",
            text: text,
            answerKey: answerKey,
            metadata: metadata
        )
    }
}

// MARK: - Errors

enum GeneratorError: Error, CustomStringConvertible {
    case invalidResponse
    case apiError(statusCode: Int, body: String)
    case unexpectedResponseFormat
    case invalidJSON(String)
    case missingField(String)

    var description: String {
        switch self {
        case .invalidResponse:
            return "Invalid HTTP response"
        case .apiError(let code, let body):
            return "API error (\(code)): \(body)"
        case .unexpectedResponseFormat:
            return "Unexpected response format from Anthropic API"
        case .invalidJSON(let raw):
            return "Failed to parse JSON from response: \(raw.prefix(200))"
        case .missingField(let field):
            return "Missing required field: \(field)"
        }
    }
}
