import Foundation

// MARK: - Drop Zone

/// Represents a valid placement position in the pyramid tree.
///
/// Drop zones are computed from the current tree state. Each zone identifies
/// where a new child block could be inserted — under which parent, at which
/// child index, and at what canvas position.
struct DropZone: Identifiable, Sendable, Equatable {
    let id: String
    /// The node ID of the parent this zone belongs to.
    let parentID: String
    /// The child index at which a block would be inserted.
    let childIndex: Int
    /// The centre point of the drop zone in canvas coordinates.
    let center: CGPoint
    /// The size of the drop zone target area.
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

// MARK: - Drop Zone State

/// Visual state of a drop zone during drag interaction.
enum DropZoneVisualState: Sendable, Equatable {
    /// Zone is visible but not targeted.
    case available
    /// A dragged block is hovering within proximity.
    case highlighted
}

// MARK: - Drop Zone Configuration

/// Configurable parameters for drop zone proximity detection.
struct DropZoneConfiguration: Sendable {
    /// Maximum distance (in points) from a dragged block centre to a drop zone
    /// centre for the zone to be considered a valid target.
    var snapDistance: CGFloat = 80

    /// Size of drop zone indicator.
    var zoneSize: CGSize = CGSize(width: 140, height: 50)

    static let `default` = DropZoneConfiguration()
}
