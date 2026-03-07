import Foundation

/// Central coordinator for coaching sessions.
///
/// `SessionManager` orchestrates the full session lifecycle: starting a session
/// (assembling the system prompt and requesting Barbara's greeting), sending
/// learner messages and streaming Barbara's responses, managing context window
/// limits, and ending sessions with a summary.
///
/// It owns the conversation state and wires together `AnthropicService`,
/// `SystemPromptAssembler`, and `ResponseParser`.
@MainActor
@Observable
final class SessionManager {

    // MARK: - Observable State

    /// All messages in the current session.
    private(set) var messages: [ChatMessage] = []

    /// Current session lifecycle state.
    private(set) var sessionState: SessionState = .idle

    /// Metadata collected from Barbara's responses during this session.
    private(set) var sessionMetadata: [BarbaraMetadata] = []

    /// The active session type, if any.
    private(set) var activeSessionType: SessionType?

    /// The active "Say it clearly" session state, if any.
    private(set) var sayItClearlySession: SayItClearlySession?


    /// The active "Find the point" session state, if any.
    private(set) var findThePointSession: FindThePointSession?

    /// The active "Elevator pitch" session state, if any.
    private(set) var elevatorPitchSession: ElevatorPitchSession?

    /// The active "Analyse my text" session state, if any.
    private(set) var analyseMyTextSession: AnalyseMyTextSession?

    /// The active "Fix this mess" session state, if any.
    private(set) var fixThisMessSession: FixThisMessSession?

    /// The active "Spot the gap" session state, if any.
    private(set) var spotTheGapSession: SpotTheGapSession?

    /// The active "Decode and rebuild" session state, if any.
    private(set) var decodeAndRebuildSession: DecodeAndRebuildSession?

    /// The latest evaluation result from the structural evaluator.
    private(set) var lastEvaluationResult: EvaluationResult?

    // MARK: - Dependencies

    private let anthropicService: AnthropicService
    private let systemPromptAssembler: SystemPromptAssembler
    private let responseParser: ResponseParser
    let structuralEvaluator: StructuralEvaluator
    private let profileUpdater: ProfileUpdater

    /// Optional profile store for persisting session results.
    var profileStore: LearnerProfileStore?

    // MARK: - Configuration

    /// Maximum number of messages before older ones are summarized.
    static let contextWindowThreshold = 50

    /// The assembled system prompt for the current session.
    private var systemPrompt: String = ""

    // MARK: - Init

    init(
        anthropicService: AnthropicService = .shared,
        systemPromptAssembler: SystemPromptAssembler = SystemPromptAssembler(),
        responseParser: ResponseParser = ResponseParser(),
        structuralEvaluator: StructuralEvaluator = StructuralEvaluator(),
        profileUpdater: ProfileUpdater = ProfileUpdater()
    ) {
        self.anthropicService = anthropicService
        self.systemPromptAssembler = systemPromptAssembler
        self.responseParser = responseParser
        self.structuralEvaluator = structuralEvaluator
        self.profileUpdater = profileUpdater
    }

    // MARK: - Public API

    /// Start a new coaching session.
    ///
    /// Assembles the system prompt from the learner profile and session type,
    /// then sends a greeting request to Barbara so she opens the conversation.
    ///
    /// - Parameters:
    ///   - type: The session type to start.
    ///   - profile: The learner's current profile.
    ///   - language: Language code ("en" or "de").
    func startSession(type: SessionType, profile: LearnerProfile, language: String) async {
        // Reset any previous session state
        messages = []
        sessionMetadata = []
        activeSessionType = type
        sayItClearlySession = nil
        findThePointSession = nil
        elevatorPitchSession = nil
        analyseMyTextSession = nil
        fixThisMessSession = nil
        spotTheGapSession = nil
        decodeAndRebuildSession = nil

        lastEvaluationResult = nil
        sessionState = .loading

        // Assemble system prompt
        systemPrompt = systemPromptAssembler.assemble(
            level: profile.currentLevel,
            sessionType: type.rawValue,
            language: language,
            profileJSON: profile.toPromptJSON()
        )

        // Prepare the structural evaluator with cached prompt for this session
        await structuralEvaluator.prepareSession(
            level: profile.currentLevel,
            sessionType: type.rawValue,
            language: language,
            profile: profile
        )

        // Request Barbara's greeting
        await streamBarbaraResponse()
    }

