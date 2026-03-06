import Foundation

/// Content language for Barbara's coaching sessions.
///
/// This controls which prompt blocks, practice texts, and topics are loaded.
/// It is NOT iOS localization — the app chrome stays in English.
enum AppLanguage: String, CaseIterable, Sendable {
    case en
    case de

    var displayName: String {
        switch self {
        case .en: "English"
        case .de: "Deutsch"
        }
    }

    var flag: String {
        switch self {
        case .en: "🇬🇧"
        case .de: "🇩🇪"
        }
    }

    /// Default language based on device locale.
    static var deviceDefault: AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("de") ? .de : .en
    }
}
