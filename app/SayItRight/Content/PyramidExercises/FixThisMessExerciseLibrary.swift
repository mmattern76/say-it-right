import Foundation

/// Manages the library of "Fix this mess" visual exercises.
struct FixThisMessExerciseLibrary: Sendable {
    let exercises: [FixThisMessExercise]

    /// Load exercises from the bundled JSON file.
    static func loadFromBundle() -> FixThisMessExerciseLibrary {
        guard let url = Bundle.main.url(
            forResource: "fix-this-mess-exercises",
            withExtension: "json"
        ) else {
            return FixThisMessExerciseLibrary(exercises: [])
        }

        do {
            let data = try Data(contentsOf: url)
            let exercises = try JSONDecoder().decode([FixThisMessExercise].self, from: data)
            return FixThisMessExerciseLibrary(exercises: exercises)
        } catch {
            return FixThisMessExerciseLibrary(exercises: [])
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
