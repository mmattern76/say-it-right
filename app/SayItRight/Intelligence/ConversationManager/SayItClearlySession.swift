import Foundation

/// Tracks the state of a "Say it clearly" session.
///
/// Captures the selected topic, the learner's response text, and timestamps
/// for the session lifecycle. This struct is the session-specific data model
/// that sits alongside the general `SessionManager` conversation state.
struct SayItClearlySession: Sendable {

    /// The topic Barbara selected for this session.
    let topic: Topic

    /// When the session was started (topic presented).
    let startedAt: Date

    /// The learner's submitted response text, if any.
    private(set) var responseText: String?

    /// When the learner submitted their response.
    private(set) var respondedAt: Date?

    /// The session type identifier for downstream processing.
    let sessionTypeID: String = "say-it-clearly"

    init(topic: Topic, startedAt: Date = .now) {
        self.topic = topic
        self.startedAt = startedAt
    }

    /// Record the learner's response.
    mutating func recordResponse(_ text: String, at date: Date = .now) {
        responseText = text
        respondedAt = date
    }

    /// Whether the learner has submitted a response.
    var hasResponse: Bool {
        responseText != nil
    }
}
