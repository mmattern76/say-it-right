import SwiftUI

// MARK: - Draggable Block View

/// A draggable block for the pyramid builder canvas.
///
/// Displays a text snippet colour-coded by block type. Supports drag gesture
/// with tactile feedback: lifts on pickup (scale + shadow), follows finger/cursor
/// smoothly, and snaps back with spring animation when released.
///
/// The block reports drag state changes through its `onDragChanged` and
/// `onDragEnded` callbacks so the parent canvas can handle drop zone logic.
struct DraggableBlockView: View {
    let block: PyramidBlock
    var visualState: BlockVisualState = .idle

    /// Called continuously during drag with the current translation.
    var onDragChanged: ((DragGesture.Value) -> Void)?
    /// Called when the drag ends with the final translation.
    var onDragEnded: ((DragGesture.Value) -> Void)?

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false

    // MARK: - Body

    var body: some View {
        blockContent
            .offset(dragOffset)
            .scaleEffect(currentScale)
            .shadow(
                color: .black.opacity(shadowOpacity),
                radius: shadowRadius,
                x: 0,
                y: shadowRadius / 2
            )
            .zIndex(isDragging ? 1000 : 0)
            .gesture(dragGesture)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragOffset)
            .accessibilityLabel(block.text)
            .accessibilityHint("Draggable block. \(block.type.label).")
            .accessibilityAddTraits(.isButton)
    }

    // MARK: - Block Content

    private var blockContent: some View {
        Text(block.text)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .padding(.horizontal, BlockDimensions.horizontalPadding)
            .padding(.vertical, BlockDimensions.verticalPadding)
            .frame(
                minWidth: BlockDimensions.minWidth,
                maxWidth: BlockDimensions.maxWidth,
                minHeight: BlockDimensions.minHeight,
                maxHeight: BlockDimensions.maxHeight
            )
            .background(backgroundShape)
            .overlay(borderOverlay)
    }

    // MARK: - Background & Border

    private var backgroundShape: some View {
        RoundedRectangle(cornerRadius: BlockDimensions.cornerRadius)
            .fill(blockColor)
    }

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: BlockDimensions.cornerRadius)
            .strokeBorder(borderColor, lineWidth: borderWidth)
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                isDragging = true
                dragOffset = value.translation
                onDragChanged?(value)
            }
            .onEnded { value in
                isDragging = false
                onDragEnded?(value)
                // Snap back — parent can override position if dropped in valid zone.
                dragOffset = .zero
            }
    }

    // MARK: - Visual State Properties

    private var effectiveState: BlockVisualState {
        isDragging ? .dragging : visualState
    }

    private var currentScale: CGFloat {
        switch effectiveState {
        case .idle: 1.0
        case .hovering: 1.02
        case .dragging: 1.05
        case .placed: 1.0
        case .error: 1.0
        }
    }

    private var shadowOpacity: Double {
        switch effectiveState {
        case .idle: 0.08
        case .hovering: 0.12
        case .dragging: 0.25
        case .placed: 0.06
        case .error: 0.08
        }
    }

    private var shadowRadius: CGFloat {
        switch effectiveState {
        case .idle: 2
        case .hovering: 4
        case .dragging: 12
        case .placed: 1
        case .error: 2
        }
    }

    private var blockColor: Color {
        switch effectiveState {
        case .error: Color.red.opacity(0.7)
        default: block.type.color
        }
    }

    private var borderColor: Color {
        switch effectiveState {
        case .idle: .white.opacity(0.15)
        case .hovering: .white.opacity(0.3)
        case .dragging: .white.opacity(0.4)
        case .placed: .white.opacity(0.2)
        case .error: .red
        }
    }

    private var borderWidth: CGFloat {
        switch effectiveState {
        case .error: 2
        default: 1
        }
    }
}

// MARK: - Previews

#Preview("All Block Types — Idle") {
    VStack(spacing: 16) {
        ForEach(BlockType.allCases, id: \.rawValue) { type in
            DraggableBlockView(
                block: PyramidBlock(
                    text: type.label,
                    type: type
                )
            )
        }
    }
    .padding()
    .background(Color.clear)
}

#Preview("Text Length Variations") {
    VStack(spacing: 16) {
        DraggableBlockView(
            block: PyramidBlock(text: "Short", type: .governingThought)
        )
        DraggableBlockView(
            block: PyramidBlock(text: "Medium length claim here", type: .supportPoint)
        )
        DraggableBlockView(
            block: PyramidBlock(
                text: "This is a longer piece of evidence that should wrap to multiple lines",
                type: .evidence
            )
        )
    }
    .padding()
}

#Preview("All Visual States") {
    DraggableBlockVisualStatesPreview()
}

/// Shows every visual state side by side for design review.
private struct DraggableBlockVisualStatesPreview: View {
    private let states: [(String, BlockVisualState)] = [
        ("Idle", .idle),
        ("Hovering", .hovering),
        ("Dragging", .dragging),
        ("Placed", .placed),
        ("Error", .error),
    ]

    var body: some View {
        VStack(spacing: 20) {
            ForEach(states, id: \.0) { label, state in
                VStack(spacing: 4) {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    DraggableBlockView(
                        block: PyramidBlock(
                            text: "Climate policy requires action",
                            type: .governingThought
                        ),
                        visualState: state
                    )
                }
            }
        }
        .padding(32)
    }
}

#Preview("Interactive Drag") {
    DraggableBlockInteractivePreview()
}

/// Interactive preview to test drag behaviour.
private struct DraggableBlockInteractivePreview: View {
    @State private var statusText = "Drag a block to see it in action"

    var body: some View {
        VStack(spacing: 32) {
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)

            DraggableBlockView(
                block: PyramidBlock(
                    text: "Drag me around!",
                    type: .supportPoint
                ),
                onDragChanged: { value in
                    let x = Int(value.translation.width)
                    let y = Int(value.translation.height)
                    statusText = "Dragging: (\(x), \(y))"
                },
                onDragEnded: { _ in
                    statusText = "Dropped — snapped back"
                }
            )

            DraggableBlockView(
                block: PyramidBlock(
                    text: "Me too!",
                    type: .evidence
                )
            )
        }
        .padding(40)
    }
}
