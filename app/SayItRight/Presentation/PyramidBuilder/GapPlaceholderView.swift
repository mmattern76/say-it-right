import SwiftUI

// MARK: - Gap Placeholder View

/// A dashed-border rectangle that pulses to indicate a missing block
/// in the pyramid (MECE gap).
///
/// Positioned by the layout engine at the location where the missing
/// block should appear. Uses a dashed outline with a pulsing animation
/// to draw attention without being distracting.
///
/// Colour-blind-safe: uses a distinct dashed pattern (not just colour)
/// to differentiate from other feedback states.
struct GapPlaceholderView: View {
    let gap: GapPlacement

    @State private var isPulsing: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: BlockDimensions.cornerRadius)
            .strokeBorder(
                style: StrokeStyle(lineWidth: 2, dash: [6, 4])
            )
            .foregroundStyle(FeedbackPalette.gap)
            .background(
                RoundedRectangle(cornerRadius: BlockDimensions.cornerRadius)
                    .fill(FeedbackPalette.gap.opacity(0.06))
            )
            .overlay(gapIcon)
            .frame(
                width: BlockDimensions.minWidth + 20,
                height: BlockDimensions.minHeight
            )
            .opacity(shouldReduceMotion ? 0.8 : (isPulsing ? 0.5 : 1.0))
            .animation(
                shouldReduceMotion
                    ? nil
                    : .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                if !shouldReduceMotion {
                    isPulsing = true
                }
            }
            .accessibilityLabel("Missing block")
            .accessibilityHint("A block is needed here to complete the group")
    }

    private var gapIcon: some View {
        Image(systemName: "plus.circle.dashed")
            .font(.title3)
            .foregroundStyle(FeedbackPalette.gap.opacity(0.6))
    }
}

// MARK: - Gap Placeholder Overlay

/// Renders gap placeholders at computed positions on the pyramid canvas.
///
/// Uses the layout engine's node positions to calculate where missing
/// blocks should appear — positioned as additional children of the
/// gap's parent block.
struct GapPlaceholderOverlay: View {
    let gaps: [GapPlacement]
    let nodeLayouts: [String: NodeLayout]
    let layoutEngine: TreeLayoutEngine

    var body: some View {
        ZStack {
            ForEach(gaps) { gap in
                if let position = gapPosition(for: gap) {
                    GapPlaceholderView(gap: gap)
                        .position(position)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: gaps.map(\.id))
    }

    /// Calculate the position for a gap placeholder.
    ///
    /// Places the gap to the right of the parent's last visible child,
    /// or directly below the parent if no children are visible.
    private func gapPosition(for gap: GapPlacement) -> CGPoint? {
        guard let parentLayout = nodeLayouts[gap.parentBlockID] else {
            return nil
        }

        // Position below parent.
        let childY = parentLayout.center.y + parentLayout.size.height / 2
            + layoutEngine.verticalSpacing + BlockDimensions.minHeight / 2

        // Count how many gaps are under this same parent (for stacking).
        let gapsUnderSameParent = gaps.filter { $0.parentBlockID == gap.parentBlockID }
        let gapIndex = gapsUnderSameParent.firstIndex(where: { $0.id == gap.id }) ?? 0

        // Find the rightmost child under this parent.
        let childLayouts = nodeLayouts.filter { key, layout in
            key != gap.parentBlockID
                && abs(layout.center.y - childY) < layoutEngine.verticalSpacing
                && abs(layout.center.x - parentLayout.center.x) < 400
        }

        let siblingXPositions = childLayouts.values.map(\.center.x)
        let rightmostX = siblingXPositions.max() ?? (parentLayout.center.x - 80)
        let gapWidth = BlockDimensions.minWidth + 20
        let gapX = rightmostX
            + gapWidth / 2
            + layoutEngine.horizontalSpacing
            + CGFloat(gapIndex) * (gapWidth + layoutEngine.horizontalSpacing)

        return CGPoint(x: gapX, y: childY)
    }
}

// MARK: - Previews

#Preview("Gap Placeholder") {
    GapPlaceholderView(
        gap: GapPlacement(parentBlockID: "SP1", missingBlockID: "E2")
    )
    .padding(40)
}

#Preview("Multiple Gap Placeholders") {
    VStack(spacing: 20) {
        GapPlaceholderView(
            gap: GapPlacement(parentBlockID: "SP1", missingBlockID: "E1")
        )
        GapPlaceholderView(
            gap: GapPlacement(parentBlockID: "SP2", missingBlockID: "E3")
        )
    }
    .padding(40)
}
