import SwiftUI

// MARK: - Pyramid Feedback Overlay

/// Composite overlay that renders all validation feedback on the pyramid canvas.
///
/// Ties together:
/// - Per-block glow/shake via ``FeedbackGlowModifier``
/// - Gap placeholders via ``GapPlaceholderOverlay``
/// - Celebration effect via ``CelebrationEffectView``
/// - A "Check my work" toggle button
///
/// This view reads from the validation result and applies feedback states
/// to blocks. It does not own the validation logic — that lives in
/// ``MECEValidationEngine``.
struct PyramidFeedbackOverlay: View {
    /// Per-block feedback states, keyed by block ID.
    let blockFeedbackStates: [String: BlockFeedbackState]
    /// Gap placements for missing blocks.
    let gaps: [GapPlacement]
    /// Node layout positions for placed blocks.
    let nodeLayouts: [String: NodeLayout]
    /// Layout engine for gap positioning.
    let layoutEngine: TreeLayoutEngine
    /// Whether the pyramid is fully correct.
    let isPyramidComplete: Bool
    /// Feedback configuration (on/off, auto/manual).
    @Binding var configuration: FeedbackConfiguration

    @State private var showCelebration: Bool = false

    var body: some View {
        ZStack {
            if configuration.isEnabled {
                // Gap placeholders behind blocks.
                GapPlaceholderOverlay(
                    gaps: gaps,
                    nodeLayouts: nodeLayouts,
                    layoutEngine: layoutEngine
                )

                // MECE overlap connections (red lines between overlapping blocks).
                // Individual block feedback is applied via .validationFeedback()
                // modifier on each DraggableBlockView — not rendered here.
            }

            // Celebration effect (rendered on top of everything).
            CelebrationEffectView(isActive: $showCelebration)
        }
        .onChange(of: isPyramidComplete) { _, isComplete in
            if isComplete && configuration.isEnabled {
                showCelebration = true
            }
        }
    }
}

// MARK: - Check My Work Button

/// Button to toggle validation feedback visibility.
///
/// Used in manual feedback mode where the learner checks their own work
/// before revealing the answer.
struct CheckMyWorkButton: View {
    @Binding var configuration: FeedbackConfiguration
    /// Callback invoked when the user requests validation.
    var onValidate: () -> Void

    var body: some View {
        Button {
            if configuration.isEnabled {
                // Toggle off.
                configuration.isEnabled = false
            } else {
                // Run validation and show.
                onValidate()
                configuration.isEnabled = true
            }
        } label: {
            Label(
                configuration.isEnabled ? "Hide Feedback" : "Check My Work",
                systemImage: configuration.isEnabled
                    ? "eye.slash.fill"
                    : "checkmark.shield.fill"
            )
            .font(.subheadline.weight(.medium))
        }
        .buttonStyle(.bordered)
        .tint(configuration.isEnabled ? .secondary : .accentColor)
        .accessibilityLabel(
            configuration.isEnabled
                ? "Hide validation feedback"
                : "Check my work — show validation feedback"
        )
    }
}

// MARK: - Previews

#Preview("Feedback Overlay — With Gaps") {
    FeedbackOverlayPreview()
}

private struct FeedbackOverlayPreview: View {
    @State private var config = FeedbackConfiguration(isEnabled: true)

    private let engine = TreeLayoutEngine()

    private var tree: TreeNode {
        TreeNode(id: "root", children: [
            TreeNode(id: "sp1", children: [
                TreeNode(id: "e1"),
            ]),
            TreeNode(id: "sp2"),
        ])
    }

    var body: some View {
        GeometryReader { geo in
            let layouts = engine.layout(root: tree, in: geo.size)

            ZStack {
                Color(white: 0.95)

                // Blocks (simplified).
                ForEach(Array(layouts.keys.sorted()), id: \.self) { nodeID in
                    if let layout = layouts[nodeID] {
                        let feedback: BlockFeedbackState = {
                            switch nodeID {
                            case "root": .correct
                            case "sp1": .correct
                            case "e1": .misplaced
                            case "sp2": .meceOverlap
                            default: .none
                            }
                        }()

                        RoundedRectangle(cornerRadius: BlockDimensions.cornerRadius)
                            .fill(Color.blue.opacity(0.6))
                            .frame(width: layout.size.width, height: layout.size.height)
                            .overlay {
                                Text(nodeID)
                                    .font(.caption)
                                    .foregroundStyle(.white)
                            }
                            .validationFeedback(feedback)
                            .position(layout.center)
                    }
                }

                // Feedback overlay with gaps.
                PyramidFeedbackOverlay(
                    blockFeedbackStates: [
                        "root": .correct,
                        "sp1": .correct,
                        "e1": .misplaced,
                        "sp2": .meceOverlap,
                    ],
                    gaps: [
                        GapPlacement(parentBlockID: "sp1", missingBlockID: "e2"),
                        GapPlacement(parentBlockID: "sp2", missingBlockID: "e3"),
                    ],
                    nodeLayouts: layouts,
                    layoutEngine: engine,
                    isPyramidComplete: false,
                    configuration: $config
                )
            }
        }
        .frame(height: 400)
        .padding()
    }
}

#Preview("Check My Work Button") {
    CheckMyWorkButtonPreview()
}

private struct CheckMyWorkButtonPreview: View {
    @State private var config = FeedbackConfiguration()

    var body: some View {
        VStack(spacing: 20) {
            CheckMyWorkButton(configuration: $config) {
                // Simulate validation.
            }
            Text(config.isEnabled ? "Feedback: ON" : "Feedback: OFF")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(40)
    }
}

#Preview("All Feedback States on Blocks") {
    AllFeedbackStatesPreview()
}

private struct AllFeedbackStatesPreview: View {
    private let states: [(String, BlockFeedbackState)] = [
        ("Correct", .correct),
        ("Misplaced", .misplaced),
        ("MECE Overlap", .meceOverlap),
        ("None", .none),
    ]

    var body: some View {
        VStack(spacing: 20) {
            ForEach(states, id: \.0) { label, state in
                VStack(spacing: 4) {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    RoundedRectangle(cornerRadius: BlockDimensions.cornerRadius)
                        .fill(Color.blue.opacity(0.6))
                        .frame(width: 200, height: 60)
                        .overlay {
                            Text("Sample Block")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                        }
                        .validationFeedback(state)
                }
            }
        }
        .padding(32)
    }
}
