import Foundation

enum EvaluationError: Error, LocalizedError, Sendable, Equatable {
    case missingMetadata
    case rateLimitExceeded(limit: Int)
    case evaluationTimeout
    case promptAssemblyFailed

    var errorDescription: String? {
        switch self {
        case .missingMetadata:
            "Barbara's evaluation was incomplete — no scoring data received."
        case .rateLimitExceeded(let limit):
            "Session limit reached (\(limit) evaluations). Start a new session to continue."
        case .evaluationTimeout:
            "Evaluation took too long. Try again."
        case .promptAssemblyFailed:
            "Could not assemble the evaluation prompt. Check that prompt blocks are available."
        }
    }
}

actor StructuralEvaluator {
    private let anthropicService: AnthropicService
    private let systemPromptAssembler: SystemPromptAssembler
    private let responseParser: ResponseParser
    private let maxCallsPerSession: Int
    private(set) var callCount: Int = 0
    private var cachedSystemPrompt: String?

    init(
        anthropicService: AnthropicService = .shared,
        systemPromptAssembler: SystemPromptAssembler = SystemPromptAssembler(),
        responseParser: ResponseParser = ResponseParser(),
        maxCallsPerSession: Int = 10
    ) {
        self.anthropicService = anthropicService
        self.systemPromptAssembler = systemPromptAssembler
        self.responseParser = responseParser
        self.maxCallsPerSession = maxCallsPerSession
    }

    func prepareSession(level: Int, sessionType: String, language: String, profile: LearnerProfile) {
        callCount = 0
        let difficultyContext = AdaptiveDifficultyEngine.difficultyContext(for: profile)
        cachedSystemPrompt = systemPromptAssembler.assemble(
            level: level, sessionType: sessionType, language: language,
            profileJSON: profile.toPromptJSON(),
            difficultyContext: difficultyContext
        )
    }

    func evaluate(
        conversationMessages: [APIMessage],
        systemPromptOverride: String? = nil
    ) async throws -> StreamingEvaluation {
        guard callCount < maxCallsPerSession else {
            throw EvaluationError.rateLimitExceeded(limit: maxCallsPerSession)
        }
        let prompt = systemPromptOverride ?? cachedSystemPrompt
        guard let systemPrompt = prompt, !systemPrompt.isEmpty else {
            throw EvaluationError.promptAssemblyFailed
        }
        callCount += 1
        let stream = await anthropicService.sendMessage(systemPrompt: systemPrompt, messages: conversationMessages)
        return StreamingEvaluation(textStream: stream, responseParser: responseParser)
    }

    func reset() { callCount = 0; cachedSystemPrompt = nil }
    var remainingCalls: Int { max(0, maxCallsPerSession - callCount) }
}

struct StreamingEvaluation: Sendable {
    let textStream: AsyncThrowingStream<String, Error>
    private let responseParser: ResponseParser

    init(textStream: AsyncThrowingStream<String, Error>, responseParser: ResponseParser) {
        self.textStream = textStream
        self.responseParser = responseParser
    }

    func collect(onChunk: @Sendable (String) -> Void = { _ in }) async throws -> EvaluationResult {
        var fullText = ""
        for try await chunk in textStream {
            fullText += chunk
            onChunk(chunk)
        }
        let parsed = responseParser.parse(fullResponse: fullText)
        return EvaluationResult(feedbackText: parsed.visibleText, metadata: parsed.metadata)
    }
}
