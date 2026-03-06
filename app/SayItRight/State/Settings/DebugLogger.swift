import Foundation

/// Collects in-flight diagnostic data when debug mode is enabled.
///
/// Data is stored locally in the app's documents directory as JSON lines.
/// Viewable and exportable from the parent settings section.
/// Automatically disabled in release builds unless explicitly toggled on.
actor DebugLogger {

    static let shared = DebugLogger()

    private let fileManager = FileManager.default
    private let maxFileSize: Int = 5_000_000 // 5 MB rotation threshold

    private var fileHandle: FileHandle?
    private var currentFilePath: URL?

    /// Whether logging is active. Reads from AppSettings on main actor.
    var isEnabled: Bool {
        AppSettings.shared.isDebugModeEnabled
    }

    // MARK: - Log Entry Types

    enum EntryKind: String, Codable {
        case apiRequest
        case apiResponse
        case apiError
        case metadataParsed
        case sessionEvent
        case evaluationResult
        case configChange
    }

    struct Entry: Codable {
        let timestamp: Date
        let kind: EntryKind
        let data: [String: String]
    }

    // MARK: - Logging

    func log(_ kind: EntryKind, data: [String: String]) {
        guard isEnabled else { return }

        let entry = Entry(
            timestamp: .now,
            kind: kind,
            data: data
        )

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            var line = try encoder.encode(entry)
            line.append(0x0A) // newline
            try ensureFileHandle()
            fileHandle?.write(line)
        } catch {
            #if DEBUG
            print("[DebugLogger] Write failed: \(error)")
            #endif
        }
    }

    // MARK: - Convenience Methods

    func logAPIRequest(model: String, systemPromptTokens: Int, messageCount: Int) {
        log(.apiRequest, data: [
            "model": model,
            "system_prompt_tokens": "\(systemPromptTokens)",
            "message_count": "\(messageCount)"
        ])
    }

    func logAPIResponse(latencyMs: Int, tokensUsed: Int, hasMetadata: Bool) {
        log(.apiResponse, data: [
            "latency_ms": "\(latencyMs)",
            "tokens_used": "\(tokensUsed)",
            "has_metadata": "\(hasMetadata)"
        ])
    }

    func logAPIError(_ error: String, statusCode: Int? = nil) {
        var data = ["error": error]
        if let code = statusCode { data["status_code"] = "\(code)" }
        log(.apiError, data: data)
    }

    func logMetadata(_ metadata: [String: String]) {
        log(.metadataParsed, data: metadata)
    }

    func logSessionEvent(_ event: String, details: [String: String] = [:]) {
        var data = details
        data["event"] = event
        log(.sessionEvent, data: data)
    }

    // MARK: - Reading & Export

    /// Returns all log entries from the current log file.
    func entries() throws -> [Entry] {
        guard let path = logFilePath() else { return [] }
        let data = try Data(contentsOf: path)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return data.split(separator: 0x0A).compactMap { line in
            try? decoder.decode(Entry.self, from: Data(line))
        }
    }

    /// Returns the raw log file URL for sharing/export.
    func logFileURL() -> URL? {
        logFilePath()
    }

    /// Deletes all collected debug data.
    func clearLogs() throws {
        closeFile()
        if let path = logFilePath() {
            try? fileManager.removeItem(at: path)
        }
    }

    // MARK: - File Management

    private func logFilePath() -> URL? {
        guard let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return docs.appendingPathComponent("debug-log.jsonl")
    }

    private func ensureFileHandle() throws {
        if fileHandle != nil { return }

        guard let path = logFilePath() else { return }

        if !fileManager.fileExists(atPath: path.path) {
            fileManager.createFile(atPath: path.path, contents: nil)
        }

        // Rotate if too large
        if let attrs = try? fileManager.attributesOfItem(atPath: path.path),
           let size = attrs[.size] as? Int, size > maxFileSize {
            try? fileManager.removeItem(at: path)
            fileManager.createFile(atPath: path.path, contents: nil)
        }

        fileHandle = try FileHandle(forWritingTo: path)
        fileHandle?.seekToEndOfFile()
        currentFilePath = path
    }

    private func closeFile() {
        try? fileHandle?.close()
        fileHandle = nil
        currentFilePath = nil
    }
}
