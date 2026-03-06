import Testing
@testable import SayItRight

// MARK: - Test Helpers

/// Convenience builder for test fixtures.
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

// MARK: - Tests

@Suite("MECE Validation Engine")
struct MECEValidationEngineTests {

    let engine = MECEValidationEngine()

    // MARK: - Test 1: Perfect arrangement

    @Test("Perfect arrangement scores 1.0 with all blocks correct")
    func perfectArrangement() {
        // Answer key: GT -> [SP1(E1, E2), SP2(E3, E4)]
        let answerKey = makeAnswerKey(
            governingThoughtID: "GT",
            groupings: [[
                ValidGroup(parentBlockID: "SP1", memberBlockIDs: ["E1", "E2"]),
                ValidGroup(parentBlockID: "SP2", memberBlockIDs: ["E3", "E4"]),
            ]]
        )

        let userTree = makeUserTree(
            root: "GT",
            parentToChildren: [
                "GT": ["SP1", "SP2"],
                "SP1": ["E1", "E2"],
                "SP2": ["E3", "E4"],
            ]
        )

        let result = engine.validate(userTree: userTree, answerKey: answerKey)

        #expect(result.governingThoughtCorrect)
        #expect(result.score == 1.0)
        #expect(result.ungroupedBlockIDs.isEmpty)
        #expect(result.blockStatuses["GT"] == .correct)
        #expect(result.blockStatuses["SP1"] == .correct)
        #expect(result.blockStatuses["SP2"] == .correct)
        #expect(result.blockStatuses["E1"] == .correct)
        #expect(result.blockStatuses["E2"] == .correct)
        #expect(result.blockStatuses["E3"] == .correct)
        #expect(result.blockStatuses["E4"] == .correct)
    }

    // MARK: - Test 2: Wrong governing thought

    @Test("Wrong governing thought is detected")
    func wrongGoverningThought() {
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

        #expect(!result.governingThoughtCorrect)
        #expect(result.score < 1.0)
    }

    // MARK: - Test 3: Blocks in wrong groups (swapped evidence)

    @Test("Blocks placed in wrong groups are detected")
    func blocksInWrongGroups() {
        let answerKey = makeAnswerKey(
            governingThoughtID: "GT",
            groupings: [[
                ValidGroup(parentBlockID: "SP1", memberBlockIDs: ["E1", "E2"]),
                ValidGroup(parentBlockID: "SP2", memberBlockIDs: ["E3", "E4"]),
            ]]
        )

        // User swapped E2 and E3.
        let userTree = makeUserTree(
            root: "GT",
            parentToChildren: [
                "GT": ["SP1", "SP2"],
                "SP1": ["E1", "E3"],  // E3 should be under SP2
                "SP2": ["E2", "E4"],  // E2 should be under SP1
            ]
        )

        let result = engine.validate(userTree: userTree, answerKey: answerKey)

        #expect(result.governingThoughtCorrect)
        #expect(result.score < 1.0)

        // E3 is in wrong group — should be under SP2.
        if case .wrongGroup(let expected) = result.blockStatuses["E3"] {
            #expect(expected == "SP2")
        } else {
            Issue.record("E3 should be wrongGroup")
        }

        // E2 is in wrong group — should be under SP1.
        if case .wrongGroup(let expected) = result.blockStatuses["E2"] {
            #expect(expected == "SP1")
        } else {
            Issue.record("E2 should be wrongGroup")
        }

        // E1 and E4 remain correct.
        #expect(result.blockStatuses["E1"] == .correct)
        #expect(result.blockStatuses["E4"] == .correct)
    }

    // MARK: - Test 4: Missing blocks (gap detection)

    @Test("Missing blocks are detected as MECE gaps")
    func missingBlocksDetected() {
        let answerKey = makeAnswerKey(
            governingThoughtID: "GT",
            groupings: [[
                ValidGroup(parentBlockID: "SP1", memberBlockIDs: ["E1", "E2"]),
                ValidGroup(parentBlockID: "SP2", memberBlockIDs: ["E3"]),
            ]]
        )

        // User only placed SP1 with E1 — missing E2, SP2, and E3.
        let userTree = makeUserTree(
            root: "GT",
            parentToChildren: [
                "GT": ["SP1"],
                "SP1": ["E1"],
            ]
        )

        let result = engine.validate(userTree: userTree, answerKey: answerKey)

        #expect(result.governingThoughtCorrect)
        #expect(result.score < 1.0)

        // Check that missing blocks are identified.
        #expect(result.blockStatuses["E3"] == .missing)

        // Check group assessments for gaps.
        let sp1Assessment = result.groupAssessments.first { $0.userParentBlockID == "SP1" }
        #expect(sp1Assessment != nil)
        #expect(sp1Assessment?.missingMembers.contains("E2") == true)
        #expect(sp1Assessment?.correctMembers.contains("E1") == true)
    }

    // MARK: - Test 5: Overlapping groups (MECE violation)

    @Test("Overlapping blocks in groups are flagged")
    func overlappingGroupsDetected() {
        let answerKey = makeAnswerKey(
            governingThoughtID: "GT",
            groupings: [[
                ValidGroup(parentBlockID: "SP1", memberBlockIDs: ["E1", "E2"]),
                ValidGroup(parentBlockID: "SP2", memberBlockIDs: ["E3"]),
            ]]
        )

        // User placed E3 under SP1 instead of SP2 (it doesn't belong there).
        let userTree = makeUserTree(
            root: "GT",
            parentToChildren: [
                "GT": ["SP1", "SP2"],
                "SP1": ["E1", "E2", "E3"],  // E3 overlaps — belongs in SP2
                "SP2": [],
            ]
        )

        let result = engine.validate(userTree: userTree, answerKey: answerKey)

        #expect(result.governingThoughtCorrect)

        // SP1 group should show E3 as overlapping.
        let sp1Assessment = result.groupAssessments.first { $0.userParentBlockID == "SP1" }
        #expect(sp1Assessment != nil)
        #expect(sp1Assessment?.overlappingMembers.contains("E3") == true)
        #expect(sp1Assessment?.isMECE == false)
    }

