import SwiftUI

/// Enhanced message bubble for Barbara's structural feedback.
///
/// When a message contains evaluation metadata (scores), this view
/// renders quoted user text with visual emphasis, distinguishes positive
/// from negative observations, and shows a collapsible structural scorecard.
struct FeedbackBubbleView: View {
    let message: ChatMessage
    var barbaraMood: BarbaraMood = .attentive

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showScorecard = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            barbaraAvatar
            VStack(alignment: .leading, spacing: 6) {
                feedbackContent
                if hasScores {
                    scorecardToggle
                    if showScorecard {
                        StructuralScorecardView(metadata: message.metadata!)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            Spacer(minLength: 40)
        }
        .animation(.easeInOut(duration: 0.25), value: showScorecard)
    }

    // MARK: - Avatar

    private var barbaraAvatar: some View {
        BarbaraAvatarView(
            mood: message.metadata?.mood ?? barbaraMood,
            size: .thumbnail
        )
    }

    // MARK: - Feedback Text

    private var feedbackContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormattedFeedbackText(text: message.text)
                .font(.body)
                .foregroundStyle(.primary)

            if message.isStreaming {
                TypingIndicatorView()
                    .padding(.leading, 8)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(bubbleColor, in: bubbleShape)
    }

    // MARK: - Scorecard Toggle

    private var scorecardToggle: some View {
        Button {
            showScorecard.toggle()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: showScorecard ? "chevron.up" : "chevron.down")
                    .font(.caption2)
                Text(showScorecard ? "Hide scores" : "Show scores")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .padding(.leading, 4)
        .accessibilityLabel(showScorecard ? "Hide structural scores" : "Show structural scores")
    }

    // MARK: - Helpers

    private var hasScores: Bool {
        message.metadata != nil && !(message.metadata!.scores.isEmpty)
    }

    private var bubbleColor: Color {
        colorScheme == .dark
            ? Color.gray.opacity(0.3)
            : Color.gray.opacity(0.12)
    }

    private var bubbleShape: some Shape {
        #if os(macOS)
        RoundedRectangle(cornerRadius: 10, style: .continuous)
        #else
        RoundedRectangle(cornerRadius: 16, style: .continuous)
        #endif
    }
}

// MARK: - Formatted Feedback Text

/// Renders Barbara's feedback with visual emphasis on quoted user text.
///
/// Text between quotation marks ("...") is rendered in a distinct style
/// to visually separate user quotes from Barbara's commentary.
struct FormattedFeedbackText: View {
    let text: String

    var body: some View {
        textContent
    }

    private var textContent: some View {
        let segments = parseQuotedSegments(text)
        return segments.reduce(Text("")) { result, segment in
            switch segment {
            case .plain(let str):
                return result + Text(str)
            case .quoted(let str):
                return result + Text("\"\(str)\"")
                    .italic()
                    .foregroundColor(.accentColor)
            }
        }
    }

    private enum TextSegment {
        case plain(String)
        case quoted(String)
    }

