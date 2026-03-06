import Foundation

/// Tracks which practice text IDs the user has encountered, per session type.
///
/// Data model: `{ sessionType: { textID: dateSeen } }`.
/// The date is stored to enable future cooldown logic (re-show after N days).
struct SeenTextsRecord: Codable, Sendable, Equatable {
    /// Map from session type raw value to a dictionary of text ID → date seen.
    var entries: [String: [String: Date]]

    init(entries: [String: [String: Date]] = [:]) {
        self.entries = entries
    }

    /// Mark a text as seen for a given session type.
    mutating func markSeen(textID: String, sessionType: String, date: Date = .now) {
        var sessionEntries = entries[sessionType] ?? [:]
        sessionEntries[textID] = date
        entries[sessionType] = sessionEntries
    }

    /// Returns the set of text IDs seen for a given session type.
    func seenIDs(for sessionType: String) -> Set<String> {
        guard let sessionEntries = entries[sessionType] else { return [] }
        return Set(sessionEntries.keys)
    }

    /// Resets all seen texts for a specific session type and difficulty level,
    /// given the full library of texts to determine which IDs belong to that level.
    mutating func resetForLevel(
        sessionType: String,
        level: Int,
        language: String,
        library: PracticeTextLibrary
    ) {
        let levelTextIDs = Set(
            library.texts(forTargetLevel: level, language: language)
                .filter { $0.metadata.targetLevel == level }
                .map(\.id)
        )
        // Only remove entries for texts at this specific level
        guard var sessionEntries = entries[sessionType] else { return }
        for id in levelTextIDs {
            sessionEntries.removeValue(forKey: id)
        }
        entries[sessionType] = sessionEntries.isEmpty ? nil : sessionEntries
    }

    /// Returns unseen texts from the library for a given session type, level, and language.
    /// If all texts at that level have been seen, returns nil to signal a reset is needed.
    func unseenTexts(
        sessionType: String,
        level: Int,
        language: String,
        library: PracticeTextLibrary
    ) -> [PracticeText]? {
        let candidates = library.texts(forTargetLevel: level, language: language)
            .filter { $0.metadata.targetLevel == level }
        let seen = seenIDs(for: sessionType)
        let unseen = candidates.filter { !seen.contains($0.id) }
        if unseen.isEmpty && !candidates.isEmpty {
            return nil // signals exhaustion
        }
        return unseen
    }
}
