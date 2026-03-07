import SwiftUI

/// Full session view for "Build the Pyramid" exercises.
///
/// Displays the governing thought at top, an unplaced block pool, and the
/// pyramid canvas where users drag blocks into position. Barbara evaluates
/// via a sidebar chat after the user taps "Check".
struct BuildThePyramidView: View {
    let sessionManager: SessionManager
    let coordinator: BuildThePyramidCoordinator
    let profile: LearnerProfile
    let language: String
    var onDismiss: (() -> Void)?

    @State private var viewModel: ChatViewModel
    @State private var treeState = PyramidTreeState()
    @State private var sessionStarted = false
    @State private var noExercisesAvailable = false
    @State private var exercise: PyramidExercise?
    @State private var validationResult: PyramidValidationResult?
    @State private var blockFeedbackStates: [String: BlockFeedbackState] = [:]
    @State private var gapPlacements: [GapPlacement] = []
    @State private var isPyramidComplete = false
    @State private var feedbackConfig = FeedbackConfiguration()
    @State private var attempts = 0

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(
        sessionManager: SessionManager,
        coordinator: BuildThePyramidCoordinator,
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
        .navigationTitle(SessionType.buildThePyramid.displayName(language: language))
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
                setupExercise(ex)
            } else {
                noExercisesAvailable = true
            }
        }
    }

    // MARK: - Session Content

    @ViewBuilder
    private var sessionContent: some View {
        #if os(macOS)
        splitLayout
        #else
        if horizontalSizeClass == .regular {
            splitLayout
        } else {
            compactLayout
        }
        #endif
    }

    /// iPad/Mac: pyramid left, chat right.
    private var splitLayout: some View {
        HStack(spacing: 0) {
            pyramidCanvas
                .frame(maxWidth: .infinity)

            Divider()

            VStack(spacing: 0) {
                ChatView(viewModel: viewModel)
                    .frame(maxWidth: .infinity)
            }
            .frame(width: 320)
        }
    }

    /// iPhone: pyramid above, feedback below.
    private var compactLayout: some View {
        VStack(spacing: 0) {
            pyramidCanvas

            Divider()

            ChatView(viewModel: viewModel)
                .frame(maxHeight: 200)
        }
    }

    // MARK: - Pyramid Canvas

    private var pyramidCanvas: some View {
        VStack(spacing: 12) {
            // Governing thought (fixed at top)
            if let ex = exercise {
                Text(ex.governingThought.text)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(BlockType.governingThought.color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
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
                                    }
                                }
                            )
                            .validationFeedback(blockFeedbackStates[placed.id.uuidString] ?? .none)
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

            // Unplaced blocks pool
            UnplacedBlocksPool(
                blocks: treeState.unplacedBlocks,
                onDragChanged: { block, value in
                    treeState.beginDrag(blockID: block.id)
                    treeState.updateDrag(position: value.location)
                },
                onDragEnded: { block, value in
                    // endDrag handles placement from unplaced pool internally
                    let zone = treeState.endDrag(position: value.location)
                    if zone == nil {
                        // Dropped outside any zone — place under root as fallback
                        placeBlockInTree(block)
                    }
                }
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            // Action buttons
            HStack(spacing: 16) {
                Button(action: checkArrangement) {
                    Label(
                        language == "de" ? "Prüfen" : "Check",
                        systemImage: "checkmark.circle"
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(treeState.unplacedBlocks.count > 0)

                if sessionManager.buildThePyramidSession?.canShowAnswer == true {
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
        }
    }

    // MARK: - Exercise Setup

    private func setupExercise(_ exercise: PyramidExercise) {
        // Place governing thought as root
        let rootBlock = PyramidBlock(
            text: exercise.governingThought.text,
            type: exercise.governingThought.type.blockType,
            level: 0
        )
        treeState.placeAsRoot(rootBlock)

        // Add remaining blocks to unplaced pool
        for block in exercise.blocks {
            let pyramidBlock = PyramidBlock(
                text: block.text,
                type: block.type.blockType,
                level: nil
            )
            treeState.addToUnplacedPool(pyramidBlock)
        }
    }

    private func placeBlockInTree(_ block: PyramidBlock) {
        // Place under root if no children yet, or find first available parent
        guard let rootID = treeState.rootBlockID else { return }
        let childCount = treeState.placedBlocks[rootID]?.childIDs.count ?? 0
        treeState.placeBlock(block, underParent: rootID, atIndex: childCount)
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
        sessionManager.recordPyramidAttempt(score: result.score)

        // Map validation result to visual feedback
        blockFeedbackStates = ValidationFeedbackMapper.blockFeedbackStates(from: result)
        gapPlacements = ValidationFeedbackMapper.gapPlacements(from: result)
        isPyramidComplete = ValidationFeedbackMapper.isPyramidComplete(result)
        feedbackConfig.isEnabled = true

        // Send description to Barbara for textual feedback
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

        var desc = "[PYRAMID CHECK — Attempt \(attempts)]\n"
        desc += "Score: \(score)%, Correct blocks: \(correct)/\(total), Governing thought correct: \(govCorrect)\n"

        for assessment in result.groupAssessments {
            if !assessment.overlappingMembers.isEmpty {
                desc += "MECE violation: group under \(assessment.userParentBlockID) has overlapping members\n"
            }
            if !assessment.missingMembers.isEmpty {
                desc += "Missing members in group under \(assessment.userParentBlockID)\n"
            }
        }

        if result.score >= 1.0 {
            desc += "PYRAMID COMPLETE — all blocks correctly placed."
        }

        return desc
    }

    private func showAnswer() {
        sessionManager.revealPyramidAnswer()
        Task {
            await sessionManager.evaluatePyramidArrangement(
                description: "[SHOW ANSWER REQUESTED — reveal the correct arrangement and explain why]"
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

#Preview("Build the Pyramid") {
    NavigationStack {
        BuildThePyramidView(
            sessionManager: SessionManager(),
            coordinator: BuildThePyramidCoordinator(exercises: []),
            profile: .createDefault(displayName: "Alex"),
            language: "en"
        )
    }
}
