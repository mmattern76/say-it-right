import Foundation

/// Evaluates whether a learner is ready for level promotion and executes transitions.
///
/// Checks rolling dimension averages against progression criteria. When all criteria
/// are met, sets the transition_ready flag. The actual level-up is triggered explicitly
/// to allow for the celebration UI.
struct LevelTransitionEngine: Sendable {

    let criteria: ProgressionCriteria

    init(criteria: ProgressionCriteria = .default) {
        self.criteria = criteria
    }

    /// Check whether the learner meets all criteria for advancing from their current level.
    func isReadyForPromotion(_ profile: LearnerProfile) -> Bool {
        guard let levelCriteria = criteria.criteria(fromLevel: profile.currentLevel) else {
            return false // No criteria defined (already at max level or no config)
        }

        // Minimum total sessions
        guard profile.sessionCount >= levelCriteria.minTotalSessions else {
            return false
        }

        // All required dimensions must meet the threshold
        for dimension in levelCriteria.requiredDimensions {
            guard let avg = profile.rollingAverage(for: dimension) else {
                return false // No data for this dimension
            }
            let maxScore = Double(ProfileUpdater.maxScores[dimension] ?? 3)
            let normalised = maxScore > 0 ? avg / maxScore : 0
            if normalised < levelCriteria.minDimensionAverage {
                return false
            }
        }

        return true
    }

    /// Execute the level transition on a profile.
    ///
    /// Increments `currentLevel`, records a `LevelTransition` entry, and returns
    /// the transition details for the celebration UI.
    func promote(_ profile: inout LearnerProfile, at date: Date = .now) -> LevelTransition? {
        let fromLevel = profile.currentLevel
        let toLevel = fromLevel + 1
        guard toLevel <= 4 else { return nil }

        let transition = LearnerProfile.LevelTransition(
            fromLevel: fromLevel,
            toLevel: toLevel,
            date: date
        )

        profile.currentLevel = toLevel
        profile.levelHistory.append(transition)

        return LevelTransition(
            fromLevel: fromLevel,
            toLevel: toLevel,
            date: date
        )
    }

    /// Level transition details for the celebration UI.
    struct LevelTransition: Sendable {
        let fromLevel: Int
        let toLevel: Int
        let date: Date

        var fromLevelName: (en: String, de: String) {
            Self.levelName(fromLevel)
        }

        var toLevelName: (en: String, de: String) {
            Self.levelName(toLevel)
        }

        static func levelName(_ level: Int) -> (en: String, de: String) {
            switch level {
            case 1: ("Plain Talk", "Klartext")
            case 2: ("Order", "Ordnung")
            case 3: ("Architecture", "Architektur")
            case 4: ("Mastery", "Meisterschaft")
            default: ("", "")
            }
        }

        func barbaraQuote(language: String) -> String {
            if language == "de" {
                return switch toLevel {
                case 2: "Du hast deine Grundlagen gemeistert. Jetzt lernst du, wie man Gedanken gruppiert — das ist der Unterschied zwischen gut und überzeugend."
                case 3: "Ordnung beherrschst du. Jetzt bauen wir Architekturen — vertikale Logik, Synthese, und die Kunst des strukturierten Denkens."
                case 4: "Du bist bereit für die Meisterklasse. Jetzt wendest du alles an: echte Texte, LLM-Prompts, Präsentationen."
                default: "Weiter so."
                }
            } else {
                return switch toLevel {
                case 2: "You've mastered the foundations. Now you'll learn to group thoughts — that's the difference between good and convincing."
                case 3: "You've got order down. Now we build architecture — vertical logic, synthesis, and the art of structured thinking."
                case 4: "You're ready for the master class. Now you apply everything: real texts, LLM prompts, presentations."
                default: "Keep going."
                }
            }
        }
    }
}
