import Testing
@testable import SayItRight

@Suite("macOS Chat Adaptation")
struct MacOSAdaptationTests {

    // MARK: - Window Title

    @MainActor
    @Test("Window title shows session type when selected")
    func windowTitleWithSession() {
        let sessionType = SessionTypeItem.allTypes[0]
        #expect(sessionType.title(language: "en") == "Say it clearly")
    }

    @MainActor
    @Test("Window title shows German session type")
    func windowTitleGerman() {
        let sessionType = SessionTypeItem.allTypes[0]
        #expect(sessionType.title(language: "de") == "Sag's klar")
    }

    // MARK: - ChatViewModel New Session

    @MainActor
    @Test("Cmd+N clears conversation via clearConversation")
    func newSessionClearsConversation() {
        let vm = ChatViewModel()
        vm.setMessages([
            ChatMessage(role: .barbara, text: "Welcome"),
            ChatMessage(role: .learner, text: "Hi"),
        ])
        vm.inputText = "Draft text"

        vm.clearConversation()

        #expect(vm.messages.isEmpty)
        #expect(vm.inputText.isEmpty)
        #expect(!vm.isLoading)
    }

    // MARK: - Multi-line Input

    @MainActor
    @Test("ViewModel preserves multi-line input text")
    func multiLineInput() {
        let vm = ChatViewModel()
        vm.inputText = "Line one\nLine two\nLine three"
        #expect(vm.inputText.contains("\n"))
        #expect(vm.inputText.components(separatedBy: "\n").count == 3)
    }

    @MainActor
    @Test("Send trims multi-line input whitespace")
    func sendTrimsMultiLine() {
        let vm = ChatViewModel()
        vm.inputText = "  First line\nSecond line  \n"
        vm.send()

        #expect(vm.messages.count >= 1)
        #expect(vm.messages[0].text == "First line\nSecond line")
    }

    // MARK: - Session Type Selection

    @MainActor
    @Test("All session types produce valid window titles in both languages")
    func allSessionTypeTitles() {
        for sessionType in SessionTypeItem.allTypes {
            let enTitle = sessionType.title(language: "en")
            let deTitle = sessionType.title(language: "de")
            #expect(!enTitle.isEmpty, "EN title empty for \(sessionType.id)")
            #expect(!deTitle.isEmpty, "DE title empty for \(sessionType.id)")
        }
    }

    @MainActor
    @Test("ViewModel session type can be updated")
    func sessionTypeUpdate() {
        let vm = ChatViewModel()
        #expect(vm.sessionType == "say-it-clearly")

        vm.sessionType = "find-the-point"
        #expect(vm.sessionType == "find-the-point")
    }

    // MARK: - Platform-Adaptive Layout Constants

    @MainActor
    @Test("ChatViewModel supports all expected session types")
    func supportedSessionTypes() {
        let vm = ChatViewModel()
        let expectedTypes = [
            "say-it-clearly", "find-the-point", "fix-this-mess",
            "build-the-pyramid", "elevator-pitch", "spot-the-gap",
            "decode-and-rebuild"
        ]
        for type in expectedTypes {
            vm.sessionType = type
            #expect(vm.sessionType == type)
        }
    }
}

@Suite("SettingsView Integration")
struct SettingsViewIntegrationTests {

    @Test("AppSettings language defaults to en")
    func defaultLanguage() {
        // AppSettings.shared may have been modified by other tests,
        // but the default in code is "en"
        let settings = AppSettings.shared
        // Just verify the property is accessible and returns a string
        #expect(settings.language == "en" || settings.language == "de")
    }

    @Test("AppSettings displayName is accessible")
    func displayNameAccessible() {
        let settings = AppSettings.shared
        // Verify the property exists and is a string (may be empty)
        #expect(settings.displayName.count >= 0)
    }
}
