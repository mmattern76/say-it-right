import SwiftUI

/// Shows a structural diff between the learner's first and final attempt.
///
/// Platform behavior:
/// - **iPhone**: Segmented control to toggle between Attempt 1 and Attempt 2.
/// - **iPad/Mac**: Side-by-side comparison.
struct RevisionDiffView: View {
    let originalText: String
    let revisedText: String
    let language: String

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedAttempt = 0

    private var isWide: Bool {
        #if os(macOS)
        true
        #else
        horizontalSizeClass == .regular
        #endif
    }

    private var diffResult: SentenceDiff.DiffResult {
        SentenceDiff.compare(original: originalText, revised: revisedText)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !diffResult.hasStructuralChanges {
                    noChangesView
                } else if isWide {
                    sideBySideView
                } else {
                    toggleView
                }

                legendView
            }
            .padding(16)
        }
        .navigationTitle(language == "de" ? "Vergleich" : "Revision Diff")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - No Changes

    private var noChangesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "equal.circle")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text(language == "de"
                ? "Keine strukturellen Änderungen erkannt"
                : "No structural changes detected")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Side by Side (iPad/Mac)

    private var sideBySideView: some View {
        HStack(alignment: .top, spacing: 16) {
            diffColumn(
                title: language == "de" ? "Versuch 1" : "Attempt 1",
                entries: diffResult.original
            )
            Divider()
            diffColumn(
                title: language == "de" ? "Versuch 2" : "Attempt 2",
                entries: diffResult.revised
            )
        }
    }

    // MARK: - Toggle View (iPhone)

    private var toggleView: some View {
        VStack(spacing: 12) {
            Picker("", selection: $selectedAttempt) {
                Text(language == "de" ? "Versuch 1" : "Attempt 1").tag(0)
                Text(language == "de" ? "Versuch 2" : "Attempt 2").tag(1)
            }
            .pickerStyle(.segmented)

            if selectedAttempt == 0 {
                diffEntries(diffResult.original)
            } else {
                diffEntries(diffResult.revised)
            }
        }
    }

    // MARK: - Diff Display

    private func diffColumn(title: String, entries: [SentenceDiff.DiffEntry]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            diffEntries(entries)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func diffEntries(_ entries: [SentenceDiff.DiffEntry]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(entries) { entry in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(colorFor(entry.status))
                        .frame(width: 8, height: 8)
                        .padding(.top, 5)

                    Text(entry.text)
                        .font(.body)
                        .foregroundStyle(entry.status == .removed ? .secondary : .primary)
                        .strikethrough(entry.status == .removed)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(backgroundFor(entry.status))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    // MARK: - Legend

    private var legendView: some View {
        HStack(spacing: 16) {
            legendItem(color: .green, label: language == "de" ? "Hinzugefügt" : "Added")
            legendItem(color: .red, label: language == "de" ? "Entfernt" : "Removed")
            legendItem(color: .purple, label: language == "de" ? "Verschoben" : "Moved")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.top, 8)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
        }
    }

    // MARK: - Colors

    private func colorFor(_ status: SentenceDiff.DiffStatus) -> Color {
        switch status {
        case .kept: .gray
        case .added: .green
        case .removed: .red
        case .moved: .purple
        }
    }

    private func backgroundFor(_ status: SentenceDiff.DiffStatus) -> some ShapeStyle {
        switch status {
        case .kept: Color.clear
        case .added: Color.green.opacity(0.1)
        case .removed: Color.red.opacity(0.1)
        case .moved: Color.purple.opacity(0.1)
        }
    }
}

// MARK: - Previews

#Preview("Improved Revision") {
    NavigationStack {
        RevisionDiffView(
            originalText: "There are many reasons why schools should start later. Research shows students are tired. Sleep is important for learning. The main point is that later start times improve academic performance.",
            revisedText: "Later school start times improve academic performance. Research shows students are tired in early mornings. Sleep is critical for learning and memory consolidation.",
            language: "en"
        )
    }
}

#Preview("Minimal Changes") {
    NavigationStack {
        RevisionDiffView(
            originalText: "Schools should start later. Students need more sleep.",
            revisedText: "Schools should start later. Students need more sleep. This helps them focus.",
            language: "en"
        )
    }
}

#Preview("Unchanged") {
    NavigationStack {
        RevisionDiffView(
            originalText: "Schools should start later. Students need more sleep.",
            revisedText: "Schools should start later. Students need more sleep.",
            language: "en"
        )
    }
}

#Preview("German") {
    NavigationStack {
        RevisionDiffView(
            originalText: "Es gibt viele Gründe für Schuluniformen. Schüler werden gleich behandelt.",
            revisedText: "Schuluniformen fördern Gleichbehandlung. Schüler werden nicht nach Kleidung beurteilt. Das reduziert sozialen Druck.",
            language: "de"
        )
    }
}

#Preview("iPad Side-by-Side") {
    NavigationStack {
        RevisionDiffView(
            originalText: "There are many reasons. Research shows things. The point is this.",
            revisedText: "The point is this: research shows clear evidence. Multiple studies confirm the findings.",
            language: "en"
        )
    }
    .environment(\.horizontalSizeClass, .regular)
}
