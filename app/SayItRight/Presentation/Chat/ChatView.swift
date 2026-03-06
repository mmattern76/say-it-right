import SwiftUI

/// The core chat interface where learners interact with Barbara.
///
/// Layout adapts per platform:
/// - **iPhone**: Full-width bubbles, compact spacing, keyboard-aware.
/// - **iPad**: Max content width ~600pt, centered, generous spacing.
/// - **Mac**: Comfortable reading width, Enter to send.
struct ChatView: View {
    @Bindable var viewModel: ChatViewModel

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(spacing: 0) {
            messageList
            Divider()
            inputBar
        }
        .frame(maxWidth: maxContentWidth)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: messagePadding) {
                    if viewModel.messages.isEmpty {
                        emptyState
                    }

                    ForEach(viewModel.messages) { message in
                        MessageBubbleView(message: message)
                            .id(message.id)
                            .padding(.horizontal, contentHorizontalPadding)
                    }

                    // Loading indicator when waiting for first token
                    if viewModel.isLoading, let last = viewModel.messages.last,
                       last.role == .barbara, last.text.isEmpty {
                        loadingIndicator
                            .id("loading")
                            .padding(.horizontal, contentHorizontalPadding)
                    }
                }
                .padding(.vertical, 12)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.messages.last?.text) { _, _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            BarbaraAvatarView(mood: .attentive, size: .header)

            Text("Ready when you are.")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Start a conversation with Barbara.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .padding(.bottom, 40)
    }

    // MARK: - Loading Indicator

    private var loadingIndicator: some View {
        HStack(alignment: .top, spacing: 8) {
            BarbaraAvatarView(mood: .evaluating, size: .thumbnail)
            TypingIndicatorView()
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            Spacer(minLength: 40)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Type a message...", text: $viewModel.inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...6)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                #if os(macOS)
                .onSubmit { sendIfReady() }
                #endif

            Button(action: { viewModel.send() }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(sendButtonColor)
            }
            .disabled(!canSend)
            .buttonStyle(.plain)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, contentHorizontalPadding)
        .padding(.vertical, 8)
    }

    // MARK: - Platform Adaptive Layout

    /// Maximum content width based on platform / size class.
    private var maxContentWidth: CGFloat {
        #if os(macOS)
        return 700
        #else
        if horizontalSizeClass == .regular {
            return 650
        }
        return .infinity
        #endif
    }

    /// Horizontal padding for content within the scroll area.
    private var contentHorizontalPadding: CGFloat {
        #if os(macOS)
        return 20
        #else
        if horizontalSizeClass == .regular {
            return 20
        }
        return 12
        #endif
    }

    /// Vertical spacing between message bubbles.
    private var messagePadding: CGFloat {
        #if os(macOS)
        return 12
        #else
        if horizontalSizeClass == .regular {
            return 12
        }
        return 8
        #endif
    }

    // MARK: - Helpers

    private var canSend: Bool {
        !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.isLoading
    }

    private var sendButtonColor: Color {
        canSend ? .accentColor : Color.gray.opacity(0.4)
    }

    private func sendIfReady() {
        if canSend {
            viewModel.send()
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastMessage = viewModel.messages.last else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
}

// MARK: - Previews

#Preview("iPhone — Empty State") {
    ChatView(viewModel: ChatViewModel())
        .environment(\.horizontalSizeClass, .compact)
}

#Preview("iPhone — Mid-Conversation") {
    ChatView(viewModel: .previewMidConversation)
        .environment(\.horizontalSizeClass, .compact)
}

#Preview("iPad — Mid-Conversation") {
    ChatView(viewModel: .previewMidConversation)
        .environment(\.horizontalSizeClass, .regular)
}

#Preview("iPhone — Dark Mode") {
    ChatView(viewModel: .previewMidConversation)
        .environment(\.horizontalSizeClass, .compact)
        .preferredColorScheme(.dark)
}

#Preview("Mac — Mid-Conversation") {
    ChatView(viewModel: .previewMidConversation)
        .frame(width: 800, height: 600)
}

#Preview("iPhone — Empty — Dark") {
    ChatView(viewModel: ChatViewModel())
        .environment(\.horizontalSizeClass, .compact)
        .preferredColorScheme(.dark)
}

// MARK: - Preview Helpers

extension ChatViewModel {
    /// A view model pre-populated with a sample conversation for previews.
    @MainActor
    static var previewMidConversation: ChatViewModel {
        let vm = ChatViewModel()
        vm.setMessages([
            ChatMessage(
                role: .barbara,
                text: "Good. Let's practise structuring your argument. Tell me: why should your school switch to a four-day week? Lead with your answer."
            ),
            ChatMessage(
                role: .learner,
                text: "I think schools should switch to a four-day week because students would be more focused, teachers would have more prep time, and it saves energy costs."
            ),
            ChatMessage(
                role: .barbara,
                text: "Better. You led with your position and gave three supporting reasons. But \"more focused\" is vague. What does focus look like? Give me a concrete measure."
            ),
        ])
        return vm
    }
}
