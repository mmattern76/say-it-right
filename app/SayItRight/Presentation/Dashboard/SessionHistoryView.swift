import SwiftUI

/// Browsable list of past sessions, newest first.
struct SessionHistoryView: View {
    let sessions: [SessionSummary]
    let language: String

    var body: some View {
        Group {
            if sessions.isEmpty {
                emptyState
            } else {
                sessionList
            }
        }
        .navigationTitle(language == "de" ? "Verlauf" : "History")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)

            Text(language == "de"
                ? "Noch kein Verlauf"
                : "No history yet")
                .font(.title3)
                .fontWeight(.semibold)

            Text(language == "de"
                ? "Abgeschlossene Sitzungen erscheinen hier."
                : "Completed sessions will appear here.")
                .font(.body)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Session List

    private var sessionList: some View {
        List {
            ForEach(groupedSessions, id: \.label) { group in
                Section(group.label) {
                    ForEach(group.sessions) { session in
                        NavigationLink {
                            SessionDetailView(session: session, language: language)
                        } label: {
                            SessionHistoryRow(session: session, language: language)
                        }
                    }
                }
            }
        }
        #if os(macOS)
        .listStyle(.inset(alternatesRowBackgrounds: true))
        #else
        .listStyle(.insetGrouped)
        #endif
    }

    // MARK: - Date Grouping

    private struct DateGroup {
        let label: String
        let sessions: [SessionSummary]
    }

    private var groupedSessions: [DateGroup] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        var todayItems: [SessionSummary] = []
        var thisWeekItems: [SessionSummary] = []
        var earlierItems: [SessionSummary] = []

        for session in sessions {
            let sessionDay = calendar.startOfDay(for: session.date)
            if sessionDay == today {
                todayItems.append(session)
            } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: today),
                      sessionDay > weekAgo {
                thisWeekItems.append(session)
            } else {
                earlierItems.append(session)
            }
        }

        var groups: [DateGroup] = []
        if !todayItems.isEmpty {
            groups.append(DateGroup(
                label: language == "de" ? "Heute" : "Today",
                sessions: todayItems
            ))
        }
        if !thisWeekItems.isEmpty {
            groups.append(DateGroup(
                label: language == "de" ? "Diese Woche" : "This Week",
                sessions: thisWeekItems
            ))
        }
        if !earlierItems.isEmpty {
            groups.append(DateGroup(
                label: language == "de" ? "Früher" : "Earlier",
                sessions: earlierItems
            ))
        }
        return groups
    }
}

// MARK: - Session History Row

struct SessionHistoryRow: View {
    let session: SessionSummary
    let language: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(session.topicTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(sessionTypeName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(formattedDate)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private var iconName: String {
        switch session.sessionType {
        case "say-it-clearly": "text.bubble"
        case "find-the-point": "magnifyingglass"
        case "elevator-pitch": "timer"
        case "analyse-my-text": "doc.text"
        default: "questionmark.circle"
        }
    }

    private var sessionTypeName: String {
        if let type = SessionType(rawValue: session.sessionType) {
            return type.displayName(language: language)
        }
        return session.sessionType
    }

    private var formattedDate: String {
        session.date.formatted(date: .abbreviated, time: .shortened)
    }
}

// MARK: - Session Detail View

struct SessionDetailView: View {
    let session: SessionSummary
    let language: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                if !session.barbaraSummary.isEmpty {
                    barbaraSection
                }
                if !session.dimensionScores.isEmpty {
                    scoresSection
                }
                statsSection
            }
            .padding(20)
        }
        .navigationTitle(session.topicTitle)
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let type = SessionType(rawValue: session.sessionType) {
                    Label(type.displayName(language: language), systemImage: type.iconName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(session.date.formatted(date: .long, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            if !session.overallAssessment.isEmpty {
                Text(session.overallAssessment)
                    .font(.body)
            }
        }
    }

    private var barbaraSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Barbara")
                .font(.headline)

            Text(session.barbaraSummary)
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.accentColor.opacity(0.08))
                )
        }
    }

    private var scoresSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(language == "de" ? "Bewertungen" : "Scores")
                .font(.headline)

            DimensionBarChartView(
                dimensionScores: session.dimensionScores.mapValues { [$0] },
                language: language
            )
        }
    }

    private var statsSection: some View {
        HStack(spacing: 20) {
            statItem(
                label: language == "de" ? "Versuche" : "Attempts",
                value: "\(session.attemptCount)"
            )
            statItem(
                label: "Level",
                value: "\(session.levelAtSession)"
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
        )
    }
}

// MARK: - Previews

#Preview("History List") {
    NavigationStack {
        SessionHistoryView(
            sessions: SessionSummary.previewSessions,
            language: "en"
        )
    }
}

#Preview("Empty History") {
    NavigationStack {
        SessionHistoryView(sessions: [], language: "en")
    }
}

#Preview("Session Detail") {
    NavigationStack {
        SessionDetailView(
            session: SessionSummary.previewSessions[0],
            language: "en"
        )
    }
}

extension SessionSummary {
    static var previewSessions: [SessionSummary] {
        [
            SessionSummary(
                date: .now,
                sessionType: "say-it-clearly",
                topicTitle: "Should schools start later?",
                attemptCount: 2,
                dimensionScores: ["governingThought": 3, "supportGrouping": 1, "clarity": 2],
                overallAssessment: "Good lead, but grouping needs work.",
                barbaraSummary: "Your governing thought was clear and well-positioned. However, your supporting points overlapped — that's a grouping issue. Next time, ask yourself: could any two points be merged?",
                levelAtSession: 1
            ),
            SessionSummary(
                date: .now.addingTimeInterval(-86400 * 2),
                sessionType: "find-the-point",
                topicTitle: "Climate policy priorities",
                attemptCount: 1,
                dimensionScores: ["governingThought": 2, "clarity": 3],
                overallAssessment: "Found the point but took too long.",
                barbaraSummary: "You identified the governing thought correctly, but your explanation was roundabout. Lead with what matters.",
                levelAtSession: 1
            ),
            SessionSummary(
                date: .now.addingTimeInterval(-86400 * 10),
                sessionType: "elevator-pitch",
                topicTitle: "School uniforms",
                attemptCount: 1,
                overallAssessment: "Solid under pressure.",
                barbaraSummary: "Under time pressure, you prioritised well. Your conclusion came first — exactly right.",
                levelAtSession: 1
            ),
        ]
    }
}
