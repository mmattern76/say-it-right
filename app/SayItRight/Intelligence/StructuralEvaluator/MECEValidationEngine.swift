import Foundation

// MARK: - Answer Key Types for Pyramid Exercises

/// Defines valid groupings for a pyramid builder exercise.
/// Multiple valid arrangements are supported — the answer key defines which
/// blocks belong together, not their exact positions.
struct PyramidAnswerKey: Sendable, Equatable, Codable {
    /// The block ID that should be the governing thought (root).
    let governingThoughtID: String
    /// Valid group arrangements. Each `ValidGroup` maps a support-point block
    /// to its expected evidence children. Multiple alternative groupings can
    /// be provided — the engine picks the best match.
    let validGroupings: [ValidGrouping]
}

/// One complete valid arrangement of the pyramid.
struct ValidGrouping: Sendable, Equatable, Codable {
    /// The groups that make up this arrangement.
    let groups: [ValidGroup]
}

/// A single support group: a parent block with its expected children.
struct ValidGroup: Sendable, Equatable, Codable {
    /// The block ID for the support point (group parent).
    let parentBlockID: String
    /// The block IDs that belong under this parent (order does not matter).
    let memberBlockIDs: Set<String>
}

// MARK: - Validation Result Types

/// Overall result of comparing the user's pyramid against the answer key.
struct PyramidValidationResult: Sendable, Equatable {
    /// Per-block validation status.
    let blockStatuses: [String: BlockValidationStatus]
    /// Group-level MECE assessment.
    let groupAssessments: [GroupAssessment]
    /// Whether the governing thought is correctly placed as root.
    let governingThoughtCorrect: Bool
    /// Overall pyramid score (0.0 to 1.0).
    let score: Double
    /// Blocks that are placed but not in any valid group.
    let ungroupedBlockIDs: Set<String>
    /// Which valid grouping was matched (index into answer key's validGroupings).
    let matchedGroupingIndex: Int?
}

/// Validation status for a single block.
enum BlockValidationStatus: Sendable, Equatable {
    /// Block is in the correct group under the correct parent.
    case correct
    /// Block is in a valid group but under the wrong parent.
    case wrongParent(expectedParentID: String)
    /// Block is placed but belongs in a different group entirely.
    case wrongGroup(expectedGroupParentID: String)
    /// Block is placed but does not appear in any valid group.
    case ungrouped
    /// Block is not placed at all but should be.
    case missing
}

/// MECE assessment for a single group in the user's pyramid.
struct GroupAssessment: Sendable, Equatable {
    /// The user's group parent block ID.
    let userParentBlockID: String
    /// The matched answer-key group parent block ID, if any.
    let matchedAnswerGroupParentID: String?
    /// Blocks correctly placed in this group.
    let correctMembers: Set<String>
    /// Blocks in this group that belong elsewhere (overlap).
    let overlappingMembers: Set<String>
    /// Blocks that should be in this group but are missing (gap).
    let missingMembers: Set<String>
    /// Whether this group is MECE-compliant (no overlaps, no gaps).
    var isMECE: Bool { overlappingMembers.isEmpty && missingMembers.isEmpty }
}

// MARK: - User Tree Representation

/// Lightweight representation of the user's pyramid tree for validation.
/// Decoupled from the UI-bound PyramidTreeState.
struct UserPyramidTree: Sendable, Equatable {
    /// The root block ID, if one is placed.
    let rootBlockID: String?
    /// Parent-to-children mapping. Key is parent block ID, value is set of child block IDs.
    let parentToChildren: [String: Set<String>]
    /// All placed block IDs.
    let allPlacedBlockIDs: Set<String>

    /// Extract a UserPyramidTree from a PyramidTreeState's placed blocks.
    init(rootBlockID: String?, parentToChildren: [String: Set<String>], allPlacedBlockIDs: Set<String>) {
        self.rootBlockID = rootBlockID
        self.parentToChildren = parentToChildren
        self.allPlacedBlockIDs = allPlacedBlockIDs
    }
}

