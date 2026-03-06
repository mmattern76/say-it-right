import Foundation

/// Drives the chat UI: manages message history, sends learner input to the
/// Anthropic API via `AnthropicService`, and streams Barbara's response
/// back token by token.
///
/// Observed by `ChatView` for reactive UI updates.
@MainActor
@Observable
final class ChatViewModel {

    // MARK: - Published State

    /// All messages in the current conversation.
    /// Use `send()` or `setMessages(_:)` to modify from outside.
    private(set) var messages: [ChatMessage] = []

    /// Replace the message list (used for previews and tests).
    func setMessages(_ newMessages: [ChatMessage]) {
        messages = newMessages
    }

    /// The text currently being composed by the learner.
    var inputText: String = ""

    /// Whether Barbara is currently generating a response.
    private(set) var isLoading: Bool = false

    /// The most recent error message, if any.
    private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let anthropicService: AnthropicService
    private let systemPromptAssembler: SystemPromptAssembler
    private let responseParser: ResponseParser

    // MARK: - Session Config

    /// Current learner level (1–4).
    var level: Int = 1

    /// Session type identifier (e.g. "say-it-clearly").
    var sessionType: String = "say-it-clearly"

    /// Language code ("en" or "de").
    var language: String = "en"

    /// JSON snapshot of the learner profile for prompt injection.
    var profileJSON: String = "{}"

    // MARK: - Init

    init(
        anthropicService: AnthropicService = .shared,
        systemPromptAssembler: SystemPromptAssembler = SystemPromptAssembler(),
        responseParser: ResponseParser = ResponseParser()
    ) {
        self.anthropicService = anthropicService
        self.systemPromptAssembler = systemPromptAssembler
        self.responseParser = responseParser
    }

    // MARK: - Public API

    /// Send the current input text as a learner message and stream Barbara's reply.
    func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        // Add learner message
        let learnerMessage = ChatMessage(role: .learner, text: text)
        messages.append(learnerMessage)
        inputText = ""
        errorMessage = nil

        // Start Barbara's response
        Task {
            await streamBarbaraResponse()
        }
    }

    /// Clear all messages and reset the conversation.
    func clearConversation() {
        messages.removeAll()
        inputText = ""
        isLoading = false
        errorMessage = nil
    }

    // MARK: - Private

    private func streamBarbaraResponse() async {
        isLoading = true

        // Create a placeholder streaming message for Barbara
        let streamingMessage = ChatMessage(
            role: .barbara,
            text: "",
            isStreaming: true
        )
        messages.append(streamingMessage)
        let streamingIndex = messages.count - 1

        do {
            // Assemble system prompt
            let systemPrompt = systemPromptAssembler.assemble(
                level: level,
                sessionType: sessionType,
                language: language,
                profileJSON: profileJSON
            )

            // Convert UI messages to API messages
            let apiMessages = messages
                .filter { !$0.text.isEmpty }
                .dropLast() // Exclude the empty streaming placeholder
                .map { message in
                    APIMessage(
                        role: message.role == .barbara ? "assistant" : "user",
                        content: message.text
                    )
                }

            // Stream response
            let stream = await anthropicService.sendMessage(
                systemPrompt: systemPrompt,
                messages: Array(apiMessages)
            )

            var fullText = ""
            for try await chunk in stream {
                fullText += chunk
                messages[streamingIndex].text = fullText
            }

            // Parse the complete response for hidden metadata
            let parsed = responseParser.parse(fullResponse: fullText)
            messages[streamingIndex].text = parsed.visibleText
            messages[streamingIndex].metadata = parsed.metadata
            messages[streamingIndex].isStreaming = false

        } catch {
            // Remove the empty streaming message on error
            if messages[streamingIndex].text.isEmpty {
                messages.remove(at: streamingIndex)
            } else {
                messages[streamingIndex].isStreaming = false
            }
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
