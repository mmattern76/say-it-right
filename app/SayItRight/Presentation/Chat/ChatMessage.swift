import Foundation

/// A single message displayed in the chat UI.
///
/// Each message has an author role (Barbara or learner), the visible
/// text content, and a timestamp. Barbara's messages may also carry
/// hidden metadata extracted by `ResponseParser`.
struct ChatMessage: Identifiable, Sendable {
    let id: UUID
    let role: ChatRole
    var text: String
    let timestamp: Date
    var metadata: BarbaraMetadata?

    /// Whether Barbara is still streaming tokens into this message.
    var isStreaming: Bool

    init(
        id: UUID = UUID(),
        role: ChatRole,
        text: String,
        timestamp: Date = .now,
        metadata: BarbaraMetadata? = nil,
        isStreaming: Bool = false
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
        self.metadata = metadata
        self.isStreaming = isStreaming
    }
}

/// Who authored a chat message.
enum ChatRole: String, Sendable {
    case barbara
    case learner
}