    /// Start a "Say it clearly" session with a specific topic.
    ///
    /// Assembles the system prompt and injects the topic prompt so Barbara
    /// greets the learner with the topic question.
    ///
    /// - Parameters:
    ///   - topic: The topic selected from the topic bank.
    ///   - profile: The learner's current profile.
    ///   - language: Language code ("en" or "de").
    func startSayItClearlySession(topic: Topic, profile: LearnerProfile, language: String) async {
        // Reset any previous session state
        messages = []
        sessionMetadata = []
        activeSessionType = .sayItClearly
        sayItClearlySession = SayItClearlySession(topic: topic)
        findThePointSession = nil
        elevatorPitchSession = nil
        analyseMyTextSession = nil
        fixThisMessSession = nil
        spotTheGapSession = nil
        decodeAndRebuildSession = nil

        lastEvaluationResult = nil
        sessionState = .loading

        // Assemble system prompt with topic directive appended
        let basePrompt = systemPromptAssembler.assemble(
            level: profile.currentLevel,
            sessionType: SessionType.sayItClearly.rawValue,
            language: language,
            profileJSON: profile.toPromptJSON()
        )

        let topicDirective = topicDirectiveBlock(topic: topic, language: language)
        systemPrompt = basePrompt + "\n\n" + topicDirective

        // Prepare the structural evaluator for this session
        await structuralEvaluator.prepareSession(
            level: profile.currentLevel,
            sessionType: SessionType.sayItClearly.rawValue,
            language: language,
            profile: profile
        )

        // Request Barbara's greeting (she will present the topic)
        await streamBarbaraResponse()
    }

    /// Start a "Find the point" session with a specific practice text.
    ///
    /// Assembles the system prompt and injects the practice text and answer key
    /// so Barbara presents the text and evaluates the learner's extraction.
    ///
    /// - Parameters:
    ///   - practiceText: The practice text selected from the library.
    ///   - profile: The learner's current profile.
    ///   - language: Language code ("en" or "de").
    func startFindThePointSession(
        practiceText: PracticeText,
        profile: LearnerProfile,
        language: String
    ) async {
        // Reset any previous session state
        messages = []
        sessionMetadata = []
        activeSessionType = .findThePoint
        sayItClearlySession = nil
        findThePointSession = FindThePointSession(practiceText: practiceText)
        elevatorPitchSession = nil
        analyseMyTextSession = nil
        fixThisMessSession = nil
        spotTheGapSession = nil
        decodeAndRebuildSession = nil

        sessionState = .loading

        // Assemble system prompt with practice text directive appended
        let basePrompt = systemPromptAssembler.assemble(
            level: profile.currentLevel,
            sessionType: SessionType.findThePoint.rawValue,
            language: language,
            profileJSON: profile.toPromptJSON()
        )

        let textDirective = practiceTextDirectiveBlock(
            practiceText: practiceText,
            language: language
        )
        systemPrompt = basePrompt + "\n\n" + textDirective

        // Request Barbara's greeting (she will present the text)
        await streamBarbaraResponse()
    }

    /// Start a voice-first "Say it clearly" session with a specific topic.
    ///
    /// Identical to `startSayItClearlySession` but appends a voice mode
    /// directive instructing Barbara to keep spoken feedback concise.
    func startVoiceSayItClearlySession(topic: Topic, profile: LearnerProfile, language: String) async {
        // Reuse the text session setup
        await startSayItClearlySession(topic: topic, profile: profile, language: language)

        // Append voice mode directive for shorter spoken feedback
        systemPrompt += "\n\n" + voiceModeDirective(language: language)
    }

    /// Start a voice-first "Elevator Pitch" session with a specific topic.
    ///
    /// Identical to `startElevatorPitchSession` but appends a voice mode
    /// directive instructing Barbara to keep spoken feedback concise.
    func startVoiceElevatorPitchSession(topic: Topic, profile: LearnerProfile, language: String) async {
        await startElevatorPitchSession(topic: topic, profile: profile, language: language)
        systemPrompt += "\n\n" + voiceModeDirective(language: language)
    }

    /// Start a voice-first "Find the Point" session with a practice text.
    ///
    /// Identical to `startFindThePointSession` but appends a voice mode
    /// directive instructing Barbara to keep spoken feedback concise.
    func startVoiceFindThePointSession(practiceText: PracticeText, profile: LearnerProfile, language: String) async {
        await startFindThePointSession(practiceText: practiceText, profile: profile, language: language)
        systemPrompt += "\n\n" + voiceModeDirective(language: language)
    }