    private func parseQuotedSegments(_ input: String) -> [TextSegment] {
        var segments: [TextSegment] = []
        var remaining = input[...]

        while let openQuote = remaining.firstIndex(of: "\u{201C}") ?? remaining.firstIndex(of: "\"") {
            // Add text before the quote
            let before = remaining[remaining.startIndex..<openQuote]
            if !before.isEmpty {
                segments.append(.plain(String(before)))
            }

            let afterOpen = remaining.index(after: openQuote)
            guard afterOpen < remaining.endIndex else {
                segments.append(.plain(String(remaining[openQuote...])))
                return segments
            }

            let searchChar: Character = remaining[openQuote] == "\u{201C}" ? "\u{201D}" : "\""
            if let closeQuote = remaining[afterOpen...].firstIndex(of: searchChar) {
                let quoted = remaining[afterOpen..<closeQuote]
                segments.append(.quoted(String(quoted)))
                remaining = remaining[remaining.index(after: closeQuote)...]
            } else {
                // No closing quote found — treat rest as plain
                segments.append(.plain(String(remaining[openQuote...])))
                return segments
            }
        }

        if !remaining.isEmpty {
            segments.append(.plain(String(remaining)))
        }

        return segments
    }
}

// MARK: - Structural Scorecard

/// Compact display of per-dimension rubric scores from Barbara's evaluation.
///
/// Shows each scored dimension as a labeled bar. Green for strong scores,
/// yellow for mid-range, red for weak. Collapsible on iPhone.
struct StructuralScorecardView: View {
    let metadata: BarbaraMetadata

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Structural Analysis")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(metadata.totalScore) pts")
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
            }

            ForEach(sortedScores, id: \.key) { key, value in
                DimensionScoreRow(
                    dimension: formatDimensionName(key),
                    score: value,
                    maxScore: maxScoreForDimension(key)
                )
            }

            if metadata.progressionSignal != .none {
                progressionBadge
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(scorecardAccessibilityLabel)
    }

    private var sortedScores: [(key: String, value: Int)] {
        metadata.scores.sorted { $0.key < $1.key }
    }

    private var progressionBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: progressionIcon)
                .font(.caption2)
            Text(progressionLabel)
                .font(.caption)
        }
        .foregroundStyle(progressionColor)
        .padding(.top, 2)
    }

    private var progressionIcon: String {
        switch metadata.progressionSignal {
        case .improving: "arrow.up.right"
        case .readyForLevelUp: "star.fill"
        case .struggling: "arrow.down.right"
        case .regression: "exclamationmark.triangle"
        case .none: "minus"
        }
    }

    private var progressionLabel: String {
        switch metadata.progressionSignal {
        case .improving: "Improving"
        case .readyForLevelUp: "Ready for next level"
        case .struggling: "Needs practice"
        case .regression: "Regression detected"
        case .none: ""
        }
    }

    private var progressionColor: Color {
        switch metadata.progressionSignal {
        case .improving, .readyForLevelUp: .green
        case .struggling: .orange
        case .regression: .red
        case .none: .secondary
        }
    }

    private func formatDimensionName(_ key: String) -> String {
        key.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .capitalized
    }

    private func maxScoreForDimension(_ key: String) -> Int {
        // L1 rubric: clarity(3), governingThought(3), supportGrouping(2), redundancy(2) = 10
        // L2 rubric: l1Gate(3), meceQuality(3), orderingLogic(3), scqApplication(2), horizontalLogic(2) = 13
        switch key {
        case "clarity", "governingThought", "l1Gate", "meceQuality", "orderingLogic":
            return 3
        case "supportGrouping", "redundancy", "scqApplication", "horizontalLogic":
            return 2
        default:
            return 3
        }
    }

    private var scorecardAccessibilityLabel: String {
        let scores = sortedScores.map { "\(formatDimensionName($0.key)): \($0.value)" }.joined(separator: ", ")
        return "Structural analysis. Total \(metadata.totalScore) points. \(scores)"
    }
}

// MARK: - Dimension Score Row

struct DimensionScoreRow: View {
    let dimension: String
    let score: Int
    let maxScore: Int

    var body: some View {
        HStack(spacing: 8) {
            Text(dimension)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(scoreColor)
                        .frame(width: max(0, geo.size.width * fillRatio), height: 6)
                }
            }
            .frame(height: 6)

            Text("\(score)/\(maxScore)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .trailing)
        }
    }

    private var fillRatio: CGFloat {
        guard maxScore > 0 else { return 0 }
        return CGFloat(score) / CGFloat(maxScore)
    }

    private var scoreColor: Color {
        let ratio = fillRatio
        if ratio >= 0.8 { return .green }
        if ratio >= 0.5 { return .orange }
        return .red
    }
}

// MARK: - Previews

#Preview("Feedback with Scores") {
    FeedbackBubbleView(
        message: ChatMessage(
            role: .barbara,
            text: "Better. You led with your position — \"Schools should switch to a four-day week\" — and gave three supporting reasons. But \"more focused\" is vague. What does focus look like? Give me a concrete measure.",
            metadata: BarbaraMetadata(
                scores: ["governingThought": 3, "supportGrouping": 2, "redundancy": 1, "clarity": 1],
                totalScore: 7,
                mood: .approving,
                progressionSignal: .improving,
                revisionRound: 1,
                sessionPhase: .evaluation,
                feedbackFocus: "clarity",
                language: "en"
            )
        )
    )
    .padding()
}

#Preview("Feedback — Proud") {
    FeedbackBubbleView(
        message: ChatMessage(
            role: .barbara,
            text: "Now *that* is how you make a point. Clear conclusion up front, three distinct reasons, no overlap. Well done.",
            metadata: BarbaraMetadata(
                scores: ["governingThought": 3, "supportGrouping": 2, "redundancy": 2, "clarity": 3],
                totalScore: 10,
                mood: .proud,
                progressionSignal: .readyForLevelUp,
                revisionRound: 2,
                sessionPhase: .evaluation,
                feedbackFocus: "",
                language: "en"
            )
        )
    )
    .padding()
}

#Preview("Scorecard Only") {
    StructuralScorecardView(
        metadata: BarbaraMetadata(
            scores: ["governingThought": 2, "supportGrouping": 1, "redundancy": 2, "clarity": 1],
            totalScore: 6,
            mood: .evaluating,
            progressionSignal: .struggling,
            revisionRound: 1,
            sessionPhase: .evaluation,
            feedbackFocus: "supportGrouping",
            language: "en"
        )
    )
    .padding()
    .frame(width: 300)
}
