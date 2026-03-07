import Foundation
import Testing
@testable import SayItRight

@Suite("Fix This Mess Visual")
struct FixThisMessVisualTests {

    // MARK: - Data Model

    @Test("FixThisMessExercise is decodable from JSON")
    func exerciseDecodable() throws {
        let json = """
        {
            "id": "ftm-test",
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
                {"id": "ev-1", "text": "Evidence 1", "type": "evidence"},
                {"id": "ev-2", "text": "Evidence 2", "type": "evidence"}
            ],
            "answerKey": {
                "governingThoughtID": "gt-1",
                "validGroupings": [{
                    "groups": [{
                        "parentBlockID": "sp-1",
                        "memberBlockIDs": ["ev-1", "ev-2"]
                    }]
                }]
            },
            "wrongArrangement": {
                "groups": [{
                    "parentBlockID": "sp-1",
                    "childBlockIDs": ["ev-2"]
                }]
            },
            "structuralFlawDescription": "Evidence 1 is missing from the group"
        }
        """.data(using: .utf8)!

        let exercise = try JSONDecoder().decode(FixThisMessExercise.self, from: json)
        #expect(exercise.id == "ftm-test")
        #expect(exercise.blocks.count == 3)
        #expect(exercise.wrongArrangement.groups.count == 1)
        #expect(exercise.wrongArrangement.groups[0].childBlockIDs == ["ev-2"])
        #expect(exercise.structuralFlawDescription.contains("Evidence 1"))
    }

    // MARK: - Library

    @Test("FixThisMessExerciseLibrary filters by level and language")
    func libraryFilters() {
        let ex1 = makeTestExercise(id: "l1-en", level: 1, language: "en")
        let ex2 = makeTestExercise(id: "l2-en", level: 2, language: "en")
        let ex3 = makeTestExercise(id: "l1-de", level: 1, language: "de")
        let library = FixThisMessExerciseLibrary(exercises: [ex1, ex2, ex3])

        let l1en = library.exercises(for: 1, language: "en")
        #expect(l1en.count == 1)
        #expect(l1en[0].id == "l1-en")

        let l2en = library.exercises(for: 2, language: "en")
        #expect(l2en.count == 2)
    }

    @Test("Library excludes recent exercises")
    func libraryExcludesRecent() {
        let ex1 = makeTestExercise(id: "a", level: 1, language: "en")
        let ex2 = makeTestExercise(id: "b", level: 1, language: "en")
        let library = FixThisMessExerciseLibrary(exercises: [ex1, ex2])

        let result = library.randomExercise(for: 1, language: "en", excluding: ["a"])
        #expect(result?.id == "b")
    }

    // MARK: - Wrong Arrangement

    @Test("WrongArrangement describes incorrect block placement")
    func wrongArrangementStructure() {
        let arrangement = WrongArrangement(groups: [
            WrongGroup(parentBlockID: "sp-1", childBlockIDs: ["ev-1", "ev-3"]),
            WrongGroup(parentBlockID: "sp-2", childBlockIDs: ["ev-2", "ev-4"]),
        ])

        #expect(arrangement.groups.count == 2)
        #expect(arrangement.groups[0].childBlockIDs.contains("ev-3"))
        #expect(arrangement.groups[1].parentBlockID == "sp-2")
    }

    @Test("Exercise title respects language")
    func titleLanguage() {
        let exercise = makeTestExercise(id: "test", level: 1, language: "en")
        #expect(exercise.title(language: "en") == "Test EN")
        #expect(exercise.title(language: "de") == "Test DE")
    }

    // MARK: - Helpers

    private func makeTestExercise(
        id: String = "test",
        level: Int = 1,
        language: String = "en"
    ) -> FixThisMessExercise {
        FixThisMessExercise(
            id: id,
            titleEN: "Test EN",
            titleDE: "Test DE",
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
            ),
            wrongArrangement: WrongArrangement(groups: [
                WrongGroup(parentBlockID: "sp", childBlockIDs: ["ev"])
            ]),
            structuralFlawDescription: "Test flaw"
        )
    }
}
