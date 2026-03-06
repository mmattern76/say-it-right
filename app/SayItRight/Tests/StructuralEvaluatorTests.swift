import Testing
@testable import SayItRight

// MARK: - EvaluationResult Tests

@Suite("EvaluationResult")
struct EvaluationResultTests {

    private static func sampleMetadata(
        scores: [String: Int] = ["governingThought": 3, "supportGrouping": 2, "redundancy": 1, "clarity": 3],
        totalScore: Int = 9,
        mood: BarbaraMood = .evaluating,
        progressionSignal: ProgressionSignal = .improving
    ) -> BarbaraMetadata {
        BarbaraMetadata(
            scores: scores,
            totalScore: totalScore,
            mood: mood,
            progressionSignal: progressionSignal,
            revisionRound: 1,
            sessionPhase: .evaluation,
            feedbackFocus: "Your conclusion is strong but buried.",
            language: "en"
        )
    }

    @Test("dimensionScores returns scores from metadata")
    func dimensionScores() {
        let result = EvaluationResult(
            feedbackText: "Good work.",
            metadata: Self.sampleMetadata()
        )
        #expect(result.dimensionScores["governingThought"] == 3)
        #expect(result.dimensionScores["supportGrouping"] == 2)
        #expect(result.dimensionScores["redundancy"] == 1)
        #expect(result.dimensionScores["clarity"] == 3)
    }

    @Test("dimensionScores returns empty dict when metadata is nil")
    func dimensionScoresNilMetadata() {
        let result = EvaluationResult(feedbackText: "No scores.", metadata: nil)
        #expect(result.dimensionScores.isEmpty)
    }

    @Test("totalScore returns value from metadata")
    func totalScore() {
        let result = EvaluationResult(
            feedbackText: "Feedback",
            metadata: Self.sampleMetadata(totalScore: 9)
        )
        #expect(result.totalScore == 9)
    }

    @Test("totalScore returns 0 when metadata is nil")
    func totalScoreNilMetadata() {
        let result = EvaluationResult(feedbackText: "No meta.", metadata: nil)
        #expect(result.totalScore == 0)
    }

    @Test("hasScores is true when metadata has scores")
    func hasScoresTrue() {
        let result = EvaluationResult(
            feedbackText: "Feedback",
            metadata: Self.sampleMetadata()
        )
        #expect(result.hasScores)
    }

    @Test("hasScores is false when metadata is nil")
    func hasScoresFalseNil() {
        let result = EvaluationResult(feedbackText: "No meta.", metadata: nil)
        #expect(!result.hasScores)
    }

    @Test("hasScores is false when scores dict is empty")
    func hasScoresFalseEmpty() {
        let result = EvaluationResult(
            feedbackText: "Feedback",
            metadata: Self.sampleMetadata(scores: [:], totalScore: 0)
        )
        #expect(!result.hasScores)
    }

    @Test("progressionSignal returns value from metadata")
    func progressionSignal() {
        let result = EvaluationResult(
            feedbackText: "Good progress.",
            metadata: Self.sampleMetadata(progressionSignal: .readyForLevelUp)
        )
        #expect(result.progressionSignal == .readyForLevelUp)
    }

    @Test("progressionSignal defaults to .none when metadata is nil")
    func progressionSignalDefault() {
        let result = EvaluationResult(feedbackText: "No meta.", metadata: nil)
        #expect(result.progressionSignal == .none)
    }

    @Test("mood returns value from metadata")
    func mood() {
        let result = EvaluationResult(
            feedbackText: "Nice!",
            metadata: Self.sampleMetadata(mood: .proud)
        )
        #expect(result.mood == .proud)
    }

    @Test("mood defaults to .evaluating when metadata is nil")
    func moodDefault() {
        let result = EvaluationResult(feedbackText: "No meta.", metadata: nil)
        #expect(result.mood == .evaluating)
    }

    @Test("feedbackFocus returns value from metadata")
    func feedbackFocus() {
        let result = EvaluationResult(
            feedbackText: "Feedback",
            metadata: Self.sampleMetadata()
        )
        #expect(result.feedbackFocus == "Your conclusion is strong but buried.")
    }

    @Test("feedbackFocus returns empty string when metadata is nil")
    func feedbackFocusDefault() {
        let result = EvaluationResult(feedbackText: "No meta.", metadata: nil)
        #expect(result.feedbackFocus.isEmpty)
    }
}

