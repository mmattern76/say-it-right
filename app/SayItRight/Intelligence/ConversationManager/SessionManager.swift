import Foundation

/// Central coordinator for coaching sessions.
///
/// `SessionManager` orchestrates the full session lifecycle: starting a session
/// (assembling the system prompt and requesting Barbara's greeting), sending
/// learner messages and streaming Barbara's responses, managing context window
/// limits, and ending sessions with a summary.
///
/// It owns the conversation state and wires together `AnthropicService`,
/// `SystemPromptAssembler`, and `ResponseParser`.
@MainActor
@Observable
final class SessionManager {

    // MARK: - Observable State

    /// All messages in the current session.
    private(set) var messages: [ChatMessage] = []

    /// Current session lifecycle state.
    private(set) var sessionState: SessionState = .idle

    /// Metadata collected from Barbara's responses during this session.
    private(set) var sessionMetadata: [BarbaraMetadata] = []

    /// The active session type, if any.
    private(set) var activeSessionType: SessionType?

    /// The active "Say it clearly" session state, if any.
    private(set) var sayItClearlySession: SayItClearlySession?


    /// The active "Find the point" session state, if any.
    private(set) var findThePointSession: FindThePointSession?

    /// The latest evaluation result from the structural evaluator.
    private(set) var lastEvaluationResult: EvaluationResult?

    // MARK: - Dependencies

    private let anthropicService: AnthropicService
    private let systemPromptAssembler: SystemPromptAssembler
    private let responseParser: ResponseParser
    let structuralEvaluator: StructuralEvaluator

    // MARK: - Configuration

    /// Maximum number of messages before older ones are summarized.
    static let contextWindowThreshold = 50

    /// The assembled system prompt for the current session.
    private var systemPrompt: String = ""

    // MARK: - Init

    init(
        anthropicService: AnthropicService = .shared,
        systemPromptAssembler: SystemPromptAssembler = SystemPromptAssembler(),
        responseParser: ResponseParser = ResponseParser(),
        structuralEvaluator: StructuralEvaluator = StructuralEvaluator()
    ) {
        self.anthropicService = anthropicService
        self.systemPromptAssembler = systemPromptAssembler
        self.responseParser = responseParser
        self.structuralEvaluator = structuralEvaluator
    }

    // MARK: - Public API

    /// Start a new coaching session.
    ///
    /// Assembles the system prompt from the learner profile and session type,
    /// then sends a greeting request to Barbara so she opens the conversation.
    ///
    /// - Parameters:
    ///   - type: The session type to start.
    ///   - profile: The learner's current profile.
    ///   - language: Language code ("en" or "de").
    func startSession(type: SessionType, profile: LearnerProfile, language: String) async {
        // Reset any previous session state
        messages = []
        sessionMetadata = []
        activeSessionType = type
        sayItClearlySession = nil
        findThePointSession = nil

        lastEvaluationResult = nil
        sessionState = .loading

        // Assemble system prompt
        systemPrompt = systemPromptAssembler.assemble(
            level: profile.currentLevel,
            sessionType: type.rawValue,
            language: language,
            profileJSON: profile.toPromptJSON()
        )

        // Prepare the structural evaluator with cached prompt for this session
        await structuralEvaluator.prepareSession(
            level: profile.currentLevel,
            sessionType: type.rawValue,
            language: language,
            profile: profile
        )

        // Request Barbara's greeting
        await streamBarbaraResponse()
    }

