import Foundation

extension String {
    /// The string parsed as inline markdown, ready for `Text`.
    ///
    /// Barbara writes with markdown emphasis (`**conclusion first**`,
    /// `*looks* solid`). `Text(someString)` takes the plain-`String` overload,
    /// which does no markdown parsing, so those markers used to reach the
    /// learner as literal asterisks.
    ///
    /// Parsing is inline-only and whitespace-preserving: emphasis and inline
    /// code are styled while the blank lines Barbara puts between paragraphs
    /// survive, which the default (`.full`) syntax would collapse. Malformed
    /// markdown falls back to as much as could be parsed, and a hard failure
    /// falls back to the raw text — never to an empty bubble.
    var barbaraMarkdown: AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        // A parse failure means the text simply isn't markdown; showing it as
        // written is the correct fallback and there is nothing to report.
        // swiftlint:disable:next no_bare_optional_try
        return (try? AttributedString(markdown: self, options: options)) ?? AttributedString(self)
    }
}
