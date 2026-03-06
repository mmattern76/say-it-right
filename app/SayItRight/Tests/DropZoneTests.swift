import Testing
import Foundation
@testable import SayItRight

// MARK: - Drop Zone Model Tests

@Suite("DropZone Model")
struct DropZoneModelTests {

    @Test("frame computes correctly from centre and size")
    func frameComputation() {
        let zone = DropZone(
            id: "test",
            parentID: "parent",
            childIndex: 0,
            center: CGPoint(x: 200, y: 100),
            size: CGSize(width: 140, height: 50)
        )

        #expect(zone.frame.origin.x == 130)
        #expect(zone.frame.origin.y == 75)
        #expect(zone.frame.width == 140)
        #expect(zone.frame.height == 50)
    }

    @Test("default configuration has reasonable snap distance")
    func defaultConfiguration() {
        let config = DropZoneConfiguration.default
        #expect(config.snapDistance == 80)
        #expect(config.zoneSize.width == 140)
        #expect(config.zoneSize.height == 50)
    }
}

// MARK: - Pyramid Tree State Tests

@Suite("PyramidTreeState")
struct PyramidTreeStateTests {

    @MainActor
    private func makeState(blocks: [PyramidBlock] = []) -> PyramidTreeState {
        let state = PyramidTreeState(blocks: blocks)
        state.canvasSize = CGSize(width: 800, height: 600)
        return state
    }

    private func sampleBlocks() -> [PyramidBlock] {
        [
            PyramidBlock(text: "Main claim", type: .governingThought),
            PyramidBlock(text: "Support A", type: .supportPoint),
            PyramidBlock(text: "Support B", type: .supportPoint),
            PyramidBlock(text: "Evidence 1", type: .evidence),
        ]
    }

    @MainActor
    @Test("initialises with blocks in unplaced pool")
    func initialState() {
        let blocks = sampleBlocks()
        let state = makeState(blocks: blocks)

        #expect(state.unplacedBlocks.count == 4)
        #expect(state.placedBlocks.isEmpty)
        #expect(state.rootBlockID == nil)
    }

    @MainActor
    @Test("place block as root")
    func placeAsRoot() {
        let blocks = sampleBlocks()
        let state = makeState(blocks: blocks)
        let root = blocks[0]

        state.placeAsRoot(root)

        #expect(state.rootBlockID == root.id)
        #expect(state.placedBlocks.count == 1)
        #expect(state.unplacedBlocks.count == 3)
        #expect(state.placedBlocks[root.id]?.parentID == nil)
    }

    @MainActor
    @Test("cannot place second root")
    func cannotPlaceSecondRoot() {
        let blocks = sampleBlocks()
        let state = makeState(blocks: blocks)

        state.placeAsRoot(blocks[0])
        state.placeAsRoot(blocks[1])

        #expect(state.rootBlockID == blocks[0].id)
        #expect(state.placedBlocks.count == 1)
    }

    @MainActor
    @Test("place child block under parent")
    func placeChild() {
        let blocks = sampleBlocks()
        let state = makeState(blocks: blocks)

        state.placeAsRoot(blocks[0])
        state.placeBlock(blocks[1], underParent: blocks[0].id, atIndex: 0)

        #expect(state.placedBlocks.count == 2)
        #expect(state.unplacedBlocks.count == 2)
        #expect(state.placedBlocks[blocks[0].id]?.childIDs == [blocks[1].id])
        #expect(state.placedBlocks[blocks[1].id]?.parentID == blocks[0].id)
    }

    @MainActor
    @Test("place multiple children preserves order")
    func placeMultipleChildren() {
        let blocks = sampleBlocks()
        let state = makeState(blocks: blocks)

        state.placeAsRoot(blocks[0])
        state.placeBlock(blocks[1], underParent: blocks[0].id, atIndex: 0)
        state.placeBlock(blocks[2], underParent: blocks[0].id, atIndex: 1)

        let children = state.placedBlocks[blocks[0].id]?.childIDs
        #expect(children == [blocks[1].id, blocks[2].id])
    }

    @MainActor
    @Test("remove block returns it and descendants to pool")
    func removeBlock() {
        let blocks = sampleBlocks()
        let state = makeState(blocks: blocks)

        state.placeAsRoot(blocks[0])
        state.placeBlock(blocks[1], underParent: blocks[0].id, atIndex: 0)
        state.placeBlock(blocks[3], underParent: blocks[1].id, atIndex: 0)

        // Remove blocks[1] — should also remove blocks[3] (descendant).
        state.removeBlock(blocks[1].id)

        #expect(state.placedBlocks.count == 1) // only root remains
        #expect(state.unplacedBlocks.count == 3) // blocks[1], blocks[2], blocks[3] in pool
        #expect(state.placedBlocks[blocks[0].id]?.childIDs.isEmpty == true)
    }

    @MainActor
    @Test("remove root clears tree")
    func removeRoot() {
        let blocks = sampleBlocks()
        let state = makeState(blocks: blocks)

        state.placeAsRoot(blocks[0])
        state.placeBlock(blocks[1], underParent: blocks[0].id, atIndex: 0)

        state.removeBlock(blocks[0].id)

        #expect(state.rootBlockID == nil)
        #expect(state.placedBlocks.isEmpty)
        #expect(state.unplacedBlocks.count == 4)
    }

