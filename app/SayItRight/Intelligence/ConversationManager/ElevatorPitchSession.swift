import Foundation

/// Tracks the state of an "Elevator pitch" / "30 Sekunden" session.
///
/// The learner writes a structured response under time pressure. No revision
/// loop — one shot, then Barbara's evaluation and summary.
struct ElevatorPitchSession: Sendable {

    /// The topic for this session.
    let topic: Topic

    /// When the session was started (topic presented).
    let startedAt: Date

    /// Duration allowed in seconds (30 or 60 based on level).
    let durationSeconds: Int

    /// The learner's submitted response, if any.
    private(set) var responseText: String?

    /// When the learner submitted (or time expired).
    private(set) var submittedAt: Date?

    /// Whether the timer expired before the learner submitted.
    private(set) var timedOut: Bool = false

    /// The session type identifier for downstream processing.
    let sessionTypeID: String = "elevator-pitch"

    init(topic: Topic, durationSeconds: Int = 60, startedAt: Date = .now) {
        self.topic = topic
        self.durationSeconds = durationSeconds
        self.startedAt = startedAt
    }

    /// Record the learner's response.
    mutating func recordResponse(_ text: String, timedOut: Bool = false, at date: Date = .now) {
        responseText = text
        submittedAt = date
        self.timedOut = timedOut
    }

    /// Whether the learner has submitted a response.
    var hasResponse: Bool {
        responseText != nil
    }

    /// Duration appropriate for the learner's level.
    static func duration(for level: Int) -> Int {
        level >= 2 ? 30 : 60
    }
}
