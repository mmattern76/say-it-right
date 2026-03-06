import Foundation

/// Assembles modular prompt blocks into a complete system prompt for Claude API calls.
///
/// Blocks are loaded from the app bundle in a fixed order:
/// 1. Identity (Barbara's persona)
/// 2. Pedagogy (teaching approach)
/// 3. Rubric (level-specific evaluation criteria)
/// 4. Session template (exercise-type-specific instructions)
/// 5. Session directive (general session rules)
/// 6. Learner profile (JSON snapshot)
/// 7. Output format (response structure specification)
struct SystemPromptAssembler {

    private let bundle: Bundle

    /// - Parameter bundle: The bundle containing prompt block resources.
    ///   Defaults to `Bundle.main`.
    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    // MARK: - Public API

    /// Assemble a complete system prompt from modular blocks.
    /// - Parameters:
    ///   - level: Learner's current level (1 or 2)
    ///   - sessionType: Session type identifier (e.g. "say-it-clearly", "find-the-point")
    ///   - language: Language code ("en" or "de")
    ///   - profileJSON: JSON string of the learner profile
    /// - Returns: The assembled system prompt string
    func assemble(level: Int, sessionType: String, language: String, profileJSON: String) -> String {
        var parts: [String] = []

        // 1–3: Identity, Pedagogy, Rubric
        let blockNames = [
            "identity-\(language)",
            "pedagogy-\(language)",
            "rubric-l\(level)-\(language)"
        ]
        for name in blockNames {
            if let content = loadBlock(name) {
                parts.append(content)
            }
        }

        // 4: Session template
        if let session = loadSession("\(sessionType)-\(language)") {
            parts.append(session)
        }

        // 5: Session directive
        if let directive = loadBlock("session-directive-\(language)") {
            parts.append(directive)
        }

        // 6: Learner profile
        parts.append("# Learner Profile\n\n```json\n\(profileJSON)\n```")

        // 7: Output format
        if let outputFormat = loadBlock("output-format-\(language)") {
            parts.append(outputFormat)
        }

        return parts.joined(separator: "\n\n")
    }

    // MARK: - Private

    private func loadBlock(_ name: String) -> String? {
        guard let url = bundle.url(
            forResource: name,
            withExtension: "md",
            subdirectory: "PromptBlocks"
        ) else {
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    private func loadSession(_ name: String) -> String? {
        guard let url = bundle.url(
            forResource: name,
            withExtension: "md",
            subdirectory: "PromptSessions"
        ) else {
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }
}
