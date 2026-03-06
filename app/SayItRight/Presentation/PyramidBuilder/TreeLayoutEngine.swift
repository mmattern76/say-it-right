import Foundation

// MARK: - Tree Node

/// A node in the pyramid tree, carrying an ID, a display size, and references to children.
struct TreeNode: Sendable {
    let id: String
    let size: CGSize
    var children: [TreeNode]

    init(id: String, size: CGSize = CGSize(width: 160, height: 60), children: [TreeNode] = []) {
        self.id = id
        self.size = size
        self.children = children
    }
}

// MARK: - Layout Result

/// The computed position and size for a single node.
struct NodeLayout: Sendable, Equatable {
    /// Centre point of the node in canvas coordinates.
    let center: CGPoint
    /// Size of the node block.
    let size: CGSize

    var frame: CGRect {
        CGRect(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2,
            width: size.width,
            height: size.height
        )
    }
}

// MARK: - Tree Layout Engine

/// Pure calculation engine that positions pyramid nodes on a 2D canvas.
///
/// Given a tree of ``TreeNode`` values and a canvas size, the engine
/// computes a ``NodeLayout`` for every node such that:
/// - The root is centred horizontally at the top.
/// - Children are evenly distributed below their parent.
/// - Sibling groups are centred under their parent.
/// - No blocks overlap.
///
/// The algorithm is a simplified Reingold-Tilford-style bottom-up
/// approach: first measure subtree widths, then assign positions
/// top-down using those widths to allocate horizontal space.
struct TreeLayoutEngine: Sendable {

    // MARK: - Configuration

    /// Horizontal gap between sibling nodes.
    var horizontalSpacing: CGFloat = 24

    /// Vertical gap between levels (added to the taller block's height).
    var verticalSpacing: CGFloat = 40

    // MARK: - Public API

    /// Calculate layout for every node in the tree.
    ///
    /// - Parameters:
    ///   - root: The root of the pyramid tree.
    ///   - canvasSize: The available canvas dimensions.
    /// - Returns: A dictionary mapping node IDs to their computed layout.
    func layout(root: TreeNode, in canvasSize: CGSize) -> [String: NodeLayout] {
        // Phase 1: Compute the minimum width each subtree requires.
        let subtreeWidths = computeSubtreeWidths(node: root)

        // Phase 2: Assign positions top-down.
        var result: [String: NodeLayout] = [:]
        let topY = verticalSpacing / 2 + root.size.height / 2
        let centerX = canvasSize.width / 2

        assignPositions(
            node: root,
            centerX: centerX,
            topY: topY,
            subtreeWidths: subtreeWidths,
            result: &result
        )

        return result
    }

    // MARK: - Phase 1: Subtree Width Measurement

    /// Returns a dictionary mapping each node ID to the total horizontal
    /// width its subtree requires (including spacing between siblings).
    private func computeSubtreeWidths(node: TreeNode) -> [String: CGFloat] {
        var widths: [String: CGFloat] = [:]
        _ = measureSubtreeWidth(node: node, widths: &widths)
        return widths
    }

    /// Recursively measures the width a subtree needs.
    ///
    /// A leaf node needs exactly its own width.
    /// A parent needs the sum of its children's subtree widths plus
    /// spacing between them, or its own width — whichever is larger.
    @discardableResult
    private func measureSubtreeWidth(node: TreeNode, widths: inout [String: CGFloat]) -> CGFloat {
        if node.children.isEmpty {
            let width = node.size.width
            widths[node.id] = width
            return width
        }

        var childrenTotalWidth: CGFloat = 0
        for (index, child) in node.children.enumerated() {
            childrenTotalWidth += measureSubtreeWidth(node: child, widths: &widths)
            if index < node.children.count - 1 {
                childrenTotalWidth += horizontalSpacing
            }
        }

        // The subtree width is the larger of the parent's own width
        // and the combined children width.
        let subtreeWidth = max(node.size.width, childrenTotalWidth)
        widths[node.id] = subtreeWidth
        return subtreeWidth
    }

    // MARK: - Phase 2: Position Assignment

    /// Recursively assigns centre positions to each node, top-down.
    ///
    /// - Parameters:
    ///   - node: Current node being positioned.
    ///   - centerX: Horizontal centre allocated to this node's subtree.
    ///   - topY: Vertical centre for this level.
    ///   - subtreeWidths: Pre-computed subtree widths from Phase 1.
    ///   - result: Accumulator for the final layout dictionary.
    private func assignPositions(
        node: TreeNode,
        centerX: CGFloat,
        topY: CGFloat,
        subtreeWidths: [String: CGFloat],
        result: inout [String: NodeLayout]
    ) {
        // Place this node at its assigned centre.
        result[node.id] = NodeLayout(center: CGPoint(x: centerX, y: topY), size: node.size)

        guard !node.children.isEmpty else { return }

        // Compute the total width the children occupy.
        let childrenTotalWidth: CGFloat = node.children.enumerated().reduce(0) { acc, pair in
            let (index, child) = pair
            let childWidth = subtreeWidths[child.id] ?? child.size.width
            let spacing = index < node.children.count - 1 ? horizontalSpacing : 0
            return acc + childWidth + spacing
        }

        // Children level: offset below current node.
        let tallestChildHeight = node.children.map(\.size.height).max() ?? 0
        let childY = topY + node.size.height / 2 + verticalSpacing + tallestChildHeight / 2

        // Start from the left edge of the children band, centred under the parent.
        var currentX = centerX - childrenTotalWidth / 2

        for child in node.children {
            let childSubtreeWidth = subtreeWidths[child.id] ?? child.size.width
            let childCenterX = currentX + childSubtreeWidth / 2

            assignPositions(
                node: child,
                centerX: childCenterX,
                topY: childY,
                subtreeWidths: subtreeWidths,
                result: &result
            )

            currentX += childSubtreeWidth + horizontalSpacing
        }
    }
}
