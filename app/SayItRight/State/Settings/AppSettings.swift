import Security
import SwiftUI

/// Central observable settings for the app.
///
/// The effective API key is resolved in priority order:
/// 1. Override key from parent settings (stored in Keychain)
/// 2. Bundled key from Config.plist
///
/// All settings use backing stored properties so `@Observable` tracking works.
/// Each setter also persists to UserDefaults for cross-launch persistence.
@Observable
final class AppSettings: @unchecked Sendable {
    static let shared = AppSettings()

    // MARK: - Init (load from UserDefaults)

    init() {
        let defaults = UserDefaults.standard
        // Migrate retired model IDs to current defaults
        let savedModel = defaults.string(forKey: "selectedModelID") ?? ModelCatalog.defaultModelID
        let retiredModels = [
            "claude-sonnet-4-5-20250514",
            "claude-opus-4-5-20250514",
            "claude-opus-4-0-20250514",
            "claude-opus-4-6",
            "claude-sonnet-4-6",
        ]
        if retiredModels.contains(savedModel) {
            self._selectedModelID = ModelCatalog.defaultModelID
        } else {
            self._selectedModelID = savedModel
        }
        self._isDebugModeEnabled = defaults.bool(forKey: "isDebugModeEnabled")
        self._isParentPINEnabled = defaults.bool(forKey: "isParentPINEnabled")
        self._isBiometricEnabled = defaults.bool(forKey: "isBiometricEnabled")
        self._language = defaults.string(forKey: "appLanguage") ?? "en"
        self._hasCompletedOnboarding = defaults.bool(forKey: "hasCompletedOnboarding")
        self._selectedAvatar = defaults.string(forKey: "selectedAvatar")
        self._displayName = defaults.string(forKey: "displayName") ?? ""
        self._levelOverride = defaults.integer(forKey: "levelOverride")
        self._preferredInputMode = defaults.string(forKey: "preferredInputMode") ?? Self.platformDefaultInputMode
        if defaults.object(forKey: "ttsAutoPlay") != nil {
            self._ttsAutoPlay = defaults.bool(forKey: "ttsAutoPlay")
        } else {
            self._ttsAutoPlay = Self.platformDefaultTTSAutoPlay
        }
        self._ttsProvider = defaults.string(forKey: "ttsProvider") ?? "apple"
        self._elevenLabsKeyLoaded = false
    }

    // MARK: - Anthropic Model

    private var _selectedModelID: String
    var selectedModelID: String {
        get { _selectedModelID }
        set {
            _selectedModelID = newValue
            UserDefaults.standard.set(newValue, forKey: "selectedModelID")
        }
    }

    /// Resolve the selected model from the catalog, with automatic fallback.
    var resolvedModel: AnthropicModelInfo? {
        let catalog = ModelCatalog.shared
        if let exact = catalog.models.first(where: { $0.id == selectedModelID }) {
            return exact
        }
        return catalog.bestFallback(for: selectedModelID)
    }

    /// Handle "unknown model" errors from the API by auto-selecting the best fit.
    func handleUnknownModelError() {
        if let fallback = ModelCatalog.shared.bestFallback(for: selectedModelID) {
            selectedModelID = fallback.id
        }
    }

