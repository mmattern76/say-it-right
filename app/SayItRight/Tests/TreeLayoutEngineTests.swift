import Testing
import Foundation
@testable import SayItRight

@Suite("TreeLayoutEngine")
struct TreeLayoutEngineTests {

    private let engine = TreeLayoutEngine()
    private let canvas = CGSize(width: 800, height: 600)
    private let defaultSize = CGSize(width: 160, height: 60)

    // MARK: - Single Node

    @Test func singleNodeCentredAtTop() {
        let root = TreeNode(id: "root", size: defaultSize)
        let result = engine.layout(root: root, in: canvas)

        #expect(result.count == 1)
        let layout = result["root"]!
        #expect(layout.center.x == 400) // canvas.width / 2
        #expect(layout.center.y == 50) // verticalSpacing/2 + height/2 = 20 + 30
        #expect(layout.size == defaultSize)
    }

    // MARK: - Two-Level Balanced (1 root + 3 children)

    @Test func twoLevelBalancedTree() {
        let children = (1...3).map { TreeNode(id: "child\($0)", size: defaultSize) }
        let root = TreeNode(id: "root", size: defaultSize, children: children)
        let result = engine.layout(root: root, in: canvas)

        #expect(result.count == 4)

        // Root centred horizontally
        let rootLayout = result["root"]!
        #expect(rootLayout.center.x == 400)

        // All children on the same Y level
        let childYs = (1...3).map { result["child\($0)"]!.center.y }
        #expect(childYs[0] == childYs[1])
        #expect(childYs[1] == childYs[2])

        // Children below root
        #expect(childYs[0] > rootLayout.center.y)

        // Children centred under root: middle child at root's X
        let childXs = (1...3).map { result["child\($0)"]!.center.x }
        #expect(childXs[1] == rootLayout.center.x)

        // Left child left of middle, right child right of middle
        #expect(childXs[0] < childXs[1])
        #expect(childXs[2] > childXs[1])

        // Symmetric
        let leftOffset = childXs[1] - childXs[0]
        let rightOffset = childXs[2] - childXs[1]
        #expect(abs(leftOffset - rightOffset) < 0.001)
    }

    // MARK: - Three-Level Pyramid

    @Test func threeLevelPyramid() {
        // Root -> [A(2 children), B(2 children), C(2 children)]
        let grandchildren: [[TreeNode]] = (0..<3).map { group in
            (0..<2).map { TreeNode(id: "gc\(group)_\($0)", size: defaultSize) }
        }
        let children = (0..<3).map { i in
            TreeNode(id: "child\(i)", size: defaultSize, children: grandchildren[i])
        }
        let root = TreeNode(id: "root", size: defaultSize, children: children)
        let result = engine.layout(root: root, in: canvas)

        #expect(result.count == 10) // 1 + 3 + 6

        // Three distinct Y levels
        let rootY = result["root"]!.center.y
        let childY = result["child0"]!.center.y
        let gcY = result["gc0_0"]!.center.y
        #expect(rootY < childY)
        #expect(childY < gcY)

        // All grandchildren at same Y
        for g in 0..<3 {
            for c in 0..<2 {
                #expect(result["gc\(g)_\(c)"]!.center.y == gcY)
            }
        }
    }

    // MARK: - No Overlap

    @Test func noOverlapBalancedTree() {
        let children = (0..<4).map { TreeNode(id: "c\($0)", size: defaultSize) }
        let root = TreeNode(id: "root", size: defaultSize, children: children)
        let result = engine.layout(root: root, in: canvas)

        assertNoOverlap(result)
    }

    @Test func noOverlapUnbalancedTree() {
        // Unbalanced: first child has 3 grandchildren, second has none
        let grandchildren = (0..<3).map { TreeNode(id: "gc\($0)", size: defaultSize) }
        let child0 = TreeNode(id: "child0", size: defaultSize, children: grandchildren)
        let child1 = TreeNode(id: "child1", size: defaultSize)
        let root = TreeNode(id: "root", size: defaultSize, children: [child0, child1])
        let result = engine.layout(root: root, in: canvas)

        assertNoOverlap(result)
    }