    /// Append the voice mode directive to the current system prompt.
    ///
    /// Call after a session is started via a coordinator to add concise
    /// spoken-feedback instructions. Safe to call multiple times (idempotent
    /// in practice since sessions reset the prompt).
    func appendVoiceDirective(language: String) {
        systemPrompt += "\n\n" + voiceModeDirective(language: language)
    }

    /// Directive appended to the system prompt for voice sessions.
    ///
    /// Instructs Barbara to keep feedback concise for spoken delivery:
    /// 2-3 sentences max per turn, punchier phrasing.
    func voiceModeDirective(language: String) -> String {
        """
        # Voice Mode

        This session uses voice interaction. The learner speaks their response \
        and your feedback is read aloud. Adapt your output for spoken delivery:

        - Keep each feedback turn to 2-3 sentences maximum.
        - Lead with your verdict, then give one specific structural critique.
        - Use short, punchy sentences. No preamble, no filler.
        - When praising, one sentence is enough: "That structure holds."
        - Avoid bullet points or numbered lists — speak in natural sentences.
        - Do NOT reduce structural rigour. The bar stays the same; the words \
        get fewer.
        """
    }

    /// Build the topic directive block injected into the system prompt.
    private func topicDirectiveBlock(topic: Topic, language: String) -> String {
        let title = topic.title(for: language)
        let prompt = topic.prompt(for: language)
        return """
        # Topic for This Session

        Present this topic to the learner. Use the prompt text below as Barbara's \
        question. Do not invent a different topic.

        **Topic:** \(title)
        **Prompt:** \(prompt)
        """
    }

    /// Build the practice text directive block injected into the system prompt
    /// for "Find the point" sessions.
    private func practiceTextDirectiveBlock(
        practiceText: PracticeText,
        language: String
    ) -> String {
        let qualityNote: String
        switch practiceText.metadata.qualityLevel {
        case .wellStructured:
            qualityNote = "This text is well-structured. The governing thought should be identifiable."
        case .buriedLead:
            qualityNote = "This text has a buried lead. The governing thought is hidden deeper in the text."
        case .rambling:
            qualityNote = "This text is rambling. The learner may correctly identify that there is no clear governing thought."
        case .adversarial:
            qualityNote = "This text appears structured but contains a hidden structural flaw."
        }

        return """
        # Practice Text for This Session

        Present this text to the learner. Ask them to identify the governing thought \
        in one sentence. Do NOT reveal the answer key.

        \(qualityNote)

        **Text:**
        \(practiceText.text)

        **Answer Key (HIDDEN — do not reveal):**
        Governing Thought: \(practiceText.answerKey.governingThought)
        Structural Assessment: \(practiceText.answerKey.structuralAssessment)
        """
    }

    /// Start an "Elevator pitch" session with a specific topic.
    ///
    /// - Parameters:
    ///   - topic: The topic selected from the topic bank.
    ///   - profile: The learner's current profile.
    ///   - language: Language code ("en" or "de").
    func startElevatorPitchSession(topic: Topic, profile: LearnerProfile, language: String) async {
        messages = []
        sessionMetadata = []
        activeSessionType = .elevatorPitch
        sayItClearlySession = nil
        findThePointSession = nil
        analyseMyTextSession = nil
        fixThisMessSession = nil
        spotTheGapSession = nil
        decodeAndRebuildSession = nil

        let duration = ElevatorPitchSession.duration(for: profile.currentLevel)
        elevatorPitchSession = ElevatorPitchSession(topic: topic, durationSeconds: duration)

        lastEvaluationResult = nil
        sessionState = .loading

        let basePrompt = systemPromptAssembler.assemble(
            level: profile.currentLevel,
            sessionType: SessionType.elevatorPitch.rawValue,
            language: language,
            profileJSON: profile.toPromptJSON()
        )

        let directive = elevatorPitchDirectiveBlock(topic: topic, duration: duration, language: language)
        systemPrompt = basePrompt + "\n\n" + directive

        await structuralEvaluator.prepareSession(
            level: profile.currentLevel,
            sessionType: SessionType.elevatorPitch.rawValue,
            language: language,
            profile: profile
        )

        await streamBarbaraResponse()
    }

