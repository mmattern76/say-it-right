import Foundation

// MARK: - NetworkError

/// Classifies all network and API errors into actionable categories.
///
/// Each case carries enough context for the UI to show a helpful,
/// in-character message and decide whether to retry automatically.
enum NetworkError: Error, Sendable, Equatable {
    /// Device has no internet connection.
    case noConnection
    /// API key is missing or invalid (HTTP 401).
    case invalidAPIKey
    /// Rate limited by Anthropic (HTTP 429). Includes retry-after seconds if available.
    case rateLimited(retryAfterSeconds: Int?)
    /// Anthropic server error (HTTP 500+). Retryable.
    case serverError(statusCode: Int)
    /// Request timed out before a response arrived.
    case requestTimeout
    /// Streaming was interrupted after partial data was received.
    case streamingInterrupted
    /// An unexpected or unclassifiable error.
    case unknown(String)

    /// Whether this error is transient and can be retried automatically.
    var isRetryable: Bool {
        switch self {
        case .noConnection, .serverError, .requestTimeout, .streamingInterrupted:
            true
        case .invalidAPIKey, .rateLimited, .unknown:
            false
        }
    }

    /// Whether this error should redirect the user to the settings screen.
    var requiresSettingsRedirect: Bool {
        switch self {
        case .invalidAPIKey:
            true
        default:
            false
        }
    }

    /// Barbara-style error message in the configured language.
    func barbaraMessage(language: String) -> String {
        switch self {
        case .noConnection:
            language == "de"
                ? "Keine Verbindung. Auch Lehrerinnen brauchen Internet. Prufe deine Verbindung und versuch's nochmal."
                : "No connection. Even teachers need the internet. Check your connection and try again."
        case .invalidAPIKey:
            language == "de"
                ? "Da stimmt etwas mit dem Schlussel nicht. Ab in die Einstellungen und prufe den API-Key."
                : "Something's wrong with your key. Head to settings and check the API key."
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                language == "de"
                    ? "Auch Lehrerinnen brauchen mal eine Pause. Versuch's in \(seconds) Sekunden nochmal."
                    : "Even teachers need a break sometimes. Try again in \(seconds) seconds."
            } else {
                language == "de"
                    ? "Zu viele Anfragen. Warte einen Moment und versuch's dann nochmal."
                    : "Too many requests. Wait a moment and try again."
            }
        case .serverError:
            language == "de"
                ? "Der Server hat gerade Probleme. Ich versuch's gleich nochmal."
                : "The server is having trouble. I'll try again shortly."
        case .requestTimeout:
            language == "de"
                ? "Das hat zu lange gedauert. Prufe deine Verbindung und versuch's nochmal."
                : "That took too long. Check your connection and try again."
        case .streamingInterrupted:
            language == "de"
                ? "Verbindung unterbrochen. Die bisherige Antwort siehst du oben."
                : "Connection lost. You can see the partial response above."
        case .unknown(let detail):
            language == "de"
                ? "Etwas ist schiefgelaufen: \(detail)"
                : "Something went wrong: \(detail)"
        }
    }

    /// The wait time in seconds for rate-limited errors, if available.
    var retryAfterSeconds: Int? {
        if case .rateLimited(let seconds) = self {
            return seconds
        }
        return nil
    }
}

// MARK: - NetworkErrorClassifier

/// Converts `AnthropicServiceError` and other errors into `NetworkError`.
enum NetworkErrorClassifier {

    /// Classify any error thrown by `AnthropicService` into a `NetworkError`.
    static func classify(_ error: Error) -> NetworkError {
        if let serviceError = error as? AnthropicServiceError {
            return classifyServiceError(serviceError)
        }

        if let urlError = error as? URLError {
            return classifyURLError(urlError)
        }

        return .unknown(error.localizedDescription)
    }