    @Test func noOverlapWideBlocks() {
        let wideSize = CGSize(width: 300, height: 60)
        let children = (0..<3).map { TreeNode(id: "c\($0)", size: wideSize) }
        let root = TreeNode(id: "root", size: wideSize, children: children)
        let result = engine.layout(root: root, in: CGSize(width: 1200, height: 600))

        assertNoOverlap(result)
    }

    // MARK: - Single Child Chain

    @Test func singleChildChain() {
        let leaf = TreeNode(id: "leaf", size: defaultSize)
        let middle = TreeNode(id: "middle", size: defaultSize, children: [leaf])
        let root = TreeNode(id: "root", size: defaultSize, children: [middle])
        let result = engine.layout(root: root, in: canvas)

        #expect(result.count == 3)

        // All centred at same X (single-child chain)
        let rootX = result["root"]!.center.x
        #expect(result["middle"]!.center.x == rootX)
        #expect(result["leaf"]!.center.x == rootX)

        // Distinct Y levels
        #expect(result["root"]!.center.y < result["middle"]!.center.y)
        #expect(result["middle"]!.center.y < result["leaf"]!.center.y)
    }

    // MARK: - Unbalanced Tree (Different Child Counts)

    @Test func unbalancedChildCounts() {
        // child0 has 4 grandchildren, child1 has 1 grandchild
        let gc0 = (0..<4).map { TreeNode(id: "gc0_\($0)", size: defaultSize) }
        let gc1 = [TreeNode(id: "gc1_0", size: defaultSize)]
        let child0 = TreeNode(id: "child0", size: defaultSize, children: gc0)
        let child1 = TreeNode(id: "child1", size: defaultSize, children: gc1)
        let root = TreeNode(id: "root", size: defaultSize, children: [child0, child1])
        let result = engine.layout(root: root, in: CGSize(width: 1200, height: 600))

        #expect(result.count == 8) // 1 + 2 + 5

        // child0's subtree should be wider than child1's
        let gc0Xs = (0..<4).map { result["gc0_\($0)"]!.center.x }
        let gc0Spread = gc0Xs.max()! - gc0Xs.min()!
        // child1 has only one grandchild, no spread
        #expect(gc0Spread > 0)

        assertNoOverlap(result)
    }

    // MARK: - Sibling Group Centred Under Parent

    @Test func siblingsGroupCentredUnderParent() {
        let children = (0..<2).map { TreeNode(id: "c\($0)", size: defaultSize) }
        let root = TreeNode(id: "root", size: defaultSize, children: children)
        let result = engine.layout(root: root, in: canvas)

        let rootX = result["root"]!.center.x
        let leftX = result["c0"]!.center.x
        let rightX = result["c1"]!.center.x

        // Midpoint of children should equal parent X
        let midpoint = (leftX + rightX) / 2
        #expect(abs(midpoint - rootX) < 0.001)
    }

    // MARK: - Dynamic Sizing (Variable Block Sizes)

    @Test func variableBlockSizes() {
        let smallSize = CGSize(width: 100, height: 40)
        let largeSize = CGSize(width: 250, height: 80)
        let child0 = TreeNode(id: "c0", size: smallSize)
        let child1 = TreeNode(id: "c1", size: largeSize)
        let root = TreeNode(id: "root", size: defaultSize, children: [child0, child1])
        let result = engine.layout(root: root, in: canvas)

        #expect(result["c0"]!.size == smallSize)
        #expect(result["c1"]!.size == largeSize)
        assertNoOverlap(result)
    }

    // MARK: - Canvas Adaptation

    @Test func layoutAdaptsToCanvasWidth() {
        let children = (0..<2).map { TreeNode(id: "c\($0)", size: defaultSize) }
        let root = TreeNode(id: "root", size: defaultSize, children: children)

        let narrowCanvas = CGSize(width: 400, height: 600)
        let wideCanvas = CGSize(width: 1200, height: 600)

        let narrowResult = engine.layout(root: root, in: narrowCanvas)
        let wideResult = engine.layout(root: root, in: wideCanvas)

        // Root centred in each canvas
        #expect(narrowResult["root"]!.center.x == 200)
        #expect(wideResult["root"]!.center.x == 600)
    }

