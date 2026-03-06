import SwiftUI

/// Platform-adaptive root view for the chat experience.
///
/// - **iPhone** (compact width): Shows `ChatView` directly in a `NavigationStack`.
/// - **iPad** (regular width): Uses `NavigationSplitView` with a session sidebar
///   and the chat detail area centered at ~650pt max width.
/// - **Mac**: Uses `NavigationSplitView` matching the iPad layout with keyboard focus.
///
/// This view reads `horizontalSizeClass` to decide which layout to present.
/// It supports portrait and landscape orientations, multitasking (Slide Over,
/// Split View), and smooth rotation transitions.
struct AdaptiveChatView: View {
    @Bindable var viewModel: ChatViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var selectedSessionType: SessionTypeItem? = SessionTypeItem.allTypes.first
    @State private var showSettings = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var language: String = "en"

    var body: some View {
        Group {
            #if os(macOS)
            splitLayout
            #else
            if horizontalSizeClass == .regular {
                splitLayout
            } else {
                compactLayout
            }
            #endif
        }
        .animation(.easeInOut(duration: 0.3), value: horizontalSizeClass)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environment(AppSettings.shared)
        }
        .onChange(of: selectedSessionType) { _, newValue in
            if let sessionType = newValue {
                viewModel.sessionType = sessionType.id
            }
        }
    }

    // MARK: - Split Layout (iPad / Mac)

    private var splitLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(
                selectedSessionType: $selectedSessionType,
                language: language,
                onSettingsTapped: { showSettings = true }
            )
            .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 340)
        } detail: {
            chatDetail
        }
    }

    private var chatDetail: some View {
        ChatView(viewModel: viewModel)
            .navigationTitle(detailTitle)
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { viewModel.clearConversation() }) {
                        Label(
                            language == "de" ? "Neues Gesprach" : "New Chat",
                            systemImage: "plus.message"
                        )
                    }
                    .disabled(viewModel.messages.isEmpty)
                }
            }
    }

    private var detailTitle: String {
        guard let session = selectedSessionType else {
            return language == "de" ? "Gesprach" : "Chat"
        }
        return session.title(language: language)
    }

    // MARK: - Compact Layout (iPhone)

    #if !os(macOS)
    private var compactLayout: some View {
        NavigationStack {
            ChatView(viewModel: viewModel)
                .navigationTitle(language == "de" ? "Sag's richtig!" : "Say it right!")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape")
                        }
                    }
                }
        }
    }
    #endif
}

// MARK: - Previews

#Preview("iPhone — Compact") {
    AdaptiveChatView(
        viewModel: .previewMidConversation,
        language: "en"
    )
    .environment(\.horizontalSizeClass, .compact)
    .environment(AppSettings.shared)
}

#Preview("iPad — Portrait", traits: .portrait) {
    AdaptiveChatView(
        viewModel: .previewMidConversation,
        language: "en"
    )
    .environment(\.horizontalSizeClass, .regular)
    .environment(AppSettings.shared)
}

#Preview("iPad — Landscape", traits: .landscapeLeft) {
    AdaptiveChatView(
        viewModel: .previewMidConversation,
        language: "en"
    )
    .environment(\.horizontalSizeClass, .regular)
    .environment(AppSettings.shared)
}

#Preview("iPad — German") {
    AdaptiveChatView(
        viewModel: .previewMidConversation,
        language: "de"
    )
    .environment(\.horizontalSizeClass, .regular)
    .environment(AppSettings.shared)
}

#Preview("iPad — Empty State") {
    AdaptiveChatView(
        viewModel: ChatViewModel(),
        language: "en"
    )
    .environment(\.horizontalSizeClass, .regular)
    .environment(AppSettings.shared)
}

#Preview("iPad — Dark Mode") {
    AdaptiveChatView(
        viewModel: .previewMidConversation,
        language: "en"
    )
    .environment(\.horizontalSizeClass, .regular)
    .environment(AppSettings.shared)
    .preferredColorScheme(.dark)
}

#Preview("Mac") {
    AdaptiveChatView(
        viewModel: .previewMidConversation,
        language: "en"
    )
    .environment(AppSettings.shared)
    .frame(width: 1024, height: 700)
}