    // MARK: - Test 6: Multiple valid groupings picks best match

    @Test("Best matching grouping is selected from alternatives")
    func multipleValidGroupings() {
        // Two valid arrangements — user matches the second one.
        let answerKey = makeAnswerKey(
            governingThoughtID: "GT",
            groupings: [
                // Grouping A: by topic.
                [
                    ValidGroup(parentBlockID: "SP1", memberBlockIDs: ["E1", "E2"]),
                    ValidGroup(parentBlockID: "SP2", memberBlockIDs: ["E3", "E4"]),
                ],
                // Grouping B: by type.
                [
                    ValidGroup(parentBlockID: "SP1", memberBlockIDs: ["E1", "E3"]),
                    ValidGroup(parentBlockID: "SP2", memberBlockIDs: ["E2", "E4"]),
                ],
            ]
        )

        // User follows Grouping B.
        let userTree = makeUserTree(
            root: "GT",
            parentToChildren: [
                "GT": ["SP1", "SP2"],
                "SP1": ["E1", "E3"],
                "SP2": ["E2", "E4"],
            ]
        )

        let result = engine.validate(userTree: userTree, answerKey: answerKey)

        #expect(result.governingThoughtCorrect)
        #expect(result.score == 1.0)
        #expect(result.matchedGroupingIndex == 1)
    }

    // MARK: - Test 7: Ungrouped blocks (placed but orphaned)

    @Test("Placed blocks not in any group are flagged as ungrouped")
    func ungroupedBlocks() {
        let answerKey = makeAnswerKey(
            governingThoughtID: "GT",
            groupings: [[
                ValidGroup(parentBlockID: "SP1", memberBlockIDs: ["E1"]),
            ]]
        )

        // User placed a block "EXTRA" that isn't in any valid group.
        // It's placed in the tree but under no recognised parent.
        var allPlaced: Set<String> = ["GT", "SP1", "E1", "EXTRA"]

        let userTree = UserPyramidTree(
            rootBlockID: "GT",
            parentToChildren: [
                "GT": ["SP1"],
                "SP1": ["E1"],
            ],
            allPlacedBlockIDs: allPlaced
        )

        let result = engine.validate(userTree: userTree, answerKey: answerKey)

        #expect(result.ungroupedBlockIDs.contains("EXTRA"))
        #expect(result.blockStatuses["EXTRA"] == .ungrouped)
    }

    // MARK: - Test 8: Order within group does not matter

    @Test("Block order within a group does not affect correctness")
    func orderWithinGroupDoesNotMatter() {
        let answerKey = makeAnswerKey(
            governingThoughtID: "GT",
            groupings: [[
                ValidGroup(parentBlockID: "SP1", memberBlockIDs: ["E1", "E2", "E3"]),
            ]]
        )

        // User placed E3, E1, E2 (different order) — still correct.
        let userTree = makeUserTree(
            root: "GT",
            parentToChildren: [
                "GT": ["SP1"],
                "SP1": ["E3", "E1", "E2"],
            ]
        )

        let result = engine.validate(userTree: userTree, answerKey: answerKey)

        #expect(result.governingThoughtCorrect)
        #expect(result.score == 1.0)
        #expect(result.blockStatuses["E1"] == .correct)
        #expect(result.blockStatuses["E2"] == .correct)
        #expect(result.blockStatuses["E3"] == .correct)
    }

    // MARK: - Test 9: Empty user tree

    @Test("Empty user tree returns all blocks as missing")
    func emptyUserTree() {
        let answerKey = makeAnswerKey(
            governingThoughtID: "GT",
            groupings: [[
                ValidGroup(parentBlockID: "SP1", memberBlockIDs: ["E1"]),
            ]]
        )

        let userTree = makeUserTree(root: nil, parentToChildren: [:])

        let result = engine.validate(userTree: userTree, answerKey: answerKey)

        #expect(!result.governingThoughtCorrect)
        #expect(result.score == 0.0)
        #expect(result.blockStatuses["GT"] == .missing)
        #expect(result.blockStatuses["E1"] == .missing)
        #expect(result.blockStatuses["SP1"] == .missing)
    }

    // MARK: - Test 10: Three-level deep pyramid

    @Test("Three-level deep pyramid validates correctly")
    func threeLevelDeepPyramid() {
        let answerKey = makeAnswerKey(
            governingThoughtID: "GT",
            groupings: [[
                ValidGroup(parentBlockID: "SP1", memberBlockIDs: ["E1", "E2"]),
                ValidGroup(parentBlockID: "SP2", memberBlockIDs: ["E3", "E4", "E5"]),
                ValidGroup(parentBlockID: "SP3", memberBlockIDs: ["E6"]),
            ]]
        )

        let userTree = makeUserTree(
            root: "GT",
            parentToChildren: [
                "GT": ["SP1", "SP2", "SP3"],
                "SP1": ["E1", "E2"],
                "SP2": ["E3", "E4", "E5"],
                "SP3": ["E6"],
            ]
        )

        let result = engine.validate(userTree: userTree, answerKey: answerKey)

        #expect(result.governingThoughtCorrect)
        #expect(result.score == 1.0)

        // All 10 blocks should be correct.
        let correctCount = result.blockStatuses.values.filter {
            if case .correct = $0 { return true }
            return false
        }.count
        #expect(correctCount == 10)
    }
}
