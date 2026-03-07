import Foundation

/// Orchestrates the "Elevator pitch" session flow.
///
/// Selects a topic from the topic bank and starts a timed session
/// on the SessionManager. Reuses the same TopicBank as Say It Clearly
/// since the topic format is identical.
@MainActor
@Observable
final class ElevatorPitchCoordinator {

    /// Topics the learner has seen recently.
    var recentTopicIDs: Set<String> = []

    /// The topic bank used for selection.
    private let topicBank: TopicBank

    /// Maximum recent topics before reset.
    private let maxRecentTopics = 20

    init(topicBank: TopicBank = TopicBank.loadFromBundle()) {
        self.topicBank = topicBank
    }

    /// Convenience initialiser for testing.
    init(topics: [Topic]) {
        self.topicBank = TopicBank(topics: topics)
    }

    /// Start an elevator pitch session.
    ///
    /// - Returns: The selected topic, or `nil` if none available.
    @discardableResult
    func startSession(
        sessionManager: SessionManager,
        profile: LearnerProfile,
        language: String
    ) async -> Topic? {
        guard let topic = selectTopic(for: profile.currentLevel, language: language) else {
            return nil
        }

        trackSeen(topic)
        await sessionManager.startElevatorPitchSession(
            topic: topic,
            profile: profile,
            language: language
        )
        return topic
    }

    /// Select a topic appropriate for the learner's level.
    func selectTopic(for level: Int, language: String) -> Topic? {
        if let topic = topicBank.randomTopic(for: level, excluding: recentTopicIDs) {
            return topic
        }
        recentTopicIDs.removeAll()
        return topicBank.randomTopic(for: level, excluding: recentTopicIDs)
    }

    private func trackSeen(_ topic: Topic) {
        recentTopicIDs.insert(topic.id)
        if recentTopicIDs.count > maxRecentTopics {
            recentTopicIDs.removeAll()
            recentTopicIDs.insert(topic.id)
        }
    }

    func clearRecentTopics() {
        recentTopicIDs.removeAll()
    }
}
