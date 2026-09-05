import SwiftUI

/// Right-click / long-press context menu for a placed pyramid block.
///
/// On Mac this is the right-click menu; on iPad and iPhone a long press.
/// It gives a placed block the same "take it back out" action that dragging
/// it to the discard zone does, without needing the drag.
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
    /// Add a context menu for pyramid block actions.
    func pyramidBlockContextMenu(
        blockID: UUID,
        onRemove: (() -> Void)? = nil
    ) -> some View {
        modifier(BlockContextMenu(blockID: blockID, onRemove: onRemove))
    }
}
