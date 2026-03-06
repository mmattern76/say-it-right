import Testing
@testable import SayItRight

// MARK: - SessionType Tests

@Suite("SessionType")
struct SessionTypeTests {

    @Test("English display names")
    func englishDisplayNames() {
        #expect(SessionType.sayItClearly.displayName(language: "en") == "Say it clearly")
        #expect(SessionType.findThePoint.displayName(language: "en") == "Find the point")
    }

    @Test("German display names")
    func germanDisplayNames() {
        #expect(SessionType.sayItClearly.displayName(language: "de") == "Sag's klar")
        #expect(SessionType.findThePoint.displayName(language: "de") == "Finde den Punkt")
    }

    @Test("Each session type has a raw value matching prompt file naming")
    func rawValues() {
        #expect(SessionType.sayItClearly.rawValue == "say-it-clearly")
        #expect(SessionType.findThePoint.rawValue == "find-the-point")
    }

    @Test("Each session type has an icon name")
    func iconNames() {
        for sessionType in SessionType.allCases {
            #expect(!sessionType.iconName.isEmpty)
        }
    }

    @Test("Each session type has subtitles in both languages")
    func subtitles() {
        for sessionType in SessionType.allCases {
            #expect(!sessionType.subtitle(language: "en").isEmpty)
            #expect(!sessionType.subtitle(language: "de").isEmpty)
        }
    }
}

// MARK: - SessionState Tests

@Suite("SessionState")
struct SessionStateTests {

    @Test("Idle equals idle")
    func idleEquality() {
        #expect(SessionState.idle == SessionState.idle)
    }

    @Test("Error states with same message are equal")
    func errorEquality() {
        #expect(SessionState.error("oops") == SessionState.error("oops"))
    }

    @Test("Error states with different messages are not equal")
    func errorInequality() {
        #expect(SessionState.error("a") != SessionState.error("b"))
    }

    @Test("Different states are not equal")
    func differentStates() {
        #expect(SessionState.idle != SessionState.active)
        #expect(SessionState.active != SessionState.loading)
    }
}

// MARK: - SessionManager Tests

@Suite("SessionManager")
struct SessionManagerTests {

    @Test("Initial state is idle with no messages")
    @MainActor
    func initialState() {
        let manager = SessionManager()
        #expect(manager.sessionState == .idle)
        #expect(manager.messages.isEmpty)
        #expect(manager.activeSessionType == nil)
        #expect(manager.sessionMetadata.isEmpty)
    }

    @Test("endSession resets state to idle")
    @MainActor
    func endSessionResetsState() {
        let manager = SessionManager()
        // Manually verify endSession clears everything
        manager.endSession()
        #expect(manager.sessionState == .idle)
        #expect(manager.messages.isEmpty)
        #expect(manager.activeSessionType == nil)
    }

    @Test("sendMessage does nothing when session is idle")
    @MainActor
    func sendMessageWhenIdle() async {
        let manager = SessionManager()
        await manager.sendMessage(text: "Hello")
        // No messages should be added because session is idle
        #expect(manager.messages.isEmpty)
    }

    @Test("sendMessage ignores empty text")
    @MainActor
    func sendMessageIgnoresEmpty() async {
        let manager = SessionManager()
        await manager.sendMessage(text: "")
        #expect(manager.messages.isEmpty)
        await manager.sendMessage(text: "   \n  ")
        #expect(manager.messages.isEmpty)
    }

    @Test("Context window threshold is 50")
    @MainActor
    func contextWindowThreshold() {
        #expect(SessionManager.contextWindowThreshold == 50)
    }
}

// MARK: - ChatViewModel Integration Tests

@Suite("ChatViewModel with SessionManager")
struct ChatViewModelSessionTests {

    @Test("ViewModel in standalone mode has no active session")
    @MainActor
    func standaloneMode() {
        let vm = ChatViewModel()
        #expect(!vm.hasActiveSession)
        #expect(!vm.isLoading)
        #expect(vm.errorMessage == nil)
    }

    @Test("ViewModel reads messages from SessionManager when provided")
    @MainActor
    func readsFromSessionManager() {
        let sm = SessionManager()
        let vm = ChatViewModel(sessionManager: sm)
        // SessionManager starts with empty messages
        #expect(vm.messages.isEmpty)
    }

    @Test("ViewModel reflects SessionManager loading state")
    @MainActor
    func reflectsLoadingState() {
        let sm = SessionManager()
        let vm = ChatViewModel(sessionManager: sm)
        // SessionManager starts idle, not loading
        #expect(!vm.isLoading)
    }

    @Test("clearConversation calls endSession on SessionManager")
    @MainActor
    func clearConversationEndsSession() {
        let sm = SessionManager()
        let vm = ChatViewModel(sessionManager: sm)
        vm.clearConversation()
        #expect(sm.sessionState == .idle)
        #expect(vm.inputText.isEmpty)
    }

    @Test("Standalone mode setMessages works")
    @MainActor
    func standaloneSetMessages() {
        let vm = ChatViewModel()
        let msgs = [
            ChatMessage(role: .barbara, text: "Hello"),
            ChatMessage(role: .learner, text: "Hi"),
        ]
        vm.setMessages(msgs)
        #expect(vm.messages.count == 2)
    }

    @Test("Standalone mode clearConversation resets")
    @MainActor
    func standaloneClear() {
        let vm = ChatViewModel()
        vm.setMessages([ChatMessage(role: .barbara, text: "Hi")])
        vm.inputText = "test"
        vm.clearConversation()
        #expect(vm.messages.isEmpty)
        #expect(vm.inputText.isEmpty)
    }
}