    /// Build the directive block for elevator pitch sessions.
    private func elevatorPitchDirectiveBlock(topic: Topic, duration: Int, language: String) -> String {
        let title = topic.title(for: language)
        let prompt = topic.prompt(for: language)
        return """
        # Elevator Pitch Session

        Present this topic to the learner. They have \(duration) seconds to write \
        a structured response under time pressure.

        **Topic:** \(title)
        **Prompt:** \(prompt)
        **Time limit:** \(duration) seconds

        After presenting the topic, wait for the learner's response. When evaluating:
        - This response was written under time pressure. Evaluate structural \
        prioritisation above all else.
        - Did the conclusion come FIRST? Under time pressure, this is the #1 skill.
        - Value brevity-with-structure over completeness: "You only made one point, \
        but it was crystal clear. Better than three muddled points."
        - Acknowledge the constraint: "In \(duration) seconds you got the key point \
        across. That's the skill."
        - No revision loop — give final feedback and a session summary.
        - Set sessionPhase to "summary" after evaluation.
        """
    }

    /// Submit the learner's elevator pitch response (called by timer or early submit).
    func submitElevatorPitch(text: String, timedOut: Bool) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || timedOut else { return }
        guard sessionState == .active else { return }

        let responseText = trimmed.isEmpty ? "[No response — time expired]" : trimmed
        elevatorPitchSession?.recordResponse(responseText, timedOut: timedOut)

        let prefix = timedOut ? "[SYSTEM: Time expired. The learner's response below was auto-submitted.]\n\n" : ""
        let learnerMessage = ChatMessage(role: .learner, text: prefix + responseText)
        messages.append(learnerMessage)

