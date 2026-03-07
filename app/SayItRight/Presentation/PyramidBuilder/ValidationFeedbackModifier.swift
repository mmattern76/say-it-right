import SwiftUI

// MARK: - Feedback Glow Modifier

/// Applies a colour-coded border glow to a block based on its feedback state.
///
/// Colour-blind-safe design:
/// - Correct: green glow + checkmark icon overlay
/// - Misplaced: amber border + triangle warning icon
/// - MECE overlap: red pulse + striped pattern overlay
struct FeedbackGlowModifier: ViewModifier {
    let feedbackState: BlockFeedbackState

    @State private var isPulsing: Bool = false

    func body(content: Content) -> some View {
        content
            .overlay(borderOverlay)
            .overlay(iconOverlay, alignment: .topTrailing)
            .animation(.easeInOut(duration: 0.3), value: feedbackState)
            .onChange(of: feedbackState) { _, newValue in
                isPulsing = newValue == .meceOverlap
            }
            .onAppear {
                isPulsing = feedbackState == .meceOverlap
            }
    }

    // MARK: - Border Overlay

    @ViewBuilder
    private var borderOverlay: some View {
        switch feedbackState {
        case .correct:
            RoundedRectangle(cornerRadius: BlockDimensions.cornerRadius)
                .strokeBorder(FeedbackPalette.correct, lineWidth: 2.5)
                .shadow(color: FeedbackPalette.correct.opacity(0.5), radius: 6)
        case .misplaced:
            RoundedRectangle(cornerRadius: BlockDimensions.cornerRadius)
                .strokeBorder(FeedbackPalette.misplaced, lineWidth: 2.5)
        case .meceOverlap:
            RoundedRectangle(cornerRadius: BlockDimensions.cornerRadius)
                .strokeBorder(FeedbackPalette.overlap, lineWidth: 3)
                .opacity(shouldReduceMotion ? 1.0 : (isPulsing ? 0.6 : 1.0))
                .animation(
                    shouldReduceMotion
                        ? nil
                        : .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: isPulsing
                )
        case .none:
            EmptyView()
        }
    }

    // MARK: - Accessibility Icon Overlay

    /// Small icon badge for colour-blind accessibility.
    @ViewBuilder
    private var iconOverlay: some View {
        switch feedbackState {
        case .correct:
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
                .foregroundStyle(FeedbackPalette.correct)
                .padding(4)
        case .misplaced:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)
                .foregroundStyle(FeedbackPalette.misplaced)
                .padding(4)
        case .meceOverlap:
            Image(systemName: "xmark.circle.fill")
                .font(.caption2)
                .foregroundStyle(FeedbackPalette.overlap)
                .padding(4)
        case .none:
            EmptyView()
        }
    }
}

// MARK: - Shake Modifier

/// Applies a horizontal shake animation to misplaced blocks.
///
/// Triggers a brief oscillation when the feedback state changes to `.misplaced`.
struct ShakeModifier: ViewModifier {
    let feedbackState: BlockFeedbackState

    @State private var shakeOffset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: shakeOffset)
            .onChange(of: feedbackState) { _, newValue in
                if newValue == .misplaced && !shouldReduceMotion {
                    triggerShake()
                }
            }
    }

    private func triggerShake() {
        let duration: Double = 0.08
        // Three oscillations: right, left, right, left, center.
        withAnimation(.easeInOut(duration: duration)) {
            shakeOffset = 6
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.easeInOut(duration: duration)) {
                shakeOffset = -5
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration * 2) {
            withAnimation(.easeInOut(duration: duration)) {
                shakeOffset = 4
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration * 3) {
            withAnimation(.easeInOut(duration: duration)) {
                shakeOffset = -3
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration * 4) {
            withAnimation(.easeInOut(duration: duration)) {
                shakeOffset = 0
            }
        }
    }
}

// MARK: - View Extension

extension View {
    /// Applies validation feedback visuals to a pyramid block.
    ///
    /// Combines glow border, accessibility icon, and shake animation.
    func validationFeedback(_ state: BlockFeedbackState) -> some View {
        self
            .modifier(FeedbackGlowModifier(feedbackState: state))
            .modifier(ShakeModifier(feedbackState: state))
    }
}

// MARK: - Feedback Palette

/// Colour-blind-safe palette for validation feedback.
///
/// Uses distinct hue + luminance combinations that remain distinguishable
/// under protanopia, deuteranopia, and tritanopia.
enum FeedbackPalette {
    /// Correct placement — green (hue 140).
    static let correct = Color(red: 0.20, green: 0.75, blue: 0.40)
    /// Misplaced block — amber/orange (hue 35).
    static let misplaced = Color(red: 0.90, green: 0.65, blue: 0.15)
    /// MECE overlap — red (hue 0).
    static let overlap = Color(red: 0.85, green: 0.20, blue: 0.25)
    /// Gap placeholder — dashed outline colour.
    static let gap = Color(red: 0.50, green: 0.50, blue: 0.60)
    /// Celebration — bright gold.
    static let celebration = Color(red: 1.0, green: 0.85, blue: 0.25)
}

// MARK: - Feedback Connection Line Style

extension ConnectionLineStyle {
    /// Line style for a validated connection (correct placement).
    static let validated = ConnectionLineStyle.highlighted
}
