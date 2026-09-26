import Foundation
import OSLog

/// Manages the library of "Fix this mess" visual exercises.
struct FixThisMessExerciseLibrary {
    private static let log = Logger(subsystem: "io.mattern.say-it-right", category: "content")

    let exercises: [FixThisMessExercise]

    /// Load exercises from the bundled JSON file.
    ///
    /// A load failure returns an empty library, which the learner sees as
    /// "No exercises available" — so failures are logged and trap in debug
    /// builds rather than passing silently.
    static func loadFromBundle() -> Self {
        guard let url = Bundle.main.url(
            forResource: "fix-this-mess-exercises",
            withExtension: "json"
        ) else {
            log.error("fix-this-mess-exercises.json is missing from the app bundle")
            assertionFailure("fix-this-mess-exercises.json is missing from the app bundle")
            return Self(exercises: [])
        }

        do {
            let data = try Data(contentsOf: url)
            let exercises = try JSONDecoder().decode([FixThisMessExercise].self, from: data)
            return Self(exercises: exercises)
        } catch {
            log.error("Failed to load fix-this-mess-exercises.json: \(String(describing: error))")
            assertionFailure("Failed to load fix-this-mess-exercises.json: \(error)")
            return Self(exercises: [])
        }
    }

    /// Filter exercises by level and language.
    func exercises(for level: Int, language: String) -> [FixThisMessExercise] {
        exercises.filter { $0.level <= level && $0.language == language }
    }

    /// Pick a random exercise, excluding recently seen IDs.
    func randomExercise(
        for level: Int,
        language: String,
        excluding recentIDs: Set<String> = []
    ) -> FixThisMessExercise? {
        var candidates = exercises(for: level, language: language)
        let unseen = candidates.filter { !recentIDs.contains($0.id) }
        if !unseen.isEmpty { candidates = unseen }
        return candidates.randomElement()
    }
}
