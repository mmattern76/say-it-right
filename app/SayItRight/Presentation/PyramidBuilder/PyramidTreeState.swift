import Foundation
import SwiftUI

// MARK: - Placed Block

/// A block that has been placed in the pyramid tree.
struct PlacedBlock: Identifiable, Sendable, Equatable {
    let id: UUID
    let block: PyramidBlock
    /// The parent block's ID, or nil if this is the root.
    var parentID: UUID?
    /// Ordered child IDs.
    var childIDs: [UUID]

    init(block: PyramidBlock, parentID: UUID? = nil, childIDs: [UUID] = []) {
        self.id = block.id
        self.block = block
        self.parentID = parentID
        self.childIDs = childIDs
    }
}

// MARK: - Pyramid Tree State

/// Observable state managing the pyramid tree: placed blocks, unplaced pool,
/// drop zone computation, and drag-drop interactions.
///
/// This is the central model that ties together the tree layout engine,
/// drop zones, and block placement logic.
@MainActor
@Observable
final class PyramidTreeState {

    // MARK: - Properties

    /// Blocks that have been placed in the tree, keyed by ID.
    private(set) var placedBlocks: [UUID: PlacedBlock] = [:]

    /// Blocks not yet placed in the tree (the unplaced pool).
    private(set) var unplacedBlocks: [PyramidBlock] = []

    /// The ID of the root block, if one has been placed.
    private(set) var rootBlockID: UUID?

    /// Currently computed drop zones based on tree state.
    private(set) var dropZones: [DropZone] = []

    /// The drop zone currently highlighted (nearest to dragged block).
    private(set) var highlightedZoneID: String?

    /// Whether a drag is in progress.
    private(set) var isDragging: Bool = false

    /// The ID of the block currently being dragged, if any.
    private(set) var draggedBlockID: UUID?

    /// Drop zone configuration (snap distance, zone size).
    var configuration: DropZoneConfiguration = .default

    /// Layout engine for computing positions.
    var layoutEngine: TreeLayoutEngine = TreeLayoutEngine()

    /// Canvas size for layout computation.
    var canvasSize: CGSize = CGSize(width: 800, height: 600)

    /// Computed layout for placed blocks.
    private(set) var nodeLayouts: [String: NodeLayout] = [:]

    // MARK: - Initialisation

    init(blocks: [PyramidBlock] = []) {
        self.unplacedBlocks = blocks
    }

    /// Add a block to the unplaced pool.
    func addToUnplacedPool(_ block: PyramidBlock) {
        unplacedBlocks.append(block)
    }

    /// Remove a block from the unplaced pool by ID.
    @discardableResult
    func removeFromUnplacedPool(_ blockID: UUID) -> PyramidBlock? {
        guard let index = unplacedBlocks.firstIndex(where: { $0.id == blockID }) else { return nil }
        return unplacedBlocks.remove(at: index)
    }

    // MARK: - Tree Construction

    /// Build a TreeNode hierarchy from placed blocks, starting at the given root.
    func buildTreeNode(from blockID: UUID) -> TreeNode? {
        guard let placed = placedBlocks[blockID] else { return nil }
        let children = placed.childIDs.compactMap { buildTreeNode(from: $0) }
        return TreeNode(
            id: blockID.uuidString,
            size: CGSize(width: 160, height: 60),
            children: children
        )
    }

    /// Recompute layout and drop zones after any tree mutation.
    func recomputeLayout() {
        guard let rootID = rootBlockID,
              let rootNode = buildTreeNode(from: rootID) else {
            nodeLayouts = [:]
            dropZones = computeDropZonesForEmptyTree()
            return
        }

        nodeLayouts = layoutEngine.layout(root: rootNode, in: canvasSize)
        dropZones = computeDropZones(root: rootID)
    }

    // MARK: - Block Placement

    /// Place a block as the root of the tree.
    func placeAsRoot(_ block: PyramidBlock) {
        guard rootBlockID == nil else { return }
        let placed = PlacedBlock(block: block, parentID: nil)
        placedBlocks[block.id] = placed
        rootBlockID = block.id
        removeFromUnplaced(block.id)
        recomputeLayout()
    }

