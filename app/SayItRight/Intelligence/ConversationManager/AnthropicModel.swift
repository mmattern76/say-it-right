import Foundation

/// A Claude model available from the Anthropic API.
///
/// Models are fetched dynamically from the backend `/models` endpoint.
/// A hardcoded fallback list is used when the backend is unreachable.
struct AnthropicModelInfo: Identifiable, Codable, Sendable, Hashable {
    let id: String
    let displayName: String
    let createdAt: String

    /// Best-effort family extraction for fallback matching.
    /// e.g. "claude-sonnet-4-5-20250514" → "sonnet"
    var family: String {
        let lower = id.lowercased()
        if lower.contains("opus") { return "opus" }
        if lower.contains("sonnet") { return "sonnet" }
        if lower.contains("haiku") { return "haiku" }
        return "unknown"
    }

    /// Major version number extracted from model ID.
    /// e.g. "claude-sonnet-4-5-..." → 4
    var majorVersion: Int? {
        let parts = id.replacingOccurrences(of: "claude-", with: "")
            .components(separatedBy: "-")
        // Skip family name, find first numeric part
        for part in parts.dropFirst() {
            if let n = Int(part) { return n }
        }
        return nil
    }
}

/// Manages the available Anthropic model list with dynamic fetching and fallback.
@Observable
final class ModelCatalog: @unchecked Sendable {

    static let shared = ModelCatalog()

    /// The project default model ID per CLAUDE.md.
    static let defaultModelID = "claude-sonnet-4-5-20250514"

    /// Currently available models (dynamically fetched or fallback).
    private(set) var models: [AnthropicModelInfo] = ModelCatalog.fallbackModels
    private(set) var isLoading = false
    private(set) var lastError: String?
    private(set) var isCached = false

    /// Fetch models from the backend API.
    func refresh(backendURL: String, apiKey: String) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let urlString = backendURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            + "/api/v1/models"
        guard let url = URL(string: urlString) else {
            lastError = "Invalid backend URL"
            return
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                lastError = "Server returned error"
                return
            }

            struct ModelsResponse: Decodable {
                let models: [AnthropicModelInfo]
                let cached: Bool?
            }

            let decoded = try JSONDecoder().decode(ModelsResponse.self, from: data)
            if !decoded.models.isEmpty {
                models = decoded.models
                isCached = decoded.cached ?? false
                lastError = nil
            }
        } catch {
            lastError = error.localizedDescription
            // Keep existing models (fallback or previously fetched)
        }
    }

    /// Find the best replacement for a model ID that no longer exists.
    /// Strategy: same family, closest version number, prefer newer.
    func bestFallback(for modelID: String) -> AnthropicModelInfo? {
        // If the model exists in our catalog, return it
        if let exact = models.first(where: { $0.id == modelID }) {
            return exact
        }

        // Build a temporary model info to extract family/version
        let target = AnthropicModelInfo(id: modelID, displayName: "", createdAt: "")

        // Try same family first, sorted by creation date (newest first)
        let sameFamily = models.filter { $0.family == target.family }
        if let best = sameFamily.first {
            return best
        }

        // Fall back to the project default
        if let fallback = models.first(where: { $0.id == ModelCatalog.defaultModelID }) {
            return fallback
        }

        // Last resort: first available model
        return models.first
    }

    // MARK: - Fallback models (used when backend is unreachable)

    static let fallbackModels: [AnthropicModelInfo] = [
        AnthropicModelInfo(id: "claude-opus-4-6", displayName: "Claude Opus 4.6", createdAt: "2025-06-01"),
        AnthropicModelInfo(id: "claude-sonnet-4-6", displayName: "Claude Sonnet 4.6", createdAt: "2025-06-01"),
        AnthropicModelInfo(id: "claude-opus-4-5-20250514", displayName: "Claude Opus 4.5", createdAt: "2025-05-14"),
        AnthropicModelInfo(id: "claude-sonnet-4-5-20250514", displayName: "Claude Sonnet 4.5", createdAt: "2025-05-14"),
        AnthropicModelInfo(id: "claude-opus-4-0-20250514", displayName: "Claude Opus 4.0", createdAt: "2025-05-14"),
        AnthropicModelInfo(id: "claude-sonnet-4-0-20250514", displayName: "Claude Sonnet 4.0", createdAt: "2025-05-14"),
        AnthropicModelInfo(id: "claude-3-7-sonnet-20250219", displayName: "Claude 3.7 Sonnet", createdAt: "2025-02-19"),
        AnthropicModelInfo(id: "claude-3-5-sonnet-20241022", displayName: "Claude 3.5 Sonnet", createdAt: "2024-10-22"),
        AnthropicModelInfo(id: "claude-3-5-haiku-20241022", displayName: "Claude 3.5 Haiku", createdAt: "2024-10-22"),
    ]
}
