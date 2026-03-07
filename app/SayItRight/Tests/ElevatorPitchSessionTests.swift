import Foundation
import Testing
@testable import SayItRight

// MARK: - ElevatorPitchSession Tests

@Suite("ElevatorPitchSession")
struct ElevatorPitchSessionTests {

    private static func makeTopic(id: String = "ep-topic") -> Topic {
        Topic(
            id: id,
            titleEN: "Test Topic",
            titleDE: "Testthema",
            promptEN: "What do you think? Conclusion first.",
            promptDE: "Was denkst du? Fazit zuerst.",
            domain: .school,
            level: 1,
            barbaraFavorite: false
        )
    }

    @Test("Session initialises with topic and duration")
    func initialisation() {
        let topic = Self.makeTopic()
        let session = ElevatorPitchSession(topic: topic, durationSeconds: 60)

        #expect(session.topic.id == "ep-topic")
        #expect(session.durationSeconds == 60)
        #expect(session.sessionTypeID == "elevator-pitch")
        #expect(!session.hasResponse)
        #expect(session.responseText == nil)
        #expect(session.timedOut == false)
    }

    @Test("recordResponse captures text and timeout status")
    func recordResponse() {
        let topic = Self.makeTopic()
        var session = ElevatorPitchSession(topic: topic)
        let before = Date.now

        session.recordResponse("Schools should have uniforms because...")

        #expect(session.hasResponse)
        #expect(session.responseText == "Schools should have uniforms because...")
        #expect(session.submittedAt != nil)
        #expect(session.submittedAt! >= before)
        #expect(!session.timedOut)
    }

    @Test("recordResponse with timeout flag")
    func recordResponseTimedOut() {
        let topic = Self.makeTopic()
        var session = ElevatorPitchSession(topic: topic)

        session.recordResponse("Partial response...", timedOut: true)

        #expect(session.hasResponse)
        #expect(session.timedOut)
    }

    @Test("duration for level 1 is 60 seconds")
    func durationLevel1() {
        #expect(ElevatorPitchSession.duration(for: 1) == 60)
    }

    @Test("duration for level 2+ is 30 seconds")
    func durationLevel2() {
        #expect(ElevatorPitchSession.duration(for: 2) == 30)
        #expect(ElevatorPitchSession.duration(for: 3) == 30)
        #expect(ElevatorPitchSession.duration(for: 4) == 30)
    }
}

// MARK: - ElevatorPitchCoordinator Tests

@Suite("ElevatorPitchCoordinator")
struct ElevatorPitchCoordinatorTests {

    private static let testTopics: [Topic] = [
        Topic(
            id: "ep-1",
            titleEN: "Topic 1",
            titleDE: "Thema 1",
            promptEN: "Prompt 1",
            promptDE: "Aufgabe 1",
            domain: .school,
            level: 1,
            barbaraFavorite: false
        ),
        Topic(
            id: "ep-2",
            titleEN: "Topic 2",
            titleDE: "Thema 2",
            promptEN: "Prompt 2",
            promptDE: "Aufgabe 2",
            domain: .everyday,
            level: 1,
            barbaraFavorite: true
        ),
    ]

    @Test("selectTopic returns a topic for matching level")
    @MainActor
    func selectTopicForLevel() {
        let coordinator = ElevatorPitchCoordinator(topics: Self.testTopics)
        let topic = coordinator.selectTopic(for: 1, language: "en")
        #expect(topic != nil)
        #expect(topic!.level <= 1)
    }

    @Test("selectTopic returns nil when no topics match")
    @MainActor
    func noMatchingTopics() {
        let coordinator = ElevatorPitchCoordinator(topics: [])
        let topic = coordinator.selectTopic(for: 1, language: "en")
        #expect(topic == nil)
    }

    @Test("selectTopic avoids recently seen topics")
    @MainActor
    func avoidsRecentTopics() {
        let coordinator = ElevatorPitchCoordinator(topics: Self.testTopics)

        let first = coordinator.selectTopic(for: 1, language: "en")
        #expect(first != nil)

        coordinator.recentTopicIDs.insert(first!.id)

        let second = coordinator.selectTopic(for: 1, language: "en")
        #expect(second != nil)
        #expect(second!.id != first!.id)
    }

    @Test("clearRecentTopics empties the set")
    @MainActor
    func clearRecentTopics() {
        let coordinator = ElevatorPitchCoordinator(topics: Self.testTopics)
        coordinator.recentTopicIDs.insert("x")
        coordinator.clearRecentTopics()
        #expect(coordinator.recentTopicIDs.isEmpty)
    }
}

// MARK: - SessionType Elevator Pitch Tests

@Suite("SessionType — Elevator Pitch")
struct SessionTypeElevatorPitchTests {

    @Test("elevatorPitch has correct raw value")
    func rawValue() {
        #expect(SessionType.elevatorPitch.rawValue == "elevator-pitch")
    }

    @Test("elevatorPitch English display name")
    func displayNameEN() {
        #expect(SessionType.elevatorPitch.displayName(language: "en") == "The elevator pitch")
    }

    @Test("elevatorPitch German display name")
    func displayNameDE() {
        #expect(SessionType.elevatorPitch.displayName(language: "de") == "30 Sekunden")
    }

    @Test("elevatorPitch icon is timer")
    func iconName() {
        #expect(SessionType.elevatorPitch.iconName == "timer")
    }

    @Test("CaseIterable includes elevatorPitch")
    func allCases() {
        #expect(SessionType.allCases.contains(.elevatorPitch))
        #expect(SessionType.allCases.count == 3)
    }
}
