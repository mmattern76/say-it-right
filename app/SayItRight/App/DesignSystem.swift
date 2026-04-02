import SwiftUI

// MARK: - Color Palette

/// Barbara's colour palette — warm, structured, confident.
///
/// The palette distinguishes the app from generic system defaults while
/// remaining accessible in both light and dark modes.
extension Color {
    // MARK: Barbara

    /// Warm parchment background for Barbara's chat bubbles.
    static let barbaraBubble = Color("BarbaraBubble", bundle: .main)

    /// Barbara's signature accent — a deep ink blue for authoritative elements.
    static let barbaraAccent = Color("BarbaraAccent", bundle: .main)

    /// Left-border accent on Barbara's message bubbles.
    static let barbaraBorder = Color("BarbaraAccent", bundle: .main)

    // MARK: Learner

    /// Learner bubble colour — a warmer, deeper blue than system accent.
    static let learnerBubble = Color("LearnerBubble", bundle: .main)

    // MARK: Scoring

    /// Score bar: strong dimension.
    static let scoreStrong = Color(red: 0.22, green: 0.65, blue: 0.45)

    /// Score bar: mid-range dimension.
    static let scoreMid = Color(red: 0.85, green: 0.55, blue: 0.20)

    /// Score bar: weak dimension.
    static let scoreWeak = Color(red: 0.80, green: 0.25, blue: 0.25)

    // MARK: Background

    /// Subtle warm tint for full-screen backgrounds (onboarding, setup).
    static let warmBackground = Color("WarmBackground", bundle: .main)

    // MARK: Session Card Accents

    /// Per-session-type tint colours. Each session gets its own personality.
    static func sessionAccent(for type: String) -> Color {
        switch type {
            case "say-it-clearly": Color(red: 0.20, green: 0.45, blue: 0.75) // deep blue
            case "find-the-point": Color(red: 0.55, green: 0.35, blue: 0.70) // purple
            case "elevator-pitch": Color(red: 0.80, green: 0.40, blue: 0.20) // warm orange
            case "analyse-my-text": Color(red: 0.30, green: 0.55, blue: 0.55) // teal
            case "fix-this-mess": Color(red: 0.70, green: 0.30, blue: 0.35) // crimson
            case "spot-the-gap": Color(red: 0.75, green: 0.55, blue: 0.20) // amber
            case "build-the-pyramid": Color(red: 0.25, green: 0.55, blue: 0.40) // forest
            case "decode-and-rebuild": Color(red: 0.45, green: 0.40, blue: 0.65) // slate purple
            default: Color.accentColor
        }
    }
}

// MARK: - Typography

/// Typography system using New York (serif) for Barbara's authoritative voice
/// and SF Pro (system) for the learner's functional interface.
extension Font {
    /// Large display title — New York serif. Used for "Say it right!" wordmark,
    /// level names, and section headers.
    static let barbaraLargeTitle = Font.system(.largeTitle, design: .serif).weight(.bold)

    /// Section heading — New York serif. Session titles, dashboard headers.
    static let barbaraTitle = Font.system(.title2, design: .serif).weight(.semibold)

    /// Smaller serif heading — card titles, Barbara's name label.
    static let barbaraHeadline = Font.system(.headline, design: .serif)

    /// Barbara's spoken text in onboarding speech bubbles.
    static let barbaraBody = Font.system(.body, design: .serif)

    /// Level name display (e.g. "Klartext", "Ordnung").
    static let levelName = Font.system(.title3, design: .serif).weight(.medium)
}
