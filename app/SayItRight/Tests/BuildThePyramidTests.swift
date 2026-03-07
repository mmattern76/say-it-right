import Foundation
import Testing
@testable import SayItRight

@Suite("Build the Pyramid")
struct BuildThePyramidTests {

    // MARK: - Session Type

    @Test("SessionType includes buildThePyramid")
    func sessionTypeExists() {
        let type = SessionType.buildThePyramid
        #expect(type.rawValue == "build-the-pyramid")
    }

    @Test("buildThePyramid has display names")
    func displayNames() {
        let en = SessionType.buildThePyramid.displayName(language: "en")
        let de = SessionType.buildThePyramid.displayName(language: "de")
        #expect(en == "Build the pyramid")
        #expect(de == "Bau die Pyramide")
    }

    @Test("buildThePyramid has icon")
    func icon() {
        #expect(SessionType.buildThePyramid.iconName == "rectangle.3.group")
    }

    // MARK: - Exercise Data Model

    @Test("PyramidExercise is decodable from JSON")
    func exerciseDecodable() throws {
        let json = """
        {
            "id": "test-001",
            "titleEN": "Test",
            "titleDE": "Test",
            "level": 1,
            "language": "en",
            "governingThought": {
                "id": "gt-1",
                "text": "Main claim",
                "type": "governing_thought"
            },
            "blocks": [
                {"id": "sp-1", "text": "Support 1", "type": "support_point"},
                {"id": "ev-1", "text": "Evidence 1", "type": "evidence"}
            ],
            "answerKey": {
                "governingThoughtID": "gt-1",
                "validGroupings": [{
                    "groups": [{
                        "parentBlockID": "sp-1",
                        "memberBlockIDs": ["ev-1"]
                    }]
                }]
            }
        }
        """.data(using: .utf8)!

        let exercise = try JSONDecoder().decode(PyramidExercise.self, from: json)
        #expect(exercise.id == "test-001")
        #expect(exercise.blocks.count == 2)
        #expect(exercise.governingThought.type == .governingThought)
        #expect(exercise.answerKey.governingThoughtID == "gt-1")
    }

    // MARK: - Session State

    @Test("BuildThePyramidSession tracks attempts")
    func sessionTracksAttempts() {
        var session = BuildThePyramidSession(
            exercise: makeTestExercise(),
            maxAttempts: 3
        )
        #expect(session.attempts == 0)
        #expect(!session.isComplete)
        #expect(!session.canShowAnswer)

        session.recordAttempt(score: 0.5)
        #expect(session.attempts == 1)
        #expect(!session.isComplete)
        #expect(!session.canShowAnswer)

        session.recordAttempt(score: 0.7)
        session.recordAttempt(score: 0.8)
        #expect(session.attempts == 3)
        #expect(session.canShowAnswer)
    }

    @Test("Session completes on perfect score")
    func sessionCompletesOnPerfect() {
        var session = BuildThePyramidSession(exercise: makeTestExercise())
        session.recordAttempt(score: 1.0)
        #expect(session.isComplete)
    }

    @Test("Session can reveal answer")
    func sessionRevealsAnswer() {
        var session = BuildThePyramidSession(exercise: makeTestExercise())
        session.revealAnswer()
        #expect(session.isComplete)
        #expect(session.showedAnswer)
    }

    // MARK: - Exercise Block Type

    @Test("ExerciseBlockType converts to BlockType")
    func blockTypeConversion() {
        #expect(ExerciseBlockType.governingThought.blockType == .governingThought)
        #expect(ExerciseBlockType.supportPoint.blockType == .supportPoint)
        #expect(ExerciseBlockType.evidence.blockType == .evidence)
    }

    // MARK: - Library

    @Test("PyramidExerciseLibrary filters by level and language")
    func libraryFilters() {
        let ex1 = makeTestExercise(id: "l1-en", level: 1, language: "en")
        let ex2 = makeTestExercise(id: "l2-en", level: 2, language: "en")
        let ex3 = makeTestExercise(id: "l1-de", level: 1, language: "de")
        let library = PyramidExerciseLibrary(exercises: [ex1, ex2, ex3])

        let l1en = library.exercises(for: 1, language: "en")
        #expect(l1en.count == 1)
        #expect(l1en[0].id == "l1-en")

        let l2en = library.exercises(for: 2, language: "en")
        #expect(l2en.count == 2) // level <= 2 returns both l1 and l2
    }

    // MARK: - Helpers

    private func makeTestExercise(id: String = "test", level: Int = 1, language: String = "en") -> PyramidExercise {
        PyramidExercise(
            id: id,
            titleEN: "Test",
            titleDE: "Test",
            level: level,
            language: language,
            governingThought: ExerciseBlock(id: "gt", text: "Claim", type: .governingThought),
            blocks: [
                ExerciseBlock(id: "sp", text: "Support", type: .supportPoint),
                ExerciseBlock(id: "ev", text: "Evidence", type: .evidence),
            ],
            answerKey: PyramidAnswerKey(
                governingThoughtID: "gt",
                validGroupings: [
                    ValidGrouping(groups: [
                        ValidGroup(parentBlockID: "sp", memberBlockIDs: ["ev"])
                    ])
                ]
            )
        )
    }
}
