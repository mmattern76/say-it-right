#!/usr/bin/env swift

// generate-practice-texts.swift
//
// Batch script that generates practice texts via the Claude API.
// Outputs JSON files to content/practice-texts/staging/ for human review.
//
// Usage:
//   ANTHROPIC_API_KEY=sk-... swift scripts/generate-practice-texts.swift [options]
//
// Options:
//   --quality <level>     Quality level: well-structured, buried-lead, rambling, adversarial
//                         (default: all four)
//   --language <lang>     Language: en, de, or both (default: both)
//   --level <n>           Target learner level: 1-4 (default: 1)
//   --domain <domain>     Topic domain: technology, school, society, everyday (default: all)
//   --count <n>           Number of texts per quality/language combination (default: 2)
//   --id-start <n>        Starting ID number (default: 100)
//   --output <dir>        Output directory (default: content/practice-texts/staging)
//   --model <model>       Claude model to use (default: claude-sonnet-4-5-20250514)

import Foundation

// MARK: - Types (self-contained for script use)

enum ScriptQualityLevel: String, CaseIterable {
    case wellStructured = "well-structured"
    case buriedLead = "buried-lead"
    case rambling
    case adversarial
}

// MARK: - Argument Parsing

struct ScriptConfig {
    var qualityLevels: [ScriptQualityLevel] = ScriptQualityLevel.allCases
    var languages: [String] = ["en", "de"]
    var targetLevel: Int = 1
    var domains: [String] = ["technology", "school", "society", "everyday"]
    var countPerCombination: Int = 2
    var idStart: Int = 100
    var outputDir: String = "content/practice-texts/staging"
    var model: String = "claude-sonnet-4-5-20250514"
    var apiKey: String = ""
}

func parseArgs() -> ScriptConfig {
    var config = ScriptConfig()
    let args = CommandLine.arguments

    var i = 1
    while i < args.count {
        switch args[i] {
        case "--quality":
            i += 1
            if i < args.count {
                if args[i] == "all" {
                    config.qualityLevels = ScriptQualityLevel.allCases
                } else {
                    config.qualityLevels = args[i].split(separator: ",").compactMap {
                        ScriptQualityLevel(rawValue: String($0))
                    }
                }
            }
        case "--language":
            i += 1
            if i < args.count {
                config.languages = args[i] == "both" ? ["en", "de"] : [args[i]]
            }
        case "--level":
            i += 1
            if i < args.count { config.targetLevel = Int(args[i]) ?? 1 }
        case "--domain":
            i += 1
            if i < args.count {
                config.domains = args[i] == "all"
                    ? ["technology", "school", "society", "everyday"]
                    : args[i].split(separator: ",").map(String.init)
            }
        case "--count":
            i += 1
            if i < args.count { config.countPerCombination = Int(args[i]) ?? 2 }
        case "--id-start":
            i += 1
            if i < args.count { config.idStart = Int(args[i]) ?? 100 }
        case "--output":
            i += 1
            if i < args.count { config.outputDir = args[i] }
        case "--model":
            i += 1
            if i < args.count { config.model = args[i] }
        case "--help", "-h":
            printUsage()
            exit(0)
        default:
            break
        }
        i += 1
    }

    // API key from environment
    if let key = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] {
        config.apiKey = key
    }

    return config
}

func printUsage() {
    print("""
    Usage: ANTHROPIC_API_KEY=sk-... swift scripts/generate-practice-texts.swift [options]

    Options:
      --quality <level>     well-structured, buried-lead, rambling, adversarial, or all
      --language <lang>     en, de, or both (default: both)
      --level <n>           Target learner level 1-4 (default: 1)
      --domain <domain>     technology, school, society, everyday, or all (default: all)
      --count <n>           Texts per quality/language/domain combo (default: 2)
      --id-start <n>        Starting ID number (default: 100)
      --output <dir>        Output directory (default: content/practice-texts/staging)
      --model <model>       Claude model (default: claude-sonnet-4-5-20250514)
    """)
}

// MARK: - Generation Prompt

func systemPrompt(qualityLevel: ScriptQualityLevel, language: String, wordRange: ClosedRange<Int>) -> String {
    let languageName = language == "de" ? "German" : "English"
    return """
    You are a practice text generator for an educational app that teaches \
    structured thinking and the Pyramid Principle. Your job is to produce \
    natural-sounding texts that students will analyze for structural quality.

    CRITICAL RULES:
    1. The text must sound like it was written by a real person — NOT like \
    AI-generated content. Use natural phrasing, varied sentence lengths, \
    and occasional colloquialisms appropriate for the topic.
    2. The text must be written entirely in \(languageName).
    3. The text must be between \(wordRange.lowerBound) and \(wordRange.upperBound) words.
    4. The topic should be engaging and relevant for teenagers and young adults (13+).
    5. The text must be age-appropriate — no graphic violence, explicit content, \
    or deeply disturbing themes.

    You MUST respond with ONLY a valid JSON object, no markdown formatting, \
    no code fences, no explanation. Just the raw JSON.
    """
}

