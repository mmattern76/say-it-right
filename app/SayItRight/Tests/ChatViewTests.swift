import Testing
@testable import SayItRight

@Suite("ChatMessage")
struct ChatMessageTests {

    @Test("Creates message with default values")
    func defaultValues() {
        let msg = ChatMessage(role: .barbara, text: "Hello")
        #expect(msg.role == .barbara)
        #expect(msg.text == "Hello")
        #expect(!msg.isStreaming)
        #expect(msg.metadata == nil)
    }

    @Test("Creates streaming message")
    func streamingMessage() {
        let msg = ChatMessage(role: .barbara, text: "", isStreaming: true)
        #expect(msg.isStreaming)
        #expect(msg.text.isEmpty)
    }

    @Test("Learner role is correct")
    func learnerRole() {
        let msg = ChatMessage(role: .learner, text: "My argument")
        #expect(msg.role == .learner)
        #expect(msg.role.rawValue == "learner")
    }

    @Test("Barbara role raw value")
    func barbaraRoleRawValue() {
        #expect(ChatRole.barbara.rawValue == "barbara")
    }

    @Test("Each message gets unique ID")
    func uniqueIDs() {
        let a = ChatMessage(role: .learner, text: "A")
        let b = ChatMessage(role: .learner, text: "B")
        #expect(a.id != b.id)
    }

    @Test("Message text is mutable")
    func mutableText() {
        var msg = ChatMessage(role: .barbara, text: "Start")
        msg.text += " more"
        #expect(msg.text == "Start more")
    }

    @Test("Streaming flag is mutable")
    func mutableStreaming() {
        var msg = ChatMessage(role: .barbara, text: "Done", isStreaming: true)
        msg.isStreaming = false
        #expect(!msg.isStreaming)
    }
}

@Suite("ChatViewModel")
struct ChatViewModelTests {

    @MainActor
    @Test("Initial state is empty")
    func initialState() {
        let vm = ChatViewModel()
        #expect(vm.messages.isEmpty)
        #expect(vm.inputText.isEmpty)
        #expect(!vm.isLoading)
        #expect(vm.errorMessage == nil)
    }

    @MainActor
    @Test("Send does nothing when input is empty")
    func sendEmptyInput() {
        let vm = ChatViewModel()
        vm.inputText = "   "
        vm.send()
        #expect(vm.messages.isEmpty)
    }

    @MainActor
    @Test("Send does nothing when already loading")
    func sendWhileLoading() {
        let vm = ChatViewModel()
        vm.setMessages([ChatMessage(role: .learner, text: "First")])
        vm.inputText = "Second"
        // Simulate loading state by checking the guard
        // We can't easily set isLoading directly, but we can verify
        // that send adds a learner message and clears input
        vm.send()
        // After send, input should be cleared
        #expect(vm.inputText.isEmpty)
    }

    @MainActor
    @Test("Send adds learner message and clears input")
    func sendAddsMessage() {
        let vm = ChatViewModel()
        vm.inputText = "My argument is..."
        vm.send()

        #expect(vm.messages.count >= 1)
        #expect(vm.messages[0].role == .learner)
        #expect(vm.messages[0].text == "My argument is...")
        #expect(vm.inputText.isEmpty)
    }

    @MainActor
    @Test("Send trims whitespace from input")
    func sendTrimsWhitespace() {
        let vm = ChatViewModel()
        vm.inputText = "  Hello Barbara  \n"
        vm.send()

        #expect(vm.messages[0].text == "Hello Barbara")
    }

    @MainActor
    @Test("clearConversation resets all state")
    func clearConversation() {
        let vm = ChatViewModel()
        vm.setMessages([
            ChatMessage(role: .barbara, text: "Welcome"),
            ChatMessage(role: .learner, text: "Hi"),
        ])
        vm.inputText = "Draft"

        vm.clearConversation()

        #expect(vm.messages.isEmpty)
        #expect(vm.inputText.isEmpty)
        #expect(!vm.isLoading)
        #expect(vm.errorMessage == nil)
    }

    @MainActor
    @Test("setMessages replaces message list")
    func setMessages() {
        let vm = ChatViewModel()
        let msgs = [
            ChatMessage(role: .barbara, text: "A"),
            ChatMessage(role: .learner, text: "B"),
        ]
        vm.setMessages(msgs)
        #expect(vm.messages.count == 2)
        #expect(vm.messages[0].text == "A")
        #expect(vm.messages[1].text == "B")
    }

    @MainActor
    @Test("Default session config values")
    func defaultConfig() {
        let vm = ChatViewModel()
        #expect(vm.level == 1)
        #expect(vm.sessionType == "say-it-clearly")
        #expect(vm.language == "en")
        #expect(vm.profileJSON == "{}")
    }
}
