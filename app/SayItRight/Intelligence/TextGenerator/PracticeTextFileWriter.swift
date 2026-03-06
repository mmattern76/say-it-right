import Foundation

/// Writes generated practice texts to JSON files in the staging directory.
///
/// Output files follow the naming convention: `{id}.json`
/// Files are written to a configurable staging directory for human review
/// before being moved to the final `content/practice-texts/` directory.
struct PracticeTextFileWriter: Sendable {

    private let outputDirectory: URL

    init(outputDirectory: URL) {
        self.outputDirectory = outputDirectory
    }

    /// Write a single practice text to a JSON file.
    func write(_ practiceText: PracticeText) throws {
        try FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        let data = try encoder.encode(practiceText)
        let fileURL = outputDirectory.appendingPathComponent("\(practiceText.id).json")
        try data.write(to: fileURL, options: .atomic)
    }

    /// Write multiple practice texts, returning the paths of successfully written files.
    func writeAll(_ texts: [PracticeText]) throws -> [URL] {
        var written: [URL] = []
        for text in texts {
            try write(text)
            let fileURL = outputDirectory.appendingPathComponent("\(text.id).json")
            written.append(fileURL)
        }
        return written
    }
}