func qualityInstructions(for level: ScriptQualityLevel) -> String {
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
        - Place the actual governing thought in paragraph 2 or 3
        - The supporting arguments should be solid once the reader finds the thesis
        - The text should feel like a newspaper feature or essay that builds up to its point
        """
    case .rambling:
        return """
        INSTRUCTIONS: Create a text with NO clear organizing structure.
        - Good individual points but scattered without hierarchy
        - Jump between subtopics without clear transitions
        - Split related arguments across non-adjacent paragraphs
        - Weak or non-committal conclusion
        - Conversational, stream-of-consciousness style
        """
    case .adversarial:
        return """
        INSTRUCTIONS: Create a text that APPEARS well-structured but has a HIDDEN logical flaw.
        - Surface structure should look like a clean pyramid
        - Embed ONE subtle flaw: false_dichotomy, circular_reasoning, non_sequitur, \
        hasty_generalization, straw_man, false_equivalence, appeal_to_authority, \
        or correlation_as_causation
        - The flaw should require careful reading to spot
        - The text should be convincing on first read
        """
    }
}

func levelContext(for level: Int) -> String {
    switch level {
    case 1: return "LEVEL: L1 Plain Talk — simple language, 13-15 year olds."
    case 2: return "LEVEL: L2 Order — moderate complexity, MECE grouping, 15-17 year olds."
    case 3: return "LEVEL: L3 Architecture — complex arguments, university-level."
    case 4: return "LEVEL: L4 Mastery — professional-grade complexity."
    default: return "LEVEL: General audience."
    }
}

func buildUserPrompt(quality: ScriptQualityLevel, domain: String, language: String, level: Int) -> String {
    let languageName = language == "de" ? "German" : "English"
    let flawField = quality == .adversarial ? """
    ,
        "structural_flaw": {
          "type": "<flaw type>",
          "description": "<what the flaw is>",
          "location": "<where it occurs>"
        }
    """ : ""
    let restructureField = quality == .rambling ? """
    ,
        "proposed_restructure": "<how to restructure into a proper pyramid>"
    """ : ""

    return """
    Generate a practice text with these specs:

    QUALITY: \(quality.rawValue)
    \(qualityInstructions(for: quality))

    DOMAIN: \(domain)
    LANGUAGE: \(languageName)
    \(levelContext(for: level))

    LENGTH: 100-400 words

    Respond with ONLY this JSON (no markdown):
    {
      "text": "<the text>",
      "answer_key": {
        "governing_thought": "<main conclusion>",
        "supports": [
          { "label": "<support label>", "evidence": ["<evidence>"] }
        ],
        "structural_assessment": "<analysis of structure>"\(flawField)\(restructureField)
      },
      "topic_domain": "\(domain)",
      "difficulty_rating": <1-5>
    }
    """
}

// MARK: - API Call

func callClaudeAPI(apiKey: String, model: String, systemPrompt: String, userPrompt: String) async throws -> String {
    let url = URL(string: "https://api.anthropic.com/v1/messages")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
    request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
    request.timeoutInterval = 120

    let body: [String: Any] = [
        "model": model,
        "max_tokens": 4096,
        "system": systemPrompt,
        "messages": [["role": "user", "content": userPrompt]]
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
        let body = String(data: data, encoding: .utf8) ?? "unknown"
        throw NSError(domain: "API", code: code, userInfo: [NSLocalizedDescriptionKey: "API error (\(code)): \(body)"])
    }

    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let content = json["content"] as? [[String: Any]],
          let first = content.first,
          let text = first["text"] as? String
    else {
        throw NSError(domain: "API", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unexpected response format"])
    }

    return text
}

// MARK: - Output Writing

func writeOutput(_ jsonString: String, id: String, language: String, outputDir: String) throws -> URL {
    let fm = FileManager.default
    let dirURL = URL(fileURLWithPath: outputDir)
    try fm.createDirectory(at: dirURL, withIntermediateDirectories: true)

    // Parse and re-serialize with the id and proper formatting
    let cleaned = jsonString
        .replacingOccurrences(of: "```json", with: "")
        .replacingOccurrences(of: "```", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)

    guard let data = cleaned.data(using: .utf8),
          var parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
        throw NSError(domain: "Parse", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
    }

    // Add id and enrich metadata
    parsed["id"] = id
    if var meta = parsed["metadata"] as? [String: Any] {
        meta["language"] = language
        parsed["metadata"] = meta
    } else {
        // Build metadata from top-level fields
        let text = parsed["text"] as? String ?? ""
        let wordCount = text.split(separator: " ").count
        let answerKey = parsed["answer_key"] as? [String: Any]

        // Restructure to match PracticeText format
        var output: [String: Any] = [
            "id": id,
            "text": text,
            "answerKey": [
                "governingThought": answerKey?["governing_thought"] ?? "",
                "supports": (answerKey?["supports"] as? [[String: Any]])?.map { s in
                    [
                        "label": s["label"] ?? "",
                        "evidence": s["evidence"] ?? []
                    ] as [String: Any]
                } ?? [],
                "structuralAssessment": answerKey?["structural_assessment"] ?? ""
            ] as [String: Any],
            "metadata": [
                "qualityLevel": parsed["quality_level"] ?? parsed["topic_domain"].map { _ in "" } ?? "",
                "difficultyRating": parsed["difficulty_rating"] ?? 1,
                "topicDomain": parsed["topic_domain"] ?? "",
                "language": language,
                "wordCount": wordCount,
                "targetLevel": 1
            ] as [String: Any]
        ]

        // Add optional fields to answer key
        if var ak = output["answerKey"] as? [String: Any] {
            if let flaw = answerKey?["structural_flaw"] {
                ak["structuralFlaw"] = flaw
            }
            if let restructure = answerKey?["proposed_restructure"] {
                ak["proposedRestructure"] = restructure
            }
            output["answerKey"] = ak
        }

        parsed = output
    }

    let outputData = try JSONSerialization.data(
        withJSONObject: parsed,
        options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    )

    let filename = "\(id).json"
    let fileURL = dirURL.appendingPathComponent(filename)
    try outputData.write(to: fileURL, options: .atomic)
    return fileURL
}

// MARK: - Main

func main() async {
    let config = parseArgs()

    guard !config.apiKey.isEmpty else {
        print("ERROR: Set ANTHROPIC_API_KEY environment variable")
        print("  ANTHROPIC_API_KEY=sk-... swift scripts/generate-practice-texts.swift")
        exit(1)
    }

    let totalTexts = config.qualityLevels.count * config.languages.count
        * config.domains.count * config.countPerCombination
    print("Practice Text Generator")
    print("=======================")
    print("Quality levels: \(config.qualityLevels.map(\.rawValue).joined(separator: ", "))")
    print("Languages: \(config.languages.joined(separator: ", "))")
    print("Domains: \(config.domains.joined(separator: ", "))")
    print("Level: \(config.targetLevel)")
    print("Count per combination: \(config.countPerCombination)")
    print("Total texts to generate: \(totalTexts)")
    print("Output: \(config.outputDir)")
    print("Model: \(config.model)")
    print("ID range: \(config.idStart) - \(config.idStart + totalTexts - 1)")
    print("")

    var currentID = config.idStart
    var successCount = 0
    var failCount = 0

    for quality in config.qualityLevels {
        for domain in config.domains {
            for language in config.languages {
                for n in 1...config.countPerCombination {
                    let id = String(format: "pt-%03d-%@", currentID, language)
                    print("[\(currentID)] Generating \(quality.rawValue) / \(domain) / \(language) (\(n)/\(config.countPerCombination))...", terminator: " ")

                    do {
                        let sysPrompt = systemPrompt(
                            qualityLevel: quality,
                            language: language,
                            wordRange: 100...400
                        )
                        let userPrompt = buildUserPrompt(
                            quality: quality,
                            domain: domain,
                            language: language,
                            level: config.targetLevel
                        )

                        let response = try await callClaudeAPI(
                            apiKey: config.apiKey,
                            model: config.model,
                            systemPrompt: sysPrompt,
                            userPrompt: userPrompt
                        )

                        let fileURL = try writeOutput(
                            response,
                            id: id,
                            language: language,
                            outputDir: config.outputDir
                        )

                        print("OK -> \(fileURL.lastPathComponent)")
                        successCount += 1
                    } catch {
                        print("FAILED: \(error)")
                        failCount += 1
                    }

                    currentID += 1

                    // Rate limiting: 2 second pause between requests
                    if currentID < config.idStart + totalTexts {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                    }
                }
            }
        }
    }

    print("")
    print("Done! \(successCount) generated, \(failCount) failed.")
    print("Review files in: \(config.outputDir)")
    print("After review, move approved files to content/practice-texts/")
}

// Entry point
Task {
    await main()
    exit(0)
}

RunLoop.main.run()
