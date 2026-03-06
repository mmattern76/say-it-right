import Foundation

/// Orchestrates the "Say it clearly" session flow.
///
/// Responsibilities:
/// 1. Select a topic from the topic bank (filtered by language and level).
/// 2. Start the session via `SessionManager` with the selected topic.
/// 3. Track recently seen topics to avoid immediate repetition.
///
/// This coordinator is the single entry point for starting a "Say it clearly"
/// session from the UI layer.
@MainActor
@Observable
final class SayItClearlyCoordinator {

    /// Topics the learner has seen recently (simple dedup, not persistent).
    /// Internal setter for testability; production code uses `trackSeen(_:)`.
    var recentTopicIDs: Set<String> = []

    /// The topic bank used for selection.
    private let topicBank: TopicBank

    /// Maximum number of recent topic IDs to track before resetting.
    private let maxRecentTopics = 20

    init(topicBank: TopicBank = TopicBank.loadFromBundle()) {
        self.topicBank = topicBank
    }

    /// Convenience initialiser for testing with an explicit topic list.
    init(topics: [Topic]) {
        self.topicBank = TopicBank(topics: topics)
    }

    /// Start a "Say it clearly" session.
    ///
    /// Selects a random level-appropriate topic and starts the session
    /// on the provided `SessionManager`.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager to start the session on.
    ///   - profile: The learner's current profile.
    ///   - language: Language code ("en" or "de").
    /// - Returns: The selected topic, or `nil` if no topics are available.
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
        await sessionManager.startSayItClearlySession(
            topic: topic,
            profile: profile,
            language: language
        )
        return topic
    }

    /// Select a topic appropriate for the learner's level and language.
    ///
    /// Filters out recently seen topics. If all topics have been seen,
    /// resets the recent list and picks from the full set.
    func selectTopic(for level: Int, language: String) -> Topic? {
        // First try excluding recently seen topics
        if let topic = topicBank.randomTopic(for: level, excluding: recentTopicIDs) {
            return topic
        }

        // All topics seen — reset and try again
        recentTopicIDs.removeAll()
        return topicBank.randomTopic(for: level, excluding: recentTopicIDs)
    }

    /// Mark a topic as recently seen.
    private func trackSeen(_ topic: Topic) {
        recentTopicIDs.insert(topic.id)
        if recentTopicIDs.count > maxRecentTopics {
            recentTopicIDs.removeAll()
            recentTopicIDs.insert(topic.id)
        }
    }

    /// Clear the recent topics list (e.g. for testing).
    func clearRecentTopics() {
        recentTopicIDs.removeAll()
    }
}
