import Foundation

/// Orchestrates the visual "Fix this mess" session flow.
///
/// Similar to BuildThePyramidCoordinator but starts from a wrong arrangement
/// rather than an empty pyramid.
@MainActor
@Observable
final class FixThisMessVisualCoordinator {

    var recentExerciseIDs: Set<String> = []

    private let library: FixThisMessExerciseLibrary
    private let validationEngine = MECEValidationEngine()
    private let maxRecentExercises = 10

    init(library: FixThisMessExerciseLibrary = .loadFromBundle()) {
        self.library = library
    }

    /// Convenience initialiser for testing.
    init(exercises: [FixThisMessExercise]) {
        self.library = FixThisMessExerciseLibrary(exercises: exercises)
    }

    /// Start a visual fix-this-mess session.
    ///
    /// - Returns: The selected exercise, or `nil` if none available.
    @discardableResult
    func startSession(
        sessionManager: SessionManager,
        profile: LearnerProfile,
        language: String
    ) async -> FixThisMessExercise? {
        guard let exercise = library.randomExercise(
            for: profile.currentLevel,
            language: language,
            excluding: recentExerciseIDs
        ) else {
            return nil
        }

        trackSeen(exercise)
        await sessionManager.startFixThisMessVisualSession(
            exercise: exercise,
            profile: profile,
            language: language
        )
        return exercise
    }

    /// Validate the user's fixed arrangement.
    func validateArrangement(
        userTree: UserPyramidTree,
        answerKey: PyramidAnswerKey
    ) -> PyramidValidationResult {
        validationEngine.validate(userTree: userTree, answerKey: answerKey)
    }

    private func trackSeen(_ exercise: FixThisMessExercise) {
        recentExerciseIDs.insert(exercise.id)
        if recentExerciseIDs.count > maxRecentExercises {
            recentExerciseIDs.removeAll()
            recentExerciseIDs.insert(exercise.id)
        }
    }
}
