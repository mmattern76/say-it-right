import SwiftUI

// MARK: - Drop Zone View

/// Visual indicator for a valid drop position in the pyramid tree.
///
/// Renders as a dashed-border rounded rectangle that pulses when highlighted.
/// When a block is being dragged, drop zones appear at valid placement positions.
/// The nearest zone within snap distance highlights to signal it will accept the drop.
struct DropZoneView: View {
    let zone: DropZone
    var visualState: DropZoneVisualState = .available

    var body: some View {
        RoundedRectangle(cornerRadius: BlockDimensions.cornerRadius)
            .strokeBorder(
                style: StrokeStyle(lineWidth: borderWidth, dash: [8, 4])
            )
            .foregroundStyle(borderColor)
            .background(
                RoundedRectangle(cornerRadius: BlockDimensions.cornerRadius)
                    .fill(fillColor)
            )
            .frame(width: zone.size.width, height: zone.size.height)
            .scaleEffect(visualState == .highlighted ? 1.05 : 1.0)
            .opacity(opacity)
            .animation(.easeInOut(duration: 0.2), value: visualState)
            .accessibilityLabel("Drop zone")
            .accessibilityHint(
                visualState == .highlighted
                    ? "Release to place block here"
                    : "Drag a block here to place it"
            )
    }

    // MARK: - Visual Properties

    private var borderColor: Color {
        switch visualState {
        case .available:
            Color.secondary.opacity(0.5)
        case .highlighted:
            Color.accentColor
        }
    }

    private var fillColor: Color {
        switch visualState {
        case .available:
            Color.secondary.opacity(0.05)
        case .highlighted:
            Color.accentColor.opacity(0.15)
        }
    }

    private var borderWidth: CGFloat {
        switch visualState {
        case .available: 1.5
        case .highlighted: 2.5
        }
    }

    private var opacity: Double {
        switch visualState {
        case .available: 0.6
        case .highlighted: 1.0
        }
    }
}

// MARK: - Drop Zone Overlay

/// Overlay that renders all active drop zones on the pyramid canvas.
///
/// Use this as an overlay on the canvas view. It positions each drop zone
/// at its computed canvas coordinates and applies highlighting based on
/// the currently highlighted zone ID.
struct DropZoneOverlay: View {
    let zones: [DropZone]
    let highlightedZoneID: String?

    var body: some View {
        ZStack {
            ForEach(zones) { zone in
                DropZoneView(
                    zone: zone,
                    visualState: zone.id == highlightedZoneID ? .highlighted : .available
                )
                .position(zone.center)
            }
        }
    }
}

// MARK: - Unplaced Blocks Pool

/// A container displaying the blocks that have not yet been placed in the tree.
///
/// On iPad this appears as a sidebar; on Mac as a top bar.
/// Blocks can be dragged from here onto the pyramid canvas.
struct UnplacedBlocksPool: View {
    let blocks: [PyramidBlock]
    var onDragChanged: ((PyramidBlock, DragGesture.Value) -> Void)?
    var onDragEnded: ((PyramidBlock, DragGesture.Value) -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(blocks) { block in
                    DraggableBlockView(
                        block: block,
                        onDragChanged: { value in
                            onDragChanged?(block, value)
                        },
                        onDragEnded: { value in
                            onDragEnded?(block, value)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Previews

#Preview("Drop Zone — Available") {
    DropZoneView(
        zone: DropZone(
            id: "preview-zone",
            parentID: "root",
            childIndex: 0,
            center: CGPoint(x: 200, y: 150),
            size: CGSize(width: 140, height: 50)
        ),
        visualState: .available
    )
    .padding(40)
}

#Preview("Drop Zone — Highlighted") {
    DropZoneView(
        zone: DropZone(
            id: "preview-zone",
            parentID: "root",
            childIndex: 0,
            center: CGPoint(x: 200, y: 150),
            size: CGSize(width: 140, height: 50)
        ),
        visualState: .highlighted
    )
    .padding(40)
}

#Preview("Drop Zone States Side by Side") {
    DropZoneStatesPreview()
}

/// Shows both visual states for design review.
private struct DropZoneStatesPreview: View {
    var body: some View {
        HStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("Available").font(.caption).foregroundStyle(.secondary)
                DropZoneView(
                    zone: DropZone(
                        id: "a",
                        parentID: "root",
                        childIndex: 0,
                        center: .zero,
                        size: CGSize(width: 140, height: 50)
                    ),
                    visualState: .available
                )
            }
            VStack(spacing: 8) {
                Text("Highlighted").font(.caption).foregroundStyle(.secondary)
                DropZoneView(
                    zone: DropZone(
                        id: "b",
                        parentID: "root",
                        childIndex: 0,
                        center: .zero,
                        size: CGSize(width: 140, height: 50)
                    ),
                    visualState: .highlighted
                )
            }
        }
        .padding(40)
    }
}

#Preview("Drop Zone Overlay") {
    DropZoneOverlayPreview()
}

/// Preview showing multiple drop zones on a canvas.
private struct DropZoneOverlayPreview: View {
    var body: some View {
        ZStack {
            Color(white: 0.95)
            DropZoneOverlay(
                zones: [
                    DropZone(
                        id: "z1",
                        parentID: "root",
                        childIndex: 0,
                        center: CGPoint(x: 200, y: 100),
                        size: CGSize(width: 140, height: 50)
                    ),
                    DropZone(
                        id: "z2",
                        parentID: "root",
                        childIndex: 1,
                        center: CGPoint(x: 400, y: 100),
                        size: CGSize(width: 140, height: 50)
                    ),
                    DropZone(
                        id: "z3",
                        parentID: "child1",
                        childIndex: 0,
                        center: CGPoint(x: 200, y: 220),
                        size: CGSize(width: 140, height: 50)
                    ),
                ],
                highlightedZoneID: "z2"
            )
        }
        .frame(width: 600, height: 400)
    }
}

#Preview("Unplaced Blocks Pool") {
    UnplacedBlocksPool(blocks: [
        PyramidBlock(text: "Climate change is urgent", type: .governingThought),
        PyramidBlock(text: "Rising temperatures", type: .supportPoint),
        PyramidBlock(text: "Arctic ice melting", type: .evidence),
        PyramidBlock(text: "Economic impact", type: .supportPoint),
    ])
    .padding()
}