    /// Place a block as a child of the given parent at the specified index.
    func placeBlock(_ block: PyramidBlock, underParent parentID: UUID, atIndex index: Int) {
        guard var parent = placedBlocks[parentID] else { return }

        // Prevent duplicate placement.
        guard placedBlocks[block.id] == nil else { return }

        let placed = PlacedBlock(block: block, parentID: parentID)
        placedBlocks[block.id] = placed

        let clampedIndex = min(index, parent.childIDs.count)
        parent.childIDs.insert(block.id, at: clampedIndex)
        placedBlocks[parentID] = parent

        removeFromUnplaced(block.id)
        recomputeLayout()
    }

    /// Remove a block from the tree and return it (and all descendants) to the unplaced pool.
    func removeBlock(_ blockID: UUID) {
        guard let placed = placedBlocks[blockID] else { return }

        // Collect all descendant IDs (depth-first).
        let descendantIDs = collectDescendants(of: blockID)

        // Remove from parent's child list.
        if let parentID = placed.parentID, var parent = placedBlocks[parentID] {
            parent.childIDs.removeAll { $0 == blockID }
            placedBlocks[parentID] = parent
        }

        // If removing root, clear rootBlockID.
        if blockID == rootBlockID {
            rootBlockID = nil
        }

        // Move block and all descendants to unplaced pool.
        let allIDs = [blockID] + descendantIDs
        for id in allIDs {
            if let removed = placedBlocks.removeValue(forKey: id) {
                unplacedBlocks.append(removed.block)
            }
        }

        recomputeLayout()
    }

    /// Move a placed block to a different parent (reparenting).
    func reparentBlock(_ blockID: UUID, toParent newParentID: UUID, atIndex index: Int) {
        guard let placed = placedBlocks[blockID] else { return }
        guard newParentID != blockID else { return }

        // Prevent circular reparenting: newParent must not be a descendant of blockID.
        let descendants = collectDescendants(of: blockID)
        guard !descendants.contains(newParentID) else { return }

        // Remove from old parent.
        if let oldParentID = placed.parentID, var oldParent = placedBlocks[oldParentID] {
            oldParent.childIDs.removeAll { $0 == blockID }
            placedBlocks[oldParentID] = oldParent
        }

        // Add to new parent.
        var newParent = placedBlocks[newParentID]!
        let clampedIndex = min(index, newParent.childIDs.count)
        newParent.childIDs.insert(blockID, at: clampedIndex)
        placedBlocks[newParentID] = newParent

        // Update the block's parentID.
        var updatedBlock = placed
        updatedBlock.parentID = newParentID
        placedBlocks[blockID] = updatedBlock

        recomputeLayout()
    }

    // MARK: - Drag Interaction

    /// Begin a drag interaction for the given block.
    func beginDrag(blockID: UUID) {
        isDragging = true
        draggedBlockID = blockID
        // Show drop zones during drag.
        if dropZones.isEmpty {
            recomputeLayout()
        }
    }

    /// Update drag position and highlight the nearest valid drop zone.
    func updateDrag(position: CGPoint) {
        highlightedZoneID = nearestZone(to: position)?.id
    }

    /// End the drag interaction.
    ///
    /// - Parameter position: The final position of the dragged block centre.
    /// - Returns: The drop zone the block was dropped on, or nil if outside all zones.
    @discardableResult
    func endDrag(position: CGPoint) -> DropZone? {
        let zone = nearestZone(to: position)
        isDragging = false
        highlightedZoneID = nil

        guard let zone = zone, let draggedID = draggedBlockID else {
            // Dropped outside — handle return to pool if block was placed.
            if let draggedID = draggedBlockID, placedBlocks[draggedID] != nil {
                removeBlock(draggedID)
            }
            draggedBlockID = nil
            return nil
        }

        // Determine if this is a new placement, or a reparent.
        if let draggedBlock = unplacedBlocks.first(where: { $0.id == draggedID }) {
            // New placement from unplaced pool.
            if zone.parentID == "root" {
                placeAsRoot(draggedBlock)
            } else if let parentUUID = UUID(uuidString: zone.parentID) {
                placeBlock(draggedBlock, underParent: parentUUID, atIndex: zone.childIndex)
            }
        } else if placedBlocks[draggedID] != nil {
            // Reparenting an already-placed block.
            if let parentUUID = UUID(uuidString: zone.parentID) {
                reparentBlock(draggedID, toParent: parentUUID, atIndex: zone.childIndex)
            }
        }

        draggedBlockID = nil
        return zone
    }

