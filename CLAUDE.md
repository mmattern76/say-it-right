# Say it right! / Sag's richtig! — Instructions for Claude Code

## What This Is
Universal app (iOS, iPadOS, macOS) teaching structured thinking and
communication skills — the meta-skill underneath argumentation,
persuasion, and effective LLM interaction. Rooted in Barbara Minto's
Pyramid Principle, adapted for teenagers and young adults (13+).

Lead character is Barbara, a strict but good-natured teacher figure who
holds you to a structural standard. She evaluates the *architecture* of
your thinking, not the content of your opinions.

## Tech Stack
- **Platform**: iOS 17+ / iPadOS 17+ / macOS 14+, Swift 6, SwiftUI
- **AI Backend**: Anthropic API (Claude Sonnet 4.5 — claude-sonnet-4-5-20250929)
- **Voice**: Apple Speech Framework (STT), Apple TTS for Barbara (try built-in first; ElevenLabs as upgrade path)
- **State**: Local JSON files (Codable structs), iCloud Drive sync for backup
- **Distribution**: TestFlight (private, family only)
- **No backend server.** The app talks directly to the Anthropic API.

## Architecture (4 Layers — dependencies flow downward only)
- Layer 4: **Presentation** — SwiftUI views (platform-adaptive), chat UI, Barbara avatar, pyramid visualiser, progress dashboard
- Layer 3: **Intelligence** — System prompt engine, conversation manager, structural evaluator, text generator, response parser
- Layer 2: **State** — Learner profile, session history, progression tracker, language settings
- Layer 1: **Content** — Exercise library, practice text corpus, evaluation rubrics, progression criteria

## Barbara's Personality (Critical — read prompts/barbara-system-prompt.md)
- Strict but good-natured. Elementary school teacher energy for older students.
- DIRECT: "That's not a conclusion, that's a preamble. Start over."
- STRUCTURALLY OBSESSIVE: Praises architecture, not content. "I disagree with your point, but your reasoning is airtight."
- ECONOMICAL WITH PRAISE: When it comes, it lands. "Now *that* is how you make a point."
- MODELS WHAT SHE TEACHES: Barbara's own speech is always pyramid-structured. She never rambles.
- NO TOLERANCE FOR MUSH: "There are many reasons" → "Which reasons? Pick your strongest."
- All interaction in configured language (German or English). All code in English.

## Two Core Modes
- **Build ("Sag's!" / "Say it!")** — User formulates structured responses; Barbara evaluates pyramid quality
- **Break ("Versteh's!" / "Get it!")** — User extracts/diagnoses structure from presented texts

## Session Types
- "Say it clearly" / "Sag's klar" — Quick structured response drill
- "Find the point" / "Finde den Punkt" — Extract governing thought
- "Fix this mess" / "Räum das auf" — Restructure a badly organised argument
- "Build the pyramid" / "Bau die Pyramide" — Visual drag-and-drop tree construction
- "The elevator pitch" / "30 Sekunden" — Timed spoken drill
- "Spot the gap" / "Finde die Lücke" — Find hidden structural weakness
- "Decode and rebuild" / "Entschlüsseln und Neubauen" — Full-cycle read + restructure

## Progression Levels
- Level 1 "Klartext" / "Plain Talk" — Foundations (lead with answer, one idea per block, "so what?" test)
- Level 2 "Ordnung" / "Order" — Grouping & logic (MECE, deductive vs. inductive, SCQ)
- Level 3 "Architektur" / "Architecture" — Advanced structures (issue trees, vertical/horizontal logic, synthesis)
- Level 4 "Meisterschaft" / "Mastery" — Real-world application (LLM prompts, exec summaries, presentations)

## Platform Postures
- **iPhone** — Voice-primary (TTS+STT). Short oral drills. Barbara in your pocket.
- **iPad** — Touch + visual. Drag-and-drop pyramid builder. Side-by-side text analysis.
- **Mac** — Keyboard + visual. Long-form writing exercises. "Analyse my text" feature.

## Code Conventions
- No third-party dependencies without explicit approval
- SwiftUI previews for every view
- Structured concurrency (async/await, no Combine)
- Tests: at minimum, test the intelligence layer (prompt assembly, structural evaluation, response parsing)
- API key stored in iOS Keychain — NEVER in UserDefaults, SwiftData, or source code

## Project Structure
```
app/SayItRight/
├── App/                    # Entry point, DI container, language config
├── Presentation/           # Layer 4: SwiftUI views
│   ├── Chat/               # Chat interface, message bubbles, Barbara avatar
│   ├── Dashboard/          # Progress dashboard, level visualization
│   ├── Session/            # Session management (mode selection, start, end)
│   ├── PyramidBuilder/     # Visual drag-and-drop tree construction (iPad/Mac)
│   └── VoiceDrill/         # Voice interaction UI (iPhone-primary)
├── Intelligence/           # Layer 3: LLM integration
│   ├── SystemPrompt/       # Modular prompt assembly (Barbara persona + rubric)
│   ├── ConversationManager/ # Message history, streaming
│   ├── StructuralEvaluator/ # Pyramid quality scoring, MECE checks
│   ├── TextGenerator/      # Practice text creation with answer keys
│   └── ResponseParser/     # Split visible chat from hidden evaluation data
├── State/                  # Layer 2: Persistence
│   ├── LearnerProfile/     # Level progression, strengths, development areas
│   ├── SessionHistory/     # Past session summaries, scores
│   └── Settings/           # Language, platform preferences
└── Content/                # Layer 1: Curriculum
    ├── ExerciseLibrary/    # Exercise templates per session type
    ├── PracticeTexts/      # Pre-generated texts with hidden answer keys
    ├── EvaluationRubrics/  # Structural quality criteria per level
    └── ProgressionCriteria/ # Level-up thresholds and signals
```

