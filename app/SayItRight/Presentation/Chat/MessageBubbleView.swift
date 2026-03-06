import SwiftUI

/// A single chat bubble for either Barbara or the learner.
///
/// Barbara's messages are left-aligned with her avatar thumbnail.
/// Learner messages are right-aligned with a distinct color.
/// Supports both light and dark mode via semantic colors.
struct MessageBubbleView: View {
    let message: ChatMessage
    var barbaraMood: BarbaraMood = .attentive

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .barbara {
                barbaraAvatar
                bubbleContent
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubbleContent
            }
        }
    }

    // MARK: - Subviews

    private var barbaraAvatar: some View {
        BarbaraAvatarView(
            mood: message.metadata?.mood ?? barbaraMood,
            size: .thumbnail
        )
    }

    private var bubbleContent: some View {
        VStack(alignment: message.role == .barbara ? .leading : .trailing, spacing: 4) {
            Text(message.text)
                .font(.body)
                .foregroundStyle(textColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(bubbleColor, in: bubbleShape)

            if message.isStreaming {
                TypingIndicatorView()
                    .padding(.leading, 8)
            }
        }
    }

    private var bubbleShape: some Shape {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
    }

    // MARK: - Colors

    private var bubbleColor: Color {
        switch message.role {
        case .barbara:
            colorScheme == .dark
                ? Color.gray.opacity(0.3)
                : Color.gray.opacity(0.12)
        case .learner:
            Color.accentColor
        }
    }

    private var textColor: Color {
        switch message.role {
        case .barbara:
            .primary
        case .learner:
            .white
        }
    }
}

// MARK: - Typing Indicator

/// Animated three-dot indicator shown while Barbara is generating a response.
struct TypingIndicatorView: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .opacity(animating ? 1.0 : 0.4)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .onAppear { animating = true }
    }
}

// MARK: - Previews

#Preview("Barbara Message — Light") {
    MessageBubbleView(
        message: ChatMessage(
            role: .barbara,
            text: "That's not a conclusion, that's a preamble. Start over."
        )
    )
    .padding()
}

#Preview("Barbara Message — Dark") {
    MessageBubbleView(
        message: ChatMessage(
            role: .barbara,
            text: "Now *that* is how you make a point."
        )
    )
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("Learner Message") {
    MessageBubbleView(
        message: ChatMessage(
            role: .learner,
            text: "I think the main point is that we should invest in renewable energy because it's cheaper in the long run."
        )
    )
    .padding()
}

#Preview("Streaming Message") {
    MessageBubbleView(
        message: ChatMessage(
            role: .barbara,
            text: "Let me look at your argument structure...",
            isStreaming: true
        )
    )
    .padding()
}

#Preview("Typing Indicator") {
    TypingIndicatorView()
        .padding()
}
