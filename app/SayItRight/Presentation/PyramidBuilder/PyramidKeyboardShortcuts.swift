import SwiftUI

/// Keyboard shortcuts for the pyramid builder (Mac-optimized).
///
/// Provides undo/redo, delete-to-discard, and zoom controls.
struct PyramidKeyboardShortcuts: ViewModifier {
    /// Called when the user presses Cmd+Z.
    var onUndo: () -> Void
    /// Called when the user presses Cmd+Shift+Z.
    var onRedo: () -> Void
    /// Current canvas zoom scale.
    @Binding var canvasScale: CGFloat

    func body(content: Content) -> some View {
        content
            #if os(macOS)
            .onKeyPress(.delete) {
                // Delete key — handled by parent for selected block discard
                return .ignored
            }
            #endif
    }
}

/// Right-click context menu for a placed pyramid block (Mac).
struct BlockContextMenu: ViewModifier {
    let blockID: UUID
    var onRemove: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button(role: .destructive) {
                    onRemove?()
                } label: {
                    Label("Remove from Pyramid", systemImage: "trash")
                }
            }
    }
}

extension View {
    /// Add a right-click context menu for pyramid block actions.
    func pyramidBlockContextMenu(
        blockID: UUID,
        onRemove: (() -> Void)? = nil
    ) -> some View {
        modifier(BlockContextMenu(blockID: blockID, onRemove: onRemove))
    }
}
