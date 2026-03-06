import Foundation

// MARK: - Data Types

/// A single message in the Anthropic Messages API conversation format.
struct ChatMessage: Codable, Sendable {
    let role: String
    let content: String
}

// MARK: - Errors

/// Errors that can occur when communicating with the Anthropic API.
enum AnthropicServiceError: Error, LocalizedError, Sendable {
    case missingAPIKey
    case invalidURL
    case invalidAPIKey
    case rateLimited(retryAfter: String?)
    case serverError(statusCode: Int, message: String)
    case networkTimeout
    case unexpectedResponse(statusCode: Int)
    case decodingError(String)
    case streamingError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "No API key configured. Add one in parent settings."
        case .invalidURL:
            "Invalid API endpoint URL."
        case .invalidAPIKey:
            "Invalid API key. Check your key in parent settings."
        case .rateLimited(let retryAfter):
            if let retry = retryAfter {
                "Rate limited. Try again in \(retry) seconds."
            } else {
                "Rate limited. Please wait before trying again."
            }
        case .serverError(let code, let message):
            "Server error (\(code)): \(message)"
        case .networkTimeout:
            "Network request timed out. Check your connection."
        case .unexpectedResponse(let code):
            "Unexpected response (HTTP \(code))."
        case .decodingError(let detail):
            "Failed to decode response: \(detail)"
        case .streamingError(let detail):
            "Streaming error: \(detail)"
        }
    }
}

// MARK: - SSE Event Types

/// Parsed SSE event from the Anthropic streaming API.
enum SSEEvent: Sendable {
    case messageStart
    case contentBlockStart
    case contentBlockDelta(text: String)
    case contentBlockStop
    case messageStop
    case messageDelta
    case ping
    case error(String)
    case unknown(type: String)
}

// MARK: - SSE Parser

/// Parses Server-Sent Events (SSE) lines into structured events.
///
/// The Anthropic streaming API sends events in SSE format:
/// ```
/// event: content_block_delta
/// data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello"}}
/// ```
struct SSEParser: Sendable {

    /// Parse a single SSE data line (the JSON after `data: `).
    ///
    /// - Parameter dataLine: The raw JSON string from an SSE `data:` field.
    /// - Returns: The parsed event, or nil if the line is empty or `[DONE]`.
    func parse(dataLine: String) -> SSEEvent? {
        let trimmed = dataLine.trimmingCharacters(in: .whitespaces)

        if trimmed.isEmpty || trimmed == "[DONE]" {
            return nil
        }

        guard let data = trimmed.data(using: .utf8) else {
            return .error("Invalid UTF-8 in SSE data")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            return .error("Failed to parse SSE JSON")
        }

        switch type {
        case "message_start":
            return .messageStart
        case "content_block_start":
            return .contentBlockStart
        case "content_block_delta":
            if let delta = json["delta"] as? [String: Any],
               let text = delta["text"] as? String {
                return .contentBlockDelta(text: text)
            }
            return .contentBlockDelta(text: "")
        case "content_block_stop":
            return .contentBlockStop
        case "message_stop":
            return .messageStop
        case "message_delta":
            return .messageDelta
        case "ping":
            return .ping
        case "error":
            let errorMsg = (json["error"] as? [String: Any])?["message"] as? String
                ?? "Unknown streaming error"
            return .error(errorMsg)
        default:
            return .unknown(type: type)
        }
    }
}

// MARK: - AnthropicService

