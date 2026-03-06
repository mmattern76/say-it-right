import Testing
@testable import SayItRight

@Suite("StreamingSentenceDetector")
struct StreamingSentenceDetectorTests {

    let detector = StreamingSentenceDetector()

    // MARK: - Basic Sentence Detection

    @Test("Detects single sentence ending with period followed by space")
    func singleSentenceWithPeriod() {
        var buffer = ""
        var metadataStarted = false

        let sentences = detector.feed("Hello world. ", into: &buffer, metadataStarted: &metadataStarted)
        #expect(sentences.count == 1)
        #expect(sentences.first?.text == "Hello world.")
    }

    @Test("Detects sentence ending with exclamation mark")
    func sentenceWithExclamation() {
        var buffer = ""
        var metadataStarted = false

        let sentences = detector.feed("Great job! ", into: &buffer, metadataStarted: &metadataStarted)
        #expect(sentences.count == 1)
        #expect(sentences.first?.text == "Great job!")
    }

    @Test("Detects sentence ending with question mark")
    func sentenceWithQuestion() {
        var buffer = ""
        var metadataStarted = false

        let sentences = detector.feed("Are you ready? ", into: &buffer, metadataStarted: &metadataStarted)
        #expect(sentences.count == 1)
        #expect(sentences.first?.text == "Are you ready?")
    }

    @Test("Detects multiple sentences in one chunk")
    func multipleSentences() {
        var buffer = ""
        var metadataStarted = false

        let sentences = detector.feed(
            "First sentence. Second sentence! Third? ",
            into: &buffer,
            metadataStarted: &metadataStarted
        )
        #expect(sentences.count == 3)
        #expect(sentences[0].text == "First sentence.")
        #expect(sentences[1].text == "Second sentence!")
        #expect(sentences[2].text == "Third?")
    }

    // MARK: - Incremental Feeding

    @Test("Accumulates chunks until sentence boundary")
    func incrementalChunks() {
        var buffer = ""
        var metadataStarted = false

        var result = detector.feed("Hello ", into: &buffer, metadataStarted: &metadataStarted)
        #expect(result.isEmpty)

        result = detector.feed("world", into: &buffer, metadataStarted: &metadataStarted)
        #expect(result.isEmpty)

        // ". Next" — period followed by space triggers "Hello world." detection
        result = detector.feed(". Next", into: &buffer, metadataStarted: &metadataStarted)
        #expect(result.count == 1)
        #expect(result[0].text == "Hello world.")

        // "Next" is still buffered, no sentence end yet
        result = detector.feed(" sentence. ", into: &buffer, metadataStarted: &metadataStarted)
        #expect(result.count == 1)
        #expect(result[0].text == "Next sentence.")
    }

    @Test("Flush emits remaining buffered text")
    func flushRemainingText() {
        var buffer = ""
        var metadataStarted = false

        _ = detector.feed("Final words", into: &buffer, metadataStarted: &metadataStarted)

        let flushed = detector.flush(buffer: &buffer, metadataStarted: metadataStarted)
        #expect(flushed?.text == "Final words")
        #expect(buffer.isEmpty)
    }

    // MARK: - Abbreviation Handling

    @Test("Does not split on Dr. abbreviation")
    func doctorAbbreviation() {
        var buffer = ""
        var metadataStarted = false

        let sentences = detector.feed(
            "Dr. Smith is here. Welcome. ",
            into: &buffer,
            metadataStarted: &metadataStarted
        )
        // Should get two sentences, not splitting on "Dr."
        #expect(sentences.count == 2)
        #expect(sentences[0].text == "Dr. Smith is here.")
        #expect(sentences[1].text == "Welcome.")
    }

    @Test("Does not split on e.g. abbreviation")
    func egAbbreviation() {
        var buffer = ""
        var metadataStarted = false

        let sentences = detector.feed(
            "Use tools e.g. a hammer. Done. ",
            into: &buffer,
            metadataStarted: &metadataStarted
        )
        #expect(sentences.count == 2)
        #expect(sentences[0].text == "Use tools e.g. a hammer.")
    }

    // MARK: - Metadata Filtering

    @Test("Stops emitting sentences when metadata marker appears")
    func metadataFiltering() {
        var buffer = ""
        var metadataStarted = false

        var sentences = detector.feed(
            "Good work! ",
            into: &buffer,
            metadataStarted: &metadataStarted
        )
        #expect(sentences.count == 1)
        #expect(sentences[0].text == "Good work!")

        sentences = detector.feed(
            "<!-- BARBARA_META: {\"scores\":{}} -->",
            into: &buffer,
            metadataStarted: &metadataStarted
        )
        #expect(sentences.isEmpty)
        #expect(metadataStarted)
    }

    @Test("Metadata in same chunk as final sentence")
    func metadataWithFinalSentence() {
        var buffer = ""
        var metadataStarted = false

        let sentences = detector.feed(
            "Last sentence. <!-- BARBARA_META: {} -->",
            into: &buffer,
            metadataStarted: &metadataStarted
        )
        #expect(sentences.count == 1)
        #expect(sentences[0].text == "Last sentence.")
        #expect(metadataStarted)
    }

    @Test("Flush returns nil when metadata has started")
    func flushDuringMetadata() {
        var buffer = "some leftover"
        let metadataStarted = true

        let flushed = detector.flush(buffer: &buffer, metadataStarted: metadataStarted)
        #expect(flushed == nil)
    }

    @Test("Text without terminal punctuation before metadata is emitted")
    func textBeforeMetadataWithoutPunctuation() {
        var buffer = ""
        var metadataStarted = false

        let sentences = detector.feed(
            "Try again<!-- BARBARA_META: {} -->",
            into: &buffer,
            metadataStarted: &metadataStarted
        )
        #expect(sentences.count == 1)
        #expect(sentences[0].text == "Try again")
        #expect(metadataStarted)
    }

    // MARK: - Edge Cases

    @Test("Empty chunk produces no sentences")
    func emptyChunk() {
        var buffer = ""
        var metadataStarted = false

        let sentences = detector.feed("", into: &buffer, metadataStarted: &metadataStarted)
        #expect(sentences.isEmpty)
    }

    @Test("Flush on empty buffer returns nil")
    func flushEmpty() {
        var buffer = ""
        let flushed = detector.flush(buffer: &buffer, metadataStarted: false)
        #expect(flushed == nil)
    }

    @Test("Consecutive terminators treated as single boundary")
    func consecutiveTerminators() {
        var buffer = ""
        var metadataStarted = false

        let sentences = detector.feed("Really?! Next. ", into: &buffer, metadataStarted: &metadataStarted)
        #expect(sentences.count == 2)
        #expect(sentences[0].text == "Really?!")
    }
}