    /// Start a "Say it clearly" session with a specific topic.
    ///
    /// Assembles the system prompt and injects the topic prompt so Barbara
    /// greets the learner with the topic question.
    ///
    /// - Parameters:
    ///   - topic: The topic selected from the topic bank.
    ///   - profile: The learner's current profile.
    ///   - language: Language code ("en" or "de").
    func startSayItClearlySession(topic: Topic, profile: LearnerProfile, language: String) async {
        // Reset any previous session state
        messages = []
        sessionMetadata = []
        activeSessionType = .sayItClearly
        sayItClearlySession = SayItClearlySession(topic: topic)
        findThePointSession = nil

        lastEvaluationResult = nil
        sessionState = .loading

        // Assemble system prompt with topic directive appended
        let basePrompt = systemPromptAssembler.assemble(
            level: profile.currentLevel,
            sessionType: SessionType.sayItClearly.rawValue,
            language: language,
            profileJSON: profile.toPromptJSON()
        )

        let topicDirective = topicDirectiveBlock(topic: topic, language: language)
        systemPrompt = basePrompt + "\n\n" + topicDirective

        // Prepare the structural evaluator for this session
        await structuralEvaluator.prepareSession(
            level: profile.currentLevel,
            sessionType: SessionType.sayItClearly.rawValue,
            language: language,
            profile: profile
        )

        // Request Barbara's greeting (she will present the topic)
        await streamBarbaraResponse()
    }

    /// Start a "Find the point" session with a specific practice text.
    ///
    /// Assembles the system prompt and injects the practice text and answer key
    /// so Barbara presents the text and evaluates the learner's extraction.
    ///
    /// - Parameters:
    ///   - practiceText: The practice text selected from the library.
    ///   - profile: The learner's current profile.
    ///   - language: Language code ("en" or "de").
    func startFindThePointSession(
        practiceText: PracticeText,
        profile: LearnerProfile,
        language: String
    ) async {
        // Reset any previous session state
        messages = []
        sessionMetadata = []
        activeSessionType = .findThePoint
        sayItClearlySession = nil
        findThePointSession = FindThePointSession(practiceText: practiceText)

        sessionState = .loading

        // Assemble system prompt with practice text directive appended
        let basePrompt = systemPromptAssembler.assemble(
            level: profile.currentLevel,
            sessionType: SessionType.findThePoint.rawValue,
            language: language,
            profileJSON: profile.toPromptJSON()
        )

        let textDirective = practiceTextDirectiveBlock(
            practiceText: practiceText,
            language: language
        )
        systemPrompt = basePrompt + "\n\n" + textDirective

        // Request Barbara's greeting (she will present the text)
        await streamBarbaraResponse()
    }

    /// Build the topic directive block injected into the system prompt.
    private func topicDirectiveBlock(topic: Topic, language: String) -> String {
        let title = topic.title(for: language)
        let prompt = topic.prompt(for: language)
        return """
        # Topic for This Session

        Present this topic to the learner. Use the prompt text below as Barbara's \
        question. Do not invent a different topic.

        **Topic:** \(title)
        **Prompt:** \(prompt)
        """
    }

    /// Build the practice text directive block injected into the system prompt
    /// for "Find the point" sessions.
    private func practiceTextDirectiveBlock(
        practiceText: PracticeText,
        language: String
    ) -> String {
        let qualityNote: String
        switch practiceText.metadata.qualityLevel {
        case .wellStructured:
            qualityNote = "This text is well-structured. The governing thought should be identifiable."
        case .buriedLead:
            qualityNote = "This text has a buried lead. The governing thought is hidden deeper in the text."
        case .rambling:
            qualityNote = "This text is rambling. The learner may correctly identify that there is no clear governing thought."
        case .adversarial:
            qualityNote = "This text appears structured but contains a hidden structural flaw."
        }

        return """
        # Practice Text for This Session

        Present this text to the learner. Ask them to identify the governing thought \
        in one sentence. Do NOT reveal the answer key.

        \(qualityNote)

        **Text:**
        \(practiceText.text)

        **Answer Key (HIDDEN — do not reveal):**
        Governing Thought: \(practiceText.answerKey.governingThought)
        Structural Assessment: \(practiceText.answerKey.structuralAssessment)
        """
    }

    /// Send a learner message and stream Barbara's response.
    ///
    /// - Parameter text: The learner's message text.
    func sendMessage(text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard sessionState == .active else { return }

        // Add the learner message
        let learnerMessage = ChatMessage(role: .learner, text: trimmed)
        messages.append(learnerMessage)

        // Track first response in "Say it clearly" session
        if sayItClearlySession != nil && !sayItClearlySession!.hasResponse {
            sayItClearlySession?.recordResponse(trimmed)
        }

        // Track extraction attempts in "Find the point" session
        if findThePointSession != nil && !findThePointSession!.hasUsedRetry {
            findThePointSession?.recordAttempt(trimmed)
        }

        // Check context window limits
        if messages.count > Self.contextWindowThreshold {
            summarizeOlderMessages()
        }

        // Stream Barbara's response
        await streamBarbaraResponse()
    }

