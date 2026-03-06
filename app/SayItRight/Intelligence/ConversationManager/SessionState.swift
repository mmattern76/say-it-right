import Foundation

/// The lifecycle state of a coaching session.
enum SessionState: Sendable, Equatable {
    /// No active session. Ready to start one.
    case idle

    /// A session is running and accepting messages.
    case active

    /// Waiting for Barbara's response from the API.
    case loading

    /// An error occurred. The message describes what went wrong.
    case error(String)
}
