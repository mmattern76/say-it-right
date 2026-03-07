import Foundation

/// Tracks the state of a "Build the Pyramid" session.
struct BuildThePyramidSession: Sendable {
    let exercise: PyramidExercise
    let startedAt: Date
    private(set) var attempts: Int = 0
    private(set) var lastScore: Double?
    private(set) var isComplete: Bool = false
    private(set) var showedAnswer: Bool = false

    /// Maximum attempts before "show answer" is offered.
    let maxAttempts: Int

    init(exercise: PyramidExercise, maxAttempts: Int = 3, startedAt: Date = .now) {
        self.exercise = exercise
        self.maxAttempts = maxAttempts
        self.startedAt = startedAt
    }

    mutating func recordAttempt(score: Double) {
        attempts += 1
        lastScore = score
        if score >= 1.0 {
            isComplete = true
        }
    }

    mutating func revealAnswer() {
        showedAnswer = true
        isComplete = true
    }

    var canShowAnswer: Bool {
        attempts >= maxAttempts && !isComplete
    }
}
