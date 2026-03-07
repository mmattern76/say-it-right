import Foundation

/// Drives the chat UI by observing a `SessionManager` for message state.
///
/// `ChatViewModel` acts as a thin presentation adapter: it reads messages and
/// loading state from the `SessionManager` and forwards user input to it.
/// When no `SessionManager` is provided it falls back to standalone mode
/// (useful for previews and tests).
///
/// Handles network errors gracefully: classifies errors, retries transient
/// failures with exponential backoff, preserves unsent input on failure,
/// and surfaces in-character error messages via `ChatErrorState`.
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

    /// Set an error state for previews and tests.
    func setErrorForPreview(_ error: NetworkError) {
        errorState = ChatErrorState(error: error)
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

    /// Whether the revision loop is complete and a summary should be shown.
    var isRevisionComplete: Bool {
        sessionManager?.sayItClearlySession?.isRevisionComplete ?? false
    }

    /// Whether the session summary has already been requested.
    var isSummaryRequested: Bool {
        sessionManager?.sayItClearlySession?.summaryRequested ?? false
    }

    /// The current revision round (0 = first draft awaiting, 1+ = revision N).
    var currentRevisionRound: Int {
        sessionManager?.sayItClearlySession?.currentRevisionRound ?? 0
    }

    // MARK: - Private State (standalone mode)

    private var _localMessages: [ChatMessage] = []
    private var _localIsLoading: Bool = false
    private var _localErrorMessage: String?

    /// Structured error state for the error banner UI.
    private(set) var errorState = ChatErrorState()

    /// Whether the settings screen should be presented (triggered by invalid API key).
    var showSettings: Bool = false

    // MARK: - Dependencies

    /// The session manager driving the conversation. Nil for standalone/preview mode.
    var sessionManager: SessionManager?

    private let anthropicService: AnthropicService
    private let systemPromptAssembler: SystemPromptAssembler
    private let responseParser: ResponseParser
    private let retryPolicy: RetryPolicy

    // MARK: - Session Config (standalone mode fallback)

    /// Current learner level (1-4).
    var level: Int = 1

    /// Session type identifier (e.g. "say-it-clearly").
    var sessionType: String = "say-it-clearly"

    /// Language code ("en" or "de").
    var language: String = "en"

    /// JSON snapshot of the learner profile for prompt injection.
    var profileJSON: String = "{}"

    // MARK: - Private State

    /// The learner's last message text, preserved for retry on failure.
    private var pendingInputText: String?

    /// Active rate-limit countdown task.
    private var countdownTask: Task<Void, Never>?

    // MARK: - Init

    init(
        sessionManager: SessionManager? = nil,
        anthropicService: AnthropicService = .shared,
        systemPromptAssembler: SystemPromptAssembler = SystemPromptAssembler(),
        responseParser: ResponseParser = ResponseParser(),
        retryPolicy: RetryPolicy = .standard
    ) {
        self.sessionManager = sessionManager
        self.anthropicService = anthropicService
        self.systemPromptAssembler = systemPromptAssembler
        self.responseParser = responseParser
        self.retryPolicy = retryPolicy
    }

    // MARK: - Public API

    /// Send the current input text as a learner message and stream Barbara's reply.
    func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        pendingInputText = text
        inputText = ""
        errorState.clear()

        if let sm = sessionManager {
            Task {
                await sm.sendMessage(text: text)
                // After Barbara responds, pre-load revision text if applicable
                preloadRevisionTextIfNeeded()
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

    /// Retry the last failed request.
    func retry() {
        guard !isLoading else { return }

        errorState.clear()
        _localErrorMessage = nil

        Task {
            await streamBarbaraResponseStandalone()
        }
    }

    /// Dismiss the current error banner without retrying.
    func dismissError() {
        errorState.clear()
        _localErrorMessage = nil
        countdownTask?.cancel()
        countdownTask = nil
    }

    /// Open settings (called when API key is invalid).
    func openSettings() {
        showSettings = true
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
        errorState.clear()
        pendingInputText = nil
        countdownTask?.cancel()
        countdownTask = nil
    }

    /// Request the session summary after the revision loop completes.
    func requestSummary() {
        guard let sm = sessionManager else { return }
        Task {
            await sm.requestSessionSummary()
        }
    }

    /// Pre-load the learner's last response into the input field for revision editing.
    private func preloadRevisionTextIfNeeded() {
        guard let sm = sessionManager,
              let preloadText = sm.revisionPreloadText,
              sm.sayItClearlySession?.canRevise == true else { return }
        // Only pre-load if input is currently empty
        if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            inputText = preloadText
        }
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

            // Stream response with automatic retry for transient errors
            var fullText = ""

            try await retryPolicy.execute(
                operation: { [anthropicService] in
                    let stream = await anthropicService.sendMessage(
                        systemPrompt: systemPrompt,
                        messages: Array(apiMessages)
                    )

                    for try await chunk in stream {
                        await MainActor.run {
                            fullText += chunk
                            self._localMessages[streamingIndex].text = fullText
                        }
                    }
                },
                onRetry: { [weak self] attempt, delay in
                    await MainActor.run {
                        self?.errorState.retryCount = attempt
                        self?.errorState.isRetrying = true
                    }
                }
            )

            let parsed = responseParser.parse(fullResponse: fullText)
            _localMessages[streamingIndex].text = parsed.visibleText
            _localMessages[streamingIndex].metadata = parsed.metadata
            _localMessages[streamingIndex].isStreaming = false

            // Success — clear pending input
            pendingInputText = nil
            errorState.clear()

        } catch {
            let classifiedError = NetworkErrorClassifier.classify(error)

            // Handle partial response from streaming interruption
            let hasPartial = !_localMessages[streamingIndex].text.isEmpty
            if hasPartial {
                _localMessages[streamingIndex].isStreaming = false
                _localMessages[streamingIndex].text += "\n\n[...]"
            } else {
                _localMessages.remove(at: streamingIndex)
            }

            // Preserve the learner's input for retry
            if let pending = pendingInputText {
                inputText = pending
                if let lastLearnerIndex = _localMessages.lastIndex(where: { $0.role == .learner && $0.text == pending }) {
                    _localMessages.remove(at: lastLearnerIndex)
                }
            }

            // Set error state for the banner
            errorState.error = classifiedError
            errorState.hasPartialResponse = hasPartial
            _localErrorMessage = classifiedError.barbaraMessage(language: language)

            // Start countdown for rate-limited errors
            if case .rateLimited(let seconds) = classifiedError, let s = seconds {
                startRateLimitCountdown(seconds: s)
            }
        }

        _localIsLoading = false
        errorState.isRetrying = false
    }

    /// Start a countdown timer for rate-limited errors.
    private func startRateLimitCountdown(seconds: Int) {
        countdownTask?.cancel()
        errorState.rateLimitCountdown = seconds

        countdownTask = Task { [weak self] in
            for remaining in stride(from: seconds - 1, through: 0, by: -1) {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.errorState.rateLimitCountdown = remaining
                }
            }
            await MainActor.run {
                self?.errorState.rateLimitCountdown = nil
            }
        }
    }
}