// MARK: - StructuralEvaluator Tests

@Suite("StructuralEvaluator")
struct StructuralEvaluatorTests {

    private static func makeProfile() -> LearnerProfile {
        LearnerProfile.createDefault(displayName: "Test Learner", language: "en")
    }

    @Test("prepareSession resets call count and caches prompt")
    func prepareSessionResets() async {
        let evaluator = StructuralEvaluator(maxCallsPerSession: 5)
        await evaluator.prepareSession(
            level: 1,
            sessionType: "say-it-clearly",
            language: "en",
            profile: Self.makeProfile()
        )

        let count = await evaluator.callCount
        #expect(count == 0)

        let remaining = await evaluator.remainingCalls
        #expect(remaining == 5)
    }

    @Test("remainingCalls is bounded by maxCallsPerSession")
    func remainingCallsBounded() async {
        let evaluator = StructuralEvaluator(maxCallsPerSession: 3)
        let remaining = await evaluator.remainingCalls
        #expect(remaining == 3)
    }

    @Test("reset clears call count")
    func resetClearsState() async {
        let evaluator = StructuralEvaluator(maxCallsPerSession: 10)
        await evaluator.prepareSession(
            level: 1,
            sessionType: "say-it-clearly",
            language: "en",
            profile: Self.makeProfile()
        )
        await evaluator.reset()

        let count = await evaluator.callCount
        #expect(count == 0)
    }

