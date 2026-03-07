import SwiftUI

/// Bar chart showing rolling average scores per structural dimension.
///
/// Each dimension is displayed as a horizontal bar with a user-friendly label.
/// Bars are colour-coded: green for strengths, red for development areas, blue for normal.
struct DimensionBarChartView: View {
    let dimensionScores: [String: [Int]]
    let language: String

    private var sortedDimensions: [(key: String, average: Double, maxScore: Double)] {
        dimensionScores.compactMap { key, scores in
            guard !scores.isEmpty else { return nil }
            let recent = scores.suffix(10)
            let avg = Double(recent.reduce(0, +)) / Double(recent.count)
            let maxScore = Double(Self.maxScoreFor(key))
            return (key: key, average: avg, maxScore: maxScore)
        }
        .sorted { $0.key < $1.key }
    }

    var body: some View {
        VStack(spacing: 10) {
            ForEach(sortedDimensions, id: \.key) { dimension in
                dimensionRow(dimension)
            }
        }
    }

    private func dimensionRow(_ dimension: (key: String, average: Double, maxScore: Double)) -> some View {
        let normalised = dimension.maxScore > 0 ? dimension.average / dimension.maxScore : 0
        let barColor = barColor(for: normalised)

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(Self.displayName(for: dimension.key, language: language))
                    .font(.caption)
                    .foregroundStyle(.primary)
                Spacer()
                Text(String(format: "%.0f%%", normalised * 100))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: max(4, geo.size.width * normalised), height: 8)
                }
            }
            .frame(height: 8)
        }
    }

    private func barColor(for normalised: Double) -> Color {
        if normalised >= ProfileUpdater.strengthThreshold {
            return .green
        } else if normalised < ProfileUpdater.developmentThreshold {
            return .red
        }
        return .blue
    }

    // MARK: - Dimension Display Names

    static func displayName(for dimension: String, language: String) -> String {
        let names: [String: (en: String, de: String)] = [
            "governingThought": ("Leading with your point", "Mit dem Kerngedanken führen"),
            "supportGrouping": ("Logical grouping", "Logische Gruppierung"),
            "redundancy": ("Avoiding redundancy", "Redundanz vermeiden"),
            "clarity": ("Clarity of expression", "Klarheit im Ausdruck"),
            "l1Gate": ("Foundation mastery", "Grundlagen beherrschen"),
            "meceQuality": ("MECE quality", "MECE-Qualität"),
            "orderingLogic": ("Ordering logic", "Ordnungslogik"),
            "scqApplication": ("SCQ framing", "SCQ-Rahmen"),
            "horizontalLogic": ("Horizontal logic", "Horizontale Logik"),
            // Break mode dimensions
            "extractionAccuracy": ("Extracting structure", "Struktur erkennen"),
            "flawIdentification": ("Finding structural flaws", "Strukturelle Fehler finden"),
            "restructuringQuality": ("Restructuring quality", "Qualität der Umstrukturierung"),
        ]

        if let name = names[dimension] {
            return language == "de" ? name.de : name.en
        }
        return dimension
    }

    static func maxScoreFor(_ dimension: String) -> Int {
        ProfileUpdater.maxScores[dimension] ?? 3
    }
}

// MARK: - Previews

#Preview("Bar Chart") {
    DimensionBarChartView(
        dimensionScores: [
            "governingThought": [2, 3, 2, 3, 3],
            "supportGrouping": [1, 1, 2, 1, 1],
            "clarity": [2, 2, 3, 2, 3],
            "redundancy": [1, 1, 0, 1, 1],
        ],
        language: "en"
    )
    .padding()
}

#Preview("Bar Chart — DE") {
    DimensionBarChartView(
        dimensionScores: [
            "governingThought": [2, 3, 3],
            "clarity": [3, 3, 3],
            "supportGrouping": [0, 1, 1],
        ],
        language: "de"
    )
    .padding()
}