    // MARK: - Drop Zone Computation

    /// Compute drop zones for an empty tree (just a single root zone).
    private func computeDropZonesForEmptyTree() -> [DropZone] {
        let rootCenter = CGPoint(x: canvasSize.width / 2, y: 50)
        return [
            DropZone(
                id: "root-zone",
                parentID: "root",
                childIndex: 0,
                center: rootCenter,
                size: configuration.zoneSize
            )
        ]
    }

    /// Compute drop zones based on current tree state.
    ///
    /// For each placed node, zones are created for adding a new child after
    /// the existing children. This uses the layout engine to determine positions.
    private func computeDropZones(root rootID: UUID) -> [DropZone] {
        var zones: [DropZone] = []
        computeDropZonesRecursive(nodeID: rootID, zones: &zones)
        return zones
    }

    private func computeDropZonesRecursive(nodeID: UUID, zones: inout [DropZone]) {
        guard let placed = placedBlocks[nodeID],
              let layout = nodeLayouts[nodeID.uuidString] else { return }

        // Zone for adding a new child to this node.
        let childCount = placed.childIDs.count
        let childY = layout.center.y + layout.size.height / 2
            + layoutEngine.verticalSpacing + configuration.zoneSize.height / 2

        if childCount == 0 {
            // Single zone directly below parent.
            let zone = DropZone(
                id: "zone-\(nodeID.uuidString)-child-0",
                parentID: nodeID.uuidString,
                childIndex: 0,
                center: CGPoint(x: layout.center.x, y: childY),
                size: configuration.zoneSize
            )
            zones.append(zone)
        } else {
            // Zone after the last child.
            if let lastChildID = placed.childIDs.last,
               let lastChildLayout = nodeLayouts[lastChildID.uuidString] {
                let newX = lastChildLayout.center.x + lastChildLayout.size.width / 2
                    + layoutEngine.horizontalSpacing + configuration.zoneSize.width / 2
                let zone = DropZone(
                    id: "zone-\(nodeID.uuidString)-child-\(childCount)",
                    parentID: nodeID.uuidString,
                    childIndex: childCount,
                    center: CGPoint(x: newX, y: lastChildLayout.center.y),
                    size: configuration.zoneSize
                )
                zones.append(zone)
            }
        }

        // Recurse into children to create zones for sub-levels.
        for childID in placed.childIDs {
            computeDropZonesRecursive(nodeID: childID, zones: &zones)
        }
    }

    // MARK: - Proximity Detection

    /// Find the nearest drop zone within snap distance.
    func nearestZone(to point: CGPoint) -> DropZone? {
        var closest: DropZone?
        var closestDistance: CGFloat = .infinity

        for zone in dropZones {
            let dx = point.x - zone.center.x
            let dy = point.y - zone.center.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance < configuration.snapDistance && distance < closestDistance {
                closest = zone
                closestDistance = distance
            }
        }

        return closest
    }

    // MARK: - Helpers

    private func removeFromUnplaced(_ blockID: UUID) {
        unplacedBlocks.removeAll { $0.id == blockID }
    }

    /// Collect all descendant IDs of a node (not including the node itself).
    private func collectDescendants(of blockID: UUID) -> [UUID] {
        guard let placed = placedBlocks[blockID] else { return [] }
        var result: [UUID] = []
        for childID in placed.childIDs {
            result.append(childID)
            result.append(contentsOf: collectDescendants(of: childID))
        }
        return result
    }
}