// MARK: - MECE Validation Engine

/// Pure-logic engine that compares the user's pyramid arrangement against
/// an answer key and identifies structural correctness and MECE violations.
///
/// This is Layer 3 (Intelligence) — no UI dependencies.
struct MECEValidationEngine: Sendable {

    // MARK: - Public API

    /// Validate the user's pyramid tree against the answer key.
    ///
    /// The engine tries each valid grouping and picks the one that produces
    /// the highest score (best match).
    func validate(userTree: UserPyramidTree, answerKey: PyramidAnswerKey) -> PyramidValidationResult {
        // Check governing thought placement.
        let governingThoughtCorrect = userTree.rootBlockID == answerKey.governingThoughtID

        // If no valid groupings defined, return basic result.
        guard !answerKey.validGroupings.isEmpty else {
            return PyramidValidationResult(
                blockStatuses: [:],
                groupAssessments: [],
                governingThoughtCorrect: governingThoughtCorrect,
                score: governingThoughtCorrect ? 1.0 : 0.0,
                ungroupedBlockIDs: [],
                matchedGroupingIndex: nil
            )
        }

        // Try each valid grouping and pick the best match.
        var bestResult: PyramidValidationResult?
        var bestScore: Double = -1

        for (index, grouping) in answerKey.validGroupings.enumerated() {
            let result = validateAgainstGrouping(
                userTree: userTree,
                answerKey: answerKey,
                grouping: grouping,
                groupingIndex: index,
                governingThoughtCorrect: governingThoughtCorrect
            )
            if result.score > bestScore {
                bestScore = result.score
                bestResult = result
            }
        }

        return bestResult!
    }

    // MARK: - Private

