import Foundation

/// Compares a user's response against a practice text's answer key using Claude
/// for semantic structural evaluation.
///
/// This is the evaluation engine behind all Break mode exercises. It sends the
/// user's extraction/restructuring and the answer key to Claude, and returns a
/// structured evaluation of how well the user captured the text's structure.
///
/// The comparison is STRUCTURAL, not textual — a differently-worded but
/// structurally equivalent extraction is considered correct.
actor AnswerKeyComparer {

    private let anthropicService: AnthropicService
    private let promptBuilder: ComparisonPromptBuilder
    private let responseParser: ComparisonResponseParser

    /// - Parameters:
    ///   - anthropicService: The Anthropic API service for Claude calls.
    ///   - promptBuilder: Builds comparison-specific prompts per session type.
    ///   - responseParser: Parses Claude's structured comparison response.
    init(
        anthropicService: AnthropicService = .shared,
        promptBuilder: ComparisonPromptBuilder = ComparisonPromptBuilder(),
        responseParser: ComparisonResponseParser = ComparisonResponseParser()
    ) {
        self.anthropicService = anthropicService
        self.promptBuilder = promptBuilder
        self.responseParser = responseParser
    }

    /// Compare a user's response against the practice text's answer key.
    ///
    /// Sends both the user response and the answer key to Claude with a
    /// session-type-specific rubric. Claude evaluates semantic structural
    /// similarity and returns a `AnswerKeyComparisonResult`.
    ///
    /// - Parameter input: All inputs for the comparison (user response,
    ///   practice text with answer key, session type, language, level).
    /// - Returns: A structured `AnswerKeyComparisonResult` with match quality,
    ///   dimension scores, feedback, and hidden metadata.
    /// - Throws: `AnswerKeyComparerError` if the API call fails or
    ///   the response cannot be parsed.
    func compare(_ input: ComparisonInput) async throws -> AnswerKeyComparisonResult {
        let systemPrompt = promptBuilder.systemPrompt(for: input)
        let userMessage = promptBuilder.userMessage(for: input)

        let messages = [APIMessage(role: "user", content: userMessage)]

        // Collect the full streamed response
        let stream = await anthropicService.sendMessage(
            systemPrompt: systemPrompt,
            messages: messages
        )

        var fullResponse = ""
        for try await chunk in stream {
            fullResponse += chunk
        }

        // Parse the structured comparison response
        guard let result = responseParser.parse(fullResponse: fullResponse) else {
            throw AnswerKeyComparerError.parsingFailed(response: fullResponse)
        }

        return result
    }
}

// MARK: - Errors

/// Errors specific to answer key comparison.
enum AnswerKeyComparerError: Error, LocalizedError, Sendable {
    case parsingFailed(response: String)

    var errorDescription: String? {
        switch self {
        case .parsingFailed:
            "Failed to parse the comparison response from Claude."
        }
    }
}
