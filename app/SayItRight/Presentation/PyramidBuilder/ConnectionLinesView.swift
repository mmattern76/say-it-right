import SwiftUI

// MARK: - Connection

/// A parent-child connection in the pyramid tree.
///
/// Stores the node IDs so the view can look up current positions
/// from the layout dictionary, enabling real-time updates during drag.
struct PyramidConnection: Identifiable, Sendable, Equatable {
    var id: String { "\(parentID)->\(childID)" }
    let parentID: String
    let childID: String
}

// MARK: - Connection Line Style

/// Visual styling for connection lines.
enum ConnectionLineStyle {
    /// Default subtle line.
    case normal
    /// Highlighted (e.g., during drag preview).
    case highlighted

    var lineWidth: CGFloat {
        switch self {
        case .normal: 1.5
        case .highlighted: 2.0
        }
    }

    var color: Color {
        switch self {
        case .normal: Color.secondary.opacity(0.35)
        case .highlighted: Color.secondary.opacity(0.55)
        }
    }
}

// MARK: - Connection Lines Canvas

/// Renders connection lines between parent and child blocks in the pyramid.
///
/// Uses a SwiftUI `Canvas` for performant rendering of all lines in a
/// single draw pass. Lines are quadratic bezier curves drawn from the
/// bottom-centre of parent blocks to the top-centre of child blocks.
///
/// This view is designed to be layered *behind* the block views
/// (lower zIndex) so lines never obscure block content.
struct ConnectionLinesView: View {
    /// Current layout positions for all nodes (keyed by node ID).
    let nodeLayouts: [String: NodeLayout]

    /// Active connections to draw.
    let connections: [PyramidConnection]

    /// IDs of connections currently being animated in (appear).
    var appearingConnectionIDs: Set<String> = []

    /// IDs of connections currently being animated out (disappear).
    var disappearingConnectionIDs: Set<String> = []

    /// Optional override positions for nodes being dragged.
    /// When a placed block is dragged, its centre is updated here
    /// so connection lines follow in real time.
    var dragOverrides: [String: CGPoint] = [:]

    var body: some View {
        Canvas { context, size in
            for connection in connections {
                guard let parentLayout = nodeLayouts[connection.parentID],
                      let childLayout = nodeLayouts[connection.childID] else {
                    continue
                }

                let parentCenter = dragOverrides[connection.parentID] ?? parentLayout.center
                let childCenter = dragOverrides[connection.childID] ?? childLayout.center

                // Parent bottom-centre
                let startPoint = CGPoint(
                    x: parentCenter.x,
                    y: parentCenter.y + parentLayout.size.height / 2
                )

                // Child top-centre
                let endPoint = CGPoint(
                    x: childCenter.x,
                    y: childCenter.y - childLayout.size.height / 2
                )

                let path = Self.bezierPath(from: startPoint, to: endPoint)

                let isDisappearing = disappearingConnectionIDs.contains(connection.id)
                let style: ConnectionLineStyle = isDisappearing ? .normal : .normal

                context.stroke(
                    path,
                    with: .color(style.color),
                    lineWidth: style.lineWidth
                )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Bezier Path

    /// Creates a quadratic bezier curve from parent bottom-centre to child top-centre.
    ///
    /// The control point sits at the vertical midpoint, producing a smooth
    /// curve that avoids sharp angles even for diagonal connections.
    static func bezierPath(from start: CGPoint, to end: CGPoint) -> Path {
        let midY = (start.y + end.y) / 2

        var path = Path()
        path.move(to: start)
        path.addCurve(
            to: end,
            control1: CGPoint(x: start.x, y: midY),
            control2: CGPoint(x: end.x, y: midY)
        )
        return path
    }
}

// MARK: - Animated Connection Lines View

/// Wraps ``ConnectionLinesView`` with appear/disappear animations
/// for individual connections.
///
/// When connections are added, they fade and scale in.
/// When connections are removed, they fade out before removal.
struct AnimatedConnectionLinesView: View {
    let nodeLayouts: [String: NodeLayout]
    let connections: [PyramidConnection]
    var dragOverrides: [String: CGPoint] = [:]

    @State private var visibleConnectionIDs: Set<String> = []

    var body: some View {
        ConnectionLinesView(
            nodeLayouts: nodeLayouts,
            connections: connections,
            dragOverrides: dragOverrides
        )
        .opacity(visibleConnectionIDs.isEmpty && !connections.isEmpty ? 0 : 1)
        .animation(.easeInOut(duration: 0.3), value: visibleConnectionIDs)
        .onChange(of: connections) { oldValue, newValue in
            let newIDs = Set(newValue.map(\.id))
            let oldIDs = Set(oldValue.map(\.id))
            let added = newIDs.subtracting(oldIDs)

            if !added.isEmpty {
                withAnimation(.easeInOut(duration: 0.3)) {
                    visibleConnectionIDs.formUnion(added)
                }
            }

            let removed = oldIDs.subtracting(newIDs)
            if !removed.isEmpty {
                withAnimation(.easeOut(duration: 0.25)) {
                    visibleConnectionIDs.subtract(removed)
                }
            }
        }
        .onAppear {
            visibleConnectionIDs = Set(connections.map(\.id))
        }
    }
}

// MARK: - Connection Extraction

extension TreeNode {
    /// Extracts all parent-child connections from the tree recursively.
    ///
    /// Returns a flat list of ``PyramidConnection`` values suitable for
    /// passing directly to ``ConnectionLinesView``.
    func extractConnections() -> [PyramidConnection] {
        var result: [PyramidConnection] = []
        collectConnections(into: &result)
        return result
    }

    private func collectConnections(into result: inout [PyramidConnection]) {
        for child in children {
            result.append(PyramidConnection(parentID: id, childID: child.id))
            child.collectConnections(into: &result)
        }
    }
}

// MARK: - Previews

#Preview("Simple Pyramid") {
    ConnectionLinesPreview()
}

/// Preview showing connection lines for a simple 3-level pyramid.
private struct ConnectionLinesPreview: View {
    private let engine = TreeLayoutEngine()

    private var tree: TreeNode {
        TreeNode(id: "root", children: [
            TreeNode(id: "a", children: [
                TreeNode(id: "a1"),
                TreeNode(id: "a2"),
            ]),
            TreeNode(id: "b", children: [
                TreeNode(id: "b1"),
            ]),
            TreeNode(id: "c"),
        ])
    }

    var body: some View {
        GeometryReader { geo in
            let layouts = engine.layout(root: tree, in: geo.size)
            let connections = tree.extractConnections()

            ZStack {
                // Lines behind blocks
                ConnectionLinesView(
                    nodeLayouts: layouts,
                    connections: connections
                )

                // Blocks on top
                ForEach(Array(layouts.keys.sorted()), id: \.self) { nodeID in
                    if let layout = layouts[nodeID] {
                        RoundedRectangle(cornerRadius: BlockDimensions.cornerRadius)
                            .fill(Color.blue.opacity(0.6))
                            .frame(width: layout.size.width, height: layout.size.height)
                            .overlay {
                                Text(nodeID)
                                    .font(.caption)
                                    .foregroundStyle(.white)
                            }
                            .position(layout.center)
                    }
                }
            }
        }
        .frame(height: 400)
        .padding()
    }
}

#Preview("Unbalanced Tree") {
    UnbalancedTreePreview()
}

/// Preview with an unbalanced tree to verify crossing lines look clean.
private struct UnbalancedTreePreview: View {
    private let engine = TreeLayoutEngine()

