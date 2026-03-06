import Testing
import Foundation
@testable import SayItRight

// MARK: - PyramidConnection Tests

@Suite("PyramidConnection")
struct PyramidConnectionTests {

    @Test("Connection ID combines parent and child IDs")
    func connectionID() {
        let connection = PyramidConnection(parentID: "root", childID: "child1")
        #expect(connection.id == "root->child1")
    }

    @Test("Connections with same parent and child are equal")
    func connectionEquality() {
        let a = PyramidConnection(parentID: "p", childID: "c")
        let b = PyramidConnection(parentID: "p", childID: "c")
        #expect(a == b)
    }

    @Test("Connections with different children are not equal")
    func connectionInequality() {
        let a = PyramidConnection(parentID: "p", childID: "c1")
        let b = PyramidConnection(parentID: "p", childID: "c2")
        #expect(a != b)
    }
}

// MARK: - TreeNode Connection Extraction Tests

@Suite("TreeNode.extractConnections")
struct TreeNodeConnectionExtractionTests {

    @Test("Leaf node has no connections")
    func leafNode() {
        let node = TreeNode(id: "leaf")
        let connections = node.extractConnections()
        #expect(connections.isEmpty)
    }

    @Test("Single parent with children produces correct connections")
    func singleLevel() {
        let tree = TreeNode(id: "root", children: [
            TreeNode(id: "a"),
            TreeNode(id: "b"),
            TreeNode(id: "c"),
        ])

        let connections = tree.extractConnections()

        #expect(connections.count == 3)
        #expect(connections[0].parentID == "root")
        #expect(connections[0].childID == "a")
        #expect(connections[1].parentID == "root")
        #expect(connections[1].childID == "b")
        #expect(connections[2].parentID == "root")
        #expect(connections[2].childID == "c")
    }

    @Test("Multi-level tree extracts all connections recursively")
    func multiLevel() {
        let tree = TreeNode(id: "root", children: [
            TreeNode(id: "a", children: [
                TreeNode(id: "a1"),
                TreeNode(id: "a2"),
            ]),
            TreeNode(id: "b"),
        ])

        let connections = tree.extractConnections()

        #expect(connections.count == 4)

        let connectionIDs = Set(connections.map(\.id))
        #expect(connectionIDs.contains("root->a"))
        #expect(connectionIDs.contains("root->b"))
        #expect(connectionIDs.contains("a->a1"))
        #expect(connectionIDs.contains("a->a2"))
    }

    @Test("Deep tree produces correct connection count")
    func deepTree() {
        let tree = TreeNode(id: "r", children: [
            TreeNode(id: "a", children: [
                TreeNode(id: "a1", children: [
                    TreeNode(id: "a1x"),
                ]),
            ]),
        ])

        let connections = tree.extractConnections()
        #expect(connections.count == 3)
    }
}

// MARK: - Bezier Path Tests

@Suite("ConnectionLinesView.bezierPath")
struct BezierPathTests {

    @Test("Bezier path starts at the start point")
    func pathStartsCorrectly() {
        let start = CGPoint(x: 100, y: 50)
        let end = CGPoint(x: 200, y: 150)
        let path = ConnectionLinesView.bezierPath(from: start, to: end)

        // Path should not be empty
        #expect(!path.isEmpty)

        // The bounding rect should encompass both points
        let bounds = path.boundingRect
        #expect(bounds.minX <= start.x + 1)
        #expect(bounds.maxX >= end.x - 1)
        #expect(bounds.minY <= start.y + 1)
        #expect(bounds.maxY >= end.y - 1)
    }

    @Test("Vertical path has narrow horizontal bounds")
    func verticalPath() {
        let start = CGPoint(x: 100, y: 0)
        let end = CGPoint(x: 100, y: 200)
        let path = ConnectionLinesView.bezierPath(from: start, to: end)

        let bounds = path.boundingRect
        // Vertical line: control points share x=100, so width should be ~0
        #expect(bounds.width < 1)
    }

    @Test("Path with horizontal offset produces wider bounds")
    func diagonalPath() {
        let start = CGPoint(x: 50, y: 0)
        let end = CGPoint(x: 250, y: 200)
        let path = ConnectionLinesView.bezierPath(from: start, to: end)

        let bounds = path.boundingRect
        #expect(bounds.width >= 150)
    }
}

// MARK: - Connection Line Style Tests

@Suite("ConnectionLineStyle")
struct ConnectionLineStyleTests {

    @Test("Normal style has thinner line than highlighted")
    func lineWidthComparison() {
        #expect(ConnectionLineStyle.normal.lineWidth < ConnectionLineStyle.highlighted.lineWidth)
    }

    @Test("Normal style has positive line width")
    func normalLineWidth() {
        #expect(ConnectionLineStyle.normal.lineWidth > 0)
    }

    @Test("Highlighted style has positive line width")
    func highlightedLineWidth() {
        #expect(ConnectionLineStyle.highlighted.lineWidth > 0)
    }
}
