import Foundation
import Testing
@testable import SayItRight

// MARK: - Error Classification Tests

@Suite("NetworkErrorClassifier")
struct NetworkErrorClassifierTests {

    @Test("Classifies missing API key as invalidAPIKey")
    func classifyMissingAPIKey() {
        let result = NetworkErrorClassifier.classify(AnthropicServiceError.missingAPIKey)
        #expect(result == .invalidAPIKey)
    }

    @Test("Classifies invalid API key as invalidAPIKey")
    func classifyInvalidAPIKey() {
        let result = NetworkErrorClassifier.classify(AnthropicServiceError.invalidAPIKey)
        #expect(result == .invalidAPIKey)
    }

    @Test("Classifies rate limited with retry-after as rateLimited")
    func classifyRateLimitedWithRetry() {
        let result = NetworkErrorClassifier.classify(
            AnthropicServiceError.rateLimited(retryAfter: "30")
        )
        #expect(result == .rateLimited(retryAfterSeconds: 30))
    }

    @Test("Classifies rate limited without retry-after")
    func classifyRateLimitedNoRetry() {
        let result = NetworkErrorClassifier.classify(
            AnthropicServiceError.rateLimited(retryAfter: nil)
        )
        #expect(result == .rateLimited(retryAfterSeconds: nil))
    }

    @Test("Classifies server error (500) as serverError")
    func classifyServerError500() {
        let result = NetworkErrorClassifier.classify(
            AnthropicServiceError.serverError(statusCode: 500, message: "Internal")
        )
        #expect(result == .serverError(statusCode: 500))
    }

    @Test("Classifies server error (503) as serverError")
    func classifyServerError503() {
        let result = NetworkErrorClassifier.classify(
            AnthropicServiceError.serverError(statusCode: 503, message: "Unavailable")
        )
        #expect(result == .serverError(statusCode: 503))
    }

    @Test("Classifies network timeout as requestTimeout")
    func classifyNetworkTimeout() {
        let result = NetworkErrorClassifier.classify(AnthropicServiceError.networkTimeout)
        #expect(result == .requestTimeout)
    }

    @Test("Classifies streaming error as streamingInterrupted")
    func classifyStreamingError() {
        let result = NetworkErrorClassifier.classify(
            AnthropicServiceError.streamingError("Connection reset")
        )
        #expect(result == .streamingInterrupted)
    }

    @Test("Classifies unexpected 401 response as invalidAPIKey")
    func classifyUnexpected401() {
        let result = NetworkErrorClassifier.classify(
            AnthropicServiceError.unexpectedResponse(statusCode: 401)
        )
        #expect(result == .invalidAPIKey)
    }

    @Test("Classifies unexpected non-401 response as unknown")
    func classifyUnexpected418() {
        let result = NetworkErrorClassifier.classify(
            AnthropicServiceError.unexpectedResponse(statusCode: 418)
        )
        if case .unknown = result {
            // Expected
        } else {
            Issue.record("Expected .unknown, got \(result)")
        }
    }

    @Test("Classifies decoding error as unknown")
    func classifyDecodingError() {
        let result = NetworkErrorClassifier.classify(
            AnthropicServiceError.decodingError("bad JSON")
        )
        if case .unknown(let detail) = result {
            #expect(detail.contains("Decoding"))
        } else {
            Issue.record("Expected .unknown, got \(result)")
        }
    }

    @Test("Classifies URLError.notConnectedToInternet as noConnection")
    func classifyNotConnected() {
        let urlError = URLError(.notConnectedToInternet)
        let result = NetworkErrorClassifier.classify(urlError)
        #expect(result == .noConnection)
    }

    @Test("Classifies URLError.networkConnectionLost as noConnection")
    func classifyConnectionLost() {
        let urlError = URLError(.networkConnectionLost)
        let result = NetworkErrorClassifier.classify(urlError)
        #expect(result == .noConnection)
    }

    @Test("Classifies URLError.timedOut as requestTimeout")
    func classifyURLTimeout() {
        let urlError = URLError(.timedOut)
        let result = NetworkErrorClassifier.classify(urlError)
        #expect(result == .requestTimeout)
    }

    @Test("Classifies URLError.cancelled as streamingInterrupted")
    func classifyCancelled() {
        let urlError = URLError(.cancelled)
        let result = NetworkErrorClassifier.classify(urlError)
        #expect(result == .streamingInterrupted)
    }

