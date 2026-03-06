import Foundation
import SwiftUI

// MARK: - Block Type

/// The structural role a block plays in the pyramid.
enum BlockType: String, Sendable, CaseIterable, Codable {
    case governingThought
    case supportPoint
    case evidence

    /// Display colour for each block type.
    var color: Color {
        switch self {
        case .governingThought: Color(red: 0.20, green: 0.45, blue: 0.75) // deep blue
        case .supportPoint: Color(red: 0.30, green: 0.65, blue: 0.50)     // teal green
        case .evidence: Color(red: 0.55, green: 0.55, blue: 0.65)         // slate grey
        }
    }

    /// Human-readable label.
    var label: String {
        switch self {
        case .governingThought: "Governing Thought"
        case .supportPoint: "Support Point"
        case .evidence: "Evidence"
        }
    }
}

// MARK: - Block Visual State

/// Visual state of a draggable block.
enum BlockVisualState: Sendable, Equatable {
    case idle
    case hovering
    case dragging
    case placed
    case error
}

// MARK: - Pyramid Block

/// The model for a single draggable block in the pyramid builder.
///
/// Each block holds a text snippet (claim, support point, or evidence)
/// and metadata about its type and assigned level in the pyramid.
struct PyramidBlock: Identifiable, Sendable, Equatable, Codable {
    let id: UUID
    let text: String
    let type: BlockType
    /// The pyramid level this block is assigned to, if placed.
    var level: Int?

    init(id: UUID = UUID(), text: String, type: BlockType, level: Int? = nil) {
        self.id = id
        self.text = text
        self.type = type
        self.level = level
    }
}

// MARK: - Block Dimensions

/// Constants controlling block sizing.
enum BlockDimensions {
    static let minWidth: CGFloat = 120
    static let maxWidth: CGFloat = 300
    static let minHeight: CGFloat = 44
    static let maxHeight: CGFloat = 120
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 10
    static let cornerRadius: CGFloat = 12
}
