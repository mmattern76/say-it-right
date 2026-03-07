import Foundation

// MARK: - Block Feedback State

/// Visual feedback state for a block based on validation results.
///
/// Maps ``BlockValidationStatus`` from the MECE validation engine to
/// concrete visual effects (colour, animation, accessibility label).
/// Colour-blind-safe: each state uses a distinct shape/pattern
/// in addition to colour.
enum BlockFeedbackState: Sendable, Equatable {
    /// Block is correctly placed — green glow, checkmark pattern.
    case correct
    /// Block is in the wrong position — amber border, shake animation.
    case misplaced
    /// Block participates in a MECE overlap — red pulse, striped pattern.
    case meceOverlap
    /// No feedback shown (feedback toggled off or not yet validated).
    case none

    /// Accessibility description for VoiceOver.
    var accessibilityLabel: String {
        switch self {
        case .correct: "Correctly placed"
        case .misplaced: "Misplaced — needs to be moved"
        case .meceOverlap: "MECE overlap — this block overlaps with another group"
        case .none: ""
        }
    }
}

// MARK: - Feedback Configuration

/// Controls how validation feedback is displayed.
struct FeedbackConfiguration: Sendable, Equatable {
    /// Whether feedback is currently visible.
    var isEnabled: Bool = false
    /// Whether feedback updates automatically on each drop,
    /// or only when the user presses "Check my work".
    var isAutomatic: Bool = false

    static let `default` = FeedbackConfiguration()
}

// MARK: - Feedback Mapping

/// Maps a ``PyramidValidationResult`` into per-block feedback states
/// and gap placeholder positions.
struct ValidationFeedbackMapper: Sendable {

    /// Derive per-block feedback states from a validation result.
    ///
    /// - Parameter result: The validation result from ``MECEValidationEngine``.
    /// - Returns: Dictionary mapping block IDs to their feedback state.
    static func blockFeedbackStates(
        from result: PyramidValidationResult
    ) -> [String: BlockFeedbackState] {
        var states: [String: BlockFeedbackState] = [:]

        // Collect block IDs involved in MECE overlaps.
        var overlappingBlockIDs: Set<String> = []
        for assessment in result.groupAssessments {
            overlappingBlockIDs.formUnion(assessment.overlappingMembers)
        }

        // Collect block IDs that are correctly matched group parents.
        // These are blocks whose user parent ID matches the answer-key
        // group parent ID — they should always be treated as correct
        // even if they also appear as children in a parent group's
        // overlap set (due to dictionary iteration order in the engine).
        var confirmedGroupParents: Set<String> = []
        for assessment in result.groupAssessments {
            if let matchedID = assessment.matchedAnswerGroupParentID,
               matchedID == assessment.userParentBlockID {
                confirmedGroupParents.insert(matchedID)
            }
        }

        for (blockID, status) in result.blockStatuses {
            // Confirmed group parents are always correct.
            if confirmedGroupParents.contains(blockID) {
                states[blockID] = .correct
                continue
            }

            switch status {
            case .correct:
                states[blockID] = .correct
            case .wrongParent, .wrongGroup:
                if overlappingBlockIDs.contains(blockID) {
                    states[blockID] = .meceOverlap
                } else {
                    states[blockID] = .misplaced
                }
            case .ungrouped:
                if overlappingBlockIDs.contains(blockID) {
                    states[blockID] = .meceOverlap
                } else {
                    states[blockID] = .misplaced
                }
            case .missing:
                // Missing blocks are shown as gap placeholders, not block feedback.
                break
            case .redHerringPlaced:
                states[blockID] = .misplaced
            case .redHerringDiscarded:
                // Correctly discarded — no visual feedback on the canvas.
                break
            }
        }

        return states
    }

    /// Extract gap information: blocks that should exist but are missing.
    ///
    /// Returns tuples of (parent block ID, missing member block IDs) so the
    /// UI can render placeholder outlines at the correct positions.
    static func gapPlacements(
        from result: PyramidValidationResult
    ) -> [GapPlacement] {
        var gaps: [GapPlacement] = []

        for assessment in result.groupAssessments {
            guard !assessment.missingMembers.isEmpty else { continue }
            let parentID = assessment.matchedAnswerGroupParentID
                ?? assessment.userParentBlockID

            for memberID in assessment.missingMembers.sorted() {
                gaps.append(GapPlacement(
                    parentBlockID: parentID,
                    missingBlockID: memberID
                ))
            }
        }

        return gaps
    }

    /// Whether all placed blocks are correct (complete pyramid).
    static func isPyramidComplete(_ result: PyramidValidationResult) -> Bool {
        guard result.governingThoughtCorrect else { return false }
        guard result.ungroupedBlockIDs.isEmpty else { return false }

        // Check for any non-correct block statuses.
        let hasNonCorrect = result.blockStatuses.values.contains { status in
            if case .correct = status { return false }
            return true
        }
        if hasNonCorrect { return false }

        // Check for any missing members in group assessments
        // (these may not appear in blockStatuses).
        let hasMissingMembers = result.groupAssessments.contains { assessment in
            !assessment.missingMembers.isEmpty
        }
        if hasMissingMembers { return false }

        // Check for any overlapping members in matched groups.
        // Only count overlaps from groups that matched an answer-key group,
        // since unmatched groups (like the root) produce structural noise.
        let hasOverlaps = result.groupAssessments.contains { assessment in
            assessment.matchedAnswerGroupParentID != nil
                && !assessment.overlappingMembers.isEmpty
        }
        if hasOverlaps { return false }

        return !result.blockStatuses.isEmpty
    }
}

// MARK: - Gap Placement

/// Describes where a gap placeholder should appear in the pyramid.
struct GapPlacement: Sendable, Equatable, Identifiable {
    var id: String { "\(parentBlockID)-gap-\(missingBlockID)" }
    /// The parent block under which the gap exists.
    let parentBlockID: String
    /// The ID of the missing block from the answer key.
    let missingBlockID: String
}