    @Test("Classifies unknown Error type as unknown")
    func classifyGenericError() {
        struct SomeError: Error {}
        let result = NetworkErrorClassifier.classify(SomeError())
        if case .unknown = result {
            // Expected
        } else {
            Issue.record("Expected .unknown, got \(result)")
        }
    }
}

// MARK: - NetworkError Property Tests

@Suite("NetworkError Properties")
struct NetworkErrorPropertyTests {

    @Test("noConnection is retryable")
    func noConnectionRetryable() {
        #expect(NetworkError.noConnection.isRetryable == true)
    }

    @Test("serverError is retryable")
    func serverErrorRetryable() {
        #expect(NetworkError.serverError(statusCode: 500).isRetryable == true)
    }

    @Test("requestTimeout is retryable")
    func timeoutRetryable() {
        #expect(NetworkError.requestTimeout.isRetryable == true)
    }

    @Test("streamingInterrupted is retryable")
    func streamingRetryable() {
        #expect(NetworkError.streamingInterrupted.isRetryable == true)
    }

    @Test("invalidAPIKey is NOT retryable")
    func invalidKeyNotRetryable() {
        #expect(NetworkError.invalidAPIKey.isRetryable == false)
    }

    @Test("rateLimited is NOT retryable")
    func rateLimitedNotRetryable() {
        #expect(NetworkError.rateLimited(retryAfterSeconds: 30).isRetryable == false)
    }

    @Test("unknown is NOT retryable")
    func unknownNotRetryable() {
        #expect(NetworkError.unknown("oops").isRetryable == false)
    }

    @Test("invalidAPIKey requires settings redirect")
    func invalidKeyRequiresSettings() {
        #expect(NetworkError.invalidAPIKey.requiresSettingsRedirect == true)
    }

    @Test("noConnection does NOT require settings redirect")
    func noConnectionNoSettings() {
        #expect(NetworkError.noConnection.requiresSettingsRedirect == false)
    }

    @Test("rateLimited retryAfterSeconds returns value")
    func rateLimitRetryAfter() {
        let error = NetworkError.rateLimited(retryAfterSeconds: 42)
        #expect(error.retryAfterSeconds == 42)
    }

    @Test("noConnection retryAfterSeconds returns nil")
    func noConnectionRetryAfter() {
        #expect(NetworkError.noConnection.retryAfterSeconds == nil)
    }
}

// MARK: - Barbara Message Tests

@Suite("NetworkError Barbara Messages")
struct NetworkErrorBarbaraMessageTests {

    @Test("English messages are non-empty for all error types")
    func englishMessages() {
        let errors: [NetworkError] = [
            .noConnection,
            .invalidAPIKey,
            .rateLimited(retryAfterSeconds: 30),
            .rateLimited(retryAfterSeconds: nil),
            .serverError(statusCode: 500),
            .requestTimeout,
            .streamingInterrupted,
            .unknown("test"),
        ]
        for error in errors {
            let message = error.barbaraMessage(language: "en")
            #expect(!message.isEmpty, "English message should not be empty for \(error)")
        }
    }

    @Test("German messages are non-empty for all error types")
    func germanMessages() {
        let errors: [NetworkError] = [
            .noConnection,
            .invalidAPIKey,
            .rateLimited(retryAfterSeconds: 30),
            .rateLimited(retryAfterSeconds: nil),
            .serverError(statusCode: 500),
            .requestTimeout,
            .streamingInterrupted,
            .unknown("test"),
        ]
        for error in errors {
            let message = error.barbaraMessage(language: "de")
            #expect(!message.isEmpty, "German message should not be empty for \(error)")
        }
    }

    @Test("Rate limit message includes wait time")
    func rateLimitIncludesTime() {
        let error = NetworkError.rateLimited(retryAfterSeconds: 30)
        let en = error.barbaraMessage(language: "en")
        let de = error.barbaraMessage(language: "de")
        #expect(en.contains("30"))
        #expect(de.contains("30"))
    }

    @Test("Unknown error includes detail string")
    func unknownIncludesDetail() {
        let error = NetworkError.unknown("custom detail")
        let message = error.barbaraMessage(language: "en")
        #expect(message.contains("custom detail"))
    }
}

// MARK: - RetryPolicy Tests

/// Thread-safe counter for use in async test closures.
private final class AtomicCounter: @unchecked Sendable {
    private var _value: Int
    private let lock = NSLock()

    init(_ initial: Int = 0) { _value = initial }

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    @discardableResult
    func increment() -> Int {
        lock.lock()
        defer { lock.unlock() }
        _value += 1
        return _value
    }
}

