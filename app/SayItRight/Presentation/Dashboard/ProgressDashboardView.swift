import SwiftUI

/// Progress dashboard showing the learner's level, dimension scores, streak, and recent sessions.
///
/// Platform behavior:
/// - **iPhone**: Scrolling list layout with compact cards.
/// - **iPad/Mac**: Wider layout with side-by-side dimension chart and stats.
struct ProgressDashboardView: View {
    let profile: LearnerProfile
    let language: String

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isWide: Bool {
        #if os(macOS)
        true
        #else
        horizontalSizeClass == .regular
        #endif
    }

    var body: some View {
        ScrollView {
            if profile.sessionCount == 0 {
                emptyState
            } else if isWide {
                wideLayout
            } else {
                compactLayout
            }
        }
        .navigationTitle(language == "de" ? "Fortschritt" : "Progress")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)
            Image(systemName: "chart.bar.xaxis.ascending")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(language == "de"
                ? "Noch keine Sitzungen abgeschlossen"
                : "No sessions completed yet")
                .font(.title3)
                .fontWeight(.semibold)

            Text(language == "de"
                ? "Starte deine erste Übung und dein Fortschritt erscheint hier."
                : "Start your first exercise and your progress will appear here.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Compact Layout (iPhone)

    private var compactLayout: some View {
        VStack(spacing: 20) {
            levelCard
            streakCard
            dimensionSection
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
    }

    // MARK: - Wide Layout (iPad/Mac)

    private var wideLayout: some View {
        VStack(spacing: 24) {
            HStack(alignment: .top, spacing: 20) {
                levelCard
                streakCard
            }
            dimensionSection
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Level Card

    private var levelCard: some View {
        VStack(spacing: 8) {
            Text(language == "de" ? "Aktuelles Level" : "Current Level")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("\(profile.currentLevel)")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(Color.accentColor)

            Text(levelName(for: profile.currentLevel))
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        )
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                streakStat(
                    title: language == "de" ? "Aktuell" : "Current",
                    value: "\(profile.currentStreak)",
                    icon: "flame.fill",
                    color: profile.currentStreak > 0 ? .orange : .secondary
                )
                Divider().frame(height: 40)
                streakStat(
                    title: language == "de" ? "Längster" : "Longest",
                    value: "\(profile.longestStreak)",
                    icon: "trophy.fill",
                    color: .yellow
                )
                Divider().frame(height: 40)
                streakStat(
                    title: language == "de" ? "Sitzungen" : "Sessions",
                    value: "\(profile.sessionCount)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        )
    }

    private func streakStat(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Dimension Section

    private var dimensionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(language == "de" ? "Strukturelle Fähigkeiten" : "Structural Skills")
                .font(.headline)

            if profile.dimensionScores.isEmpty {
                Text(language == "de"
                    ? "Deine Bewertungen erscheinen nach der ersten Sitzung."
                    : "Your scores will appear after your first session.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                DimensionBarChartView(
                    dimensionScores: profile.dimensionScores,
                    language: language
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        )
    }

    // MARK: - Helpers

    private func levelName(for level: Int) -> String {
        switch level {
        case 1: language == "de" ? "Klartext" : "Plain Talk"
        case 2: language == "de" ? "Ordnung" : "Order"
        case 3: language == "de" ? "Architektur" : "Architecture"
        case 4: language == "de" ? "Meisterschaft" : "Mastery"
        default: ""
        }
    }
}

// MARK: - Previews

#Preview("Populated — EN") {
    NavigationStack {
        ProgressDashboardView(
            profile: .previewPopulated,
            language: "en"
        )
    }
}

#Preview("Populated — DE") {
    NavigationStack {
        ProgressDashboardView(
            profile: .previewPopulated,
            language: "de"
        )
    }
}

#Preview("Empty State") {
    NavigationStack {
        ProgressDashboardView(
            profile: .createDefault(displayName: "Alex"),
            language: "en"
        )
    }
}

#Preview("iPad") {
    NavigationStack {
        ProgressDashboardView(
            profile: .previewPopulated,
            language: "en"
        )
    }
    .environment(\.horizontalSizeClass, .regular)
}

// MARK: - Preview Helpers

extension LearnerProfile {
    static var previewPopulated: LearnerProfile {
        var profile = LearnerProfile.createDefault(displayName: "Alex")
        profile.currentLevel = 1
        profile.sessionCount = 12
        profile.currentStreak = 3
        profile.longestStreak = 7

        // Simulate some dimension scores
        for _ in 0..<5 {
            profile.recordScore(2, for: "governingThought")
            profile.recordScore(1, for: "supportGrouping")
            profile.recordScore(2, for: "clarity")
            profile.recordScore(1, for: "redundancy")
        }
        profile.recordScore(3, for: "governingThought")
        profile.recordScore(3, for: "clarity")

        profile.structuralStrengths = ["governingThought", "clarity"]
        profile.developmentAreas = ["supportGrouping"]

        return profile
    }
}
