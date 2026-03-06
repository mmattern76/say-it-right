import SwiftUI

/// Displays a practice text in a readable, scrollable format.
///
/// Distinct from chat bubbles — uses a card-based layout with clear
/// typography optimised for reading comprehension. Shows the text title
/// area and body with comfortable line spacing.
struct PracticeTextView: View {
    let text: String
    let language: String

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header label
            Label(
                language == "de" ? "Lesetext" : "Reading Text",
                systemImage: "doc.text"
            )
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)

            // Text body
            Text(text)
                .font(.body)
                .lineSpacing(6)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(contentPadding)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(borderColor, lineWidth: 1)
        )
    }

    // MARK: - Platform Adaptive Styling

    private var contentPadding: CGFloat {
        #if os(macOS)
        20
        #else
        horizontalSizeClass == .regular ? 20 : 16
        #endif
    }

    private var backgroundColor: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor).opacity(0.5)
        #else
        Color(.secondarySystemGroupedBackground)
        #endif
    }

    private var borderColor: Color {
        #if os(macOS)
        Color(nsColor: .separatorColor).opacity(0.3)
        #else
        Color(.separator).opacity(0.3)
        #endif
    }
}

// MARK: - Previews

#Preview("English — Short") {
    PracticeTextView(
        text: "School uniforms reduce social pressure by eliminating visible economic differences among students. When everyone wears the same clothes, students focus more on learning and less on fashion. Studies show that schools with uniform policies report fewer incidents of bullying related to clothing choices.",
        language: "en"
    )
    .padding()
}

#Preview("German — Medium") {
    PracticeTextView(
        text: "Schuluniformen reduzieren den sozialen Druck, indem sie sichtbare wirtschaftliche Unterschiede zwischen Schülern beseitigen. Wenn alle die gleiche Kleidung tragen, konzentrieren sich die Schüler mehr auf das Lernen und weniger auf Mode. Studien zeigen, dass Schulen mit Uniformrichtlinien weniger Mobbing-Vorfälle im Zusammenhang mit Kleidung melden. Allerdings gibt es auch kritische Stimmen, die argumentieren, dass Uniformen die individuelle Ausdrucksfreiheit einschränken.",
        language: "de"
    )
    .padding()
}

#Preview("Dark Mode") {
    PracticeTextView(
        text: "Artificial intelligence will transform education within the next decade. Personalised learning algorithms can adapt to each student's pace, identifying gaps in understanding before they become problems.",
        language: "en"
    )
    .padding()
    .preferredColorScheme(.dark)
}
