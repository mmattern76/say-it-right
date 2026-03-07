import Foundation

/// Orchestrates the "Build the Pyramid" session flow.
///
/// Selects an exercise from the library and manages the session lifecycle
/// including validation attempts and answer reveal.
@MainActor
@Observable
final class BuildThePyramidCoordinator {

    var recentExerciseIDs: Set<String> = []

    private let library: PyramidExerciseLibrary
    private let validationEngine = MECEValidationEngine()
    private let maxRecentExercises = 10

    init(library: PyramidExerciseLibrary = .loadFromBundle()) {
        self.library = library
    }

    /// Convenience initialiser for testing.
    init(exercises: [PyramidExercise]) {
        self.library = PyramidExerciseLibrary(exercises: exercises)
    }

    /// Start a pyramid builder session.
    ///
    /// - Returns: The selected exercise, or `nil` if none available.
    @discardableResult
    func startSession(
        sessionManager: SessionManager,
        profile: LearnerProfile,
        language: String
    ) async -> PyramidExercise? {
        guard let exercise = library.randomExercise(
            for: profile.currentLevel,
            language: language,
            excluding: recentExerciseIDs
        ) else {
            return nil
        }

        trackSeen(exercise)
        await sessionManager.startBuildThePyramidSession(
            exercise: exercise,
            profile: profile,
            language: language
        )
        return exercise
    }

    /// Validate the user's pyramid arrangement.
    func validateArrangement(
        userTree: UserPyramidTree,
        answerKey: PyramidAnswerKey
    ) -> PyramidValidationResult {
        validationEngine.validate(userTree: userTree, answerKey: answerKey)
    }

    private func trackSeen(_ exercise: PyramidExercise) {
        recentExerciseIDs.insert(exercise.id)
        if recentExerciseIDs.count > maxRecentExercises {
            recentExerciseIDs.removeAll()
            recentExerciseIDs.insert(exercise.id)
        }
    }
}