/// Communicates with the Anthropic Messages API using streaming SSE responses.
///
/// Retrieves the API key from `KeychainService` (override) or `ConfigProvider`
/// (bundled fallback). Sends conversation history with the assembled system
/// prompt and returns an `AsyncThrowingStream` of text deltas for progressive
/// display.
actor AnthropicService {

    static let shared = AnthropicService()

    // MARK: - Configuration

    private let apiEndpoint = "https://api.anthropic.com/v1/messages"
    private let anthropicVersion = "2023-06-01"
    private let maxTokens = 1024
    private let requestTimeout: TimeInterval = 60

    let sseParser = SSEParser()

    // MARK: - Public API

    /// Send a message to the Anthropic API and stream back the response.
    ///
    /// - Parameters:
    ///   - systemPrompt: The assembled system prompt (from `SystemPromptAssembler`).
    ///   - messages: The conversation history as an array of `ChatMessage`.
    ///   - model: Optional model ID override. Defaults to `ModelCatalog.defaultModelID`.
    /// - Returns: An `AsyncThrowingStream` yielding text chunks as they arrive.
    func sendMessage(
        systemPrompt: String,
        messages: [ChatMessage],
        model: String? = nil
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let apiKey = try await resolveAPIKey()
                    let request = try buildRequest(
                        apiKey: apiKey,
                        systemPrompt: systemPrompt,
                        messages: messages,
                        model: model ?? ModelCatalog.defaultModelID
                    )
                    try await streamResponse(request: request, continuation: continuation)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - Private: API Key Resolution

    /// Resolve the API key: Keychain override first, then Config.plist fallback.
    private func resolveAPIKey() async throws -> String {
        // 1. Check Keychain override (set in parent settings)
        if let keychainKey = await KeychainService.shared.retrieveAPIKey() {
            return keychainKey
        }

        // 2. Fall back to bundled Config.plist
        if let configKey = ConfigProvider.anthropicAPIKey {
            return configKey
        }

        throw AnthropicServiceError.missingAPIKey
    }

    // MARK: - Private: Request Building

    private func buildRequest(
        apiKey: String,
        systemPrompt: String,
        messages: [ChatMessage],
        model: String
    ) throws -> URLRequest {
        guard let url = URL(string: apiEndpoint) else {
            throw AnthropicServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = requestTimeout

        // Required headers per Anthropic API docs
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        // Build request body
        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "stream": true,
            "system": systemPrompt,
            "messages": messages.map { ["role": $0.role, "content": $0.content] }
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    // MARK: - Private: Streaming

    private func streamResponse(
        request: URLRequest,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        let (bytes, response): (URLSession.AsyncBytes, URLResponse)
        do {
            (bytes, response) = try await URLSession.shared.bytes(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw AnthropicServiceError.networkTimeout
        } catch let error as URLError where error.code == .notConnectedToInternet
            || error.code == .networkConnectionLost {
            throw AnthropicServiceError.networkTimeout
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AnthropicServiceError.unexpectedResponse(statusCode: 0)
        }

        // Handle HTTP error status codes before reading the stream
        try handleHTTPStatus(httpResponse, bytes: bytes)

        // Parse SSE stream line by line
        for try await line in bytes.lines {
            if Task.isCancelled { break }

            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip SSE event-type lines and empty lines (event boundaries)
            guard trimmed.hasPrefix("data:") else { continue }

            let dataContent = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)

            if let event = sseParser.parse(dataLine: dataContent) {
                switch event {
                case .contentBlockDelta(let text):
                    if !text.isEmpty {
                        continuation.yield(text)
                    }
                case .error(let message):
                    continuation.finish(throwing: AnthropicServiceError.streamingError(message))
                    return
                case .messageStop:
                    continuation.finish()
                    return
                case .messageStart, .contentBlockStart, .contentBlockStop,
                     .messageDelta, .ping, .unknown:
                    // These events don't produce text output
                    break
                }
            }
        }

        // Stream ended without explicit message_stop
        continuation.finish()
    }

    /// Check HTTP status and throw appropriate errors for non-200 responses.
    private func handleHTTPStatus(
        _ response: HTTPURLResponse,
        bytes: URLSession.AsyncBytes
    ) throws {
        switch response.statusCode {
        case 200:
            return // Success — proceed to stream
        case 401:
            throw AnthropicServiceError.invalidAPIKey
        case 429:
            let retryAfter = response.value(forHTTPHeaderField: "retry-after")
            throw AnthropicServiceError.rateLimited(retryAfter: retryAfter)
        case 400...499:
            throw AnthropicServiceError.unexpectedResponse(statusCode: response.statusCode)
        case 500...599:
            throw AnthropicServiceError.serverError(
                statusCode: response.statusCode,
                message: "Anthropic API server error"
            )
        default:
            throw AnthropicServiceError.unexpectedResponse(statusCode: response.statusCode)
        }
    }
}
