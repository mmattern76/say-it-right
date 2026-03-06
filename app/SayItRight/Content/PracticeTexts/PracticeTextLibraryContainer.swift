import Foundation

/// Versioned container for the practice text library JSON files.
///
/// Wraps the flat array of `PracticeText` with metadata that tracks
/// content version independently of the app version, enabling additive
/// updates without breaking existing functionality.
struct PracticeTextLibraryContainer: Codable, Sendable, Equatable {
    /// Semantic version string for the content (e.g. "1.0.0").
    /// Tracks content updates independently of the app version.
    let contentVersion: String

    /// ISO 8601 date string when this content batch was generated.
    let generatedDate: String

    /// The practice texts in this library file.
    let texts: [PracticeText]

    init(
        contentVersion: String,
        generatedDate: String,
        texts: [PracticeText]
    ) {
        self.contentVersion = contentVersion
        self.generatedDate = generatedDate
        self.texts = texts
    }
}
