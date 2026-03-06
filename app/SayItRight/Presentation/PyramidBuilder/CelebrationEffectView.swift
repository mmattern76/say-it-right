import SwiftUI

// MARK: - Celebration Effect View

/// A brief celebration effect shown when all blocks are correctly placed.
///
/// Displays a scale-bounce animation with a radial glow, then fades out.
/// Intentionally restrained — a quick flash of satisfaction, not a fireworks show.
struct CelebrationEffectView: View {
    /// Whether the celebration is currently active.
    @Binding var isActive: Bool

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    @State private var innerOpacity: Double = 0.0

    var body: some View {
        ZStack {
            // Radial glow background.
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            FeedbackPalette.celebration.opacity(0.3),
                            FeedbackPalette.correct.opacity(0.1),
                            Color.clear,
                        ]),
                        center: .center,
                        startRadius: 20,
                        endRadius: 200
                    )
                )
                .scaleEffect(scale)
                .opacity(opacity)

            // Checkmark icon.
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(FeedbackPalette.correct)
                .scaleEffect(scale)
                .opacity(innerOpacity)
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, newValue in
            if newValue {
                playCelebration()
            }
        }
        .accessibilityLabel(isActive ? "Pyramid complete!" : "")
    }

    private func playCelebration() {
        // Phase 1: Scale up and fade in.
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            scale = 1.2
            opacity = 1.0
            innerOpacity = 1.0
        }

        // Phase 2: Settle to normal scale.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                scale = 1.0
            }
        }

        // Phase 3: Fade out after a pause.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 0.0
                innerOpacity = 0.0
            }
        }

        // Phase 4: Reset.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            scale = 0.5
            isActive = false
        }
    }
}

// MARK: - Previews

#Preview("Celebration Effect") {
    CelebrationEffectPreview()
}

private struct CelebrationEffectPreview: View {
    @State private var showCelebration = false

    var body: some View {
        ZStack {
            Color(white: 0.95)

            VStack(spacing: 32) {
                Button("Celebrate!") {
                    showCelebration = true
                }
                .buttonStyle(.borderedProminent)
            }

            CelebrationEffectView(isActive: $showCelebration)
        }
        .frame(width: 400, height: 400)
    }
}
