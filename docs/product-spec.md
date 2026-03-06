# Say it right! / Sag's richtig!

## Product Concept Specification

---

## Vision

**Say it right!** teaches teenagers and young adults the most transferable communication skill there is: structuring thought. Rooted in Barbara Minto's Pyramid Principle and expanded with modern structured-thinking frameworks, the app trains two complementary abilities:

1. **Build** — formulate your thoughts and position in a clear, structured manner
2. **Break** — quickly absorb and decode written (or spoken) trains of thought

These are the foundational skills for effective communication with both humans and LLMs. Every other communication skill — argumentation (Überzeuge mich!), philosophical reasoning (Plato), persuasion, academic writing — sits on top of structural literacy. Say it right! trains the meta-skill.

---

## Barbara — The Lead Character

Barbara is a middle-aged, well-spoken woman. Strict but good-natured. Think elementary school teacher energy applied to older students — she holds you to a standard because she knows you can meet it.

### Personality Traits

- **Direct.** Barbara doesn't pad her feedback. "That's not a conclusion, that's a preamble. Start over."
- **Structurally obsessive.** She praises architecture, not content. "I disagree with your point, but your reasoning is excellent. Well done."
- **Economical with praise.** When it comes, it lands. "Now *that* is how you make a point."
- **Models what she teaches.** Barbara's own speech is always crisp and pyramid-structured. She never rambles. The student absorbs good structure just by interacting with her.
- **Warm underneath.** She remembers what you struggled with last time. "You used to bury your conclusions. Look at you now — leading with the answer. I'm impressed."
- **No tolerance for mush.** Vague language gets called out immediately. "There are many reasons" → "Which reasons? Pick your strongest and start there."

### Voice & Language

Barbara speaks in both German and English, configured per user. Her German is educated Hochdeutsch — the kind of teacher who corrects your "weil" clause word order. Her English is precise without being stiff. In both languages, she is the embodiment of clear expression.

For TTS: a warm but authoritative female voice, moderate pace, clear enunciation. Not robotic, not overly cheerful. Think public radio host, not Siri.

### Visual Design

Barbara should feel real but stylized — not a cartoon character, not a photorealistic render. An illustrated style that conveys competence and warmth. Glasses optional but on-brand. She gestures when she explains (for animated versions). Her expressions are readable: the raised eyebrow when you're rambling, the slight nod when you get it right, the crossed arms when you're being lazy.

#### Barbara's Mood Artwork

Midjourney-generated illustrations at @2x and @3x scales. Each mood maps to a structural metadata tag from Barbara's hidden response JSON:

| Mood | Asset | When Used |
|------|-------|-----------|
| Attentive | `barbara-attentive` | Listening to user input, waiting for response |
| Skeptical | `barbara-raised-eyebrow` | Spotting structural weakness, vague language |
| Approving | `barbara-nodding` | User's structure is solid |
| Waiting | `barbara-crossed-arms` | User is rambling, needs to cut |
| Proud | `barbara-warm-smile` | Level-up moments, strong improvement |
| Evaluating | `barbara-thinking` | Processing, analyzing structure |
| Teaching | `barbara-explaining` | Explaining a concept, giving instruction |
| Disappointed | `barbara-disappointed` | Repeated same mistake, lazy attempt |

A full-height launch portrait (`launch-barbara`) is used in onboarding and splash screens.

#### Learner Avatars

Profile avatars sourced from the Think app: Maxi and Alex. Used during onboarding selection and in the chat UI alongside the learner's messages.

---

## Pedagogical Framework

### The Pyramid Principle — Core Concepts

The app teaches the Minto Pyramid Principle as its backbone, adapted and expanded for a younger audience.

**Core Insight:** Communication is most effective when you state your conclusion first, then group your supporting arguments logically, then provide evidence for each. Most people do the opposite — they build up to their point. This is harder to follow, harder to remember, and harder to act on.

### Progression Levels

#### Level 1 — Foundations ("Klartext" / "Plain Talk")

Target: Complete beginners, younger teenagers (13–14)

Concepts:
- Lead with your answer (the "so what?" test)
- One main idea per paragraph or statement
- The difference between a topic and a position
- Eliminating filler and mush words

