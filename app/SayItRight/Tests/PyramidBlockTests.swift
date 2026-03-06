import Testing
import Foundation
@testable import SayItRight

@Suite("PyramidBlock")
struct PyramidBlockTests {

    // MARK: - Block Creation

    @Test func blockCreatedWithDefaults() {
        let block = PyramidBlock(text: "Test claim", type: .governingThought)

        #expect(block.text == "Test claim")
        #expect(block.type == .governingThought)
        #expect(block.level == nil)
    }

    @Test func blockCreatedWithLevel() {
        let block = PyramidBlock(text: "Evidence", type: .evidence, level: 2)

        #expect(block.level == 2)
        #expect(block.type == .evidence)
    }

    @Test func blockHasUniqueId() {
        let a = PyramidBlock(text: "A", type: .supportPoint)
        let b = PyramidBlock(text: "A", type: .supportPoint)

        #expect(a.id != b.id)
    }

    @Test func blockWithExplicitId() {
        let id = UUID()
        let block = PyramidBlock(id: id, text: "Custom ID", type: .evidence)

        #expect(block.id == id)
    }

    // MARK: - Block Type

    @Test func allBlockTypesHaveDistinctLabels() {
        let labels = BlockType.allCases.map(\.label)
        let uniqueLabels = Set(labels)

        #expect(labels.count == uniqueLabels.count)
    }

    @Test func allBlockTypesExist() {
        #expect(BlockType.allCases.count == 3)
        #expect(BlockType.allCases.contains(.governingThought))
        #expect(BlockType.allCases.contains(.supportPoint))
        #expect(BlockType.allCases.contains(.evidence))
    }

    // MARK: - Equatable

    @Test func blocksWithSameIdAreEqual() {
        let id = UUID()
        let a = PyramidBlock(id: id, text: "Same", type: .supportPoint)
        let b = PyramidBlock(id: id, text: "Same", type: .supportPoint)

        #expect(a == b)
    }

    @Test func blocksWithDifferentIdsAreNotEqual() {
        let a = PyramidBlock(text: "Same text", type: .supportPoint)
        let b = PyramidBlock(text: "Same text", type: .supportPoint)

        #expect(a != b)
    }

    // MARK: - Codable

    @Test func blockRoundTripsThroughJSON() throws {
        let original = PyramidBlock(text: "Encode me", type: .governingThought, level: 0)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PyramidBlock.self, from: data)

        #expect(decoded == original)
        #expect(decoded.text == "Encode me")
        #expect(decoded.type == .governingThought)
        #expect(decoded.level == 0)
    }

    @Test func blockTypeRoundTripsThroughJSON() throws {
        for blockType in BlockType.allCases {
            let data = try JSONEncoder().encode(blockType)
            let decoded = try JSONDecoder().decode(BlockType.self, from: data)
            #expect(decoded == blockType)
        }
    }

    // MARK: - Block Dimensions

    @Test func dimensionConstraintsAreReasonable() {
        #expect(BlockDimensions.minWidth > 0)
        #expect(BlockDimensions.maxWidth > BlockDimensions.minWidth)
        #expect(BlockDimensions.minHeight > 0)
        #expect(BlockDimensions.maxHeight > BlockDimensions.minHeight)
        #expect(BlockDimensions.cornerRadius > 0)
    }

    // MARK: - Visual State

    @Test func allVisualStatesAreDistinct() {
        let states: [BlockVisualState] = [.idle, .hovering, .dragging, .placed, .error]
        for i in 0..<states.count {
            for j in (i + 1)..<states.count {
                #expect(states[i] != states[j])
            }
        }
    }
}
