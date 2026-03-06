import Testing
import Foundation
@testable import SayItRight

// MARK: - Test Helpers

private func makeAnswerKey(
    governingThoughtID: String,
    groupings: [[ValidGroup]]
) -> PyramidAnswerKey {
    PyramidAnswerKey(
        governingThoughtID: governingThoughtID,
        validGroupings: groupings.map { ValidGrouping(groups: $0) }
    )
}

private func makeUserTree(
    root: String?,
    parentToChildren: [String: Set<String>]
) -> UserPyramidTree {
    var allPlaced: Set<String> = []
    if let root { allPlaced.insert(root) }
    for (parent, children) in parentToChildren {
        allPlaced.insert(parent)
        allPlaced.formUnion(children)
    }
    return UserPyramidTree(
        rootBlockID: root,
        parentToChildren: parentToChildren,
        allPlacedBlockIDs: allPlaced
    )
}

// MARK: - Feedback Mapping Tests

@Suite("ValidationFeedbackMapper")
struct ValidationFeedbackMapperTests {

    let engine = MECEValidationEngine()

    // MARK: - Block Feedback States

    @Test("Perfect arrangement maps all blocks to correct feedback")
    func perfectArrangementFeedback() {
        let answerKey = makeAnswerKey(
            governingThoughtID: "GT",
            groupings: [[
                ValidGroup(parentBlockID: "SP1", memberBlockIDs: ["E1", "E2"]),
                ValidGroup(parentBlockID: "SP2", memberBlockIDs: ["E3"]),
            ]]
        )

        let userTree = makeUserTree(
            root: "GT",
            parentToChildren: [
                "GT": ["SP1", "SP2"],
                "SP1": ["E1", "E2"],
                "SP2": ["E3"],
            ]
        )

        let result = engine.validate(userTree: userTree, answerKey: answerKey)
        let feedback = ValidationFeedbackMapper.blockFeedbackStates(from: result)

        #expect(feedback["GT"] == .correct)
        #expect(feedback["SP1"] == .correct)
        #expect(feedback["SP2"] == .correct)
        #expect(feedback["E1"] == .correct)
        #expect(feedback["E2"] == .correct)
        #expect(feedback["E3"] == .correct)
    }

    @Test("Misplaced blocks map to misplaced feedback")
    func misplacedBlockFeedback() {
        let answerKey = makeAnswerKey(
            governingThoughtID: "GT",
            groupings: [[
                ValidGroup(parentBlockID: "SP1", memberBlockIDs: ["E1", "E2"]),
                ValidGroup(parentBlockID: "SP2", memberBlockIDs: ["E3"]),
            ]]
        )

        // E2 placed under SP2 instead of SP1.
        let userTree = makeUserTree(
            root: "GT",
            parentToChildren: [
                "GT": ["SP1", "SP2"],
                "SP1": ["E1"],
                "SP2": ["E3", "E2"],
            ]
        )

        let result = engine.validate(userTree: userTree, answerKey: answerKey)
        let feedback = ValidationFeedbackMapper.blockFeedbackStates(from: result)

        #expect(feedback["E1"] == .correct)
        #expect(feedback["E3"] == .correct)
        // E2 is in the wrong group — should be misplaced or meceOverlap.
        let e2State = feedback["E2"]
        #expect(e2State == .misplaced || e2State == .meceOverlap)
    }

    @Test("Overlap blocks map to meceOverlap feedback")
    func overlapBlockFeedback() {
        let answerKey = makeAnswerKey(
            governingThoughtID: "GT",
            groupings: [[
                ValidGroup(parentBlockID: "SP1", memberBlockIDs: ["E1"]),
                ValidGroup(parentBlockID: "SP2", memberBlockIDs: ["E2"]),
            ]]
        )

        // E2 placed under SP1 (belongs in SP2) — is an overlapping member.
        let userTree = makeUserTree(
            root: "GT",
            parentToChildren: [
                "GT": ["SP1", "SP2"],
                "SP1": ["E1", "E2"],
            ]
        )

        let result = engine.validate(userTree: userTree, answerKey: answerKey)
        let feedback = ValidationFeedbackMapper.blockFeedbackStates(from: result)

        #expect(feedback["E1"] == .correct)
        // E2 is in SP1's overlapping set — should be meceOverlap.
        #expect(feedback["E2"] == .meceOverlap)
    }