    /// Validate the user's tree against a single valid grouping.
    private func validateAgainstGrouping(
        userTree: UserPyramidTree,
        answerKey: PyramidAnswerKey,
        grouping: ValidGrouping,
        groupingIndex: Int,
        governingThoughtCorrect: Bool
    ) -> PyramidValidationResult {
        // Build the best mapping between user groups and answer groups.
        let mapping = findBestGroupMapping(userTree: userTree, grouping: grouping)

        var blockStatuses: [String: BlockValidationStatus] = [:]
        var groupAssessments: [GroupAssessment] = []
        var accountedBlocks: Set<String> = []

        // Track which answer groups have been matched.
        var matchedAnswerGroups: Set<String> = Set(mapping.values.map { $0.parentBlockID })

        // Evaluate each user group (each parent node with children).
        for (userParentID, userChildren) in userTree.parentToChildren {
            // Skip root's own entry if root is governing thought — it's not a "group" in MECE sense.
            // We evaluate root separately.

            let matchedAnswerGroup = mapping[userParentID]
            let expectedMembers = matchedAnswerGroup.map { Set($0.memberBlockIDs) } ?? Set()

            let correctMembers = userChildren.intersection(expectedMembers)
            let overlappingMembers = userChildren.subtracting(expectedMembers)
            let missingMembers = expectedMembers.subtracting(userChildren)

            let assessment = GroupAssessment(
                userParentBlockID: userParentID,
                matchedAnswerGroupParentID: matchedAnswerGroup?.parentBlockID,
                correctMembers: correctMembers,
                overlappingMembers: overlappingMembers,
                missingMembers: missingMembers
            )
            groupAssessments.append(assessment)

            // Set per-block statuses for children in this group.
            for childID in userChildren {
                if correctMembers.contains(childID) {
                    blockStatuses[childID] = .correct
                } else if let correctGroup = findCorrectGroup(for: childID, in: grouping) {
                    blockStatuses[childID] = .wrongGroup(expectedGroupParentID: correctGroup.parentBlockID)
                } else {
                    blockStatuses[childID] = .ungrouped
                }
                accountedBlocks.insert(childID)
            }

            // Mark the user parent block status.
            if matchedAnswerGroup != nil && matchedAnswerGroup?.parentBlockID == userParentID {
                blockStatuses[userParentID] = .correct
            }
            accountedBlocks.insert(userParentID)
        }

        // Check for answer-key groups with no user match (completely missing groups).
        for answerGroup in grouping.groups {
            if !matchedAnswerGroups.contains(answerGroup.parentBlockID) {
                // This entire group is missing from the user's arrangement.
                let assessment = GroupAssessment(
                    userParentBlockID: answerGroup.parentBlockID,
                    matchedAnswerGroupParentID: answerGroup.parentBlockID,
                    correctMembers: [],
                    overlappingMembers: [],
                    missingMembers: answerGroup.memberBlockIDs
                )
                groupAssessments.append(assessment)

                // Mark all members as missing.
                for memberID in answerGroup.memberBlockIDs {
                    if blockStatuses[memberID] == nil {
                        blockStatuses[memberID] = .missing
                    }
                }
                // Mark the group parent as missing if not placed.
                if !userTree.allPlacedBlockIDs.contains(answerGroup.parentBlockID) {
                    blockStatuses[answerGroup.parentBlockID] = .missing
                }
            }
        }

        // Identify ungrouped blocks: placed but not accounted for in any group.
        let ungroupedBlockIDs = userTree.allPlacedBlockIDs
            .subtracting(accountedBlocks)
            .subtracting(userTree.rootBlockID.map { Set([$0]) } ?? [])

        for blockID in ungroupedBlockIDs {
            if let correctGroup = findCorrectGroup(for: blockID, in: grouping) {
                blockStatuses[blockID] = .wrongGroup(expectedGroupParentID: correctGroup.parentBlockID)
            } else {
                blockStatuses[blockID] = .ungrouped
            }
        }

        // Handle governing thought block status.
        if governingThoughtCorrect {
            blockStatuses[answerKey.governingThoughtID] = .correct
        } else if let rootID = userTree.rootBlockID {
            // Wrong block is at root.
            if let correctGroup = findCorrectGroup(for: rootID, in: grouping) {
                blockStatuses[rootID] = .wrongGroup(expectedGroupParentID: correctGroup.parentBlockID)
            }
            // The correct governing thought is misplaced or missing.
            if blockStatuses[answerKey.governingThoughtID] == nil {
                if userTree.allPlacedBlockIDs.contains(answerKey.governingThoughtID) {
                    // It's placed but not as root — it might have been marked in a group already.
                    // Keep existing status if any; otherwise mark as wrongParent.
                } else {
                    blockStatuses[answerKey.governingThoughtID] = .missing
                }
            }
        }

        // Compute score.
        let score = computeScore(
            blockStatuses: blockStatuses,
            groupAssessments: groupAssessments,
            governingThoughtCorrect: governingThoughtCorrect,
            answerKey: answerKey,
            grouping: grouping
        )

        return PyramidValidationResult(
            blockStatuses: blockStatuses,
            groupAssessments: groupAssessments,
            governingThoughtCorrect: governingThoughtCorrect,
            score: score,
            ungroupedBlockIDs: ungroupedBlockIDs,
            matchedGroupingIndex: groupingIndex
        )
    }

    /// Find which answer-key group a block belongs to.
    private func findCorrectGroup(for blockID: String, in grouping: ValidGrouping) -> ValidGroup? {
        grouping.groups.first { group in
            group.memberBlockIDs.contains(blockID) || group.parentBlockID == blockID
        }
    }