## Git Workflow
- Branch: `feat/{issue-number}-{slug}`
- Commit: conventional commits (`feat:`, `fix:`, `chore:`, `content:`)
- Always run `swift build` before pushing
- PR title references the issue number

## Key Design Rules
- **Structural evaluation, not content critique** — Barbara never judges whether
  an opinion is "right", only whether the argument structure holds
- **Hidden metadata pattern**: Every Barbara response includes a JSON postscript
  (invisible to user) with structural scores, progression signals, level data
- **System prompt is modular**: assembled per request (Identity, Pedagogy,
  Evaluation Rubric, Learner Profile, Session Directive, Output Format)
- **Language-aware, not translated**: German and English content uses
  culturally appropriate examples and rhetorical conventions
- **Platform-adaptive UI**: Same codebase, different interaction patterns
  per device class (voice-first on iPhone, visual on iPad, keyboard on Mac)

## Design Decisions (Resolved)
- **Barbara's visual design**: Midjourney-generated illustrations. Style must feel
  distinct from the animal characters in the other portfolio apps (Plato, Think).
  Human-looking, illustrated, not photorealistic. Glasses on-brand.
- **Voice**: Start with Apple built-in TTS (human review for quality). ElevenLabs
  is the upgrade path if built-in quality is insufficient. Voice quality is critical
  on iPhone where voice is the primary interaction mode.
- **Gamification**: Streaks and progress tracking only. No leaderboards, no points.
  Barbara's personality is the primary motivator, not extrinsic rewards.
- **User-submitted text analysis ("Analyse my text")**: Introduce early (E3/E4).
  Family-only distribution means no content moderation risk for now. AI flags
  concerning input and logs it for learnings on how to handle this at scale later.
- **LLM prompt training (Level 4)**: Yes, with live Claude API calls. User writes
  a prompt, sends it, sees the result alongside Barbara's structural critique.
  Rate-limited: max 10 requests/day, configurable in parent settings.
- **Monetization**: Deferred. Family-only TestFlight for now.

## Session Workflow

Stories follow pattern SIR-NNN. One named session per story.

```bash
claude                                    # start new session
/rename sir-SIR-007                       # name it immediately
claude --resume                           # resume (pick from list)
claude --continue                         # resume most recent session
```

Cross-story context persists via `.claude/MEMORY.md` — each completed
story appends a summary there, and each new story reads it.

## Slash Commands

### Story lifecycle (in .claude/commands/project/)

```bash
/project:start-story SIR-007      # load issue, create branch, begin implementing
/project:start-story next          # pull next unstarted story from backlog
/project:complete-story            # test, commit, push, create PR, update board
/project:implement-story next      # fully autonomous: start → implement → complete
/project:implement-epic E1 E2      # implement all stories in epic(s), any board status
/project:implement-all             # implement all Todo stories across all epics
```

### Analyst (in .claude/commands/analyst/)

```bash
/analyst:analyze-epic E1 E2 E3     # break epic(s) into new stories with acceptance criteria
/analyst:refine-epic E1 E2         # refine all existing stories in epic(s)
/analyst:refine-story SIR-001      # refine specific story(ies), or "new: <desc>" to create
```

### QA (in .claude/commands/qa/)

```bash
/qa:review-story SIR-007           # adopt QA persona, review story against acceptance criteria
/qa:safety-audit                   # full codebase pedagogy & safety sweep
```

### Barbara testing (in .claude/commands/barbara/)

```bash
/barbara:test-session klartext      # simulate coaching session, evaluate structural feedback quality
/barbara:test-session ordnung       # test with different level
```

## Session Lifecycle

```
Story SIR-007 assigned
  │
  ├─ claude
  │  /rename sir-SIR-007
  │    ├─ CLAUDE.md loaded (project rules)
  │    ├─ /project:start-story SIR-007
  │    │    └─ reads .claude/MEMORY.md (cross-story context)
  │    │    └─ reads issue body from GitHub
  │    │    └─ creates feat/7-<slug> branch
  │    │    └─ begins implementation (no confirmation)
  │    ├─ ... implementation work ...
  │    ├─ (break) claude --continue
  │    ├─ ... more work ...
  │    ├─ /project:complete-story
  │    │    └─ tests, fix loop
  │    │    └─ commits, pushes, creates PR
  │    │    └─ appends learnings to .claude/MEMORY.md
  │    │    └─ resets session (/compact)
  │    └─ session ends
  │
  ▼
Story SIR-008 starts
  │
  ├─ claude
  │  /rename sir-SIR-008
  │    ├─ /project:start-story SIR-008
  │    │    └─ reads .claude/MEMORY.md → knows SIR-007 patterns
  │    └─ ... continues with full project context
```
