import Foundation

/// Thread-safe persistence layer for session history.
actor SessionHistoryStore {
    private let fileURL: URL
    private var sessions: [SessionSummary]

    static let maxSessions = 200

    init(directory: URL? = nil) async {
        let dir = directory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = dir.appendingPathComponent("session-history.json")

        if let data = try? Data(contentsOf: fileURL),
           let loaded = try? JSONDecoder.iso8601.decode([SessionSummary].self, from: data) {
            self.sessions = loaded
        } else {
            self.sessions = []
        }
    }

    /// All sessions, newest first.
    var allSessions: [SessionSummary] {
        sessions.sorted { $0.date > $1.date }
    }

    /// Most recent N sessions, newest first.
    func recentSessions(_ count: Int) -> [SessionSummary] {
        Array(allSessions.prefix(count))
    }

    /// Total number of stored sessions.
    var count: Int { sessions.count }

    /// Append a new session summary. Prunes oldest if over limit.
    func append(_ summary: SessionSummary) async throws {
        sessions.append(summary)

        if sessions.count > Self.maxSessions {
            let sorted = sessions.sorted { $0.date < $1.date }
            sessions = Array(sorted.suffix(Self.maxSessions))
        }

        try await save()
    }

    /// Remove all sessions (for testing).
    func removeAll() async throws {
        sessions = []
        try await save()
    }

    private func save() async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(sessions)
        let tempURL = fileURL.deletingLastPathComponent()
            .appendingPathComponent(UUID().uuidString + ".tmp")
        try data.write(to: tempURL, options: .atomic)
        _ = try FileManager.default.replaceItemAt(fileURL, withItemAt: tempURL)
    }
}

private extension JSONDecoder {
    static let iso8601: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