Barbara's tone at this level: Patient, encouraging, lots of concrete examples. "Let's try something. Tell me your opinion about homework — but the very first sentence has to be your conclusion. No setup, no background. Just your point."

#### Level 2 — Grouping & Logic ("Ordnung" / "Order")

Target: Intermediate, ages 14–16

Concepts:
- MECE grouping (Mutually Exclusive, Collectively Exhaustive) — taught as "No overlaps, no gaps"
- Deductive vs. inductive ordering
- The SCQ framework (Situation → Complication → Question → Answer)
- Recognizing when a list is really a hierarchy
- Horizontal logic (do these things at the same level actually belong together?)

Barbara's tone: More demanding. "You gave me four reasons, but two and four are the same point in different words. That's not four reasons, that's three — and one of them is weak. Cut it."

#### Level 3 — Advanced Structures ("Architektur" / "Architecture")

Target: Advanced, ages 16–18

Concepts:
- Issue trees and problem decomposition
- Vertical logic (does each level of detail actually support the level above it?)
- Synthesizing multiple sources into one coherent structure
- Spotting logical gaps, non-sequiturs, and false groupings
- Governing thoughts vs. mere summaries
- The difference between grouping by structure and grouping by process

Barbara's tone: Collegial but exacting. "Your pyramid holds, but your governing thought is a summary, not an insight. 'Three factors affect climate change' isn't a conclusion — it's a table of contents. What do those three factors *tell us*?"

#### Level 4 — Real-World Application ("Meisterschaft" / "Mastery")

Target: Young adults, university prep, 18+

Concepts:
- Writing effective LLM prompts (the meta-skill made explicit)
- Executive summaries and one-pagers
- Structuring presentations and pitches
- Debriefing a complex text in 60 seconds
- Structured responses under time pressure
- Peer review through a structural lens

Barbara's tone: Near-peer professional. "This prompt would confuse a human and it will confuse an AI. You're asking three questions disguised as one. Separate them, lead with context, and specify what you want. Try again."

---

## Two Modes

### Mode 1: Build ("Sag's!" / "Say it!")

The user has a thought, opinion, or argument. The app guides them through structuring it top-down.

**Flow:**
1. Barbara poses a question or the user brings their own topic
2. The user formulates a response (spoken via STT on mobile, or typed on tablet/desktop)
3. Barbara analyzes the *structure* — not grammar, not style, not content correctness
4. Feedback is specific and actionable: "Your conclusion is in sentence three. Move it to the front." / "Points B and C overlap. Merge them or differentiate them."
5. The user revises
6. Barbara confirms or pushes further

**What Barbara evaluates:**
- Is there a clear governing thought / conclusion?
- Does it come first?
- Are supporting points grouped logically (MECE)?
- Does the evidence actually support each point?
- Is there redundancy?
- Is the structure appropriate for the complexity of the topic?

