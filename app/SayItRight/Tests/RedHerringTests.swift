import Foundation
@testable import SayItRight
import Testing

struct RedHerringTests {
    // MARK: - Block Type

    @Test("RedHerring block type exists")
    func redHerringBlockType() {
        let block = PyramidBlock(text: "Irrelevant", type: .redHerring)
        #expect(block.type == .redHerring)
        // Red herrings look like evidence — same color
        #expect(block.type.color == BlockType.evidence.color)
        // Label says "Evidence" to not give away the trick
        #expect(block.type.label == "Evidence")
    }

    @Test("ExerciseBlockType includes redHerring")
    func exerciseBlockType() {
        let type = ExerciseBlockType.redHerring
        #expect(type.rawValue == "red_herring")
        #expect(type.blockType == .redHerring)
    }

    // MARK: - Answer Key Decoding

    @Test("PyramidAnswerKey decodes when redHerringBlockIDs is absent")
    func answerKeyDecodesWithoutRedHerringKey() throws {
        // Most exercises have no red herrings and omit the key entirely. A default
        // value on the property does not make it optional for a synthesized
        // Codable, so this used to throw and empty the whole exercise library.
        let json = """
        {
            "governingThoughtID": "gt-001",
            "validGroupings": [
                { "groups": [ { "parentBlockID": "sp-001", "memberBlockIDs": ["ev-001"] } ] }
            ]
        }
        """
        let key = try JSONDecoder().decode(PyramidAnswerKey.self, from: Data(json.utf8))
        #expect(key.governingThoughtID == "gt-001")
        #expect(key.redHerringBlockIDs.isEmpty)
    }

    @Test("PyramidAnswerKey decodes redHerringBlockIDs when present")
    func answerKeyDecodesWithRedHerringKey() throws {
        let json = """
        {
            "governingThoughtID": "gt-001",
            "validGroupings": [
                { "groups": [ { "parentBlockID": "sp-001", "memberBlockIDs": ["ev-001"] } ] }
            ],
            "redHerringBlockIDs": ["rh-001", "rh-002"]
        }
        """
        let key = try JSONDecoder().decode(PyramidAnswerKey.self, from: Data(json.utf8))
        #expect(key.redHerringBlockIDs == ["rh-001", "rh-002"])
    }

    @Test("A whole exercise decodes when its answer key omits redHerringBlockIDs")
    func exerciseDecodesWithoutRedHerringKey() throws {
        // The library decodes exercises as one array, so a single throwing element
        // empties the entire library — which the learner sees as
        // "No exercises available" at every level.
        let json = """
        [{
            "id": "pe-test-en",
            "titleEN": "Test",
            "titleDE": "Test",
            "level": 1,
            "language": "en",
            "governingThought": { "id": "gt-001", "text": "Claim.", "type": "governing_thought" },
            "blocks": [
                { "id": "sp-001", "text": "Support.", "type": "support_point" },
                { "id": "ev-001", "text": "Evidence.", "type": "evidence" }
            ],
            "answerKey": {
                "governingThoughtID": "gt-001",
                "validGroupings": [
                    { "groups": [ { "parentBlockID": "sp-001", "memberBlockIDs": ["ev-001"] } ] }
                ]
            }
        }]
        """
        let exercises = try JSONDecoder().decode([PyramidExercise].self, from: Data(json.utf8))
        #expect(exercises.count == 1)
        #expect(exercises[0].answerKey.redHerringBlockIDs.isEmpty)
    }

    // MARK: - Answer Key

    @Test("PyramidAnswerKey supports redHerringBlockIDs")
    func answerKeyWithRedHerrings() {
        let key = PyramidAnswerKey(
            governingThoughtID: "gt",
            validGroupings: [],
            redHerringBlockIDs: ["rh-1", "rh-2"]
        )
        #expect(key.redHerringBlockIDs.count == 2)
        #expect(key.redHerringBlockIDs.contains("rh-1"))
    }

    @Test("PyramidAnswerKey defaults to empty red herrings")
    func answerKeyDefaultEmpty() {
        let key = PyramidAnswerKey(
            governingThoughtID: "gt",
            validGroupings: []
        )
        #expect(key.redHerringBlockIDs.isEmpty)
    }

    // MARK: - Validation

