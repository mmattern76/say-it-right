import SwiftUI

/// Visual variant of "Fix this mess" — starts with a broken pyramid arrangement.
///
/// The user must diagnose what is wrong and drag blocks to fix the structure.
/// Similar to BuildThePyramidView but initializes with a wrong arrangement
/// and tracks which blocks the user has moved.
struct FixThisMessVisualView: View {
    let sessionManager: SessionManager
    let coordinator: FixThisMessVisualCoordinator
    let profile: LearnerProfile
    let language: String
    var onDismiss: (() -> Void)?

    @State private var viewModel: ChatViewModel
    @State private var treeState = PyramidTreeState()
    @State private var sessionStarted = false
    @State private var noExercisesAvailable = false
    @State private var exercise: FixThisMessExercise?
    @State private var validationResult: PyramidValidationResult?
    @State private var blockFeedbackStates: [String: BlockFeedbackState] = [:]
    @State private var gapPlacements: [GapPlacement] = []
    @State private var isPyramidComplete = false
    @State private var feedbackConfig = FeedbackConfiguration()
    @State private var attempts = 0
    /// Track which blocks the user has moved from their original wrong position.
    @State private var movedBlockIDs: Set<String> = []
    /// Original wrong positions for change tracking.
    @State private var originalParentMap: [String: String] = [:]
    @State private var sessionHaptic: PyramidHaptic?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(
        sessionManager: SessionManager,
        coordinator: FixThisMessVisualCoordinator,
        profile: LearnerProfile,
        language: String,
        onDismiss: (() -> Void)? = nil
    ) {
        self.sessionManager = sessionManager
        self.coordinator = coordinator
        self.profile = profile
        self.language = language
        self.onDismiss = onDismiss
        self._viewModel = State(initialValue: ChatViewModel(sessionManager: sessionManager))
    }