    private static func classifyServiceError(_ error: AnthropicServiceError) -> NetworkError {
        switch error {
        case .missingAPIKey, .invalidAPIKey:
            return .invalidAPIKey
        case .rateLimited(let retryAfter):
            let seconds = retryAfter.flatMap { Int($0) }
            return .rateLimited(retryAfterSeconds: seconds)
        case .serverError(let statusCode, _):
            return .serverError(statusCode: statusCode)
        case .networkTimeout:
            return .requestTimeout
        case .streamingError:
            return .streamingInterrupted
        case .invalidURL:
            return .unknown("Invalid API endpoint URL")
        case .unexpectedResponse(let code):
            if code == 401 {
                return .invalidAPIKey
            }
            return .unknown("Unexpected response (HTTP \(code))")
        case .decodingError(let detail):
            return .unknown("Decoding error: \(detail)")
        }
    }

    private static func classifyURLError(_ error: URLError) -> NetworkError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            return .noConnection
        case .timedOut:
            return .requestTimeout
        case .cancelled:
            return .streamingInterrupted
        default:
            return .unknown(error.localizedDescription)
        }
    }
}

// MARK: - RetryPolicy

/// Exponential backoff retry policy for transient network errors.
///
/// Delays: 1s, 2s, 4s — then gives up.
struct RetryPolicy: Sendable {

    /// Maximum number of retry attempts.
    let maxRetries: Int

    /// Base delay in seconds. Each retry doubles this.
    let baseDelay: TimeInterval

    /// Default policy: 3 retries with 1s base delay (1s, 2s, 4s).
    static let standard = RetryPolicy(maxRetries: 3, baseDelay: 1.0)

    /// Calculate the delay for a given attempt (0-indexed).
    func delay(forAttempt attempt: Int) -> TimeInterval {
        baseDelay * pow(2.0, Double(attempt))
    }

    /// Execute an async throwing closure with automatic retry on transient errors.
    ///
    /// - Parameters:
    ///   - operation: The async operation to attempt.
    ///   - onRetry: Optional callback invoked before each retry with the attempt number and delay.
    /// - Returns: The result of the successful operation.
    /// - Throws: The last error if all retries are exhausted, or a non-retryable error immediately.
    func execute<T: Sendable>(
        operation: @Sendable () async throws -> T,
        onRetry: (@Sendable (Int, TimeInterval) async -> Void)? = nil
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0...maxRetries {
            do {
                return try await operation()
            } catch {
                let classified = NetworkErrorClassifier.classify(error)
                lastError = error

                // Non-retryable errors fail immediately
                guard classified.isRetryable else {
                    throw error
                }

                // Last attempt — don't retry
                if attempt == maxRetries {
                    break
                }

                let delaySeconds = delay(forAttempt: attempt)
                await onRetry?(attempt + 1, delaySeconds)

                try await Task.sleep(for: .seconds(delaySeconds))

                // Check for cancellation between retries
                try Task.checkCancellation()
            }
        }

        throw lastError ?? NetworkError.unknown("All retries exhausted")
    }
}

// MARK: - ChatErrorState

/// Observable error state for the chat UI.
///
/// Tracks the current error, whether the user's input should be preserved,
/// and provides retry/dismiss actions.
@MainActor
struct ChatErrorState: Sendable {
    /// The classified error, if any.
    var error: NetworkError?

    /// Number of retry attempts made so far.
    var retryCount: Int

    /// Whether a retry is currently in progress.
    var isRetrying: Bool

    /// Countdown seconds remaining for rate-limited errors.
    var rateLimitCountdown: Int?

    /// Whether there is a partial response from an interrupted stream.
    var hasPartialResponse: Bool

    /// Whether an error is currently being displayed.
    var isShowingError: Bool { error != nil }

    init(
        error: NetworkError? = nil,
        retryCount: Int = 0,
        isRetrying: Bool = false,
        rateLimitCountdown: Int? = nil,
        hasPartialResponse: Bool = false
    ) {
        self.error = error
        self.retryCount = retryCount
        self.isRetrying = isRetrying
        self.rateLimitCountdown = rateLimitCountdown
        self.hasPartialResponse = hasPartialResponse
    }

    /// Clear the error state.
    mutating func clear() {
        error = nil
        retryCount = 0
        isRetrying = false
        rateLimitCountdown = nil
        hasPartialResponse = false
    }
}
