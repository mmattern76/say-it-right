import Foundation

/// Drives the chat UI by observing a `SessionManager` for message state.
///
/// `ChatViewModel` acts as a thin presentation adapter: it reads messages and
/// loading state from the `SessionManager` and forwards user input to it.
/// When no `SessionManager` is provided it falls back to standalone mode
/// (useful for previews and tests).
///
/// Observed by `ChatView` for reactive UI updates.
@MainActor
@Observable
final class ChatViewModel {

    // MARK: - Published State

    /// All messages in the current conversation.
    /// Reads from SessionManager when available, otherwise uses local storage.
    var messages: [ChatMessage] {
        get { sessionManager?.messages ?? _localMessages }
        set {
            if sessionManager != nil {
                // SessionManager owns messages; ignore direct sets
            } else {
                _localMessages = newValue
            }
        }
    }

    /// Replace the message list (used for previews and tests in standalone mode).
    func setMessages(_ newMessages: [ChatMessage]) {
        _localMessages = newMessages
    }

    /// The text currently being composed by the learner.
    var inputText: String = ""

    /// Whether Barbara is currently generating a response.
    var isLoading: Bool {
        if let sm = sessionManager {
            return sm.sessionState == .loading
        }
        return _localIsLoading
    }

    /// The most recent error message, if any.
    var errorMessage: String? {
        if let sm = sessionManager {
            if case .error(let msg) = sm.sessionState {
                return msg
            }
            return nil
        }
        return _localErrorMessage
    }

    /// Whether there is an active session.
    var hasActiveSession: Bool {
        sessionManager?.sessionState == .active || sessionManager?.sessionState == .loading
    }

    // MARK: - Private State (standalone mode)

    private var _localMessages: [ChatMessage] = []
    private var _localIsLoading: Bool = false
    private var _localErrorMessage: String?

    // MARK: - Dependencies

    /// The session manager driving the conversation. Nil for standalone/preview mode.
    var sessionManager: SessionManager?

    private let anthropicService: AnthropicService
    private let systemPromptAssembler: SystemPromptAssembler
    private let responseParser: ResponseParser

    // MARK: - Session Config (standalone mode fallback)

    /// Current learner level (1-4).
    var level: Int = 1

    /// Session type identifier (e.g. "say-it-clearly").
    var sessionType: String = "say-it-clearly"

    /// Language code ("en" or "de").
    var language: String = "en"

    /// JSON snapshot of the learner profile for prompt injection.
    var profileJSON: String = "{}"

    // MARK: - Init

    init(
        sessionManager: SessionManager? = nil,
        anthropicService: AnthropicService = .shared,
        systemPromptAssembler: SystemPromptAssembler = SystemPromptAssembler(),
        responseParser: ResponseParser = ResponseParser()
    ) {
        self.sessionManager = sessionManager
        self.anthropicService = anthropicService
        self.systemPromptAssembler = systemPromptAssembler
        self.responseParser = responseParser
    }

    // MARK: - Public API

    /// Send the current input text as a learner message and stream Barbara's reply.
    func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        inputText = ""

        if let sm = sessionManager {
            Task {
                await sm.sendMessage(text: text)
            }
        } else {
            // Standalone mode: direct API call
            let learnerMessage = ChatMessage(role: .learner, text: text)
            _localMessages.append(learnerMessage)
            _localErrorMessage = nil
            Task {
                await streamBarbaraResponseStandalone()
            }
        }
    }

    /// Clear all messages and reset the conversation.
    func clearConversation() {
        if let sm = sessionManager {
            sm.endSession()
        } else {
            _localMessages.removeAll()
            _localIsLoading = false
            _localErrorMessage = nil
        }
        inputText = ""
    }

    // MARK: - Private: Standalone streaming (no SessionManager)

    private func streamBarbaraResponseStandalone() async {
        _localIsLoading = true

        let streamingMessage = ChatMessage(
            role: .barbara,
            text: "",
            isStreaming: true
        )
        _localMessages.append(streamingMessage)
        let streamingIndex = _localMessages.count - 1

        do {
            let systemPrompt = systemPromptAssembler.assemble(
                level: level,
                sessionType: sessionType,
                language: language,
                profileJSON: profileJSON
            )

            let apiMessages = _localMessages
                .filter { !$0.text.isEmpty }
                .map { message in
                    APIMessage(
                        role: message.role == .barbara ? "assistant" : "user",
                        content: message.text
                    )
                }

            let stream = await anthropicService.sendMessage(
                systemPrompt: systemPrompt,
                messages: apiMessages
            )

            var fullText = ""
            for try await chunk in stream {
                fullText += chunk
                _localMessages[streamingIndex].text = fullText
            }

            let parsed = responseParser.parse(fullResponse: fullText)
            _localMessages[streamingIndex].text = parsed.visibleText
            _localMessages[streamingIndex].metadata = parsed.metadata
            _localMessages[streamingIndex].isStreaming = false

        } catch {
            if _localMessages[streamingIndex].text.isEmpty {
                _localMessages.remove(at: streamingIndex)
            } else {
                _localMessages[streamingIndex].isStreaming = false
            }
            _localErrorMessage = error.localizedDescription
        }

        _localIsLoading = false
    }
}
