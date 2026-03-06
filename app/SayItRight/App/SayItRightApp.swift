import SwiftUI

@main
struct SayItRightApp: App {
    @State private var settings = AppSettings.shared
    @State private var chatViewModel = ChatViewModel()

    var body: some Scene {
        mainWindow
        #if os(macOS)
        Settings {
            SettingsView()
                .environment(settings)
        }
        #endif
    }

    private var mainWindow: some Scene {
        WindowGroup {
            AdaptiveChatView(
                viewModel: chatViewModel,
                language: settings.language
            )
            .environment(settings)
            #if os(macOS)
            .frame(minWidth: 500, minHeight: 400)
            #endif
        }
        #if os(macOS)
        .defaultSize(width: 800, height: 600)
        .commands {
            AppCommands(viewModel: chatViewModel)
        }
        #endif
    }
}

// MARK: - macOS Menu Commands

#if os(macOS)
/// Keyboard shortcut commands for macOS menu bar integration.
///
/// Provides standard Mac keyboard shortcuts:
/// - Cmd+N: New session (clears conversation)
struct AppCommands: Commands {
    let viewModel: ChatViewModel

    var body: some Commands {
        // Replace the default New Window command with New Session
        CommandGroup(replacing: .newItem) {
            Button("New Session") {
                Task { @MainActor in
                    viewModel.clearConversation()
                }
            }
            .keyboardShortcut("n", modifiers: .command)
        }
    }
}
#endif

#Preview {
    AdaptiveChatView(
        viewModel: .previewMidConversation,
        language: "en"
    )
    .environment(AppSettings.shared)
    .frame(width: 800, height: 600)
}