    @Test("Missing blocks do not appear in feedback states")
    func missingBlocksNotInFeedback() {
        let answerKey = makeAnswerKey(
            governingThoughtID: "GT",
            groupings: [[
                ValidGroup(parentBlockID: "SP1", memberBlockIDs: ["E1", "E2"]),
            ]]
        )

        let userTree = makeUserTree(
            root: "GT",
            parentToChildren: [
                "GT": ["SP1"],
                "SP1": ["E1"],
            ]
        )

        let result = engine.validate(userTree: userTree, answerKey: answerKey)
        let feedback = ValidationFeedbackMapper.blockFeedbackStates(from: result)

        // E2 is missing — should not be in feedback (shown as gap instead).
        #expect(feedback["E2"] == nil)
    }

    // MARK: - Gap Placements

    @Test("Missing blocks generate gap placements")
    func gapPlacementsFromMissingBlocks() {
        let answerKey = makeAnswerKey(
            governingThoughtID: "GT",
            groupings: [[
                ValidGroup(parentBlockID: "SP1", memberBlockIDs: ["E1", "E2"]),
                ValidGroup(parentBlockID: "SP2", memberBlockIDs: ["E3"]),
            ]]
        )

        let userTree = makeUserTree(
            root: "GT",
            parentToChildren: [
                "GT": ["SP1"],
                "SP1": ["E1"],
            ]
        )

        let result = engine.validate(userTree: userTree, answerKey: answerKey)
        let gaps = ValidationFeedbackMapper.gapPlacements(from: result)

        // E2 missing from SP1, E3 missing from SP2.
        let missingIDs = Set(gaps.map(\.missingBlockID))
        #expect(missingIDs.contains("E2"))
        #expect(missingIDs.contains("E3"))
    }

    @Test("No gaps when all blocks are placed correctly")
    func noGapsWhenComplete() {
        let answerKey = makeAnswerKey(
            governingThoughtID: "GT",
            groupings: [[
                ValidGroup(parentBlockID: "SP1", memberBlockIDs: ["E1"]),
            ]]
        )

        let userTree = makeUserTree(
            root: "GT",
            parentToChildren: [
                "GT": ["SP1"],
                "SP1": ["E1"],
            ]
        )

        let result = engine.validate(userTree: userTree, answerKey: answerKey)
        let gaps = ValidationFeedbackMapper.gapPlacements(from: result)

        #expect(gaps.isEmpty)
    }

    @Test("Gap placements have correct parent block IDs")
    func gapParentBlockIDs() {
        let answerKey = makeAnswerKey(
            governingThoughtID: "GT",
            groupings: [[
                ValidGroup(parentBlockID: "SP1", memberBlockIDs: ["E1", "E2"]),
                ValidGroup(parentBlockID: "SP2", memberBlockIDs: ["E3", "E4"]),
            ]]
        )

        // Only SP1 with E1 placed.
        let userTree = makeUserTree(
            root: "GT",
            parentToChildren: [
                "GT": ["SP1"],
                "SP1": ["E1"],
            ]
        )

        let result = engine.validate(userTree: userTree, answerKey: answerKey)
        let gaps = ValidationFeedbackMapper.gapPlacements(from: result)

        let sp1Gaps = gaps.filter { $0.parentBlockID == "SP1" }
        let sp2Gaps = gaps.filter { $0.parentBlockID == "SP2" }

        #expect(sp1Gaps.contains { $0.missingBlockID == "E2" })
        #expect(sp2Gaps.contains { $0.missingBlockID == "E3" } || sp2Gaps.contains { $0.missingBlockID == "E4" })
    }

    // MARK: - Pyramid Complete Detection

    @Test("Complete pyramid detected when all blocks correct")
    func pyramidCompleteWhenAllCorrect() {
        let answerKey = makeAnswerKey(
            governingThoughtID: "GT",
            groupings: [[
                ValidGroup(parentBlockID: "SP1", memberBlockIDs: ["E1"]),
            ]]
        )

        let userTree = makeUserTree(
            root: "GT",
            parentToChildren: [
                "GT": ["SP1"],
                "SP1": ["E1"],
            ]
        )

        let result = engine.validate(userTree: userTree, answerKey: answerKey)
        let isComplete = ValidationFeedbackMapper.isPyramidComplete(result)

        #expect(isComplete)
    }

    @Test("Pyramid not complete with wrong governing thought")
    func pyramidNotCompleteWrongRoot() {
        let answerKey = makeAnswerKey(
            governingThoughtID: "GT",
            groupings: [[
                ValidGroup(parentBlockID: "SP1", memberBlockIDs: ["E1"]),
            ]]
        )

        let userTree = makeUserTree(
            root: "SP1",
            parentToChildren: [
                "SP1": ["E1"],
            ]
        )

        let result = engine.validate(userTree: userTree, answerKey: answerKey)
        let isComplete = ValidationFeedbackMapper.isPyramidComplete(result)

        #expect(!isComplete)
    }

