import Foundation

/// An exercise for "Fix this mess" visual mode.
///
/// Contains a pyramid exercise with an intentionally wrong initial arrangement.
/// The user must diagnose and fix the structural problems.
struct FixThisMessExercise: Codable, Sendable, Identifiable {
    let id: String
    let titleEN: String
    let titleDE: String
    let level: Int
    let language: String

    /// The correct governing thought block.
    let governingThought: ExerciseBlock

    /// All blocks (support points and evidence) in the exercise.
    let blocks: [ExerciseBlock]

    /// The correct answer key.
    let answerKey: PyramidAnswerKey

    /// The wrong initial arrangement: maps parent block IDs to child block IDs.
    /// The governing thought is always placed as root.
    let wrongArrangement: WrongArrangement

    /// Description of what is structurally wrong (for Barbara's reference).
    let structuralFlawDescription: String

    func title(language: String) -> String {
        language == "de" ? titleDE : titleEN
    }
}

/// Describes a wrong initial arrangement of blocks in the pyramid.
struct WrongArrangement: Codable, Sendable, Equatable {
    /// Parent-to-children mapping. Keys are block IDs from the exercise.
    let groups: [WrongGroup]
}

/// A single wrong grouping in the initial arrangement.
struct WrongGroup: Codable, Sendable, Equatable {
    /// The parent block ID.
    let parentBlockID: String
    /// The child block IDs placed under this parent (in wrong order/grouping).
    let childBlockIDs: [String]
}
