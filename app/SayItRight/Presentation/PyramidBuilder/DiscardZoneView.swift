import SwiftUI

/// A drop target for discarding red herring blocks from the pyramid.
///
/// Appears at the bottom of the pyramid canvas. Blocks dragged here are
/// removed from play (but can be retrieved from the discarded pile).
struct DiscardZoneView: View {
    /// Whether a block is currently being dragged near the zone.
    var isHighlighted: Bool = false
    /// Blocks that have been discarded.
    let discardedBlocks: [PyramidBlock]
    /// Called when the user taps a discarded block to retrieve it.
    var onRetrieve: ((PyramidBlock) -> Void)?

    var body: some View {
        VStack(spacing: 8) {
            // Drop target area
            HStack(spacing: 8) {
                Image(systemName: "xmark.bin")
                    .font(.title3)
                Text("Discard")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(isHighlighted ? .red : .secondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 2, dash: isHighlighted ? [] : [8, 4])
                    )
                    .foregroundStyle(isHighlighted ? .red : .secondary.opacity(0.5))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isHighlighted ? Color.red.opacity(0.1) : Color.clear)
                    )
            )
            .scaleEffect(isHighlighted ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHighlighted)
            .accessibilityLabel("Discard zone")
            .accessibilityHint("Drag blocks here to discard them")

            // Discarded blocks (retrievable)
            if !discardedBlocks.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(discardedBlocks) { block in
                            Button {
                                onRetrieve?(block)
                            } label: {
                                Text(block.text)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(.secondary.opacity(0.15))
                                    )
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Retrieve: \(block.text)")
                            .accessibilityHint("Tap to return this block to the unplaced pool")
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Discard Zone — Empty") {
    DiscardZoneView(discardedBlocks: [])
        .padding()
}

#Preview("Discard Zone — Highlighted") {
    DiscardZoneView(isHighlighted: true, discardedBlocks: [])
        .padding()
}

#Preview("Discard Zone — With Discarded Blocks") {
    DiscardZoneView(
        discardedBlocks: [
            PyramidBlock(text: "Irrelevant fact about weather", type: .redHerring),
            PyramidBlock(text: "Unrelated statistic", type: .redHerring),
        ]
    )
    .padding()
}
