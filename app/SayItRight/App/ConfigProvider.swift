import Foundation

/// Loads bundled configuration from Config.plist.
///
/// Config.plist is gitignored. Developers copy Config.template.plist
/// to Config.plist and fill in their API keys. The app settings UI
/// can override the bundled API key at runtime (stored in Keychain).
enum ConfigProvider {

    nonisolated(unsafe) private static let values: [String: Any] = {
        guard let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(
                  from: data, format: nil) as? [String: Any]
        else {
            #if DEBUG
            print("[ConfigProvider] Config.plist not found — copy Config.template.plist to Config.plist")
            #endif
            return [:]
        }
        return dict
    }()

    /// The Anthropic API key bundled in Config.plist.
    /// Returns nil if the plist is missing or still contains the placeholder.
    static var anthropicAPIKey: String? {
        guard let key = values["AnthropicAPIKey"] as? String,
              !key.isEmpty,
              !key.contains("REPLACE_ME")
        else { return nil }
        return key
    }

    /// The backend URL from Config.plist.
    static var backendURL: String? {
        guard let url = values["BackendURL"] as? String,
              !url.isEmpty,
              !url.contains("your-app")
        else { return nil }
        return url
    }

    /// The backend API key from Config.plist.
    static var backendAPIKey: String? {
        guard let key = values["BackendAPIKey"] as? String,
              !key.isEmpty,
              !key.contains("REPLACE_ME")
        else { return nil }
        return key
    }

    // MARK: - ElevenLabs (upgrade path from Apple TTS)

    /// ElevenLabs API key.
    static var elevenLabsAPIKey: String? {
        guard let key = values["ElevenLabsAPIKey"] as? String,
              !key.isEmpty,
              !key.contains("REPLACE_ME")
        else { return nil }
        return key
    }

    /// ElevenLabs voice ID for German Barbara.
    static var elevenLabsVoiceID_DE: String? {
        guard let id = values["ElevenLabsVoiceID_DE"] as? String,
              !id.isEmpty,
              !id.contains("REPLACE_ME")
        else { return nil }
        return id
    }

    /// ElevenLabs voice ID for English Barbara.
    static var elevenLabsVoiceID_EN: String? {
        guard let id = values["ElevenLabsVoiceID_EN"] as? String,
              !id.isEmpty,
              !id.contains("REPLACE_ME")
        else { return nil }
        return id
    }

    /// Returns the ElevenLabs voice ID for the given language, or nil if not configured.
    static func elevenLabsVoiceID(for language: String) -> String? {
        language == "de" ? elevenLabsVoiceID_DE : elevenLabsVoiceID_EN
    }
}