**What Barbara explicitly does NOT evaluate:**
- Grammar and spelling (she might note it but it's not the focus)
- Whether the opinion is "correct"
- Writing style or eloquence
- Factual accuracy of claims (though she may flag obviously unsupported assertions)

### Mode 2: Break ("Versteh's!" / "Get it!")

The user receives a text and must extract or diagnose its structure.

**Flow:**
1. Barbara presents a text (generated by AI at calibrated difficulty)
2. The user must identify: What is the main claim? What are the supporting pillars? Where is the evidence?
3. On iPad/Mac: visual pyramid-building exercise (drag and drop elements into a tree structure)
4. On iPhone: spoken summary ("Tell me what this person is actually saying, in one sentence")
5. Barbara evaluates the extraction and points out what was missed or misidentified

**Text quality spectrum:**
- **Well-structured texts** (easier): Clean pyramids where the structure is visible. Good for beginners learning to recognize the pattern.
- **Buried-lead texts** (medium): The conclusion is there but hidden in paragraph three. Common in academic and corporate writing.
- **Rambling texts** (hard): No clear structure. The user must identify that the structure is *missing* and propose what it *should* be.
- **Adversarial texts** (expert): Texts that *appear* structured but have logical gaps, false groupings, or non-sequitur evidence. The user must spot the flaw.

**Text sources:**
- AI-generated practice texts (primary, for controlled difficulty calibration)
- Real-world texts from news, opinion pieces, corporate communications (with appropriate licensing/fair use)
- User-submitted texts ("Barbara, can you help me understand this article?")

---

## Session Types

### "Say it clearly" / "Sag's klar"
Barbara gives a topic. 30–60 seconds to formulate a structured response. Spoken or written. Evaluated on pyramid quality. Quick, daily-drill format.

### "Find the point" / "Finde den Punkt"
A text is presented. User extracts the governing thought in one sentence. Trains the core reading comprehension skill. Can be timed for challenge.

### "Fix this mess" / "Räum das auf"
A badly structured argument with good content. User restructures it into a clean pyramid. On iPad: drag-and-drop. On iPhone: dictate the restructured version.

### "Build the pyramid" / "Bau die Pyramide"
Visual exercise. A claim and a pile of unsorted supporting points. Arrange them into a proper tree — grouping, ordering, eliminating redundancies. The Tetris-for-arguments mode.

### "The elevator pitch" / "30 Sekunden"
Timed. Barbara says: "You have 30 seconds. Convince me." Forces ruthless prioritization and top-down structure under pressure. Spoken only.

### "Spot the gap" / "Finde die Lücke"
A seemingly solid argument with a hidden structural weakness. User must identify what's missing, what doesn't follow, or what's grouped incorrectly. Barbara's hardest exercise.

### "Decode and rebuild" / "Entschlüsseln und Neubauen"
Combines both modes. Read a complex text. Extract the pyramid. Then re-present the argument in your own words with better structure. The full-cycle exercise.

---

## AI Architecture

### Claude's Role

Claude serves two functions:

**1. Structural Coach (evaluation)**
Analyzes the user's output for structural quality. This is where the Pyramid Principle criteria become a structured evaluation rubric passed to Claude:

- Governing thought present and positioned first? (Score + feedback)
- Supports grouped by MECE logic? (Score + feedback)
- Evidence aligned to correct support points? (Score + feedback)
- Redundancy detected? (Flag)
- Appropriate complexity for the user's level? (Calibration signal)

The system prompt for Claude embodies Barbara's personality and adapts to the user's current level.

**2. Text Generator (content creation)**
Produces practice texts at specified difficulty levels and on age-appropriate topics. Each generated text comes with a hidden "answer key" — the intended pyramid structure — against which the user's extraction is compared.

### Real-Time vs. Batch

Unlike MeTube, this app benefits from real-time AI interaction. The conversational drill format (Barbara asks → user responds → Barbara gives feedback → user revises) requires synchronous Claude API calls. This is acceptable because:

- Interactions are 1:1 and user-initiated (no background processing needed)
- Latency tolerance is higher (a 2–3 second "thinking" pause feels natural — Barbara is "reading your response")
- The evaluation rubric is well-structured, keeping responses focused and fast
- Volume per user is moderate (a few exercises per session, not continuous streaming)

However, text generation for the "Break" mode exercises can be pre-generated in batches to ensure variety and quality control. A library of practice texts at various difficulty levels, refreshed periodically via batch jobs.

### Prompt Architecture

**Barbara's system prompt** should:
- Establish her personality and communication style
- Include the full structural evaluation rubric for the user's current level
- Specify the language (German or English)
- Include the user's progression history (what they've mastered, where they struggle)
- Constrain feedback to structural concerns (explicitly exclude grammar, style, factual critique)

**Text generation prompts** should:
- Specify difficulty level, target length, and topic domain
- Request both the text AND the "hidden pyramid" answer key
- Ensure topic age-appropriateness
- Produce texts in the configured language

---

## Platform Design — Universal App

### iPhone — "Barbara in Your Pocket"

**Primary interaction mode:** Voice (TTS + STT)

The iPhone is the daily drill device. Short, focused exercises optimized for spoken interaction.

Key features:
- "Say it clearly" drills with voice input
- "The elevator pitch" timed challenges
- "Find the point" with text displayed and spoken summary expected
- Push notification reminders: "Good morning. Barbara has a question for you."
- Progress streaks and daily practice tracking

UI: Minimal. Barbara's avatar, the current prompt or text, a microphone button, and feedback display. No complex visual layouts — the phone is for oral drills.

### iPad — "The Workbench"

**Primary interaction mode:** Touch + visual + optional voice

The iPad is for deeper exercises that benefit from screen real estate.

