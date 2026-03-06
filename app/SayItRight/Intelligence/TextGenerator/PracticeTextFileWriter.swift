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

    /// Write a batch of texts as a versioned library container JSON file.
    ///
    /// This produces a file in the container format expected by
    /// `PracticeTextLibrary.loadFromBundle()`, suitable for merging into
    /// an existing library file.
    func writeLibraryContainer(
        texts: [PracticeText],
        contentVersion: String,
        filename: String
    ) throws -> URL {
        try FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let container = PracticeTextLibraryContainer(
            contentVersion: contentVersion,
            generatedDate: formatter.string(from: Date()),
            texts: texts
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        let data = try encoder.encode(container)
        let fileURL = outputDirectory.appendingPathComponent(filename)
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }
}