    var body: some View {
        Group {
            if noExercisesAvailable {
                noExercisesView
            } else if exercise != nil {
                sessionContent
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(language == "de" ? "Räum das auf (visuell)" : "Fix this mess (visual)")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: endSessionAndDismiss) {
                    Label(
                        language == "de" ? "Beenden" : "End Session",
                        systemImage: "xmark.circle"
                    )
                }
            }
        }
        .task {
            guard !sessionStarted else { return }
            sessionStarted = true
            let ex = await coordinator.startSession(
                sessionManager: sessionManager,
                profile: profile,
                language: language
            )
            if let ex {
                exercise = ex
                setupWrongArrangement(ex)
            } else {
                noExercisesAvailable = true
            }
        }
    }

    // MARK: - Session Content

    @ViewBuilder
    private var sessionContent: some View {
        AdaptivePyramidLayout {
            pyramidCanvas
        } sidebar: {
            ChatView(viewModel: viewModel)
        }
    }

    // MARK: - Pyramid Canvas

    private var pyramidCanvas: some View {
        VStack(spacing: 12) {
            // Governing thought (fixed at top)
            if let ex = exercise {
                VStack(spacing: 4) {
                    Text(ex.governingThought.text)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(BlockType.governingThought.color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Text(language == "de"
                         ? "Diese Pyramide ist kaputt. Repariere sie!"
                         : "This pyramid is broken. Fix it!")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .fontWeight(.medium)
                }
                .padding(.top, 12)
            }

            // Pyramid tree area
            GeometryReader { geo in
                ZStack {
                    // Connection lines
                    if let rootID = treeState.rootBlockID,
                       let rootNode = treeState.buildTreeNode(from: rootID) {
                        ConnectionLinesView(
                            nodeLayouts: treeState.nodeLayouts,
                            connections: rootNode.extractConnections(),
                            dragOverrides: [:]
                        )
                    }

                    // Drop zones
                    DropZoneOverlay(
                        zones: treeState.dropZones,
                        highlightedZoneID: treeState.highlightedZoneID
                    )

                    // Placed blocks
                    ForEach(Array(treeState.placedBlocks.values), id: \.id) { placed in
                        if let layout = treeState.nodeLayouts[placed.id.uuidString] {
                            DraggableBlockView(
                                block: placed.block,
                                visualState: .placed,
                                onDragChanged: { value in
                                    treeState.beginDrag(blockID: placed.id)
                                    treeState.updateDrag(position: value.location)
                                },
                                onDragEnded: { value in
                                    if let zone = treeState.endDrag(position: value.location) {
                                        treeState.reparentBlock(placed.id, toParent: UUID(uuidString: zone.parentID)!, atIndex: zone.childIndex)
                                        trackMove(blockID: placed.id.uuidString)
                                        sessionHaptic = .validDrop
                                    }
                                }
                            )
                            .validationFeedback(blockFeedbackStates[placed.id.uuidString] ?? .none)
                            .overlay(alignment: .topLeading) {
                                if movedBlockIDs.contains(placed.id.uuidString) {
                                    Image(systemName: "arrow.turn.up.right")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                        .padding(3)
                                }
                            }
                            .position(layout.center)
                        }
                    }

                    // Feedback overlays
                    if feedbackConfig.isEnabled {
                        PyramidFeedbackOverlay(
                            blockFeedbackStates: blockFeedbackStates,
                            gaps: gapPlacements,
                            nodeLayouts: treeState.nodeLayouts,
                            layoutEngine: treeState.layoutEngine,
                            isPyramidComplete: isPyramidComplete,
                            configuration: $feedbackConfig
                        )
                    }
                }
            }

            // Unplaced blocks pool (blocks removed from tree go here)
            if !treeState.unplacedBlocks.isEmpty {
                UnplacedBlocksPool(
                    blocks: treeState.unplacedBlocks,
                    onDragChanged: { block, value in
                        treeState.beginDrag(blockID: block.id)
                        treeState.updateDrag(position: value.location)
                    },
                    onDragEnded: { block, value in
                        let zone = treeState.endDrag(position: value.location)
                        if zone == nil {
                            placeBlockInTree(block)
                        }
                        trackMove(blockID: block.id.uuidString)
                        sessionHaptic = .validDrop
                    }
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }

            // Action buttons
            HStack(spacing: 16) {
                Button(action: checkArrangement) {
                    Label(
                        language == "de" ? "Prüfen" : "Check",
                        systemImage: "checkmark.circle"
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(!treeState.unplacedBlocks.isEmpty)

                if attempts >= 3 {
                    Button(action: showAnswer) {
                        Label(
                            language == "de" ? "Lösung zeigen" : "Show Answer",
                            systemImage: "eye"
                        )
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.bottom, 12)

            // Change tracking indicator
            if !movedBlockIDs.isEmpty {
                Text(language == "de"
                     ? "\(movedBlockIDs.count) Block(s) verschoben"
                     : "\(movedBlockIDs.count) block(s) moved")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            }
        }
        .pyramidHaptic(sessionHaptic)
    }

    // MARK: - Exercise Setup

    private func setupWrongArrangement(_ exercise: FixThisMessExercise) {
        // Build a mapping from exercise block IDs to PyramidBlock instances
        var blockMap: [String: PyramidBlock] = [:]

        // Create governing thought as root
        let rootBlock = PyramidBlock(
            text: exercise.governingThought.text,
            type: exercise.governingThought.type.blockType,
            level: 0
        )
        blockMap[exercise.governingThought.id] = rootBlock
        treeState.placeAsRoot(rootBlock)

        // Create all blocks
        for block in exercise.blocks {
            let pyramidBlock = PyramidBlock(
                text: block.text,
                type: block.type.blockType,
                level: nil
            )
            blockMap[block.id] = pyramidBlock
        }

        // Place support points under root according to wrong arrangement
        for wrongGroup in exercise.wrongArrangement.groups {
            guard let parentBlock = blockMap[wrongGroup.parentBlockID],
                  let rootID = treeState.rootBlockID else { continue }

            // Place the support point under root
            let parentChildIndex = treeState.placedBlocks[rootID]?.childIDs.count ?? 0
            treeState.placeBlock(parentBlock, underParent: rootID, atIndex: parentChildIndex)

            // Record original parent for change tracking
            originalParentMap[wrongGroup.parentBlockID] = rootID.uuidString

            // Place children under this support point
            for (index, childID) in wrongGroup.childBlockIDs.enumerated() {
                guard let childBlock = blockMap[childID] else { continue }
                treeState.placeBlock(childBlock, underParent: parentBlock.id, atIndex: index)
                originalParentMap[childID] = parentBlock.id.uuidString
            }
        }

        // Any blocks not in the wrong arrangement go to unplaced pool
        let placedIDs = Set(treeState.placedBlocks.keys.map { $0.uuidString })
        for block in exercise.blocks {
            if blockMap[block.id] != nil && !placedIDs.contains(blockMap[block.id]!.id.uuidString) {
                treeState.addToUnplacedPool(blockMap[block.id]!)
            }
        }
    }

    private func placeBlockInTree(_ block: PyramidBlock) {
        guard let rootID = treeState.rootBlockID else { return }
        let childCount = treeState.placedBlocks[rootID]?.childIDs.count ?? 0
        treeState.placeBlock(block, underParent: rootID, atIndex: childCount)
    }

    private func trackMove(blockID: String) {
        movedBlockIDs.insert(blockID)
    }

    // MARK: - Validation

    private func checkArrangement() {
        guard let exercise else { return }

        let userTree = UserPyramidTree.from(treeState)
        let result = coordinator.validateArrangement(
            userTree: userTree,
            answerKey: exercise.answerKey
        )
        validationResult = result
        attempts += 1

        // Map validation result to visual feedback
        blockFeedbackStates = ValidationFeedbackMapper.blockFeedbackStates(from: result)
        gapPlacements = ValidationFeedbackMapper.gapPlacements(from: result)
        isPyramidComplete = ValidationFeedbackMapper.isPyramidComplete(result)
        feedbackConfig.isEnabled = true

        if isPyramidComplete {
            sessionHaptic = .pyramidComplete
        } else {
            sessionHaptic = .invalidDrop
        }

        // Build description including change tracking for Barbara
        let description = buildArrangementDescription(result: result)
        Task {
            await sessionManager.evaluatePyramidArrangement(description: description)
        }
    }

    private func buildArrangementDescription(result: PyramidValidationResult) -> String {
        let score = Int(result.score * 100)
        let correct = result.blockStatuses.values.filter { if case .correct = $0 { return true } else { return false } }.count
        let total = result.blockStatuses.count
        let govCorrect = result.governingThoughtCorrect ? "yes" : "no"

        var desc = "[FIX THIS MESS — Attempt \(attempts)]\n"
        desc += "Score: \(score)%, Correct blocks: \(correct)/\(total), Governing thought correct: \(govCorrect)\n"
        desc += "Blocks moved by learner: \(movedBlockIDs.count)\n"

        for assessment in result.groupAssessments {
            if !assessment.overlappingMembers.isEmpty {
                desc += "MECE violation: group under \(assessment.userParentBlockID) has overlapping members\n"
            }
            if !assessment.missingMembers.isEmpty {
                desc += "Missing members in group under \(assessment.userParentBlockID)\n"
            }
        }

        if result.score >= 1.0 {
            desc += "PYRAMID FIXED — all blocks correctly placed."
        } else if movedBlockIDs.isEmpty {
            desc += "DIAGNOSIS ONLY — learner checked without making changes."
        }

        return desc
    }

    private func showAnswer() {
        Task {
            await sessionManager.evaluatePyramidArrangement(
                description: "[SHOW ANSWER REQUESTED — reveal the correct arrangement and explain what was broken in the original]"
            )
        }
    }

    // MARK: - No Exercises

    private var noExercisesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.3.group")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(language == "de"
                 ? "Keine \u{00DC}bungen verf\u{00FC}gbar"
                 : "No exercises available")
                .font(.title3)
                .fontWeight(.semibold)

            Text(language == "de"
                 ? "Es gibt aktuell keine passenden \u{00DC}bungen f\u{00FC}r dein Level."
                 : "There are no matching exercises for your current level.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let onDismiss {
                Button(language == "de" ? "Zur\u{00FC}ck" : "Go Back") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
        }
        .padding(32)
    }

    // MARK: - Actions

    private func endSessionAndDismiss() {
        sessionManager.endSession()
        onDismiss?()
    }
}

// MARK: - Previews

#Preview("Fix This Mess Visual") {
    NavigationStack {
        FixThisMessVisualView(
            sessionManager: SessionManager(),
            coordinator: FixThisMessVisualCoordinator(exercises: []),
            profile: .createDefault(displayName: "Alex"),
            language: "en"
        )
    }
}
