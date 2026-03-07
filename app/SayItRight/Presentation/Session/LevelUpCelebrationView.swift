import SwiftUI

/// Brief celebration modal shown when the learner advances to a new level.
///
/// Warm but not over-the-top — Barbara acknowledges real growth.
struct LevelUpCelebrationView: View {
    let fromLevel: Int
    let toLevel: Int
    let language: String
    let onDismiss: () -> Void

    private var transition: LevelTransitionEngine.LevelTransition {
        LevelTransitionEngine.LevelTransition(fromLevel: fromLevel, toLevel: toLevel, date: .now)
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Level badge
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 100, height: 100)

                Text("\(toLevel)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.accentColor)
            }

            // Level name
            VStack(spacing: 4) {
                Text(language == "de" ? "Level \(toLevel)" : "Level \(toLevel)")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(language == "de"
                    ? transition.toLevelName.de
                    : transition.toLevelName.en)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            // Barbara's quote
            VStack(spacing: 8) {
                Image(systemName: "quote.opening")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor.opacity(0.6))

                Text(transition.barbaraQuote(language: language))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .foregroundStyle(.primary)

                Text("— Barbara")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
            }
            .padding(.vertical, 8)

            // What was mastered
            VStack(spacing: 6) {
                Text(language == "de"
                    ? "Gemeistert: \(transition.fromLevelName.de)"
                    : "Mastered: \(transition.fromLevelName.en)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Dismiss button
            Button(action: onDismiss) {
                Text(language == "de" ? "Los geht's!" : "Let's go!")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: 400)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

#Preview("L1 → L2 — EN") {
    LevelUpCelebrationView(
        fromLevel: 1,
        toLevel: 2,
        language: "en"
    ) {}
}

#Preview("L1 → L2 — DE") {
    LevelUpCelebrationView(
        fromLevel: 1,
        toLevel: 2,
        language: "de"
    ) {}
}

#Preview("L2 → L3") {
    LevelUpCelebrationView(
        fromLevel: 2,
        toLevel: 3,
        language: "en"
    ) {}
}

#Preview("L3 → L4") {
    LevelUpCelebrationView(
        fromLevel: 3,
        toLevel: 4,
        language: "en"
    ) {}
}
