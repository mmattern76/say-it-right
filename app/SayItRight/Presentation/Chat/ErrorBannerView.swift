import SwiftUI

/// Non-blocking error banner displayed inline in the chat view.
///
/// Shows Barbara's in-character error message with contextual actions:
/// - **Retry** button for transient errors
/// - **Settings** link for invalid API key
/// - **Countdown** display for rate-limited errors
/// - **Dismiss** button to clear the error
struct ErrorBannerView: View {
    let error: NetworkError
    let language: String
    var retryCount: Int = 0
    var rateLimitCountdown: Int? = nil
    var hasPartialResponse: Bool = false
    var onRetry: (() -> Void)? = nil
    var onOpenSettings: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                errorIcon
                VStack(alignment: .leading, spacing: 4) {
                    Text(error.barbaraMessage(language: language))
                        .font(.callout)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let countdown = rateLimitCountdown, countdown > 0 {
                        countdownLabel(seconds: countdown)
                    }

                    if hasPartialResponse {
                        partialResponseNote
                    }
                }
                Spacer(minLength: 0)
                dismissButton
            }

            actionButtons
        }
        .padding(12)
        .background(bannerBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 12)
    }

    // MARK: - Subviews

    private var errorIcon: some View {
        Image(systemName: iconName)
            .font(.title3)
            .foregroundStyle(iconColor)
            .frame(width: 24)
    }

    private var iconName: String {
        switch error {
        case .noConnection:
            "wifi.slash"
        case .invalidAPIKey:
            "key.fill"
        case .rateLimited:
            "clock.fill"
        case .serverError:
            "exclamationmark.icloud.fill"
        case .requestTimeout:
            "hourglass"
        case .streamingInterrupted:
            "bolt.horizontal.fill"
        case .unknown:
            "exclamationmark.triangle.fill"
        }
    }

    private var iconColor: Color {
        switch error {
        case .invalidAPIKey:
            .red
        case .rateLimited:
            .orange
        default:
            .yellow
        }
    }

    private func countdownLabel(seconds: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
                .font(.caption)
            Text(language == "de" ? "\(seconds)s warten..." : "\(seconds)s remaining...")
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }

    private var partialResponseNote: some View {
        HStack(spacing: 4) {
            Image(systemName: "text.badge.checkmark")
                .font(.caption)
            Text(language == "de"
                 ? "Teilweise Antwort wird angezeigt."
                 : "Partial response shown above.")
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }

    private var dismissButton: some View {
        Button(action: { onDismiss?() }) {
            Image(systemName: "xmark")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(language == "de" ? "Schliessen" : "Dismiss")
    }

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 12) {
            if error.isRetryable {
                retryButton
            }

            if error.requiresSettingsRedirect {
                settingsButton
            }
        }
    }

    private var retryButton: some View {
        Button(action: { onRetry?() }) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.clockwise")
                    .font(.caption.weight(.semibold))
                Text(language == "de" ? "Nochmal versuchen" : "Retry")
                    .font(.callout.weight(.medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(language == "de" ? "Nochmal versuchen" : "Retry")
    }

    private var settingsButton: some View {
        Button(action: { onOpenSettings?() }) {
            HStack(spacing: 4) {
                Image(systemName: "gearshape")
                    .font(.caption.weight(.semibold))
                Text(language == "de" ? "Einstellungen" : "Settings")
                    .font(.callout.weight(.medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.red, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(language == "de" ? "Einstellungen offnen" : "Open Settings")
    }

    private var bannerBackground: Color {
        colorScheme == .dark
            ? Color.orange.opacity(0.15)
            : Color.orange.opacity(0.08)
    }
}

// MARK: - Previews

#Preview("No Connection") {
    ErrorBannerView(
        error: .noConnection,
        language: "en",
        onRetry: {},
        onDismiss: {}
    )
    .padding()
}

#Preview("No Connection — German") {
    ErrorBannerView(
        error: .noConnection,
        language: "de",
        onRetry: {},
        onDismiss: {}
    )
    .padding()
}

#Preview("Invalid API Key") {
    ErrorBannerView(
        error: .invalidAPIKey,
        language: "en",
        onOpenSettings: {},
        onDismiss: {}
    )
    .padding()
}

#Preview("Rate Limited — With Countdown") {
    ErrorBannerView(
        error: .rateLimited(retryAfterSeconds: 30),
        language: "en",
        rateLimitCountdown: 25,
        onDismiss: {}
    )
    .padding()
}

#Preview("Server Error") {
    ErrorBannerView(
        error: .serverError(statusCode: 500),
        language: "en",
        onRetry: {},
        onDismiss: {}
    )
    .padding()
}

#Preview("Streaming Interrupted — Partial Response") {
    ErrorBannerView(
        error: .streamingInterrupted,
        language: "en",
        hasPartialResponse: true,
        onRetry: {},
        onDismiss: {}
    )
    .padding()
}

#Preview("Dark Mode — No Connection") {
    ErrorBannerView(
        error: .noConnection,
        language: "en",
        onRetry: {},
        onDismiss: {}
    )
    .padding()
    .preferredColorScheme(.dark)
}
