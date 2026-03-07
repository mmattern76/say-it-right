import Foundation

/// A pyramid builder exercise containing blocks to arrange and an answer key.
///
/// The exercise provides a governing thought (fixed at pyramid top) and a set
/// of scrambled blocks that the user must arrange into the correct tree structure.
struct PyramidExercise: Codable, Sendable, Identifiable {
    let id: String
    let titleEN: String
    let titleDE: String
    let level: Int
    let language: String

    /// The governing thought block (fixed at top).
    let governingThought: ExerciseBlock

    /// Scrambled blocks to arrange.
    let blocks: [ExerciseBlock]

    /// Answer key for validation.
    let answerKey: PyramidAnswerKey

    func title(for language: String) -> String {
        language == "de" ? titleDE : titleEN
    }
}

/// A single block in a pyramid exercise.
struct ExerciseBlock: Codable, Sendable, Identifiable {
    let id: String
    let text: String
    let type: ExerciseBlockType
}

/// Block type in exercise data.
enum ExerciseBlockType: String, Codable, Sendable {
    case governingThought = "governing_thought"
    case supportPoint = "support_point"
    case evidence = "evidence"
    case redHerring = "red_herring"

    /// Convert to the presentation-layer BlockType.
    var blockType: BlockType {
        switch self {
        case .governingThought: .governingThought
        case .supportPoint: .supportPoint
        case .evidence: .evidence
        case .redHerring: .redHerring
        }
    }
}