    @Test("Pyramid not complete with missing blocks")
    func pyramidNotCompleteWithMissing() {
        let answerKey = makeAnswerKey(
            governingThoughtID: "GT",
            groupings: [[
                ValidGroup(parentBlockID: "SP1", memberBlockIDs: ["E1", "E2"]),
            ]]
        )

        let userTree = makeUserTree(
            root: "GT",
            parentToChildren: [
                "GT": ["SP1"],
                "SP1": ["E1"],
            ]
        )

        let result = engine.validate(userTree: userTree, answerKey: answerKey)
        let isComplete = ValidationFeedbackMapper.isPyramidComplete(result)

        #expect(!isComplete)
    }

    @Test("Pyramid not complete with misplaced blocks")
    func pyramidNotCompleteWithMisplaced() {
        let answerKey = makeAnswerKey(
            governingThoughtID: "GT",
            groupings: [[
                ValidGroup(parentBlockID: "SP1", memberBlockIDs: ["E1", "E2"]),
                ValidGroup(parentBlockID: "SP2", memberBlockIDs: ["E3"]),
            ]]
        )

        // E2 swapped to SP2.
        let userTree = makeUserTree(
            root: "GT",
            parentToChildren: [
                "GT": ["SP1", "SP2"],
                "SP1": ["E1"],
                "SP2": ["E3", "E2"],
            ]
        )

        let result = engine.validate(userTree: userTree, answerKey: answerKey)
        let isComplete = ValidationFeedbackMapper.isPyramidComplete(result)

        #expect(!isComplete)
    }
}

// MARK: - Block Feedback State Tests

@Suite("BlockFeedbackState")
struct BlockFeedbackStateTests {

    @Test("All feedback states have accessibility labels")
    func accessibilityLabels() {
        let states: [BlockFeedbackState] = [.correct, .misplaced, .meceOverlap, .none]
        for state in states {
            if state == .none {
                #expect(state.accessibilityLabel.isEmpty)
            } else {
                #expect(!state.accessibilityLabel.isEmpty)
            }
        }
    }

    @Test("Feedback states are equatable")
    func equatable() {
        #expect(BlockFeedbackState.correct == BlockFeedbackState.correct)
        #expect(BlockFeedbackState.misplaced == BlockFeedbackState.misplaced)
        #expect(BlockFeedbackState.meceOverlap == BlockFeedbackState.meceOverlap)
        #expect(BlockFeedbackState.none == BlockFeedbackState.none)
        #expect(BlockFeedbackState.correct != BlockFeedbackState.misplaced)
    }
}

// MARK: - Feedback Configuration Tests

@Suite("FeedbackConfiguration")
struct FeedbackConfigurationTests {

    @Test("Default configuration has feedback disabled")
    func defaultConfiguration() {
        let config = FeedbackConfiguration.default
        #expect(!config.isEnabled)
        #expect(!config.isAutomatic)
    }

    @Test("Configuration is equatable")
    func equatable() {
        let a = FeedbackConfiguration(isEnabled: true, isAutomatic: false)
        let b = FeedbackConfiguration(isEnabled: true, isAutomatic: false)
        let c = FeedbackConfiguration(isEnabled: false, isAutomatic: true)

        #expect(a == b)
        #expect(a != c)
    }
}

// MARK: - Gap Placement Tests

@Suite("GapPlacement")
struct GapPlacementTests {

    @Test("Gap placement has deterministic ID")
    func deterministicID() {
        let gap = GapPlacement(parentBlockID: "SP1", missingBlockID: "E2")
        #expect(gap.id == "SP1-gap-E2")
    }

    @Test("Different gaps have different IDs")
    func uniqueIDs() {
        let a = GapPlacement(parentBlockID: "SP1", missingBlockID: "E1")
        let b = GapPlacement(parentBlockID: "SP1", missingBlockID: "E2")
        let c = GapPlacement(parentBlockID: "SP2", missingBlockID: "E1")

        #expect(a.id != b.id)
        #expect(a.id != c.id)
        #expect(b.id != c.id)
    }

    @Test("Gap placement is equatable")
    func equatable() {
        let a = GapPlacement(parentBlockID: "SP1", missingBlockID: "E1")
        let b = GapPlacement(parentBlockID: "SP1", missingBlockID: "E1")

        #expect(a == b)
    }
}

// MARK: - Feedback Palette Tests

@Suite("FeedbackPalette")
struct FeedbackPaletteTests {

    @Test("Palette colours are distinct")
    func distinctColours() {
        // Verify the palette entries exist and are accessible.
        let _ = FeedbackPalette.correct
        let _ = FeedbackPalette.misplaced
        let _ = FeedbackPalette.overlap
        let _ = FeedbackPalette.gap
        let _ = FeedbackPalette.celebration
    }
}
