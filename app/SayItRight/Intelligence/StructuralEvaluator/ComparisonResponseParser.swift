import Foundation

/// Parses Claude's comparison response into visible feedback and structured metadata.
///
/// Comparison responses use `<!-- COMPARISON_META: {...} -->` to embed structured
/// evaluation data, similar to the `BARBARA_META` pattern used in coaching sessions.
struct ComparisonResponseParser: Sendable {

    /// Raw decoded JSON from the COMPARISON_META block.
    private struct RawComparisonMeta: Decodable {
        let matchQuality: String
        let dimensionScores: [String: Int]
        let mood: String
        let progressionSignal: String
        let sessionPhase: String
        let feedbackFocus: String
        let language: String
    }

    /// Parse a full comparison response from Claude.
    ///
    /// - Parameter fullResponse: The raw text containing visible feedback
    ///   and a `COMPARISON_META` HTML comment block.
    /// - Returns: A `AnswerKeyComparisonResult` if metadata was found and valid, nil otherwise.
    func parse(fullResponse: String) -> AnswerKeyComparisonResult? {
        let pattern = #"<!--\s*COMPARISON_META:\s*(.*?)\s*-->"#

        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.dotMatchesLineSeparators]
        ) else {
            return nil
        }

        let nsString = fullResponse as NSString
        let matches = regex.matches(
            in: fullResponse,
            range: NSRange(location: 0, length: nsString.length)
        )

        guard let lastMatch = matches.last else {
            return nil
        }

        // Extract JSON from the last metadata block.
        let jsonRange = lastMatch.range(at: 1)
        let jsonString = nsString.substring(with: jsonRange)

        // Remove all metadata blocks from visible text.
        var visibleText = fullResponse
        for match in matches.reversed() {
            guard let fullRange = Range(match.range, in: fullResponse) else { continue }
            visibleText.removeSubrange(fullRange)
        }
        visibleText = visibleText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Decode JSON payload.
        guard let data = jsonString.data(using: .utf8),
              let raw = try? JSONDecoder().decode(RawComparisonMeta.self, from: data),
              let matchQuality = MatchQuality(rawValue: raw.matchQuality) else {
            return nil
        }

        let metadata = ComparisonMetadata(
            mood: raw.mood,
            progressionSignal: raw.progressionSignal,
            sessionPhase: raw.sessionPhase,
            feedbackFocus: raw.feedbackFocus,
            language: raw.language
        )

        return AnswerKeyComparisonResult(
            matchQuality: matchQuality,
            feedback: visibleText,
            dimensionScores: raw.dimensionScores,
            metadata: metadata
        )
    }
}