    private var tree: TreeNode {
        TreeNode(id: "root", children: [
            TreeNode(id: "left", children: [
                TreeNode(id: "l1"),
                TreeNode(id: "l2"),
                TreeNode(id: "l3"),
            ]),
            TreeNode(id: "right"),
        ])
    }

    var body: some View {
        GeometryReader { geo in
            let layouts = engine.layout(root: tree, in: geo.size)
            let connections = tree.extractConnections()

            ZStack {
                ConnectionLinesView(
                    nodeLayouts: layouts,
                    connections: connections
                )

                ForEach(Array(layouts.keys.sorted()), id: \.self) { nodeID in
                    if let layout = layouts[nodeID] {
                        RoundedRectangle(cornerRadius: BlockDimensions.cornerRadius)
                            .fill(Color.teal.opacity(0.6))
                            .frame(width: layout.size.width, height: layout.size.height)
                            .overlay {
                                Text(nodeID)
                                    .font(.caption)
                                    .foregroundStyle(.white)
                            }
                            .position(layout.center)
                    }
                }
            }
        }
        .frame(height: 400)
        .padding()
    }
}

#Preview("Drag Override") {
    DragOverridePreview()
}

/// Interactive preview demonstrating real-time line updates during drag.
private struct DragOverridePreview: View {
    private let engine = TreeLayoutEngine()
    @State private var dragOffset: CGSize = .zero

    private var tree: TreeNode {
        TreeNode(id: "root", children: [
            TreeNode(id: "child-a"),
            TreeNode(id: "child-b"),
        ])
    }

    var body: some View {
        GeometryReader { geo in
            let layouts = engine.layout(root: tree, in: geo.size)
            let connections = tree.extractConnections()

            let overrides: [String: CGPoint] = {
                guard let original = layouts["child-a"]?.center else { return [:] }
                return ["child-a": CGPoint(
                    x: original.x + dragOffset.width,
                    y: original.y + dragOffset.height
                )]
            }()

            ZStack {
                ConnectionLinesView(
                    nodeLayouts: layouts,
                    connections: connections,
                    dragOverrides: overrides
                )

                ForEach(Array(layouts.keys.sorted()), id: \.self) { nodeID in
                    if let layout = layouts[nodeID] {
                        let position: CGPoint = {
                            if nodeID == "child-a" {
                                return CGPoint(
                                    x: layout.center.x + dragOffset.width,
                                    y: layout.center.y + dragOffset.height
                                )
                            }
                            return layout.center
                        }()

                        RoundedRectangle(cornerRadius: BlockDimensions.cornerRadius)
                            .fill(nodeID == "child-a" ? Color.orange.opacity(0.7) : Color.blue.opacity(0.6))
                            .frame(width: layout.size.width, height: layout.size.height)
                            .overlay {
                                Text(nodeID)
                                    .font(.caption)
                                    .foregroundStyle(.white)
                            }
                            .position(position)
                            .gesture(
                                nodeID == "child-a"
                                ? DragGesture()
                                    .onChanged { value in dragOffset = value.translation }
                                    .onEnded { _ in
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            dragOffset = .zero
                                        }
                                    }
                                : nil
                            )
                    }
                }
            }
        }
        .frame(height: 300)
        .padding()
    }
}
