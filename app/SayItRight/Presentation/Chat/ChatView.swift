import SwiftUI

/// Input mode for the chat interface.
enum ChatInputMode: Sendable, Equatable {
    case text
    case voice
}

/// The core chat interface where learners interact with Barbara.
///
/// Layout adapts per platform:
/// - **iPhone**: Full-width bubbles, compact spacing, keyboard-aware.
/// - **iPad**: Max content width ~600pt, centered, generous spacing.
/// - **Mac**: Comfortable reading width, Enter to send.
struct ChatView: View {
    @Bindable var viewModel: ChatViewModel

    /// Optional voice input view model. When set, enables voice input mode
    /// and a toggle button to switch between voice and text input.
    var voiceInputViewModel: VoiceInputViewModel?

    /// Called when the user submits a voice transcription.
    var onVoiceSubmit: ((String) -> Void)?

    /// The current input mode. Defaults to `.voice` when a voice view model
    /// is provided, `.text` otherwise. Users can toggle mid-session.
    @State private var inputMode: ChatInputMode = .text

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(spacing: 0) {
            messageList

            if viewModel.errorState.isShowingError, let error = viewModel.errorState.error {
                ErrorBannerView(
                    error: error,
                    language: viewModel.language,
                    retryCount: viewModel.errorState.retryCount,
                    rateLimitCountdown: viewModel.errorState.rateLimitCountdown,
                    hasPartialResponse: viewModel.errorState.hasPartialResponse,
                    onRetry: { viewModel.retry() },
                    onOpenSettings: { viewModel.openSettings() },
                    onDismiss: { viewModel.dismissError() }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.vertical, 4)
            }

            Divider()

            inputArea
        }
        .frame(maxWidth: maxContentWidth)
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.25), value: viewModel.errorState.isShowingError)
        .onAppear {
            // Default to voice mode when voice VM is available
            if voiceInputViewModel != nil {
                inputMode = .voice
            }
        }
    }

    // MARK: - Input Area

    @ViewBuilder
    private var inputArea: some View {
        if let voiceVM = voiceInputViewModel {
            // Voice-capable: show current mode with toggle
            VStack(spacing: 0) {
                if inputMode == .voice {
                    VoiceInputView(viewModel: voiceVM) { text in
                        onVoiceSubmit?(text)
                    }
                } else {
                    inputBar
                }

                inputModeToggle
            }
            .animation(.easeInOut(duration: 0.2), value: inputMode)
        } else {
            // Text-only: no toggle available
            inputBar
        }
    }

    /// Toggle button to switch between voice and text input.
    private var inputModeToggle: some View {
        HStack {
            Spacer()
            Button {
                switchInputMode()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: inputMode == .voice ? "keyboard" : "mic.fill")
                        .font(.caption)
                    Text(inputMode == .voice
                         ? (viewModel.language == "de" ? "Tippen" : "Type")
                         : (viewModel.language == "de" ? "Sprechen" : "Speak"))
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(inputMode == .voice ? "Switch to text input" : "Switch to voice input")
            .accessibilityIdentifier("inputModeToggle")
            Spacer()
        }
        .padding(.bottom, 4)
    }

    /// Switch between voice and text input, preserving partial transcription.
    private func switchInputMode() {
        if inputMode == .voice, let voiceVM = voiceInputViewModel {
            // Voice → Text: preserve any partial transcription
            let partial: String
            if voiceVM.state == .review {
                partial = voiceVM.editableText
            } else if voiceVM.state == .recording {
                partial = voiceVM.transcriptionText
            } else {
                partial = ""
            }
            voiceVM.reset()

            if !partial.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                viewModel.inputText = partial
            }

            inputMode = .text
        } else {
            // Text → Voice: keep any typed text in inputText (user can switch back)
            inputMode = .voice
        }
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
            #if os(macOS)
            MacChatInputView(
                text: $viewModel.inputText,
                onSend: { sendIfReady() }
            )
            .frame(minHeight: 36, maxHeight: 120)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            #else
            TextField("Type a message...", text: $viewModel.inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...6)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .accessibilityIdentifier("chatInputField")
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
            .accessibilityIdentifier("sendButton")
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

#Preview("iPhone - Error Banner") {
    ChatView(viewModel: .previewWithError)
        .environment(\.horizontalSizeClass, .compact)
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

    /// A view model with an active error state for previews.
    @MainActor
    static var previewWithError: ChatViewModel {
        let vm = ChatViewModel()
        vm.setMessages([
            ChatMessage(
                role: .barbara,
                text: "Good. Let's practise structuring your argument."
            ),
        ])
        vm.inputText = "I think schools should switch to a four-day week"
        vm.setErrorForPreview(.noConnection)
        return vm
    }
}
