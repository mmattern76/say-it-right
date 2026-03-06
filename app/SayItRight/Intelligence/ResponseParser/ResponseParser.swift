import Foundation

/// Parsed result from Barbara's response.
struct ParsedResponse {
    let visibleText: String
    let metadata: BarbaraMetadata?
}

/// Hidden metadata appended to every Barbara response.
///
/// Barbara's system prompt instructs her to end each reply with
/// `<!-- BARBARA_META: { … } -->`. This struct captures that JSON payload.
struct BarbaraMetadata: Codable, Sendable {
    let scores: [String: Int]
    let totalScore: Int
    let mood: BarbaraMood
    let progressionSignal: ProgressionSignal
    let revisionRound: Int
    let sessionPhase: SessionPhase
    let feedbackFocus: String
    let language: String
}

// MARK: - Supporting Enums

/// Signal indicating the learner's trajectory within the current level.
enum ProgressionSignal: String, Codable, Sendable {
    case none
    case improving
    case struggling
    case readyForLevelUp = "ready_for_level_up"
    case regression
}

/// Phase of a coaching session, used to adapt Barbara's behaviour.
enum SessionPhase: String, Codable, Sendable {
    case greeting
    case topicPresentation = "topic_presentation"
    case evaluation
    case revision
    case summary
    case closing
}

// NOTE: `BarbaraMood` is defined in Presentation/Chat/BarbaraMood.swift
// and shared across the single app target. It provides the 8 mood cases:
// attentive, skeptical, approving, waiting, proud, evaluating, teaching, disappointed.

// MARK: - ResponseParser

/// Parses Barbara's response into visible text and hidden metadata.
///
/// Barbara ends every reply with an HTML comment containing structured
/// evaluation data:
/// ```
/// <!-- BARBARA_META: {"scores":{"clarity":3}, …} -->
/// ```
/// `ResponseParser` strips that block from the user-visible text and
/// decodes its JSON payload into a `BarbaraMetadata` value.
struct ResponseParser {

    /// Parse a complete response from Barbara.
    ///
    /// - Parameter fullResponse: The raw text returned by the LLM,
    ///   potentially containing one or more `BARBARA_META` blocks.
    /// - Returns: A `ParsedResponse` with clean visible text and,
    ///   if present and valid, the decoded metadata from the *last* block.
    func parse(fullResponse: String) -> ParsedResponse {
        // Pattern: <!-- BARBARA_META: {...} -->
        let pattern = #"<!--\s*BARBARA_META:\s*(.*?)\s*-->"#

        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.dotMatchesLineSeparators]
        ) else {
            return ParsedResponse(visibleText: fullResponse, metadata: nil)
        }

        let nsString = fullResponse as NSString
        let matches = regex.matches(
            in: fullResponse,
            range: NSRange(location: 0, length: nsString.length)
        )

        guard let lastMatch = matches.last else {
            return ParsedResponse(
                visibleText: fullResponse.trimmingCharacters(in: .whitespacesAndNewlines),
                metadata: nil
            )
        }

        // Extract JSON from the last metadata block.
        let jsonRange = lastMatch.range(at: 1)
        let jsonString = nsString.substring(with: jsonRange)

        // Remove all metadata blocks from visible text.
        var visibleText = fullResponse
        for match in matches.reversed() {
            let fullRange = Range(match.range, in: fullResponse)!
            visibleText.removeSubrange(fullRange)
        }
        visibleText = visibleText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Decode JSON payload.
        let metadata: BarbaraMetadata?
        if let data = jsonString.data(using: .utf8) {
            let decoder = JSONDecoder()
            metadata = try? decoder.decode(BarbaraMetadata.self, from: data)
        } else {
            metadata = nil
        }

        return ParsedResponse(visibleText: visibleText, metadata: metadata)
    }
}