Key features:
- "Build the pyramid" with drag-and-drop visual tree construction
- "Fix this mess" with side-by-side view (original text left, restructured version right)
- "Decode and rebuild" full-cycle exercises
- Written response mode for "Say it clearly" (typing rather than speaking)
- Visual progress map showing the full Level 1–4 journey

UI: Split-view layouts. A visual pyramid builder component that feels tactile and satisfying — blocks that snap into place, connections that draw themselves, elements that glow when MECE is achieved.

### Mac — "The Serious Desk"

**Primary interaction mode:** Keyboard + visual

The Mac is for advanced users and real-world application.

Key features:
- Longer-form writing exercises with structural feedback
- Multi-source synthesis exercises
- "Analyze my text" — paste in your own essay, email, or report and get Barbara's structural critique
- LLM prompt structuring workshop (Level 4)
- Export and share structured outputs

UI: Desktop-native layout. Wider panels, keyboard shortcuts, potentially a menu bar widget for quick drills.

---

## Progression & Maturity Assessment

### Adaptive Difficulty

Like the other apps in the portfolio, Say it right! adapts to the user's demonstrated ability rather than relying on self-reported age or grade level.

**Assessment dimensions:**
- **Structural complexity tolerance:** Can they handle 2-level pyramids? 3-level? Multiple competing arguments?
- **Speed of extraction:** How quickly do they identify the governing thought in "Break" mode?
- **Revision efficiency:** How many iterations does it take to reach a clean structure in "Build" mode?
- **Self-correction rate:** Do they catch their own structural issues before Barbara points them out?
- **Consistency across topics:** Do they maintain structural discipline on unfamiliar topics, or only on comfortable ones?

### Progression Signals

Barbara explicitly marks transitions between levels: "You've been consistent with your grouping for two weeks now. It's time to learn about horizontal logic — this is where it gets interesting."

Level transitions are celebrated but not gamified into meaninglessness. Barbara doesn't hand out trophies — she acknowledges growth: "Compare your answer today to what you wrote three months ago. You've come a long way."

### Parent Visibility

Parents can view:
- Current level and progression pace
- Session frequency and duration
- Specific skill areas (strengths and development areas)
- Sample exercises and Barbara's feedback (read-only)

Parents cannot:
- Alter the curriculum or skip levels
- See the content of the user's opinions or arguments (privacy for the learner's intellectual development)
- Override Barbara's assessment

---

## Language Configuration

The app supports German and English as content languages, configured at the user level.

- **German mode ("Sag's richtig!"):** All UI, all Barbara dialogue, all practice texts, and all evaluation in German. Barbara speaks educated Hochdeutsch.
- **English mode ("Say it right!"):** All of the above in English. Barbara speaks clear, precise English.
- **Language switching:** The user can switch between languages in settings. Progress is tracked per language independently, since structural literacy may develop at different rates in different languages.

The pedagogical content is language-aware, not merely translated. German examples use German rhetorical conventions. English examples use English ones. The Pyramid Principle itself is universal, but its application is culturally contextualized.

---

## Relationship to Portfolio

Say it right! is the foundational skill trainer in the educational app family:

- **Überzeuge mich!** requires structured argumentation → Say it right! teaches the structure
- **Plato** requires clear philosophical reasoning → Say it right! teaches clarity of thought expression
- **Professor Albert** requires problem decomposition → Say it right!'s issue trees are the same skill
- **Das Wunderbuch** develops narrative comprehension → "Break" mode trains comprehension of non-fiction

The long-term vision may involve cross-app skill recognition ("Your pyramid skills from Say it right! have unlocked advanced debate mode in Überzeuge mich!"), but this is a future consideration, not a V1 requirement.

---

## Technical Architecture (V1)

### App Architecture

- **SwiftUI universal app** (iOS 17+, iPadOS 17+, macOS 14+) with platform-adaptive layouts
- **Direct Claude API integration** for real-time conversational evaluation
- **Local storage** for user progression, session history, and settings (Codable JSON)
- **Pre-generated text library** bundled with the app (refreshed via app updates; later via backend content feed)
- **Apple Speech Framework** for STT; Apple TTS for Barbara's voice (ElevenLabs as upgrade path)
- **Parent controls** via PIN + Face ID protected settings section
- **Distribution:** TestFlight (private, family only)

### Backend (Railway)

