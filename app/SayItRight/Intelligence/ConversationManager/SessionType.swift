import Foundation

/// Available coaching session types that Barbara can lead.
///
/// Each type maps to a prompt template file in the `PromptSessions` bundle
/// directory and defines the interaction pattern for that exercise.
enum SessionType: String, CaseIterable, Identifiable, Sendable {
    case sayItClearly = "say-it-clearly"
    case findThePoint = "find-the-point"
    case elevatorPitch = "elevator-pitch"
    case analyseMyText = "analyse-my-text"
    case fixThisMess = "fix-this-mess"
    case spotTheGap = "spot-the-gap"
    case buildThePyramid = "build-the-pyramid"
    case decodeAndRebuild = "decode-and-rebuild"

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
        case .analyseMyText:
            language == "de" ? "Analysiere meinen Text" : "Analyse my text"
        case .fixThisMess:
            language == "de" ? "Räum das auf" : "Fix this mess"
        case .spotTheGap:
            language == "de" ? "Finde die Lücke" : "Spot the gap"
        case .buildThePyramid:
            language == "de" ? "Bau die Pyramide" : "Build the pyramid"
        case .decodeAndRebuild:
            language == "de" ? "Entschlüsseln und Neubauen" : "Decode and rebuild"
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
        case .analyseMyText:
            language == "de"
                ? "F\u{00FC}g deinen eigenen Text ein. Barbara bewertet die Struktur."
                : "Paste your own text. Barbara evaluates the structure."
        case .buildThePyramid:
            language == "de"
                ? "Ordne Bausteine in eine Pyramide. Barbara pr\u{00FC}ft ob sie MECE ist."
                : "Arrange blocks into a pyramid. Barbara checks if it is MECE."
        case .fixThisMess:
            language == "de"
                ? "Bringe Ordnung in ein schlecht strukturiertes Argument."
                : "Restructure a badly organised argument."
        case .spotTheGap:
            language == "de"
                ? "Finde die versteckte strukturelle Schwäche in einem überzeugend wirkenden Argument."
                : "Find the hidden structural weakness in a convincing-looking argument."
        case .decodeAndRebuild:
            language == "de"
                ? "Lies einen Text, erkenne die Struktur, und schreibe ihn besser."
                : "Read a text, extract the structure, and rewrite it better."
        }
    }

    /// SF Symbol name for the session type icon.
    var iconName: String {
        switch self {
        case .sayItClearly: "text.bubble"
        case .findThePoint: "magnifyingglass"
        case .elevatorPitch: "timer"
        case .analyseMyText: "doc.text"
        case .buildThePyramid: "rectangle.3.group"
        case .fixThisMess: "arrow.up.and.down.text.horizontal"
        case .spotTheGap: "eye.trianglebadge.exclamationmark"
        case .decodeAndRebuild: "arrow.triangle.2.circlepath"
        }
    }
}