    /// End the current session.
    ///
    /// Clears conversation state and returns to idle. The session summary
    /// (last metadata) remains accessible until a new session starts.
    func endSession() {
        activeSessionType = nil
        sayItClearlySession = nil

        findThePointSession = nil
 
        lastEvaluationResult = nil
        sessionState = .idle
        messages = []
        systemPrompt = ""
        // sessionMetadata is preserved until next startSession
        Task { await structuralEvaluator.reset() }
    }

    /// The number of remaining evaluation calls in this session.
    var remainingEvaluations: Int {
        get async { await structuralEvaluator.remainingCalls }
    }

    /// The number of evaluation calls made in this session.
    var evaluationCallCount: Int {
        get async { await structuralEvaluator.callCount }
    }

    // MARK: - Private: Streaming

    private func streamBarbaraResponse() async {
        sessionState = .loading

        // Create a placeholder streaming message
        let streamingMessage = ChatMessage(
            role: .barbara,
            text: "",
            isStreaming: true
        )
        messages.append(streamingMessage)
        let streamingIndex = messages.count - 1

        do {
            // Build API messages from conversation history (exclude empty streaming placeholder)
            let apiMessages = messages
                .filter { !$0.text.isEmpty }
                .map { message in
                    APIMessage(
                        role: message.role == .barbara ? "assistant" : "user",
                        content: message.text
                    )
                }

            // Stream response from Anthropic
            let stream = await anthropicService.sendMessage(
                systemPrompt: systemPrompt,
                messages: apiMessages
            )

            var fullText = ""
            for try await chunk in stream {
                fullText += chunk
                messages[streamingIndex].text = fullText
            }

            // Parse the complete response for hidden metadata
            let parsed = responseParser.parse(fullResponse: fullText)
            messages[streamingIndex].text = parsed.visibleText
            messages[streamingIndex].isStreaming = false

            if let metadata = parsed.metadata {
                messages[streamingIndex].metadata = metadata
                sessionMetadata.append(metadata)

                // Capture evaluation result when the response contains scores
                if !metadata.scores.isEmpty {
                    lastEvaluationResult = EvaluationResult(
                        feedbackText: parsed.visibleText,
                        metadata: metadata
                    )
                }
            }

            sessionState = .active

        } catch {
            // Remove the empty streaming message on error
            if messages[streamingIndex].text.isEmpty {
                messages.remove(at: streamingIndex)
            } else {
                messages[streamingIndex].isStreaming = false
            }
            sessionState = .error(error.localizedDescription)
        }
    }

    // MARK: - Private: Context Window Management

    /// Summarize older messages when the conversation exceeds the threshold.
    ///
    /// Keeps the first message (Barbara's greeting) and the most recent messages,
    /// replacing the middle portion with a summary message.
    private func summarizeOlderMessages() {
        let keepRecentCount = 20
        let keepFromStart = 1 // Keep Barbara's greeting

        guard messages.count > keepFromStart + keepRecentCount else { return }

        let startMessages = Array(messages.prefix(keepFromStart))
        let middleMessages = Array(messages.dropFirst(keepFromStart).dropLast(keepRecentCount))
        let recentMessages = Array(messages.suffix(keepRecentCount))

        // Build a text summary of the middle messages
        let summaryLines = middleMessages.map { msg in
            let role = msg.role == .barbara ? "Barbara" : "Learner"
            let truncated = String(msg.text.prefix(200))
            return "[\(role)] \(truncated)"
        }

        let summaryText = "[Session context summary — \(middleMessages.count) earlier messages condensed]\n\n"
            + summaryLines.joined(separator: "\n")

        let summaryMessage = ChatMessage(
            role: .barbara,
            text: summaryText
        )

        messages = startMessages + [summaryMessage] + recentMessages
    }
}
