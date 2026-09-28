import Foundation
import OSLog

/// Library of pyramid builder exercises, loaded from bundled JSON.
struct PyramidExerciseLibrary {
    private static let log = Logger(subsystem: "io.mattern.say-it-right", category: "content")

    let exercises: [PyramidExercise]

    /// Load exercises from the app bundle.
    ///
    /// A load failure returns an empty library, which surfaces to the learner as
    /// "No exercises available". That is indistinguishable from a content gap, so
    /// failures are logged and trap in debug builds rather than passing silently.
    static func loadFromBundle() -> Self {
        guard let url = Bundle.main.url(forResource: "pyramid-exercises", withExtension: "json") else {
            log.error("pyramid-exercises.json is missing from the app bundle")
            assertionFailure("pyramid-exercises.json is missing from the app bundle")
            return Self(exercises: [])
        }
        do {
            let data = try Data(contentsOf: url)
            let exercises = try JSONDecoder().decode([PyramidExercise].self, from: data)
            return Self(exercises: exercises)
        } catch {
            log.error("Failed to load pyramid-exercises.json: \(String(describing: error))")
            assertionFailure("Failed to load pyramid-exercises.json: \(error)")
            return Self(exercises: [])
        }
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