@Suite("RetryPolicy")
struct RetryPolicyTests {

    @Test("Standard policy has 3 max retries")
    func standardMaxRetries() {
        #expect(RetryPolicy.standard.maxRetries == 3)
    }

    @Test("Standard policy base delay is 1 second")
    func standardBaseDelay() {
        #expect(RetryPolicy.standard.baseDelay == 1.0)
    }

    @Test("Delay doubles each attempt: 1s, 2s, 4s")
    func exponentialBackoff() {
        let policy = RetryPolicy.standard
        #expect(policy.delay(forAttempt: 0) == 1.0)
        #expect(policy.delay(forAttempt: 1) == 2.0)
        #expect(policy.delay(forAttempt: 2) == 4.0)
    }

    @Test("Succeeds on first try without retry")
    func successFirstTry() async throws {
        let policy = RetryPolicy(maxRetries: 3, baseDelay: 0.01)
        let counter = AtomicCounter()

        let result = try await policy.execute(operation: {
            counter.increment()
            return "success"
        })

        #expect(result == "success")
        #expect(counter.value == 1)
    }

    @Test("Non-retryable errors fail immediately")
    func nonRetryableFailsImmediately() async {
        let policy = RetryPolicy(maxRetries: 3, baseDelay: 0.01)
        let counter = AtomicCounter()

        do {
            _ = try await policy.execute(operation: {
                counter.increment()
                throw AnthropicServiceError.invalidAPIKey
            })
            Issue.record("Should have thrown")
        } catch {
            #expect(counter.value == 1)
            let classified = NetworkErrorClassifier.classify(error)
            #expect(classified == .invalidAPIKey)
        }
    }

    @Test("Retryable errors are retried up to maxRetries")
    func retriesTransientErrors() async {
        let policy = RetryPolicy(maxRetries: 3, baseDelay: 0.01)
        let counter = AtomicCounter()

        do {
            let _: String = try await policy.execute(operation: {
                counter.increment()
                throw AnthropicServiceError.networkTimeout
            })
            Issue.record("Should have thrown")
        } catch {
            // Initial attempt + 3 retries = 4 total
            #expect(counter.value == 4)
        }
    }

    @Test("Succeeds after transient failures")
    func succeedsAfterRetries() async throws {
        let policy = RetryPolicy(maxRetries: 3, baseDelay: 0.01)
        let counter = AtomicCounter()

        let result = try await policy.execute(operation: {
            let current = counter.increment()
            if current < 3 {
                throw AnthropicServiceError.networkTimeout
            }
            return "recovered"
        })

        #expect(result == "recovered")
        #expect(counter.value == 3)
    }

    @Test("onRetry callback is called with correct attempt number")
    func onRetryCallback() async {
        let policy = RetryPolicy(maxRetries: 2, baseDelay: 0.01)
        let retryCounter = AtomicCounter()

        do {
            let _: String = try await policy.execute(
                operation: {
                    throw AnthropicServiceError.networkTimeout
                },
                onRetry: { _, _ in
                    retryCounter.increment()
                }
            )
        } catch {
            // Expected
        }

        #expect(retryCounter.value == 2)
    }
}

// MARK: - ChatErrorState Tests

@Suite("ChatErrorState")
struct ChatErrorStateTests {

    @Test("Initial state shows no error")
    @MainActor
    func initialState() {
        let state = ChatErrorState()
        #expect(state.error == nil)
        #expect(state.isShowingError == false)
        #expect(state.retryCount == 0)
        #expect(state.isRetrying == false)
        #expect(state.rateLimitCountdown == nil)
        #expect(state.hasPartialResponse == false)
    }

    @Test("Clear resets all fields")
    @MainActor
    func clearResetsAll() {
        var state = ChatErrorState()
        state.error = .noConnection
        state.retryCount = 2
        state.isRetrying = true
        state.rateLimitCountdown = 10
        state.hasPartialResponse = true

        state.clear()

        #expect(state.error == nil)
        #expect(state.isShowingError == false)
        #expect(state.retryCount == 0)
        #expect(state.isRetrying == false)
        #expect(state.rateLimitCountdown == nil)
        #expect(state.hasPartialResponse == false)
    }

    @Test("isShowingError is true when error is set")
    @MainActor
    func isShowingErrorWhenSet() {
        var state = ChatErrorState()
        state.error = .requestTimeout
        #expect(state.isShowingError == true)
    }
}
