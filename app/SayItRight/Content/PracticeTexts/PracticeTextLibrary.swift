import Foundation

/// Loads and filters the bundled practice text library for Break mode exercises.
struct PracticeTextLibrary: Sendable {
    let texts: [PracticeText]

    /// Content version string from the library JSON metadata.
    /// Tracks content updates independently of the app version.
    let contentVersion: String

    init(texts: [PracticeText] = [], contentVersion: String = "0.0.0") {
        self.texts = texts
        self.contentVersion = contentVersion
    }

    /// Loads practice texts from the app bundle JSON files.
    /// Texts are split by language: PracticeTextLibrary_en.json and PracticeTextLibrary_de.json.
    /// Each file uses the versioned container format with `contentVersion` metadata.
    static func loadFromBundle() -> PracticeTextLibrary {
        let decoder = JSONDecoder()
        var allTexts: [PracticeText] = []
        var latestVersion = "0.0.0"

        for language in ["en", "de"] {
            let filename = "PracticeTextLibrary_\(language)"
            guard let url = Bundle.main.url(
                forResource: filename,
                withExtension: "json"
            ) else {
                continue
            }
            guard let data = try? Data(contentsOf: url) else {
                continue
            }

            // Try versioned container format first, fall back to flat array
            if let container = try? decoder.decode(PracticeTextLibraryContainer.self, from: data) {
                allTexts.append(contentsOf: container.texts)
                if container.contentVersion > latestVersion {
                    latestVersion = container.contentVersion
                }
            } else if let texts = try? decoder.decode([PracticeText].self, from: data) {
                allTexts.append(contentsOf: texts)
            }
        }

        return PracticeTextLibrary(texts: allTexts, contentVersion: latestVersion)
    }

    /// Loads practice texts from JSON data (for testing or custom sources).
    /// Supports both the versioned container format and flat arrays.
    static func load(from data: Data) throws -> PracticeTextLibrary {
        let decoder = JSONDecoder()

        if let container = try? decoder.decode(PracticeTextLibraryContainer.self, from: data) {
            return PracticeTextLibrary(
                texts: container.texts,
                contentVersion: container.contentVersion
            )
        }

        let texts = try decoder.decode([PracticeText].self, from: data)
        return PracticeTextLibrary(texts: texts)
    }

    /// Merges another library into this one, appending new texts (by ID).
    /// Returns a new library with the higher content version.
    func merging(_ other: PracticeTextLibrary) -> PracticeTextLibrary {
        let existingIDs = Set(texts.map(\.id))
        let newTexts = other.texts.filter { !existingIDs.contains($0.id) }
        let mergedVersion = contentVersion >= other.contentVersion
            ? contentVersion : other.contentVersion
        return PracticeTextLibrary(
            texts: texts + newTexts,
            contentVersion: mergedVersion
        )
    }

    /// Validates that all text IDs are unique. Returns duplicate IDs if any.
    func validateUniqueIDs() -> [String] {
        var seen = Set<String>()
        var duplicates: [String] = []
        for text in texts {
            if seen.contains(text.id) {
                duplicates.append(text.id)
            }
            seen.insert(text.id)
        }
        return duplicates
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
