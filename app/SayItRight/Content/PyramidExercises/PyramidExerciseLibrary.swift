import Foundation

/// Library of pyramid builder exercises, loaded from bundled JSON.
struct PyramidExerciseLibrary {
    let exercises: [PyramidExercise]

    /// Load exercises from the app bundle.
    static func loadFromBundle() -> Self {
        guard let url = Bundle.main.url(forResource: "pyramid-exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let exercises = try? JSONDecoder().decode([PyramidExercise].self, from: data)
        else {
            return Self(exercises: [])
        }
        return Self(exercises: exercises)
    }

    /// Filter exercises by level and language.
    func exercises(for level: Int, language: String) -> [PyramidExercise] {
        exercises.filter { $0.level <= level && $0.language == language }
    }

    /// Select a random exercise, excluding recently seen IDs.
    func randomExercise(for level: Int, language: String, excluding: Set<String>) -> PyramidExercise? {
        let candidates = exercises(for: level, language: language)
            .filter { !excluding.contains($0.id) }
        if let result = candidates.randomElement() {
            return result
        }
        // If all excluded, reset and pick any
        return exercises(for: level, language: language).randomElement()
    }
}