    @MainActor
    @Test("reparent block moves to new parent")
    func reparentBlock() {
        let blocks = sampleBlocks()
        let state = makeState(blocks: blocks)

        state.placeAsRoot(blocks[0])
        state.placeBlock(blocks[1], underParent: blocks[0].id, atIndex: 0)
        state.placeBlock(blocks[2], underParent: blocks[0].id, atIndex: 1)
        state.placeBlock(blocks[3], underParent: blocks[1].id, atIndex: 0)

        // Move evidence from under Support A to under Support B.
        state.reparentBlock(blocks[3].id, toParent: blocks[2].id, atIndex: 0)

        #expect(state.placedBlocks[blocks[1].id]?.childIDs.isEmpty == true)
        #expect(state.placedBlocks[blocks[2].id]?.childIDs == [blocks[3].id])
        #expect(state.placedBlocks[blocks[3].id]?.parentID == blocks[2].id)
    }

    @MainActor
    @Test("reparent prevents circular reference")
    func reparentPreventsCircular() {
        let blocks = sampleBlocks()
        let state = makeState(blocks: blocks)

        state.placeAsRoot(blocks[0])
        state.placeBlock(blocks[1], underParent: blocks[0].id, atIndex: 0)
        state.placeBlock(blocks[3], underParent: blocks[1].id, atIndex: 0)

        // Try to move blocks[1] under its own child blocks[3] — should be rejected.
        state.reparentBlock(blocks[1].id, toParent: blocks[3].id, atIndex: 0)

        // blocks[1] should still be under blocks[0].
        #expect(state.placedBlocks[blocks[1].id]?.parentID == blocks[0].id)
    }

    @MainActor
    @Test("no two blocks can occupy the same position")
    func preventDuplicatePlacement() {
        let blocks = sampleBlocks()
        let state = makeState(blocks: blocks)

        state.placeAsRoot(blocks[0])
        state.placeBlock(blocks[1], underParent: blocks[0].id, atIndex: 0)

        // Try to place blocks[1] again — should be rejected.
        state.placeBlock(blocks[1], underParent: blocks[0].id, atIndex: 1)

        #expect(state.placedBlocks[blocks[0].id]?.childIDs.count == 1)
    }

    // MARK: - Drop Zone Computation

    @MainActor
    @Test("empty tree has root drop zone")
    func emptyTreeDropZones() {
        let state = makeState(blocks: sampleBlocks())
        state.recomputeLayout()

        #expect(!state.dropZones.isEmpty)
        #expect(state.dropZones.first?.parentID == "root")
    }

    @MainActor
    @Test("tree with root has child drop zone")
    func rootHasChildDropZone() {
        let blocks = sampleBlocks()
        let state = makeState(blocks: blocks)

        state.placeAsRoot(blocks[0])

        let childZones = state.dropZones.filter { $0.parentID == blocks[0].id.uuidString }
        #expect(!childZones.isEmpty)
    }

    // MARK: - Proximity Detection

    @MainActor
    @Test("nearest zone returns zone within snap distance")
    func nearestZoneWithinDistance() {
        let state = makeState(blocks: sampleBlocks())
        state.recomputeLayout()

        guard let zone = state.dropZones.first else {
            Issue.record("Expected at least one drop zone")
            return
        }

        // Point very close to zone centre.
        let nearby = CGPoint(x: zone.center.x + 10, y: zone.center.y + 10)
        let result = state.nearestZone(to: nearby)

        #expect(result?.id == zone.id)
    }

    @MainActor
    @Test("nearest zone returns nil when too far")
    func nearestZoneOutOfRange() {
        let state = makeState(blocks: sampleBlocks())
        state.recomputeLayout()

        // Point far from any zone.
        let farAway = CGPoint(x: 9999, y: 9999)
        let result = state.nearestZone(to: farAway)

        #expect(result == nil)
    }

    // MARK: - Drag Interaction

    @MainActor
    @Test("drag lifecycle updates state correctly")
    func dragLifecycle() {
        let blocks = sampleBlocks()
        let state = makeState(blocks: blocks)
        state.recomputeLayout()

        state.beginDrag(blockID: blocks[0].id)
        #expect(state.isDragging)
        #expect(state.draggedBlockID == blocks[0].id)

        // Update with position near root zone.
        if let zone = state.dropZones.first {
            state.updateDrag(position: zone.center)
            #expect(state.highlightedZoneID == zone.id)
        }

        state.endDrag(position: CGPoint(x: 9999, y: 9999))
        #expect(!state.isDragging)
        #expect(state.draggedBlockID == nil)
        #expect(state.highlightedZoneID == nil)
    }

    @MainActor
    @Test("drop on valid zone places block from pool")
    func dropOnValidZone() {
        let blocks = sampleBlocks()
        let state = makeState(blocks: blocks)
        state.recomputeLayout()

        guard let rootZone = state.dropZones.first(where: { $0.parentID == "root" }) else {
            Issue.record("Expected root drop zone")
            return
        }

        state.beginDrag(blockID: blocks[0].id)
        let result = state.endDrag(position: rootZone.center)

        #expect(result != nil)
        #expect(state.rootBlockID == blocks[0].id)
        #expect(state.unplacedBlocks.count == 3)
    }

    @MainActor
    @Test("drop outside valid zone returns placed block to pool")
    func dropOutsideReturnsToPool() {
        let blocks = sampleBlocks()
        let state = makeState(blocks: blocks)

        state.placeAsRoot(blocks[0])
        state.placeBlock(blocks[1], underParent: blocks[0].id, atIndex: 0)

        #expect(state.placedBlocks.count == 2)

        // Drag blocks[1] and drop far away.
        state.beginDrag(blockID: blocks[1].id)
        let result = state.endDrag(position: CGPoint(x: 9999, y: 9999))

        #expect(result == nil)
        #expect(state.placedBlocks.count == 1) // only root remains
        #expect(state.unplacedBlocks.contains(where: { $0.id == blocks[1].id }))
    }
}
