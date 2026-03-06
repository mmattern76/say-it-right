import SwiftUI

/// A subtle pulsing animation shown while waiting for Barbara's first sentence.
///
/// Displayed during the latency window between the user finishing speaking
/// and Barbara beginning to speak. Three dots pulse sequentially to convey
/// that Barbara is "thinking" — maintaining the conversational feel.
///
/// Usage:
/// ```swift
/// if streamingState == .waitingForFirstSentence {
///     ThinkingIndicatorView()
/// }
/// ```
struct ThinkingIndicatorView: View {
    @State private var animatingDot: Int = 0

    private let dotCount = 3
    private let dotSize: CGFloat = 8
    private let dotSpacing: CGFloat = 6
    private let animationDuration: Double = 0.4

    var body: some View {
        HStack(spacing: dotSpacing) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(Color.secondary.opacity(opacity(for: index)))
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(scale(for: index))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.secondary.opacity(0.1))
        )
        .onAppear {
            startAnimation()
        }
        .accessibilityLabel("Barbara is thinking")
        .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: - Animation

    private func opacity(for index: Int) -> Double {
        index == animatingDot ? 0.9 : 0.3
    }

    private func scale(for index: Int) -> CGFloat {
        index == animatingDot ? 1.3 : 1.0
    }

    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: animationDuration, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: animationDuration)) {
                    animatingDot = (animatingDot + 1) % dotCount
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Thinking Indicator") {
    VStack(spacing: 24) {
        Text("Barbara is thinking...")
            .font(.caption)
            .foregroundStyle(.secondary)

        ThinkingIndicatorView()

        // In context: next to Barbara's avatar
        HStack(alignment: .bottom, spacing: 8) {
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(Text("B").font(.headline))

            ThinkingIndicatorView()

            Spacer()
        }
        .padding()
    }
    .padding()
}
