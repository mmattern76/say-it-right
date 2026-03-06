#if os(macOS)
import SwiftUI
import AppKit

/// A multi-line text input for macOS that sends on Enter and inserts
/// a newline on Shift+Enter.
///
/// Uses `NSTextView` via `NSViewRepresentable` to intercept key events
/// before SwiftUI processes them. This gives the desktop-native feel
/// expected for a Mac chat interface: keyboard-first, multi-line editing,
/// and the standard Enter-to-send convention.
struct MacChatInputView: NSViewRepresentable {
    @Binding var text: String
    var onSend: () -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = .systemFont(ofSize: NSFont.systemFontSize)
        textView.textColor = .labelColor
        textView.backgroundColor = .clear
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainerInset = NSSize(width: 0, height: 4)
        textView.textContainer?.widthTracksTextView = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false

        // Remove scroll view border for clean appearance
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = false
        scrollView.drawsBackground = false

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        // Only update if the text has changed externally (e.g. cleared after send)
        if textView.string != text {
            textView.string = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSend: onSend)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        var onSend: () -> Void

        init(text: Binding<String>, onSend: @escaping () -> Void) {
            self.text = text
            self.onSend = onSend
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
        }

        /// Intercept Return key: plain Return sends, Shift+Return inserts newline.
        func textView(
            _ textView: NSTextView,
            doCommandBy commandSelector: Selector
        ) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                let flags = NSApp.currentEvent?.modifierFlags ?? []
                if flags.contains(.shift) {
                    // Shift+Enter: insert actual newline
                    textView.insertNewlineIgnoringFieldEditor(nil)
                    text.wrappedValue = textView.string
                    return true
                } else {
                    // Enter: send message
                    onSend()
                    return true
                }
            }
            return false
        }
    }
}

// MARK: - Previews

#Preview("Mac Chat Input — Empty") {
    MacChatInputView(text: .constant(""), onSend: {})
        .frame(width: 400, height: 60)
        .padding()
}

#Preview("Mac Chat Input — With Text") {
    MacChatInputView(
        text: .constant("I think the main argument is that renewable energy reduces long-term costs."),
        onSend: {}
    )
    .frame(width: 400, height: 60)
    .padding()
}

#Preview("Mac Chat Input — Multi-line") {
    MacChatInputView(
        text: .constant("First point: cost reduction.\nSecond point: environmental impact.\nThird point: energy independence."),
        onSend: {}
    )
    .frame(width: 400, height: 100)
    .padding()
}
#endif
