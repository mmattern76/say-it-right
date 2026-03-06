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
            ContentView()
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

struct ContentView: View {
    @Environment(AppSettings.self) private var settings
    @State private var sessionManager = SessionManager()
    @State private var coordinator = SayItClearlyCoordinator()
    @State private var showSayItClearly = false

    private var language: String { settings.language }

    private var profile: LearnerProfile {
        LearnerProfile.createDefault(
            displayName: settings.displayName,
            language: language
        )
    }

    var body: some View {
        NavigationStack {
            SessionPickerView(
                sessionManager: sessionManager,
                profile: profile,
                language: language,
                sayItClearlyCoordinator: coordinator
            ) { sessionType in
                if sessionType == .sayItClearly {
                    showSayItClearly = true
                }
            }
            .navigationDestination(isPresented: $showSayItClearly) {
                SayItClearlyView(
                    sessionManager: sessionManager,
                    coordinator: coordinator,
                    profile: profile,
                    language: language
                ) {
                    showSayItClearly = false
                }
            }
        }
    }
}

// MARK: - macOS Menu Commands

#if os(macOS)
struct AppCommands: Commands {
    let viewModel: ChatViewModel

    var body: some Commands {
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
    ContentView()
        .environment(AppSettings.shared)
        .frame(width: 800, height: 600)
}