    @Test("evaluate throws promptAssemblyFailed without preparation")
    func evaluateWithoutPreparation() async {
        let evaluator = StructuralEvaluator()
        do {
            _ = try await evaluator.evaluate(conversationMessages: [])
            Issue.record("Expected promptAssemblyFailed error")
        } catch let error as EvaluationError {
            #expect(error == .promptAssemblyFailed)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("evaluate throws rateLimitExceeded when limit reached")
    func evaluateRateLimited() async {
        let evaluator = StructuralEvaluator(maxCallsPerSession: 0)
        await evaluator.prepareSession(
            level: 1,
            sessionType: "say-it-clearly",
            language: "en",
            profile: Self.makeProfile()
        )

        do {
            _ = try await evaluator.evaluate(conversationMessages: [])
            Issue.record("Expected rateLimitExceeded error")
        } catch let error as EvaluationError {
            if case .rateLimitExceeded(let limit) = error {
                #expect(limit == 0)
            } else {
                Issue.record("Expected rateLimitExceeded, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("evaluate accepts systemPromptOverride without preparation")
    func evaluateWithOverride() async throws {
        let evaluator = StructuralEvaluator(maxCallsPerSession: 5)
        let streaming = try await evaluator.evaluate(
            conversationMessages: [],
            systemPromptOverride: "Test system prompt"
        )

        // Verify call count was incremented
        let count = await evaluator.callCount
        #expect(count == 1)

        // StreamingEvaluation was returned
        _ = streaming.textStream
    }
}

// MARK: - EvaluationError Tests

@Suite("EvaluationError")
struct EvaluationErrorTests {

    @Test("missingMetadata has descriptive message")
    func missingMetadataDescription() {
        let error = EvaluationError.missingMetadata
        #expect(error.errorDescription?.contains("incomplete") == true)
    }

    @Test("rateLimitExceeded includes limit in message")
    func rateLimitDescription() {
        let error = EvaluationError.rateLimitExceeded(limit: 10)
        #expect(error.errorDescription?.contains("10") == true)
    }

    @Test("evaluationTimeout has descriptive message")
    func timeoutDescription() {
        let error = EvaluationError.evaluationTimeout
        #expect(error.errorDescription?.contains("long") == true)
    }

    @Test("promptAssemblyFailed has descriptive message")
    func promptAssemblyDescription() {
        let error = EvaluationError.promptAssemblyFailed
        #expect(error.errorDescription?.contains("prompt") == true)
    }

    @Test("EvaluationError equatable")
    func equatable() {
        #expect(EvaluationError.missingMetadata == .missingMetadata)
        #expect(EvaluationError.evaluationTimeout == .evaluationTimeout)
        #expect(EvaluationError.promptAssemblyFailed == .promptAssemblyFailed)
        #expect(EvaluationError.rateLimitExceeded(limit: 5) == .rateLimitExceeded(limit: 5))
        #expect(EvaluationError.rateLimitExceeded(limit: 5) != .rateLimitExceeded(limit: 10))
    }
}

// MARK: - StreamingEvaluation Tests

@Suite("StreamingEvaluation - collect")
struct StreamingEvaluationTests {

    @Test("collect parses response with metadata into EvaluationResult")
    func collectWithMetadata() async throws {
        let visibleText = "Your conclusion leads clearly. Good structure!"
        let metaJSON = """
        {"scores":{"governingThought":3,"clarity":2},"totalScore":5,"mood":"approving","progressionSignal":"improving","revisionRound":1,"sessionPhase":"evaluation","feedbackFocus":"Lead with answer","language":"en"}
        """
        let fullResponse = "\(visibleText)\n\n<!-- BARBARA_META: \(metaJSON) -->"

        let stream = AsyncThrowingStream<String, Error> { continuation in
            continuation.yield(fullResponse)
            continuation.finish()
        }

        let evaluation = StreamingEvaluation(
            textStream: stream,
            responseParser: ResponseParser()
        )

        let result = try await evaluation.collect()

        #expect(result.feedbackText == visibleText)
        #expect(result.hasScores)
        #expect(result.dimensionScores["governingThought"] == 3)
        #expect(result.dimensionScores["clarity"] == 2)
        #expect(result.totalScore == 5)
        #expect(result.mood == .approving)
        #expect(result.progressionSignal == .improving)
    }

    @Test("collect handles response without metadata gracefully")
    func collectWithoutMetadata() async throws {
        let plainText = "That's not a conclusion, that's a preamble."

        let stream = AsyncThrowingStream<String, Error> { continuation in
            continuation.yield(plainText)
            continuation.finish()
        }

        let evaluation = StreamingEvaluation(
            textStream: stream,
            responseParser: ResponseParser()
        )

        let result = try await evaluation.collect()
        #expect(result.feedbackText == plainText)
        #expect(!result.hasScores)
        #expect(result.metadata == nil)
    }

    @Test("collect assembles multiple chunks into complete response")
    func collectMultipleChunks() async throws {
        let metaJSON = """
        {"scores":{"clarity":3},"totalScore":3,"mood":"teaching","progressionSignal":"none","revisionRound":0,"sessionPhase":"evaluation","feedbackFocus":"Structure","language":"en"}
        """

        let stream = AsyncThrowingStream<String, Error> { continuation in
            continuation.yield("Part one. ")
            continuation.yield("Part two.")
            continuation.yield("\n\n<!-- BARBARA_META: \(metaJSON) -->")
            continuation.finish()
        }

        let evaluation = StreamingEvaluation(
            textStream: stream,
            responseParser: ResponseParser()
        )

        let result = try await evaluation.collect()

        #expect(result.feedbackText == "Part one. Part two.")
        #expect(result.hasScores)
        #expect(result.totalScore == 3)
    }

    @Test("collect propagates stream errors")
    func collectPropagatesError() async {
        let stream = AsyncThrowingStream<String, Error> { continuation in
            continuation.yield("Partial text")
            continuation.finish(throwing: AnthropicServiceError.networkTimeout)
        }

        let evaluation = StreamingEvaluation(
            textStream: stream,
            responseParser: ResponseParser()
        )

        do {
            _ = try await evaluation.collect()
            Issue.record("Expected error to propagate")
        } catch {
            #expect(error is AnthropicServiceError)
        }
    }
}

// MARK: - SessionManager Evaluation Integration Tests

@Suite("SessionManager - evaluation integration")
struct SessionManagerEvaluationTests {

    @Test("SessionManager initialises with structural evaluator")
    @MainActor
    func hasEvaluator() {
        let manager = SessionManager()
        #expect(manager.lastEvaluationResult == nil)
    }

    @Test("endSession clears lastEvaluationResult")
    @MainActor
    func endSessionClearsEvaluation() {
        let manager = SessionManager()
        manager.endSession()
        #expect(manager.lastEvaluationResult == nil)
    }

    @Test("SessionManager accepts custom evaluator")
    @MainActor
    func customEvaluator() {
        let evaluator = StructuralEvaluator(maxCallsPerSession: 3)
        let manager = SessionManager(structuralEvaluator: evaluator)
        #expect(manager.lastEvaluationResult == nil)
    }
}
