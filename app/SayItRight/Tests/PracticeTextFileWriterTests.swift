import Foundation
@testable import SayItRight
import Testing

/// Round-trip contract between the practice-text generator's output and the
/// loader the app actually reads content with.
///
/// The generator writes JSON; `PracticeTextLibrary` decodes it at launch. When
/// those two drift apart the app does not crash — it silently ships an empty
/// library and the learner sees "no texts available". These tests fail instead.
struct PracticeTextFileWriterTests {
    // MARK: - Fixtures

    private func makeText(id: String, language: String = "en") -> PracticeText {
        PracticeText(
            id: id,
            text: "Schools should adopt uniforms. They reduce social pressure and improve focus.",
            answerKey: AnswerKey(
                governingThought: "Schools should adopt uniforms.",
                supports: [
                    SupportGroup(label: "Social pressure", evidence: ["Fewer visible brand differences"]),
                    SupportGroup(label: "Focus", evidence: ["Less time spent on outfit decisions"]),
                ],
                structuralAssessment: "Conclusion first, two clean support groups."
            ),
            metadata: PracticeTextMetadata(
                qualityLevel: .wellStructured,
                difficultyRating: 2,
                topicDomain: "school",
                language: language,
                wordCount: 12,
                targetLevel: 1
            )
        )
    }

    private func makeTempDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("practice-text-writer-\(UUID().uuidString)")
    }

    // MARK: - Round Trip

    @Test("A written practice text decodes back into an identical value")
    func singleTextRoundTrips() throws {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let original = makeText(id: "pt-round-trip-en")
        try PracticeTextFileWriter(outputDirectory: dir).write(original)

        let data = try Data(contentsOf: dir.appendingPathComponent("\(original.id).json"))
        let decoded = try JSONDecoder().decode(PracticeText.self, from: data)

        #expect(decoded == original)
    }

    @Test("A written library container loads through the app's decoder")
    func libraryContainerRoundTrips() throws {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let texts = [makeText(id: "pt-900-en"), makeText(id: "pt-901-de", language: "de")]
        let url = try PracticeTextFileWriter(outputDirectory: dir).writeLibraryContainer(
            texts: texts,
            contentVersion: "9.9.9",
            filename: "PracticeTextLibrary_test.json"
        )

        // Same decode path PracticeTextLibrary.loadFromBundle() uses.
        let container = try JSONDecoder().decode(
            PracticeTextLibraryContainer.self,
            from: Data(contentsOf: url)
        )

        #expect(container.contentVersion == "9.9.9")
        #expect(container.texts == texts)
    }

    @Test("Written texts survive the library's filtering API")
    func writtenTextsAreUsableByTheLibrary() throws {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let texts = [makeText(id: "pt-910-en"), makeText(id: "pt-911-de", language: "de")]
        let url = try PracticeTextFileWriter(outputDirectory: dir).writeLibraryContainer(
            texts: texts,
            contentVersion: "1.0.0",
            filename: "PracticeTextLibrary_en.json"
        )

        let container = try JSONDecoder().decode(
            PracticeTextLibraryContainer.self,
            from: Data(contentsOf: url)
        )
        let library = PracticeTextLibrary(texts: container.texts, contentVersion: container.contentVersion)

        #expect(library.texts(for: "en").count == 1)
        #expect(library.texts(for: "de").count == 1)
        #expect(library.texts(forTargetLevel: 1).count == 2)
    }
}
