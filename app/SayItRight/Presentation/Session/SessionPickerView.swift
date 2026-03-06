import SwiftUI

/// Session type selection screen shown before starting a coaching session.
///
/// Displays available session types as tappable cards. On selection,
/// starts a new session via the `SessionManager`.
struct SessionPickerView: View {
    let sessionManager: SessionManager
    let profile: LearnerProfile
    let language: String
    var onSessionStarted: (() -> Void)?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                sessionCards
            }
            .padding(.horizontal, contentPadding)
            .padding(.vertical, 24)
        }
        .frame(maxWidth: maxContentWidth)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Text(language == "de" ? "Was m\u{00F6}chtest du \u{00FC}ben?" : "What would you like to practise?")
                .font(.title2)
                .fontWeight(.bold)

            Text(language == "de" ? "W\u{00E4}hle eine \u{00DC}bung" : "Choose an exercise")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Session Cards

    private var sessionCards: some View {
        VStack(spacing: 16) {
            ForEach(SessionType.allCases) { sessionType in
                SessionCardView(
                    sessionType: sessionType,
                    language: language
                ) {
                    Task {
                        await sessionManager.startSession(
                            type: sessionType,
                            profile: profile,
                            language: language
                        )
                        onSessionStarted?()
                    }
                }
            }
        }
    }

    // MARK: - Layout

    private var maxContentWidth: CGFloat {
        #if os(macOS)
        600
        #else
        horizontalSizeClass == .regular ? 500 : .infinity
        #endif
    }

    private var contentPadding: CGFloat {
        #if os(macOS)
        24
        #else
        horizontalSizeClass == .regular ? 24 : 16
        #endif
    }
}

// MARK: - Session Card

/// A single tappable card representing a session type.
struct SessionCardView: View {
    let sessionType: SessionType
    let language: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: sessionType.iconName)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 44, height: 44)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(sessionType.displayName(language: language))
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(sessionType.subtitle(language: language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("English") {
    SessionPickerView(
        sessionManager: SessionManager(),
        profile: .createDefault(),
        language: "en"
    )
}

#Preview("German") {
    SessionPickerView(
        sessionManager: SessionManager(),
        profile: .createDefault(language: "de"),
        language: "de"
    )
}

#Preview("iPad") {
    SessionPickerView(
        sessionManager: SessionManager(),
        profile: .createDefault(),
        language: "en"
    )
    .environment(\.horizontalSizeClass, .regular)
}

#Preview("Dark Mode") {
    SessionPickerView(
        sessionManager: SessionManager(),
        profile: .createDefault(),
        language: "en"
    )
    .preferredColorScheme(.dark)
}
