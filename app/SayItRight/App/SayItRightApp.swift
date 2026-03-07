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

    /// Whether the app needs first-launch setup (no API key or onboarding incomplete).
    private var needsFirstLaunchSetup: Bool {
        settings.effectiveAPIKey == nil || !settings.hasCompletedOnboarding
    }

    private var mainWindow: some Scene {
        WindowGroup {
            if needsFirstLaunchSetup {
                FirstLaunchSetupView(settings: settings) {
                    // Setup complete — main UI will show automatically
                }
            } else {
                ContentView()
                    .environment(settings)
                #if os(macOS)
                .frame(minWidth: 500, minHeight: 400)
                #endif
            }
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
    @State private var findThePointCoordinator = FindThePointCoordinator()
    @State private var elevatorPitchCoordinator = ElevatorPitchCoordinator()
    @State private var fixThisMessCoordinator = FixThisMessCoordinator()
    @State private var showSayItClearly = false
    @State private var showFindThePoint = false
    @State private var showElevatorPitch = false
    @State private var showAnalyseMyText = false
    @State private var showFixThisMess = false
    @State private var showDashboard = false

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
                switch sessionType {
                case .sayItClearly:
                    showSayItClearly = true
                case .findThePoint:
                    showFindThePoint = true
                case .elevatorPitch:
                    showElevatorPitch = true
                case .analyseMyText:
                    showAnalyseMyText = true
                case .fixThisMess:
                    showFixThisMess = true
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
            .navigationDestination(isPresented: $showFindThePoint) {
                FindThePointView(
                    sessionManager: sessionManager,
                    coordinator: findThePointCoordinator,
                    profile: profile,
                    language: language
                ) {
                    showFindThePoint = false
                }
            }
            .navigationDestination(isPresented: $showElevatorPitch) {
                ElevatorPitchView(
                    sessionManager: sessionManager,
                    coordinator: elevatorPitchCoordinator,
                    profile: profile,
                    language: language
                ) {
                    showElevatorPitch = false
                }
            }
            .navigationDestination(isPresented: $showAnalyseMyText) {
                AnalyseMyTextView(
                    sessionManager: sessionManager,
                    profile: profile,
                    language: language
                ) {
                    showAnalyseMyText = false
                }
            }
            .navigationDestination(isPresented: $showFixThisMess) {
                FixThisMessView(
                    sessionManager: sessionManager,
                    coordinator: fixThisMessCoordinator,
                    profile: profile,
                    language: language
                ) {
                    showFixThisMess = false
                }
            }
            .navigationDestination(isPresented: $showDashboard) {
                ProgressDashboardView(
                    profile: profile,
                    language: language
                )
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        showDashboard = true
                    } label: {
                        Label(
                            language == "de" ? "Fortschritt" : "Progress",
                            systemImage: "chart.bar.fill"
                        )
                    }
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