        await streamBarbaraResponse()
    }

    /// Start an "Analyse my text" session.
    ///
    /// No topic selection — the user provides their own text. Barbara greets
    /// the learner and asks them to paste their text.
    func startAnalyseMyTextSession(profile: LearnerProfile, language: String) async {
        messages = []
        sessionMetadata = []
        activeSessionType = .analyseMyText
        sayItClearlySession = nil
        findThePointSession = nil
        elevatorPitchSession = nil
        fixThisMessSession = nil
        spotTheGapSession = nil
        decodeAndRebuildSession = nil
        analyseMyTextSession = AnalyseMyTextSession()

        lastEvaluationResult = nil
        sessionState = .loading

        let basePrompt = systemPromptAssembler.assemble(
            level: profile.currentLevel,
            sessionType: SessionType.analyseMyText.rawValue,
            language: language,
            profileJSON: profile.toPromptJSON()
        )

        let directive = analyseMyTextDirectiveBlock(language: language)
        systemPrompt = basePrompt + "\n\n" + directive

        await structuralEvaluator.prepareSession(
            level: profile.currentLevel,
            sessionType: SessionType.analyseMyText.rawValue,
            language: language,
            profile: profile
        )

        await streamBarbaraResponse()
    }

    /// Build the directive block for "Analyse my text" sessions.
    private func analyseMyTextDirectiveBlock(language: String) -> String {
        """
        # Analyse My Text Session

        The learner will paste their own text (essay, email, article draft) for \
        structural analysis. Greet them and ask them to paste or type their text.

        When evaluating:
        - Analyse the STRUCTURE of the text, never the content correctness.
        - Identify the governing thought (or note its absence).
        - Evaluate grouping, MECE compliance, and logical flow.
        - Reference specific sentences from the text in your feedback.
        - Be exploratory: "What's your main point here? I can see several \
        candidates — which one did you intend?"
        - Acknowledge real-world context: "If this is for a school essay, your \
        teacher will appreciate a clearer lead."
        - After evaluation, encourage revision: "Now revise with my feedback in \
        mind. Lead with your key point."

        If the text is too short (less than 2 sentences), ask for more: \
        "That's not enough to evaluate. Give me at least a paragraph."

        If the text is very long, focus on the overall structure and the first \
        few paragraphs in detail.

        IMPORTANT: If the text contains distressing, violent, or inappropriate \
        content, still provide structural feedback but include a content_flag \
        field in the BARBARA_META block set to true.

        Set sessionPhase to "evaluation" when providing feedback.
        After revisions are complete, provide a session summary with \
        sessionPhase "summary".
        """
    }

    // MARK: - Fix This Mess

    /// Start a "Fix this mess" session.
    ///
    /// Presents a poorly structured text and asks the learner to restructure it.
    func startFixThisMessSession(practiceText: PracticeText, profile: LearnerProfile, language: String) async {
        messages = []
        sessionMetadata = []
        activeSessionType = .fixThisMess
        sayItClearlySession = nil
        findThePointSession = nil
        elevatorPitchSession = nil
        analyseMyTextSession = nil
        spotTheGapSession = nil
        decodeAndRebuildSession = nil
        fixThisMessSession = FixThisMessSession(practiceText: practiceText)

        lastEvaluationResult = nil
        sessionState = .loading

        let basePrompt = systemPromptAssembler.assemble(
            level: profile.currentLevel,
            sessionType: SessionType.fixThisMess.rawValue,
            language: language,
            profileJSON: profile.toPromptJSON()
        )

        let directive = fixThisMessDirectiveBlock(practiceText: practiceText, language: language)
        systemPrompt = basePrompt + "\n\n" + directive

        await structuralEvaluator.prepareSession(
            level: profile.currentLevel,
            sessionType: SessionType.fixThisMess.rawValue,
            language: language,
            profile: profile
        )

        await streamBarbaraResponse()
    }

    /// Build the directive block for "Fix this mess" sessions.
    private func fixThisMessDirectiveBlock(practiceText: PracticeText, language: String) -> String {
        let answerKey = practiceText.answerKey
        return """
        # Fix This Mess Session

        Present this text to the learner and ask them to restructure it \
        with proper pyramid structure — conclusion first, then grouped supports.

        ## Original Text
        \(practiceText.text)

        ## Answer Key (hidden from learner)
        Governing thought: \(answerKey.governingThought)
        Support groups: \(answerKey.supports.map { "\($0.label): \($0.evidence.joined(separator: ", "))" }.joined(separator: "; "))
        \(answerKey.proposedRestructure.map { "Proposed restructure: \($0)" } ?? "")

        ## Evaluation Guidelines
        - The learner's restructuring does NOT need to match the answer key exactly.
        - Multiple valid restructurings are acceptable.
        - Evaluate: Did they find the conclusion? Did they group correctly? \
        Did they eliminate redundancy?
        - Reference specific parts of their restructuring in feedback.
        - One revision is allowed after feedback.
        - Be specific: "You found the main point but your second group mixes \
        two ideas — split them."
        - Word count hint: the restructured version should be similar length \
        to the original (\(practiceText.metadata.wordCount) words).
        """
    }

    // MARK: - Spot The Gap

    /// Start a "Spot the gap" session.
    ///
    /// Presents a seemingly solid argument with a hidden structural flaw.
    func startSpotTheGapSession(practiceText: PracticeText, profile: LearnerProfile, language: String) async {
        messages = []
        sessionMetadata = []
        activeSessionType = .spotTheGap
        sayItClearlySession = nil
        findThePointSession = nil
        elevatorPitchSession = nil
        analyseMyTextSession = nil
        fixThisMessSession = nil
        decodeAndRebuildSession = nil
        spotTheGapSession = SpotTheGapSession(practiceText: practiceText)

        lastEvaluationResult = nil
        sessionState = .loading

        let basePrompt = systemPromptAssembler.assemble(
            level: profile.currentLevel,
            sessionType: SessionType.spotTheGap.rawValue,
            language: language,
            profileJSON: profile.toPromptJSON()
        )

        let directive = spotTheGapDirectiveBlock(practiceText: practiceText, language: language)
        systemPrompt = basePrompt + "\n\n" + directive

        await structuralEvaluator.prepareSession(
            level: profile.currentLevel,
            sessionType: SessionType.spotTheGap.rawValue,
            language: language,
            profile: profile
        )

        await streamBarbaraResponse()
    }

    /// Build the directive block for "Spot the gap" sessions.
    private func spotTheGapDirectiveBlock(practiceText: PracticeText, language: String) -> String {
        let flaw = practiceText.answerKey.structuralFlaw
        return """
        # Spot The Gap Session

        Present this argument to the learner. It LOOKS solid but has a hidden \
        structural weakness. Ask them to find it.

        ## The Argument
        \(practiceText.text)

        ## Hidden Structural Flaw (DO NOT reveal to the learner)
        Type: \(flaw?.type ?? "unknown")
        Description: \(flaw?.description ?? "No flaw description")
        Location: \(flaw?.location ?? "unspecified")

        ## Progressive Hint System (3 tiers)
        When the learner misidentifies the flaw, provide progressively specific hints:

        ### After attempt 1 (Tier 1 — general area):
        \(flaw?.hints?.tier1 ?? "Hint: identify the general structural area (grouping, evidence, conclusion) where the problem lies. Do NOT name the specific flaw.")

        ### After attempt 2 (Tier 2 — specific element):
        \(flaw?.hints?.tier2 ?? "Hint: narrow to the specific support group or evidence item. Compare specific elements.")

        ### After attempt 3 (Tier 3 — full reveal):
        \(flaw?.hints?.tier3 ?? "Reveal the flaw with a full structural explanation. Explain WHY it's a flaw and what correct structure would look like.")

        ## Evaluation Guidelines
        - The learner has up to 3 attempts to identify the flaw.
        - If they identify it correctly at any point: confirm with a detailed explanation.
        - If they misidentify: acknowledge any valid observations, then deliver the \
        appropriate tier hint. Say "Good eye, but that's not the main problem." then \
        give the hint for their current tier.
        - After 3 failed attempts: use Tier 3 to reveal the flaw with a teaching explanation.
        - Only evaluate STRUCTURAL flaws — not content disagreements.
        - Valid flaw identifications don't need to match the exact wording, \
        just the structural concept.
        - Hints teach the NARROWING methodology: area → element → specific. \
        This narrowing process IS the skill being taught.
        """
    }

    // MARK: - Decode and Rebuild

    /// Start a "Decode and rebuild" session.
    ///
    /// Two-phase capstone: Phase 1 extracts structure, Phase 2 rebuilds.
    func startDecodeAndRebuildSession(practiceText: PracticeText, profile: LearnerProfile, language: String) async {
        messages = []
        sessionMetadata = []
        activeSessionType = .decodeAndRebuild
        sayItClearlySession = nil
        findThePointSession = nil
        elevatorPitchSession = nil
        analyseMyTextSession = nil
        fixThisMessSession = nil
        spotTheGapSession = nil
        decodeAndRebuildSession = DecodeAndRebuildSession(practiceText: practiceText)

        lastEvaluationResult = nil
        sessionState = .loading

        let basePrompt = systemPromptAssembler.assemble(
            level: profile.currentLevel,
            sessionType: SessionType.decodeAndRebuild.rawValue,
            language: language,
            profileJSON: profile.toPromptJSON()
        )

        let directive = decodeAndRebuildDirectiveBlock(practiceText: practiceText, language: language)
        systemPrompt = basePrompt + "\n\n" + directive

        await structuralEvaluator.prepareSession(
            level: profile.currentLevel,
            sessionType: SessionType.decodeAndRebuild.rawValue,
            language: language,
            profile: profile
        )

        await streamBarbaraResponse()
    }

    /// Build the directive block for "Decode and rebuild" sessions.
    private func decodeAndRebuildDirectiveBlock(practiceText: PracticeText, language: String) -> String {
        let answerKey = practiceText.answerKey
        return """
        # Decode and Rebuild Session

        This is a TWO-PHASE capstone exercise. Guide the learner through both phases.

        ## Phase 1: Extract the Structure (Break mode)
        Present this text and ask: "What is this text really saying? Extract the \
        governing thought and identify the key support groups."

        ### The Text
        \(practiceText.text)

        ### Answer Key (HIDDEN — do not reveal)
        Governing Thought: \(answerKey.governingThought)
        Support Groups: \(answerKey.supports.map { "\($0.label): \($0.evidence.joined(separator: ", "))" }.joined(separator: "; "))
        Structural Assessment: \(answerKey.structuralAssessment)

        ### Phase 1 Evaluation
        - Compare the learner's extraction against the answer key.
        - Did they find the governing thought (or correctly note its absence)?
        - Did they identify the main support groups?
        - Multiple valid groupings are acceptable.
        - Provide specific feedback: "You found the main point, but you missed \
        the economic argument as a separate support group."

        ## Transition to Phase 2
        After evaluating Phase 1, explicitly connect the two phases:
        "You found the key point. Now present it the way it SHOULD have been written."
        Or if they struggled: "Let me show you the structure. Now rebuild it \
        properly — conclusion first, then your grouped supports."
        Set sessionPhase to "phase2_prompt" during transition.

        ## Phase 2: Rebuild the Argument (Build mode)
        The learner rewrites the argument in their own words with clean pyramid structure.

        ### Phase 2 Evaluation
        - Evaluate the STRUCTURE of their rewrite, not content accuracy.
        - Did they lead with a clear governing thought?
        - Are supports logically grouped?
        - Is the overall structure an improvement on the original?
        - One revision is allowed after feedback.
        - Word count hint: similar length to the original (\(practiceText.metadata.wordCount) words).

        ## Session Summary
        After Phase 2 evaluation, provide a combined summary:
        - Phase 1 score: how well they extracted the structure
        - Phase 2 score: how well they rebuilt it
        - Key insight connecting both phases
        Set sessionPhase to "summary" for the final message.
        """
    }

    /// Send a learner message and stream Barbara's response.
    ///
    /// - Parameter text: The learner's message text.
    func sendMessage(text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard sessionState == .active else { return }

        // Add the learner message
        let learnerMessage = ChatMessage(role: .learner, text: trimmed)
        messages.append(learnerMessage)

        // Track response attempts in "Say it clearly" session
        if sayItClearlySession != nil {
            sayItClearlySession?.recordAttempt(trimmed)

            // Inject revision context if this is a revision
            if sayItClearlySession!.currentRevisionRound > 0 {
                injectRevisionContext()
            }
        }

        // Track extraction attempts in "Find the point" session
        if findThePointSession != nil && !findThePointSession!.hasUsedRetry {
            findThePointSession?.recordAttempt(trimmed)
        }

        // Track submissions in "Analyse my text" session
        if analyseMyTextSession != nil {
            analyseMyTextSession?.recordSubmission(trimmed)
        }

        // Check context window limits
        if messages.count > Self.contextWindowThreshold {
            summarizeOlderMessages()
        }

        // Stream Barbara's response
        await streamBarbaraResponse()
    }

    /// Whether the learner's input should be pre-loaded with their previous
    /// response for revision editing.
    var revisionPreloadText: String? {
        guard let session = sayItClearlySession else { return nil }
        // Only pre-load after feedback has been given (we have a response and
        // the last message is from Barbara with scores) and revisions remain.
        guard session.hasResponse, session.canRevise else { return nil }
        guard let lastBarbaraMsg = messages.last(where: { $0.role == .barbara }),
              lastBarbaraMsg.metadata != nil,
              !lastBarbaraMsg.metadata!.scores.isEmpty else { return nil }
        // Only pre-load if the learner hasn't already typed something new
        return session.latestAttemptText
    }

    /// Request the session summary after the revision loop completes.
    func requestSessionSummary() async {
        guard var session = sayItClearlySession, !session.summaryRequested else { return }
        session.markSummaryRequested()
        sayItClearlySession = session

        // Inject a summary directive as a system-level user message
        let summaryDirective = buildSummaryDirective()
        let directiveMessage = ChatMessage(role: .learner, text: summaryDirective)
        messages.append(directiveMessage)

        await streamBarbaraResponse()
    }

    /// End the current session.
    ///
    /// Clears conversation state and returns to idle. The session summary
    /// (last metadata) remains accessible until a new session starts.
    func endSession() {
        // Apply profile updates from this session's metadata before clearing
        let metadata = sessionMetadata
        let sessionType = activeSessionType?.rawValue ?? ""
        if let store = profileStore, !metadata.isEmpty {
            Task {
                try? await profileUpdater.applySessionResults(
                    store: store,
                    metadataList: metadata,
                    sessionType: sessionType
                )
            }
        }

        activeSessionType = nil
        sayItClearlySession = nil

        findThePointSession = nil
        elevatorPitchSession = nil
        analyseMyTextSession = nil
        fixThisMessSession = nil
        spotTheGapSession = nil
        decodeAndRebuildSession = nil

        lastEvaluationResult = nil
        sessionState = .idle
        messages = []
        systemPrompt = ""
        // sessionMetadata is preserved until next startSession
        Task { await structuralEvaluator.reset() }
    }

    /// The number of remaining evaluation calls in this session.
    var remainingEvaluations: Int {
        get async { await structuralEvaluator.remainingCalls }
    }

    /// The number of evaluation calls made in this session.
    var evaluationCallCount: Int {
        get async { await structuralEvaluator.callCount }
    }

    // MARK: - Private: Revision Loop

    /// Inject a hidden system message with revision context so Barbara can
    /// compare the original and revised responses.
    private func injectRevisionContext() {
        guard let session = sayItClearlySession, session.attempts.count >= 2 else { return }

        let originalText = session.attempts[0].text
        let revisedText = session.attempts.last!.text

        // Check if unchanged
        if session.isLatestAttemptUnchanged {
            // Barbara will see the flag and call it out
            let context = """
            [SYSTEM: The learner has resubmitted their response WITHOUT changes. \
            The text is identical to their previous attempt. Call this out — \
            ask them to read your feedback and make specific changes.]
            """
            let contextMsg = ChatMessage(role: .learner, text: context)
            // Insert before the learner's latest message
            let insertIndex = max(0, messages.count - 1)
            messages.insert(contextMsg, at: insertIndex)
            return
        }

        let revisionRound = session.currentRevisionRound
        let maxRevisions = session.maxRevisions
        let isLastRevision = revisionRound >= maxRevisions

        var context = """
        [SYSTEM: This is revision \(revisionRound) of \(maxRevisions). \
        Compare the revised response against the original and note what \
        improved, what stayed the same, and what regressed. \
        Focus on structural changes, not content changes.

        ORIGINAL RESPONSE:
        \(originalText)

        REVISED RESPONSE:
        \(revisedText)
        """

        if isLastRevision {
            context += """

            This is the FINAL revision. After your evaluation, provide a brief \
            session summary: what was practiced, what improved across revisions, \
            and one key structural takeaway. Set sessionPhase to "summary".]
            """
        } else {
            context += """

            After evaluation, prompt the learner to revise again if there is \
            room for structural improvement. Even strong revisions should get \
            a push for tighter structure.]
            """
        }

        let contextMsg = ChatMessage(role: .learner, text: context)
        // Insert before the learner's latest message
        let insertIndex = max(0, messages.count - 1)
        messages.insert(contextMsg, at: insertIndex)
    }

    /// Build a directive for Barbara to summarise the session.
    private func buildSummaryDirective() -> String {
        guard let session = sayItClearlySession else { return "" }

        var parts = ["[SYSTEM: The revision loop is complete. Summarise this session:"]
        for (index, attempt) in session.attempts.enumerated() {
            let label = index == 0 ? "FIRST DRAFT" : "REVISION \(index)"
            parts.append("\(label):\n\(attempt.text)")
        }
        parts.append("""
        Provide a brief session summary covering:
        1. What structural skill was practiced
        2. What improved across revisions
        3. One key takeaway for the learner
        Set sessionPhase to "summary" and mood to "teaching".]
        """)
        return parts.joined(separator: "\n\n")
    }

    // MARK: - Private: Streaming

    private func streamBarbaraResponse() async {
        sessionState = .loading

        // Create a placeholder streaming message
        let streamingMessage = ChatMessage(
            role: .barbara,
            text: "",
            isStreaming: true
        )
        messages.append(streamingMessage)
        let streamingIndex = messages.count - 1

        do {
            // Build API messages from conversation history (exclude empty streaming placeholder)
            let apiMessages = messages
                .filter { !$0.text.isEmpty }
                .map { message in
                    APIMessage(
                        role: message.role == .barbara ? "assistant" : "user",
                        content: message.text
                    )
                }

            // Stream response from Anthropic
            let stream = await anthropicService.sendMessage(
                systemPrompt: systemPrompt,
                messages: apiMessages
            )

            var fullText = ""
            for try await chunk in stream {
                fullText += chunk
                messages[streamingIndex].text = fullText
            }

            // Parse the complete response for hidden metadata
            let parsed = responseParser.parse(fullResponse: fullText)
            messages[streamingIndex].text = parsed.visibleText
            messages[streamingIndex].isStreaming = false

            if let metadata = parsed.metadata {
                messages[streamingIndex].metadata = metadata
                sessionMetadata.append(metadata)

                // Capture evaluation result when the response contains scores
                if !metadata.scores.isEmpty {
                    lastEvaluationResult = EvaluationResult(
                        feedbackText: parsed.visibleText,
                        metadata: metadata
                    )
                }
            }

            sessionState = .active

        } catch {
            // Remove the empty streaming message on error
            if messages[streamingIndex].text.isEmpty {
                messages.remove(at: streamingIndex)
            } else {
                messages[streamingIndex].isStreaming = false
            }
            sessionState = .error(error.localizedDescription)
        }
    }

    // MARK: - Private: Context Window Management

    /// Summarize older messages when the conversation exceeds the threshold.
    ///
    /// Keeps the first message (Barbara's greeting) and the most recent messages,
    /// replacing the middle portion with a summary message.
    private func summarizeOlderMessages() {
        let keepRecentCount = 20
        let keepFromStart = 1 // Keep Barbara's greeting

        guard messages.count > keepFromStart + keepRecentCount else { return }

        let startMessages = Array(messages.prefix(keepFromStart))
        let middleMessages = Array(messages.dropFirst(keepFromStart).dropLast(keepRecentCount))
        let recentMessages = Array(messages.suffix(keepRecentCount))

        // Build a text summary of the middle messages
        let summaryLines = middleMessages.map { msg in
            let role = msg.role == .barbara ? "Barbara" : "Learner"
            let truncated = String(msg.text.prefix(200))
            return "[\(role)] \(truncated)"
        }

        let summaryText = "[Session context summary — \(middleMessages.count) earlier messages condensed]\n\n"
            + summaryLines.joined(separator: "\n")

        let summaryMessage = ChatMessage(
            role: .barbara,
            text: summaryText
        )

        messages = startMessages + [summaryMessage] + recentMessages
    }
}
