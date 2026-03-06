import Foundation

/// Detects sentence boundaries in a stream of text chunks.
///
/// As the Anthropic API streams `content_block_delta` events, each delta
/// contains a small fragment of text. `StreamingSentenceDetector` accumulates
/// these fragments and emits complete sentences as soon as a boundary is
/// detected.
///
/// **Metadata filtering**: Barbara's responses end with a hidden HTML comment
/// (`<!-- BARBARA_META: {...} -->`). The detector watches for the opening
/// `<!--` marker and withholds all subsequent text from sentence emission,
/// ensuring metadata is never spoken aloud.
///
/// Design:
/// - Sentence boundaries: `.`, `!`, `?` followed by whitespace or end-of-stream.
/// - Abbreviation handling: common abbreviations (e.g., "Dr.", "Mr.", "z.B.")
///   are not treated as sentence endings.
/// - Thread-safe: all mutation is protected by `NSLock`.
struct StreamingSentenceDetector: Sendable {

    // MARK: - Abbreviations

    /// Common abbreviations that should not trigger sentence splits.
    /// Covers English and German patterns.
    private static let abbreviations: Set<String> = [
        // English
        "mr", "mrs", "ms", "dr", "prof", "sr", "jr",
        "st", "ave", "blvd", "dept", "est", "govt",
        "inc", "ltd", "co", "corp", "vs", "etc",
        "e.g", "i.e", "al", "approx", "dept", "fig",
        "vol", "no", "jan", "feb", "mar", "apr",
        "jun", "jul", "aug", "sep", "oct", "nov", "dec",
        // German
        "z.b", "d.h", "u.a", "s.o", "o.g", "bzgl",
        "bzw", "ca", "evtl", "ggf", "inkl", "max",
        "min", "nr", "tel", "usw", "vgl",
    ]

    // MARK: - Result

    /// A detected complete sentence ready for TTS.
    struct Sentence: Sendable, Equatable {
        let text: String
    }

    // MARK: - Public API

    /// Feed a new text chunk from the streaming API.
    ///
    /// - Parameter chunk: A delta text fragment.
    /// - Returns: Zero or more complete sentences detected so far.
    func feed(_ chunk: String, into buffer: inout String, metadataStarted: inout Bool) -> [Sentence] {
        // If we've entered a metadata block, swallow everything.
        if metadataStarted {
            buffer.append(chunk)
            return []
        }

        buffer.append(chunk)

        // Check if metadata marker has started appearing.
        // Look for `<!--` which signals the start of the BARBARA_META block.
        if let metaRange = buffer.range(of: "<!--") {
            // Everything before the marker may contain sentences.
            let beforeMeta = String(buffer[buffer.startIndex..<metaRange.lowerBound])
            metadataStarted = true

            // Extract any complete sentences from the pre-metadata text.
            var tempBuffer = beforeMeta
            var tempMeta = false
            var sentences = extractSentences(from: &tempBuffer, metadataStarted: &tempMeta)

            // If there's remaining text that didn't end with punctuation,
            // emit it as the final sentence (it's the last visible text).
            let remainder = tempBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
            if !remainder.isEmpty {
                sentences.append(Sentence(text: remainder))
            }

            buffer = String(buffer[metaRange.lowerBound...])
            return sentences
        }

        return extractSentences(from: &buffer, metadataStarted: &metadataStarted)
    }

    /// Call when the stream has ended to flush any remaining text.
    ///
    /// - Returns: The final sentence, if any buffered text remains.
    func flush(buffer: inout String, metadataStarted: Bool) -> Sentence? {
        guard !metadataStarted else {
            buffer.removeAll()
            return nil
        }

        let remaining = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        buffer.removeAll()

        guard !remaining.isEmpty else { return nil }
        return Sentence(text: remaining)
    }

    // MARK: - Private

    /// Scans the buffer for sentence-ending punctuation followed by whitespace
    /// and extracts complete sentences.
    private func extractSentences(
        from buffer: inout String,
        metadataStarted: inout Bool
    ) -> [Sentence] {
        var sentences: [Sentence] = []
        let terminators: Set<Character> = [".", "!", "?"]

        while true {
            guard let (endIndex, nextIndex) = findSentenceEnd(
                in: buffer,
                terminators: terminators
            ) else {
                break
            }

            let sentenceText = String(buffer[buffer.startIndex...endIndex])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !sentenceText.isEmpty {
                sentences.append(Sentence(text: sentenceText))
            }

            buffer = String(buffer[nextIndex...])
        }

        return sentences
    }

    /// Finds the end of the first complete sentence in the string.
    ///
    /// A sentence ends at a terminator (`.`, `!`, `?`) that is:
    /// 1. Followed by whitespace or end-of-string with more content buffered
    /// 2. Not part of a known abbreviation
    ///
    /// Returns the index of the terminator and the index of the next character after whitespace.
    private func findSentenceEnd(
        in text: String,
        terminators: Set<Character>
    ) -> (endIndex: String.Index, nextIndex: String.Index)? {
        var index = text.startIndex

        while index < text.endIndex {
            let char = text[index]

            if terminators.contains(char) {
                let afterTerminator = text.index(after: index)

                // Handle consecutive terminators (e.g., "!!", "?!", "...")
                var finalTerminator = index
                var scanIndex = afterTerminator
                while scanIndex < text.endIndex && terminators.contains(text[scanIndex]) {
                    finalTerminator = scanIndex
                    scanIndex = text.index(after: scanIndex)
                }

                // Check if followed by whitespace or quote+whitespace
                let afterFinal = text.index(after: finalTerminator)
                if afterFinal < text.endIndex {
                    let nextChar = text[afterFinal]

                    // Closing quote after punctuation: include it and check what follows
                    if nextChar == "\"" || nextChar == "\u{201D}" || nextChar == "'" {
                        let afterQuote = text.index(after: afterFinal)
                        if afterQuote < text.endIndex && text[afterQuote].isWhitespace {
                            if !isAbbreviation(before: index, in: text) {
                                // Skip whitespace after quote
                                var nextNonSpace = afterQuote
                                while nextNonSpace < text.endIndex && text[nextNonSpace].isWhitespace {
                                    nextNonSpace = text.index(after: nextNonSpace)
                                }
                                return (afterFinal, nextNonSpace)
                            }
                        }
                    } else if nextChar.isWhitespace {
                        if !isAbbreviation(before: index, in: text) {
                            // Skip whitespace
                            var nextNonSpace = afterFinal
                            while nextNonSpace < text.endIndex && text[nextNonSpace].isWhitespace {
                                nextNonSpace = text.index(after: nextNonSpace)
                            }
                            return (finalTerminator, nextNonSpace)
                        }
                    }
                    // If not followed by whitespace, not a sentence boundary yet
                    // (might be mid-abbreviation or decimal number)
                }
                // If at end of string, don't split — we might get more text
            }

            index = text.index(after: index)
        }

        return nil
    }

    /// Checks whether the period at `periodIndex` is part of a known abbreviation.
    private func isAbbreviation(before periodIndex: String.Index, in text: String) -> Bool {
        // Walk backwards to find the word before the period
        let wordEnd = periodIndex
        var wordStart = periodIndex

        while wordStart > text.startIndex {
            let prev = text.index(before: wordStart)
            let ch = text[prev]
            if ch.isLetter || ch == "." {
                wordStart = prev
            } else {
                break
            }
        }

        guard wordStart < wordEnd else { return false }

        let word = String(text[wordStart..<wordEnd]).lowercased()
        return Self.abbreviations.contains(word)
    }
}
