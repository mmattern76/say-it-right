import Foundation

/// Loads and filters the bundled practice text library for Break mode exercises.
struct PracticeTextLibrary: Sendable {
    let texts: [PracticeText]

    init(texts: [PracticeText] = []) {
        self.texts = texts
    }

    /// Loads practice texts from the app bundle JSON files.
    /// Texts are split by language: PracticeTextLibrary_en.json and PracticeTextLibrary_de.json.
    static func loadFromBundle() -> PracticeTextLibrary {
        let decoder = JSONDecoder()
        var allTexts: [PracticeText] = []

        for language in ["en", "de"] {
            let filename = "PracticeTextLibrary_\(language)"
            guard let url = Bundle.main.url(
                forResource: filename,
                withExtension: "json",
                subdirectory: "PracticeTexts"
            ) else {
                continue
            }
            guard let data = try? Data(contentsOf: url),
                  let texts = try? decoder.decode([PracticeText].self, from: data)
            else {
                continue
            }
            allTexts.append(contentsOf: texts)
        }

        return PracticeTextLibrary(texts: allTexts)
    }

    /// All texts for a given language.
    func texts(for language: String) -> [PracticeText] {
        texts.filter { $0.metadata.language == language }
    }

    /// Texts matching a quality level and optional language filter.
    func texts(quality: QualityLevel, language: String? = nil) -> [PracticeText] {
        texts.filter { text in
            text.metadata.qualityLevel == quality
                && (language == nil || text.metadata.language == language)
        }
    }

    /// Texts matching a target level and optional language filter.
    func texts(forTargetLevel level: Int, language: String? = nil) -> [PracticeText] {
        texts.filter { text in
            text.metadata.targetLevel <= level
                && (language == nil || text.metadata.language == language)
        }
    }

    /// Texts matching a topic domain and optional language filter.
    func texts(domain: String, language: String? = nil) -> [PracticeText] {
        texts.filter { text in
            text.metadata.topicDomain == domain
                && (language == nil || text.metadata.language == language)
        }
    }

    /// Returns a random text matching the given criteria, excluding previously seen IDs.
    func randomText(
        quality: QualityLevel? = nil,
        targetLevel: Int? = nil,
        domain: String? = nil,
        language: String? = nil,
        excluding seen: Set<String> = []
    ) -> PracticeText? {
        let candidates = texts.filter { text in
            (quality == nil || text.metadata.qualityLevel == quality)
                && (targetLevel == nil || text.metadata.targetLevel <= targetLevel!)
                && (domain == nil || text.metadata.topicDomain == domain)
                && (language == nil || text.metadata.language == language)
                && !seen.contains(text.id)
        }
        return candidates.randomElement()
    }
}