    // MARK: - Vertical Spacing

    @Test func verticalSpacingBetweenLevels() {
        let child = TreeNode(id: "child", size: defaultSize)
        let root = TreeNode(id: "root", size: defaultSize, children: [child])
        let result = engine.layout(root: root, in: canvas)

        let rootBottom = result["root"]!.center.y + result["root"]!.size.height / 2
        let childTop = result["child"]!.center.y - result["child"]!.size.height / 2

        // Gap should equal verticalSpacing (40)
        #expect(abs((childTop - rootBottom) - engine.verticalSpacing) < 0.001)
    }

    // MARK: - Large Tree (15 Blocks)

    @Test func largeTreeFifteenBlocks() {
        // Root -> 3 children -> each has 3 grandchildren -> one grandchild has 2 great-grandchildren
        // = 1 + 3 + 9 + 2 = 15
        var grandchildren: [[TreeNode]] = (0..<3).map { g in
            (0..<3).map { c in TreeNode(id: "gc\(g)_\(c)", size: defaultSize) }
        }
        // Add 2 great-grandchildren to gc0_0
        let greatGrandchildren = (0..<2).map { TreeNode(id: "ggc\($0)", size: defaultSize) }
        grandchildren[0][0] = TreeNode(id: "gc0_0", size: defaultSize, children: greatGrandchildren)

        let children = (0..<3).map { i in
            TreeNode(id: "child\(i)", size: defaultSize, children: grandchildren[i])
        }
        let root = TreeNode(id: "root", size: defaultSize, children: children)
        let result = engine.layout(root: root, in: CGSize(width: 1600, height: 800))

        #expect(result.count == 15)
        assertNoOverlap(result)

        // Four distinct Y levels
        let yValues = Set(result.values.map { round($0.center.y * 100) / 100 })
        #expect(yValues.count == 4)
    }

    // MARK: - Custom Spacing

    @Test func customSpacing() {
        var customEngine = TreeLayoutEngine()
        customEngine.horizontalSpacing = 50
        customEngine.verticalSpacing = 80

        let children = (0..<2).map { TreeNode(id: "c\($0)", size: defaultSize) }
        let root = TreeNode(id: "root", size: defaultSize, children: children)
        let result = customEngine.layout(root: root, in: canvas)

        let rootBottom = result["root"]!.center.y + result["root"]!.size.height / 2
        let childTop = result["c0"]!.center.y - result["c0"]!.size.height / 2
        #expect(abs((childTop - rootBottom) - 80) < 0.001)

        // Children should be spaced further apart
        let gap = result["c1"]!.center.x - result["c0"]!.center.x
        // Gap = child width + horizontal spacing = 160 + 50 = 210
        #expect(abs(gap - 210) < 0.001)
    }

    // MARK: - Frame Computation

    @Test func nodeLayoutFrame() {
        let layout = NodeLayout(center: CGPoint(x: 100, y: 50), size: CGSize(width: 160, height: 60))
        let frame = layout.frame
        #expect(frame.origin.x == 20)
        #expect(frame.origin.y == 20)
        #expect(frame.size.width == 160)
        #expect(frame.size.height == 60)
    }

    // MARK: - Helpers

    /// Asserts that no two node frames overlap.
    private func assertNoOverlap(_ layouts: [String: NodeLayout]) {
        let entries = Array(layouts)
        for i in 0..<entries.count {
            for j in (i + 1)..<entries.count {
                let frameA = entries[i].value.frame
                let frameB = entries[j].value.frame
                let overlaps = frameA.intersects(frameB)
                #expect(
                    !overlaps,
                    "Overlap detected between \(entries[i].key) and \(entries[j].key): \(frameA) vs \(frameB)"
                )
            }
        }
    }
}