    // MARK: - API Key Resolution

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
        if let envKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY_OVERRIDE"],
           !envKey.isEmpty
        {
            return envKey
        }
        if let override = apiKeyOverride, !override.isEmpty {
            return override
        }
        return ConfigProvider.anthropicAPIKey
    }

    // MARK: - Backend

    var backendURL: String? {
        ConfigProvider.backendURL
    }

    var backendAPIKey: String? {
        ConfigProvider.backendAPIKey
    }

    // MARK: - Debug Mode

    private var _isDebugModeEnabled: Bool
    var isDebugModeEnabled: Bool {
        get { _isDebugModeEnabled }
        set {
            _isDebugModeEnabled = newValue
            UserDefaults.standard.set(newValue, forKey: "isDebugModeEnabled")
        }
    }

    // MARK: - Parent Gate

    private var _isParentPINEnabled: Bool
    var isParentPINEnabled: Bool {
        get { _isParentPINEnabled }
        set {
            _isParentPINEnabled = newValue
            UserDefaults.standard.set(newValue, forKey: "isParentPINEnabled")
        }
    }

    private var _isBiometricEnabled: Bool
    var isBiometricEnabled: Bool {
        get { _isBiometricEnabled }
        set {
            _isBiometricEnabled = newValue
            UserDefaults.standard.set(newValue, forKey: "isBiometricEnabled")
        }
    }

    // MARK: - Language

    private var _language: String
    var language: String {
        get { _language }
        set {
            _language = newValue
            UserDefaults.standard.set(newValue, forKey: "appLanguage")
        }
    }

    // MARK: - Onboarding

    private var _hasCompletedOnboarding: Bool
    var hasCompletedOnboarding: Bool {
        get { _hasCompletedOnboarding }
        set {
            _hasCompletedOnboarding = newValue
            UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding")
        }
    }

    private var _selectedAvatar: String?
    var selectedAvatar: String? {
        get { _selectedAvatar }
        set {
            _selectedAvatar = newValue
            UserDefaults.standard.set(newValue, forKey: "selectedAvatar")
        }
    }

    private var _displayName: String
    var displayName: String {
        get { _displayName }
        set {
            _displayName = newValue
            UserDefaults.standard.set(newValue, forKey: "displayName")
        }
    }

    // MARK: - Level Override (Testing)

    private var _levelOverride: Int
    var levelOverride: Int {
        get { _levelOverride }
        set {
            _levelOverride = newValue
            UserDefaults.standard.set(newValue, forKey: "levelOverride")
        }
    }

    // MARK: - Voice Preferences

    private var _preferredInputMode: String
    var preferredInputMode: String {
        get { _preferredInputMode }
        set {
            _preferredInputMode = newValue
            UserDefaults.standard.set(newValue, forKey: "preferredInputMode")
        }
    }

    private var _ttsAutoPlay: Bool
    var ttsAutoPlay: Bool {
        get { _ttsAutoPlay }
        set {
            _ttsAutoPlay = newValue
            UserDefaults.standard.set(newValue, forKey: "ttsAutoPlay")
        }
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

    // MARK: - TTS Provider

    private var _ttsProvider: String
    /// Which TTS engine to use: "apple" or "elevenlabs"
    var ttsProvider: String {
        get { _ttsProvider }
        set {
            _ttsProvider = newValue
            UserDefaults.standard.set(newValue, forKey: "ttsProvider")
        }
    }

    var isElevenLabsEnabled: Bool {
        _ttsProvider == "elevenlabs"
    }

    // MARK: - ElevenLabs API Key

    private var _elevenLabsKeyLoaded: Bool
    private var _elevenLabsKey: String?

    /// The ElevenLabs API key, loaded from Keychain.
    var elevenLabsAPIKey: String? {
        get {
            if !_elevenLabsKeyLoaded { loadElevenLabsKey() }
            return _elevenLabsKey
        }
        set {
            _elevenLabsKey = newValue
            _elevenLabsKeyLoaded = true
            Task {
                if let key = newValue {
                    try? await KeychainService.shared.saveElevenLabsKey(key)
                } else {
                    try? await KeychainService.shared.deleteElevenLabsKey()
                }
            }
        }
    }

    private func loadElevenLabsKey() {
        _elevenLabsKeyLoaded = true
        // Synchronous Keychain read — fast enough for main thread.
        // Must be available immediately so TTSServiceFactory can check
        // at view init time (before any async Task completes).
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.sayitright.app",
            kSecAttrAccount as String: "elevenlabs-api-key",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            _elevenLabsKey = String(data: data, encoding: .utf8)
        }
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
