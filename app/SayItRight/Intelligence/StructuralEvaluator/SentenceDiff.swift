import Foundation

/// Computes sentence-level structural diffs between two text attempts.
///
/// Splits texts into sentences and classifies each as kept, added, removed,
/// or moved. Designed for structural comparison, not character-level precision.
struct SentenceDiff: Sendable {

    /// A single sentence with its diff status.
    struct DiffEntry: Sendable, Identifiable, Equatable {
        let id: Int
        let text: String
        let status: DiffStatus
    }

    /// Classification of a sentence in the diff.
    enum DiffStatus: String, Sendable, Equatable {
        case kept       // Present in both, same position
        case added      // Present only in revised version
        case removed    // Present only in original version
        case moved      // Present in both, different position
    }

    /// Result of a structural diff comparison.
    struct DiffResult: Sendable {
        /// Entries for the original text.
        let original: [DiffEntry]
        /// Entries for the revised text.
        let revised: [DiffEntry]
        /// Whether meaningful structural changes were detected.
        let hasStructuralChanges: Bool
    }

    /// Compare two texts at the sentence level.
    static func compare(original: String, revised: String) -> DiffResult {
        let origSentences = splitSentences(original)
        let revSentences = splitSentences(revised)

        let origNormalised = origSentences.map { normalise($0) }
        let revNormalised = revSentences.map { normalise($0) }

        var origEntries: [DiffEntry] = []
        var revEntries: [DiffEntry] = []

        // Classify original sentences
        for (i, sentence) in origSentences.enumerated() {
            let norm = origNormalised[i]

            if let revIndex = revNormalised.firstIndex(of: norm) {
                if revIndex == i {
                    origEntries.append(DiffEntry(id: i, text: sentence, status: .kept))
                } else {
                    origEntries.append(DiffEntry(id: i, text: sentence, status: .moved))
                }
            } else {
                origEntries.append(DiffEntry(id: i, text: sentence, status: .removed))
            }
        }

        // Classify revised sentences
        for (i, sentence) in revSentences.enumerated() {
            let norm = revNormalised[i]

            if let origIndex = origNormalised.firstIndex(of: norm) {
                if origIndex == i {
                    revEntries.append(DiffEntry(id: 1000 + i, text: sentence, status: .kept))
                } else {
                    revEntries.append(DiffEntry(id: 1000 + i, text: sentence, status: .moved))
                }
            } else {
                revEntries.append(DiffEntry(id: 1000 + i, text: sentence, status: .added))
            }
        }

        let hasChanges = origEntries.contains { $0.status != .kept }
            || revEntries.contains { $0.status != .kept }

        return DiffResult(
            original: origEntries,
            revised: revEntries,
            hasStructuralChanges: hasChanges
        )
    }

    // MARK: - Helpers

    /// Split text into sentences using linguistic boundaries.
    static func splitSentences(_ text: String) -> [String] {
        var sentences: [String] = []
        text.enumerateSubstrings(
            in: text.startIndex...,
            options: [.bySentences, .localized]
        ) { substring, _, _, _ in
            if let sentence = substring?.trimmingCharacters(in: .whitespacesAndNewlines),
               !sentence.isEmpty {
                sentences.append(sentence)
            }
        }
        // Fallback: if enumeration yields nothing, split on period
        if sentences.isEmpty && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sentences = text.components(separatedBy: ". ")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        return sentences
    }

    /// Normalise a sentence for comparison (lowercase, collapse whitespace).
    static func normalise(_ sentence: String) -> String {
        sentence.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
