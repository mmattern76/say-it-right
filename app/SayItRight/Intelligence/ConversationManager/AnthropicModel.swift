import Foundation

/// A Claude model available from the Anthropic API.
///
/// Models are fetched dynamically from the Anthropic Models API.
/// A hardcoded fallback list is used when the API is unreachable.
struct AnthropicModelInfo: Identifiable, Codable, Hashable {
    let id: String
    let displayName: String
    let createdAt: String

    /// Best-effort family extraction for fallback matching.
    /// e.g. "claude-sonnet-4-5-20250929" → "sonnet"
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
    static let defaultModelID = "claude-sonnet-4-5-20250929"

    /// Currently available models (dynamically fetched or fallback).
    private(set) var models: [AnthropicModelInfo] = ModelCatalog.fallbackModels
    private(set) var isLoading = false
    private(set) var lastError: String?

    // MARK: - Fetch from Anthropic Models API

    /// Fetch available models directly from the Anthropic API.
    ///
    /// Uses the `/v1/models` endpoint. Only includes Claude models suitable
    /// for chat (filters out embedding models, etc.).
    func refreshFromAPI(apiKey: String) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "https://api.anthropic.com/v1/models") else {
            lastError = "Invalid URL"
            return
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                lastError = "API returned HTTP \(code)"
                return
            }

            struct ModelsListResponse: Decodable {
                struct ModelEntry: Decodable {
                    let id: String
                    let display_name: String
                    let created_at: String?
                }

                let data: [ModelEntry]
            }

            let decoded = try JSONDecoder().decode(ModelsListResponse.self, from: data)

            // Filter to claude chat models, sorted newest first
            let chatModels = decoded.data
                .filter { $0.id.hasPrefix("claude-") }
                .map { AnthropicModelInfo(
                    id: $0.id,
                    displayName: $0.display_name,
                    createdAt: $0.created_at ?? ""
                )
                }
                .sorted { $0.createdAt > $1.createdAt }

            if !chatModels.isEmpty {
                models = chatModels
                lastError = nil
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Legacy backend refresh (kept for compatibility).
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
                lastError = nil
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Transparent Model Fallback

    /// Find the best replacement for a model that is no longer available.
    ///
    /// Strategy (preserves model family — never silently switches e.g. sonnet→opus):
    /// 1. Exact match in catalog → return it
    /// 2. Same family, newest available → return it
    /// 3. Project default → return it
    /// 4. First available model → last resort
    func bestFallback(for modelID: String) -> AnthropicModelInfo? {
        if let exact = models.first(where: { $0.id == modelID }) {
            return exact
        }

        let target = AnthropicModelInfo(id: modelID, displayName: "", createdAt: "")

        // Same family, sorted newest first (models are already sorted by createdAt desc)
        let sameFamily = models.filter { $0.family == target.family }
        if let best = sameFamily.first {
            return best
        }

        // Fall back to project default
        if let fallback = models.first(where: { $0.id == Self.defaultModelID }) {
            return fallback
        }

        return models.first
    }

    /// Transparently resolve a model ID, auto-migrating if the model was retired.
    ///
    /// Returns the model ID to use and whether a migration occurred.
    /// The caller should persist the new ID if `didMigrate` is true.
    func resolveModelID(_ selectedID: String) -> (modelID: String, didMigrate: Bool) {
        // Exact match — no migration needed
        if models.contains(where: { $0.id == selectedID }) {
            return (selectedID, false)
        }

        // Find best replacement in the same family
        if let replacement = bestFallback(for: selectedID) {
            return (replacement.id, true)
        }

        // Nothing available — use the selected ID and let the API error
        return (selectedID, false)
    }

    // MARK: - Fallback models (used when API is unreachable)

    static let fallbackModels: [AnthropicModelInfo] = [
        AnthropicModelInfo(id: "claude-sonnet-4-5-20250929", displayName: "Claude Sonnet 4.5", createdAt: "2025-09-29"),
        AnthropicModelInfo(id: "claude-haiku-4-5-20251001", displayName: "Claude Haiku 4.5", createdAt: "2025-10-01"),
        AnthropicModelInfo(id: "claude-sonnet-4-0-20250514", displayName: "Claude Sonnet 4.0", createdAt: "2025-05-14"),
        AnthropicModelInfo(id: "claude-3-5-sonnet-20241022", displayName: "Claude 3.5 Sonnet", createdAt: "2024-10-22"),
        AnthropicModelInfo(id: "claude-3-5-haiku-20241022", displayName: "Claude 3.5 Haiku", createdAt: "2024-10-22"),
    ]
}
