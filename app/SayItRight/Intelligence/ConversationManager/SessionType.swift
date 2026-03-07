import Foundation

/// Available coaching session types that Barbara can lead.
///
/// Each type maps to a prompt template file in the `PromptSessions` bundle
/// directory and defines the interaction pattern for that exercise.
enum SessionType: String, CaseIterable, Identifiable, Sendable {
    case sayItClearly = "say-it-clearly"
    case findThePoint = "find-the-point"
    case elevatorPitch = "elevator-pitch"

    var id: String { rawValue }

    /// Localised display name for the session picker.
    func displayName(language: String) -> String {
        switch self {
        case .sayItClearly:
            language == "de" ? "Sag's klar" : "Say it clearly"
        case .findThePoint:
            language == "de" ? "Finde den Punkt" : "Find the point"
        case .elevatorPitch:
            language == "de" ? "30 Sekunden" : "The elevator pitch"
        }
    }

    /// Short description shown beneath the session name.
    func subtitle(language: String) -> String {
        switch self {
        case .sayItClearly:
            language == "de"
                ? "Formuliere eine strukturierte Antwort. Barbara bewertet die Pyramidenqualit\u{00E4}t."
                : "Formulate a structured response. Barbara evaluates pyramid quality."
        case .findThePoint:
            language == "de"
                ? "Finde den Kerngedanken in einem Text. Barbara pr\u{00FC}ft dein Verst\u{00E4}ndnis."
                : "Extract the governing thought from a text. Barbara checks your understanding."
        case .elevatorPitch:
            language == "de"
                ? "Schreib unter Zeitdruck. Barbara bewertet, ob du priorisieren kannst."
                : "Write under time pressure. Barbara evaluates your ability to prioritise."
        }
    }

    /// SF Symbol name for the session type icon.
    var iconName: String {
        switch self {
        case .sayItClearly: "text.bubble"
        case .findThePoint: "magnifyingglass"
        case .elevatorPitch: "timer"
        }
    }
}
