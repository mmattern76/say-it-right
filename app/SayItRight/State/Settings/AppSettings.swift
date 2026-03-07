import SwiftUI

/// Central observable settings for the app.
///
/// The effective API key is resolved in priority order:
/// 1. Override key from parent settings (stored in Keychain)
/// 2. Bundled key from Config.plist
///
/// The Anthropic model, debug mode, and parent PIN are stored in UserDefaults
/// via @AppStorage. The API key override is in Keychain (sensitive).
@Observable
final class AppSettings: @unchecked Sendable {

    static let shared = AppSettings()

    // MARK: - Anthropic Model

    /// Raw model ID stored in UserDefaults.
    var selectedModelID: String {
        get { UserDefaults.standard.string(forKey: "selectedModelID")
              ?? ModelCatalog.defaultModelID }
        set { UserDefaults.standard.set(newValue, forKey: "selectedModelID") }
    }

    /// Resolve the selected model from the catalog, with automatic fallback.
    var resolvedModel: AnthropicModelInfo? {
        let catalog = ModelCatalog.shared
        if let exact = catalog.models.first(where: { $0.id == selectedModelID }) {
            return exact
        }
        // Model no longer exists — find best replacement
        return catalog.bestFallback(for: selectedModelID)
    }

    /// Handle "unknown model" errors from the API by auto-selecting the best fit.
    func handleUnknownModelError() {
        if let fallback = ModelCatalog.shared.bestFallback(for: selectedModelID) {
            selectedModelID = fallback.id
        }
    }

    // MARK: - API Key Resolution

    /// The API key override entered in parent settings, if any.
    /// Loaded from Keychain on first access, cached in memory.
    private var _cachedOverrideKey: String?
    private var _overrideKeyLoaded = false

    var apiKeyOverride: String? {
        get {
            if !_overrideKeyLoaded { loadOverrideKey() }
            return _cachedOverrideKey
        }
        set {
            _cachedOverrideKey = newValue
            _overrideKeyLoaded = true
            Task { await persistOverrideKey(newValue) }
        }
    }

    /// The effective API key: environment override > Keychain override > Config.plist > nil.
    var effectiveAPIKey: String? {
        // UI test override via launch environment
        if let envKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY_OVERRIDE"],
           !envKey.isEmpty {
            return envKey
        }
        if let override = apiKeyOverride, !override.isEmpty {
            return override
        }
        return ConfigProvider.anthropicAPIKey
    }

    // MARK: - Backend

    /// Backend URL from Config.plist.
    var backendURL: String? {
        ConfigProvider.backendURL
    }

    /// Backend API key from Config.plist.
    var backendAPIKey: String? {
        ConfigProvider.backendAPIKey
    }

    // MARK: - Debug Mode

    var isDebugModeEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "isDebugModeEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "isDebugModeEnabled") }
    }

    // MARK: - Parent Gate

    var isParentPINEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "isParentPINEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "isParentPINEnabled") }
    }

    var isBiometricEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "isBiometricEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "isBiometricEnabled") }
    }

    // MARK: - Language

    var language: String {
        get { UserDefaults.standard.string(forKey: "appLanguage") ?? "en" }
        set { UserDefaults.standard.set(newValue, forKey: "appLanguage") }
    }

    // MARK: - Onboarding

    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }

    var selectedAvatar: String? {
        get { UserDefaults.standard.string(forKey: "selectedAvatar") }
        set { UserDefaults.standard.set(newValue, forKey: "selectedAvatar") }
    }

    var displayName: String {
        get { UserDefaults.standard.string(forKey: "displayName") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "displayName") }
    }

    // MARK: - Voice Preferences

    /// Preferred input mode. Platform defaults: iPhone = voice, iPad/Mac = text.
    var preferredInputMode: String {
        get {
            UserDefaults.standard.string(forKey: "preferredInputMode")
                ?? Self.platformDefaultInputMode
        }
        set { UserDefaults.standard.set(newValue, forKey: "preferredInputMode") }
    }

    /// Whether TTS auto-plays Barbara's responses. iPhone = true, iPad/Mac = false.
    var ttsAutoPlay: Bool {
        get {
            if UserDefaults.standard.object(forKey: "ttsAutoPlay") != nil {
                return UserDefaults.standard.bool(forKey: "ttsAutoPlay")
            }
            return Self.platformDefaultTTSAutoPlay
        }
        set { UserDefaults.standard.set(newValue, forKey: "ttsAutoPlay") }
    }

    /// Platform default for input mode.
    static var platformDefaultInputMode: String {
        #if os(macOS)
        return "text"
        #else
        if UIDevice.current.userInterfaceIdiom == .phone {
            return "voice"
        }
        return "text"
        #endif
    }

    /// Platform default for TTS auto-play.
    static var platformDefaultTTSAutoPlay: Bool {
        #if os(macOS)
        return false
        #else
        return UIDevice.current.userInterfaceIdiom == .phone
        #endif
    }

    // MARK: - Private

    private func loadOverrideKey() {
        _overrideKeyLoaded = true
        Task {
            let key = await KeychainService.shared.retrieveAPIKey()
            await MainActor.run { _cachedOverrideKey = key }
        }
    }

    private func persistOverrideKey(_ key: String?) async {
        do {
            if let key, !key.isEmpty {
                try await KeychainService.shared.saveAPIKey(key)
            } else {
                try await KeychainService.shared.deleteAPIKey()
            }
        } catch {
            #if DEBUG
            print("[AppSettings] Keychain error: \(error)")
            #endif
        }
    }
}
