import Foundation
import Testing
@testable import SayItRight

@Suite("SentenceDiff")
struct SentenceDiffTests {

    @Test("Identical texts have no structural changes")
    func identicalTexts() {
        let result = SentenceDiff.compare(
            original: "Schools should start later. Students need sleep.",
            revised: "Schools should start later. Students need sleep."
        )
        #expect(!result.hasStructuralChanges)
        #expect(result.original.allSatisfy { $0.status == .kept })
        #expect(result.revised.allSatisfy { $0.status == .kept })
    }

    @Test("Added sentence detected")
    func addedSentence() {
        let result = SentenceDiff.compare(
            original: "Schools should start later.",
            revised: "Schools should start later. This helps academic performance."
        )
        #expect(result.hasStructuralChanges)
        #expect(result.revised.contains { $0.status == .added })
    }

    @Test("Removed sentence detected")
    func removedSentence() {
        let result = SentenceDiff.compare(
            original: "Schools should start later. There are many reasons for this.",
            revised: "Schools should start later."
        )
        #expect(result.hasStructuralChanges)
        #expect(result.original.contains { $0.status == .removed })
    }

    @Test("Moved sentence detected")
    func movedSentence() {
        let result = SentenceDiff.compare(
            original: "There are many reasons. The main point is this. Evidence supports it.",
            revised: "The main point is this. There are many reasons. Evidence supports it."
        )
        #expect(result.hasStructuralChanges)
        #expect(result.original.contains { $0.status == .moved })
        #expect(result.revised.contains { $0.status == .moved })
    }

    @Test("Split sentences handles standard punctuation")
    func splitSentences() {
        let sentences = SentenceDiff.splitSentences(
            "First sentence. Second sentence! Third sentence?"
        )
        #expect(sentences.count == 3)
    }

    @Test("Normalise collapses whitespace and lowercases")
    func normalise() {
        let result = SentenceDiff.normalise("  Hello   WORLD  ")
        #expect(result == "hello world")
    }

    @Test("Case-insensitive matching")
    func caseInsensitive() {
        let result = SentenceDiff.compare(
            original: "Schools Should Start Later.",
            revised: "schools should start later."
        )
        #expect(!result.hasStructuralChanges)
    }

    @Test("Empty texts produce no entries")
    func emptyTexts() {
        let result = SentenceDiff.compare(original: "", revised: "")
        #expect(result.original.isEmpty)
        #expect(result.revised.isEmpty)
        #expect(!result.hasStructuralChanges)
    }

    @Test("Complete rewrite marks all as removed and added")
    func completeRewrite() {
        let result = SentenceDiff.compare(
            original: "Old content here. Another old sentence.",
            revised: "Completely new content. Different structure entirely."
        )
        #expect(result.hasStructuralChanges)
        #expect(result.original.allSatisfy { $0.status == .removed })
        #expect(result.revised.allSatisfy { $0.status == .added })
    }
}