    /// Greedy bipartite matching: map each user group to the answer-key group
    /// with the highest overlap (Jaccard similarity).
    private func findBestGroupMapping(
        userTree: UserPyramidTree,
        grouping: ValidGrouping
    ) -> [String: ValidGroup] {
        var mapping: [String: ValidGroup] = [:]
        var usedAnswerGroups: Set<String> = []

        // Build scored pairs: (userParentID, answerGroup, jaccardScore).
        struct ScoredPair: Comparable {
            let userParentID: String
            let answerGroup: ValidGroup
            let score: Double

            static func < (lhs: ScoredPair, rhs: ScoredPair) -> Bool {
                lhs.score < rhs.score
            }
        }

        var pairs: [ScoredPair] = []

        for (userParentID, userChildren) in userTree.parentToChildren {
            // Include the parent itself in the comparison set for parent-level matching.
            let userSet = userChildren

            for answerGroup in grouping.groups {
                let answerSet = answerGroup.memberBlockIDs
                let intersection = userSet.intersection(answerSet).count
                let union = userSet.union(answerSet).count

                let jaccardScore: Double
                if union == 0 {
                    // Check if the user parent matches the answer group parent.
                    jaccardScore = userParentID == answerGroup.parentBlockID ? 0.5 : 0.0
                } else {
                    let jaccard = Double(intersection) / Double(union)
                    // Bonus if parent IDs match.
                    let parentBonus: Double = userParentID == answerGroup.parentBlockID ? 0.1 : 0.0
                    jaccardScore = jaccard + parentBonus
                }

                if jaccardScore > 0 {
                    pairs.append(ScoredPair(
                        userParentID: userParentID,
                        answerGroup: answerGroup,
                        score: jaccardScore
                    ))
                }
            }
        }

        // Sort descending by score — greedy matching.
        pairs.sort { $0.score > $1.score }

        var mappedUserParents: Set<String> = []

        for pair in pairs {
            guard !mappedUserParents.contains(pair.userParentID),
                  !usedAnswerGroups.contains(pair.answerGroup.parentBlockID) else {
                continue
            }
            mapping[pair.userParentID] = pair.answerGroup
            mappedUserParents.insert(pair.userParentID)
            usedAnswerGroups.insert(pair.answerGroup.parentBlockID)
        }

        return mapping
    }

    /// Compute an overall score (0.0 to 1.0) from validation results.
    private func computeScore(
        blockStatuses: [String: BlockValidationStatus],
        groupAssessments: [GroupAssessment],
        governingThoughtCorrect: Bool,
        answerKey: PyramidAnswerKey,
        grouping: ValidGrouping
    ) -> Double {
        // Total expected elements: governing thought + all group parents + all group members.
        var totalExpected = 1 // governing thought
        for group in grouping.groups {
            totalExpected += 1 // group parent
            totalExpected += group.memberBlockIDs.count
        }

        guard totalExpected > 0 else { return governingThoughtCorrect ? 1.0 : 0.0 }

        var correctCount = 0

        // Governing thought.
        if governingThoughtCorrect {
            correctCount += 1
        }

        // Count correct blocks.
        for (_, status) in blockStatuses {
            if case .correct = status {
                correctCount += 1
            }
        }

        // Subtract 1 if governing thought was already counted in blockStatuses as correct.
        if governingThoughtCorrect, let gtStatus = blockStatuses[answerKey.governingThoughtID],
           case .correct = gtStatus {
            correctCount -= 1 // Avoid double-counting.
        }

        return min(1.0, Double(correctCount) / Double(totalExpected))
    }
}

// MARK: - Convenience Initialiser from PyramidTreeState

extension UserPyramidTree {
    /// Create a UserPyramidTree from a PyramidTreeState's placed blocks.
    @MainActor
    static func from(_ treeState: PyramidTreeState) -> UserPyramidTree {
        let rootID = treeState.rootBlockID.map { $0.uuidString }

        var parentToChildren: [String: Set<String>] = [:]
        var allPlaced: Set<String> = []

        for (id, placed) in treeState.placedBlocks {
            let idString = id.uuidString
            allPlaced.insert(idString)

            if !placed.childIDs.isEmpty {
                parentToChildren[idString] = Set(placed.childIDs.map { $0.uuidString })
            }
        }

        return UserPyramidTree(
            rootBlockID: rootID,
            parentToChildren: parentToChildren,
            allPlacedBlockIDs: allPlaced
        )
    }
}
