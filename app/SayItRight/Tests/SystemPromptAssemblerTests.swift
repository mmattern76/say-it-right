import Foundation
import Testing

@testable import SayItRight

/// Creates a temporary bundle directory populated with prompt block fixtures
/// so that `SystemPromptAssembler` can load them via `Bundle`.
private func makeTestBundle() throws -> Bundle {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("SystemPromptAssemblerTests-\(UUID().uuidString)")

    let blocksDir = root.appendingPathComponent("PromptBlocks")
    let sessionsDir = root.appendingPathComponent("PromptSessions")
    try FileManager.default.createDirectory(at: blocksDir, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: sessionsDir, withIntermediateDirectories: true)

    // English blocks
    let enBlocks: [(String, String)] = [
        ("identity-en", "# Identity EN\nYou are Barbara."),
        ("pedagogy-en", "# Pedagogy EN\nTeach structure."),
        ("rubric-l1-en", "# Rubric L1 EN\nFoundations criteria."),
        ("rubric-l2-en", "# Rubric L2 EN\nGrouping criteria."),
        ("session-directive-en", "# Session Directive EN\nRules for sessions."),
        ("output-format-en", "# Output Format EN\nRespond in JSON postscript.")
    ]

    // German blocks
    let deBlocks: [(String, String)] = [
        ("identity-de", "# Identitaet DE\nDu bist Barbara."),
        ("pedagogy-de", "# Paedagogik DE\nStruktur lehren."),
        ("rubric-l1-de", "# Rubrik L1 DE\nGrundlagen-Kriterien."),
        ("rubric-l2-de", "# Rubrik L2 DE\nOrdnung-Kriterien."),
        ("session-directive-de", "# Sitzungsanweisung DE\nRegeln fuer Sitzungen."),
        ("output-format-de", "# Ausgabeformat DE\nAntwort im JSON-Postskript.")
    ]

    for (name, content) in enBlocks + deBlocks {
        let fileURL = blocksDir.appendingPathComponent("\(name).md")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    // Session templates
    let sessions: [(String, String)] = [
        ("say-it-clearly-en", "# Say It Clearly EN\nQuick drill instructions."),
        ("say-it-clearly-de", "# Sags Klar DE\nSchnelluebung."),
        ("find-the-point-en", "# Find The Point EN\nExtract governing thought."),
        ("find-the-point-de", "# Finde Den Punkt DE\nKernaussage extrahieren.")
    ]

    for (name, content) in sessions {
        let fileURL = sessionsDir.appendingPathComponent("\(name).md")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    guard let bundle = Bundle(url: root) else {
        throw TestError(message: "Could not create bundle from \(root.path)")
    }
    return bundle
}

private struct TestError: Error {
    let message: String
}

// MARK: - Tests

@Suite("SystemPromptAssembler")
struct SystemPromptAssemblerTests {

    let profileJSON = """
    {"name":"Test User","level":1,"language":"en"}
    """

    @Test("Assembly produces a non-empty string")
    func assemblyProducesNonEmptyString() throws {
        let bundle = try makeTestBundle()
        let assembler = SystemPromptAssembler(bundle: bundle)
        let result = assembler.assemble(
            level: 1,
            sessionType: "say-it-clearly",
            language: "en",
            profileJSON: profileJSON
        )
        #expect(!result.isEmpty)
    }

    @Test("Block order: identity first, output-format last")
    func blockOrder() throws {
        let bundle = try makeTestBundle()
        let assembler = SystemPromptAssembler(bundle: bundle)
        let result = assembler.assemble(
            level: 1,
            sessionType: "say-it-clearly",
            language: "en",
            profileJSON: profileJSON
        )

        // Identity should appear before pedagogy, which appears before rubric, etc.
        let identityRange = result.range(of: "# Identity EN")
        let pedagogyRange = result.range(of: "# Pedagogy EN")
        let rubricRange = result.range(of: "# Rubric L1 EN")
        let sessionRange = result.range(of: "# Say It Clearly EN")
        let directiveRange = result.range(of: "# Session Directive EN")
        let profileRange = result.range(of: "# Learner Profile")
        let outputRange = result.range(of: "# Output Format EN")

        #expect(identityRange != nil)
        #expect(outputRange != nil)

        // Verify ordering
        #expect(identityRange!.lowerBound < pedagogyRange!.lowerBound)
        #expect(pedagogyRange!.lowerBound < rubricRange!.lowerBound)
        #expect(rubricRange!.lowerBound < sessionRange!.lowerBound)
        #expect(sessionRange!.lowerBound < directiveRange!.lowerBound)
        #expect(directiveRange!.lowerBound < profileRange!.lowerBound)
        #expect(profileRange!.lowerBound < outputRange!.lowerBound)
    }

    @Test("Language selection: English vs German")
    func languageSelection() throws {
        let bundle = try makeTestBundle()
        let assembler = SystemPromptAssembler(bundle: bundle)

        let enResult = assembler.assemble(
            level: 1,
            sessionType: "say-it-clearly",
            language: "en",
            profileJSON: profileJSON
        )
        let deResult = assembler.assemble(
            level: 1,
            sessionType: "say-it-clearly",
            language: "de",
            profileJSON: profileJSON
        )

        #expect(enResult.contains("# Identity EN"))
        #expect(!enResult.contains("# Identitaet DE"))

        #expect(deResult.contains("# Identitaet DE"))
        #expect(!deResult.contains("# Identity EN"))
    }

    @Test("Level selection: L1 vs L2 rubric")
    func levelSelection() throws {
        let bundle = try makeTestBundle()
        let assembler = SystemPromptAssembler(bundle: bundle)

        let l1Result = assembler.assemble(
            level: 1,
            sessionType: "say-it-clearly",
            language: "en",
            profileJSON: profileJSON
        )
        let l2Result = assembler.assemble(
            level: 2,
            sessionType: "say-it-clearly",
            language: "en",
            profileJSON: profileJSON
        )

        #expect(l1Result.contains("# Rubric L1 EN"))
        #expect(!l1Result.contains("# Rubric L2 EN"))

        #expect(l2Result.contains("# Rubric L2 EN"))
        #expect(!l2Result.contains("# Rubric L1 EN"))
    }

    @Test("Profile JSON is interpolated correctly")
    func profileJSONInterpolation() throws {
        let bundle = try makeTestBundle()
        let assembler = SystemPromptAssembler(bundle: bundle)

        let customProfile = """
        {"name":"Alice","level":2,"strengths":["MECE"]}
        """
        let result = assembler.assemble(
            level: 2,
            sessionType: "find-the-point",
            language: "en",
            profileJSON: customProfile
        )

        #expect(result.contains("# Learner Profile"))
        #expect(result.contains("```json"))
        #expect(result.contains(customProfile))
    }

    @Test("Session type selection works for different types")
    func sessionTypeSelection() throws {
        let bundle = try makeTestBundle()
        let assembler = SystemPromptAssembler(bundle: bundle)

        let sayResult = assembler.assemble(
            level: 1,
            sessionType: "say-it-clearly",
            language: "en",
            profileJSON: profileJSON
        )
        let findResult = assembler.assemble(
            level: 1,
            sessionType: "find-the-point",
            language: "en",
            profileJSON: profileJSON
        )

        #expect(sayResult.contains("# Say It Clearly EN"))
        #expect(!sayResult.contains("# Find The Point EN"))

        #expect(findResult.contains("# Find The Point EN"))
        #expect(!findResult.contains("# Say It Clearly EN"))
    }
}
