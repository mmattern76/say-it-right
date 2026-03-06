import Foundation

/// Thread-safe persistence layer for seen text tracking.
///
/// Stores data as `seen-texts.json` in the app's Documents directory,
/// following the same actor-based pattern as `LearnerProfileStore`.
actor SeenTextsStore {
    private let fileURL: URL
    private var record: SeenTextsRecord

    init(directory: URL? = nil) {
        let dir = directory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = dir.appendingPathComponent("seen-texts.json")

        if let data = try? Data(contentsOf: fileURL),
           let loaded = try? JSONDecoder.seenTexts.decode(SeenTextsRecord.self, from: data) {
            self.record = loaded
        } else {
            self.record = SeenTextsRecord()
        }
    }

    var current: SeenTextsRecord { record }

    /// Mark a text as seen for a session type, persisting immediately.
    func markSeen(textID: String, sessionType: String, date: Date = .now) async throws {
        record.markSeen(textID: textID, sessionType: sessionType, date: date)
        try await save()
    }

    /// Returns the set of seen text IDs for a session type.
    func seenIDs(for sessionType: String) -> Set<String> {
        record.seenIDs(for: sessionType)
    }

    /// Selects an unseen text for the given criteria. If all texts at the level
    /// have been seen, resets tracking for that level and returns a text from the
    /// full pool, along with a flag indicating the reset occurred.
    func selectUnseenText(
        sessionType: String,
        level: Int,
        language: String,
        library: PracticeTextLibrary,
        quality: QualityLevel? = nil,
        domain: String? = nil
    ) async throws -> (text: PracticeText, didReset: Bool)? {
        let unseen = record.unseenTexts(
            sessionType: sessionType,
            level: level,
            language: language,
            library: library
        )

        if let available = unseen {
            // Filter further by quality/domain if requested
            let filtered = available.filter { text in
                (quality == nil || text.metadata.qualityLevel == quality)
                    && (domain == nil || text.metadata.topicDomain == domain)
            }
            // Fall back to unfiltered if quality/domain filter is too restrictive
            let pool = filtered.isEmpty ? available : filtered
            guard let selected = pool.randomElement() else { return nil }
            return (text: selected, didReset: false)
        } else {
            // All texts exhausted — reset for this level
            record.resetForLevel(
                sessionType: sessionType,
                level: level,
                language: language,
                library: library
            )
            try await save()

            // Now select from the full pool
            let freshPool = library.texts(forTargetLevel: level, language: language)
                .filter { $0.metadata.targetLevel == level }
                .filter { text in
                    (quality == nil || text.metadata.qualityLevel == quality)
                        && (domain == nil || text.metadata.topicDomain == domain)
                }
            guard let selected = freshPool.randomElement() else { return nil }
            return (text: selected, didReset: true)
        }
    }

    /// Update the record with a transform and persist.
    func update(_ transform: (inout SeenTextsRecord) -> Void) async throws {
        transform(&record)
        try await save()
    }

    func save() async throws {
        let data = try JSONEncoder.seenTexts.encode(record)
        let tempURL = fileURL.deletingLastPathComponent()
            .appendingPathComponent(UUID().uuidString + ".tmp")
        try data.write(to: tempURL, options: .atomic)
        _ = try FileManager.default.replaceItemAt(fileURL, withItemAt: tempURL)
    }

    func reset() async throws {
        record = SeenTextsRecord()
        try await save()
    }

    /// Barbara's acknowledgment message when all texts at a level have been exhausted.
    static func exhaustionMessage(language: String) -> String {
        if language == "de" {
            return "Du hast meine gesamte Sammlung auf diesem Level durchgearbeitet. Lass uns einige nochmal ansehen \u{2014} du wirst sie jetzt mit anderen Augen sehen."
        } else {
            return "You\u{2019}ve worked through my entire collection at this level. Let\u{2019}s revisit some \u{2014} you\u{2019}ll see them differently now."
        }
    }
}

private extension JSONEncoder {
    static let seenTexts: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}

private extension JSONDecoder {
    static let seenTexts: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