    @Test("Red herring placed in tree is flagged")
    func redHerringPlacedFlagged() {
        let engine = MECEValidationEngine()
        let answerKey = PyramidAnswerKey(
            governingThoughtID: "gt",
            validGroupings: [
                ValidGrouping(groups: [
                    ValidGroup(parentBlockID: "sp", memberBlockIDs: ["ev"]),
                ]),
            ],
            redHerringBlockIDs: ["rh"]
        )

        let userTree = UserPyramidTree(
            rootBlockID: "gt",
            parentToChildren: [
                "gt": ["sp"],
                "sp": ["ev", "rh"],
            ],
            allPlacedBlockIDs: ["gt", "sp", "ev", "rh"]
        )

        let result = engine.validate(userTree: userTree, answerKey: answerKey)

        if case .redHerringPlaced = result.blockStatuses["rh"] {
            // Expected
        } else {
            Issue
                .record(
                    "Expected red herring to be flagged as redHerringPlaced, got \(String(describing: result.blockStatuses["rh"]))"
                )
        }
    }

    @Test("Red herring discarded is marked correct")
    func redHerringDiscardedCorrect() {
        let engine = MECEValidationEngine()
        let answerKey = PyramidAnswerKey(
            governingThoughtID: "gt",
            validGroupings: [
                ValidGrouping(groups: [
                    ValidGroup(parentBlockID: "sp", memberBlockIDs: ["ev"]),
                ]),
            ],
            redHerringBlockIDs: ["rh"]
        )

        // User correctly didn't place the red herring
        let userTree = UserPyramidTree(
            rootBlockID: "gt",
            parentToChildren: [
                "gt": ["sp"],
                "sp": ["ev"],
            ],
            allPlacedBlockIDs: ["gt", "sp", "ev"]
        )

        let result = engine.validate(userTree: userTree, answerKey: answerKey)

        if case .redHerringDiscarded = result.blockStatuses["rh"] {
            // Expected
        } else {
            Issue
                .record(
                    "Expected red herring to be flagged as redHerringDiscarded, got \(String(describing: result.blockStatuses["rh"]))"
                )
        }
    }

    // MARK: - Feedback Mapping

    @Test("Red herring placed maps to misplaced feedback")
    func redHerringFeedbackMapping() {
        let result = PyramidValidationResult(
            blockStatuses: ["rh": .redHerringPlaced, "ev": .correct],
            groupAssessments: [],
            governingThoughtCorrect: true,
            score: 0.5,
            ungroupedBlockIDs: [],
            matchedGroupingIndex: 0
        )

        let states = ValidationFeedbackMapper.blockFeedbackStates(from: result)
        #expect(states["rh"] == .misplaced)
        #expect(states["ev"] == .correct)
    }

    // MARK: - JSON Decoding

    @Test("Exercise with red herring decodes from JSON")
    func exerciseWithRedHerringDecodes() throws {
        let json = """
        {
            "id": "rh-test",
            "titleEN": "Test",
            "titleDE": "Test",
            "level": 2,
            "language": "en",
            "governingThought": {"id": "gt", "text": "Claim", "type": "governing_thought"},
            "blocks": [
                {"id": "sp", "text": "Support", "type": "support_point"},
                {"id": "ev", "text": "Evidence", "type": "evidence"},
                {"id": "rh", "text": "Red herring", "type": "red_herring"}
            ],
            "answerKey": {
                "governingThoughtID": "gt",
                "validGroupings": [{"groups": [{"parentBlockID": "sp", "memberBlockIDs": ["ev"]}]}],
                "redHerringBlockIDs": ["rh"]
            }
        }
        """.data(using: .utf8)!

        let exercise = try JSONDecoder().decode(PyramidExercise.self, from: json)
        #expect(exercise.answerKey.redHerringBlockIDs == ["rh"])
        #expect(exercise.blocks[2].type == .redHerring)
    }

    // MARK: - Discard Zone

    @Test("PyramidTreeState removeFromUnplacedPool works")
    @MainActor
    func removeFromUnplacedPool() {
        let block = PyramidBlock(text: "Test", type: .evidence)
        let state = PyramidTreeState(blocks: [block])
        #expect(state.unplacedBlocks.count == 1)

        let removed = state.removeFromUnplacedPool(block.id)
        #expect(removed != nil)
        #expect(state.unplacedBlocks.isEmpty)
    }
}