Express.js + TypeScript + Prisma ORM, deployed on Railway with PostgreSQL:

- **Cross-device sync** — Pull/push API for learner profiles, session summaries, seen texts
- **Dynamic model catalog** — Proxies `anthropic.models.list()` with 1-hour cache; app fetches available models from here instead of hardcoding
- **Debug log collection** — When debug mode is enabled, the app uploads structured JSONL entries to the backend for remote diagnosis
- **Health endpoint** — `/api/v1/health` for monitoring

All endpoints (except health) require `X-API-Key` header authentication.

### Configuration

`Config.plist` (gitignored, template committed as `Config.template.plist`):

| Key | Purpose |
|-----|---------|
| `AnthropicAPIKey` | Bundled Anthropic API key |
| `BackendURL` | Railway backend URL |
| `BackendAPIKey` | Backend authentication key |
| `ElevenLabsAPIKey` | ElevenLabs API key (upgrade path) |
| `ElevenLabsVoiceID_DE` | ElevenLabs voice ID for German Barbara |
| `ElevenLabsVoiceID_EN` | ElevenLabs voice ID for English Barbara |

The Anthropic API key can be overridden at runtime via parent settings (stored in iOS Keychain). Resolution order: Keychain override > Config.plist > nil.

### Dynamic Model Selection

The app fetches available Claude models from the backend `/api/v1/models` endpoint, which proxies the Anthropic Models API with a 1-hour cache. A hardcoded fallback list is used when the backend is unreachable.

When the Anthropic API returns an "unknown model" error, the app automatically selects the best-fit replacement using family matching (e.g., sonnet 4.7 replaces defunct sonnet 4.4).

### Onboarding

First-time welcome flow with three phases:
1. **Welcome** — Barbara introduces herself with character-by-character typing + TTS narration
2. **Avatar selection** — Pick Maxi or Alex, enter name
3. **Pep talk** — Barbara delivers a personalized motivational message

The welcome message is replayable from the profile screen after onboarding.

### TestFlight Deployment

Automated via `scripts/testflight-upload.sh`:
1. Bumps build number in `project.yml`
2. Regenerates Xcode project via XcodeGen
3. Archives Release build
4. Uploads to App Store Connect

Bundle ID: `io.mattern.say-it-right`, Team: `LC9HD3YWNR`

### Content Pipeline (Post-V1)

When the pre-bundled text library needs to grow beyond what app updates can sustain:

- A batch job generates new practice texts with answer keys
- Content is reviewed (automated quality checks + periodic human review)
- Delivered to the app via the backend content feed

---

## Design Decisions (Resolved)

1. **Barbara's visual design:** Midjourney-generated illustrations. The style must feel distinct from the animal characters in the other portfolio apps (Plato's owl, Think's Jonah). Barbara is human-looking, illustrated (not photorealistic), warm but authoritative. Glasses are on-brand. Multiple expression variants needed (neutral, raised eyebrow, slight nod, crossed arms, warm smile, thinking).

2. **Voice provider for Barbara:** Start with Apple's built-in TTS (AVSpeechSynthesizer). Human review required to select the best voice for Barbara's character in both German and English. ElevenLabs is the upgrade path if built-in quality is insufficient for the character. Voice quality is critical on iPhone where voice is the primary interaction mode.

3. **Gamification depth:** Streaks and progress tracking only. No leaderboards, no points, no badges. Barbara's personality is the primary motivator, not extrinsic rewards. Level transitions are meaningful milestones, not gamified rewards. Barbara acknowledges growth without handing out trophies.

4. **User-submitted text analysis:** Introduce early (in Build mode, E3). "Paste your own text and get Barbara's structural feedback" is available from the start. Family-only TestFlight distribution means no content moderation risk for V1. The AI flags concerning input and logs it for learnings on how to handle this at scale later. This data informs a future content moderation strategy.

5. **LLM prompt training (Level 4):** Yes, with live Claude API calls. The user writes a prompt, sends it to Claude, sees the result, and gets Barbara's structural critique of the prompt (not the response). Rate-limited: max 10 prompt-test requests per day, configurable in parent settings. This prevents runaway API costs while allowing meaningful practice.

6. **Monetization:** Deferred. Family-only TestFlight distribution for now. Monetization strategy will be decided portfolio-wide when any app approaches public release.
