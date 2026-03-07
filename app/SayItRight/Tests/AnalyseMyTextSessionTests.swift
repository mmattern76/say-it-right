import Foundation
import Testing
@testable import SayItRight

@Suite("AnalyseMyTextSession")
struct AnalyseMyTextSessionTests {

    @Test("Session initialises with defaults")
    func initialisation() {
        let session = AnalyseMyTextSession()

        #expect(session.sessionTypeID == "analyse-my-text")
        #expect(!session.hasSubmission)
        #expect(session.originalText == nil)
        #expect(session.latestText == nil)
        #expect(session.currentRevisionRound == 0)
        #expect(session.maxRevisions == 2)
        #expect(!session.contentFlagged)
    }

    @Test("recordSubmission captures text and word count")
    func recordSubmission() {
        var session = AnalyseMyTextSession()

        session.recordSubmission("Schools should require uniforms. This reduces social pressure among students.")

        #expect(session.hasSubmission)
        #expect(session.originalText?.contains("Schools should") == true)
        #expect(session.submissions.count == 1)
        #expect(session.submissions[0].wordCount == 10)
    }

    @Test("Multiple submissions tracked for revision loop")
    func multipleSubmissions() {
        var session = AnalyseMyTextSession()

        session.recordSubmission("First draft of my essay. It has several points.")
        #expect(session.canRevise == true)
        #expect(session.currentRevisionRound == 0)

        session.recordSubmission("Revised draft with clearer structure. The main point comes first.")
        #expect(session.currentRevisionRound == 1)
        #expect(session.canRevise == true)

        session.recordSubmission("Final revision with tight structure. Lead with conclusion.")
        #expect(session.currentRevisionRound == 2)
        #expect(session.canRevise == false)
        #expect(session.originalText?.contains("First draft") == true)
        #expect(session.latestText?.contains("Final revision") == true)
    }

    @Test("Content flag can be set")
    func contentFlag() {
        var session = AnalyseMyTextSession()
        #expect(!session.contentFlagged)
        session.markContentFlagged()
        #expect(session.contentFlagged)
    }

    // MARK: - Text Validation

    @Test("Empty text is invalid")
    func validateEmpty() {
        #expect(AnalyseMyTextSession.validate("") == .empty)
        #expect(AnalyseMyTextSession.validate("   ") == .empty)
    }

    @Test("Single sentence is too short")
    func validateTooShort() {
        #expect(AnalyseMyTextSession.validate("Just one sentence") == .tooShort)
    }

    @Test("Two sentences is valid")
    func validateMinimum() {
        let text = "This is the first sentence. This is the second sentence."
        #expect(AnalyseMyTextSession.validate(text) == .valid)
    }

    @Test("Very long text is rejected")
    func validateTooLong() {
        let words = (0..<2100).map { "word\($0)" }.joined(separator: " ")
        let text = words + ". Another sentence here."
        let result = AnalyseMyTextSession.validate(text)
        if case .tooLong(let count) = result {
            #expect(count > 2000)
        } else {
            Issue.record("Expected .tooLong but got \(result)")
        }
    }
}

// MARK: - SessionType Tests

@Suite("SessionType — Analyse My Text")
struct SessionTypeAnalyseMyTextTests {

    @Test("analyseMyText raw value")
    func rawValue() {
        #expect(SessionType.analyseMyText.rawValue == "analyse-my-text")
    }

    @Test("English display name")
    func displayNameEN() {
        #expect(SessionType.analyseMyText.displayName(language: "en") == "Analyse my text")
    }

    @Test("German display name")
    func displayNameDE() {
        #expect(SessionType.analyseMyText.displayName(language: "de") == "Analysiere meinen Text")
    }

    @Test("Icon is doc.text")
    func iconName() {
        #expect(SessionType.analyseMyText.iconName == "doc.text")
    }

    @Test("CaseIterable includes analyseMyText")
    func allCases() {
        #expect(SessionType.allCases.contains(.analyseMyText))
        #expect(SessionType.allCases.count >= 4)
    }
}
