# E3: Build Mode — Structural Coaching

## Vision
The user says or writes something — an opinion, an argument, an answer to
Barbara's question — and Barbara dissects the *structure*. Not the grammar,
not whether the opinion is right, but whether the pyramid holds. The user
revises, Barbara re-evaluates, and within a few rounds the user *feels*
the difference between a mushy answer and a crisp one. This is the core
value loop of the app.

## Status
- [x] Epic defined
- [ ] Stories broken down (by Analyst)
- [ ] Sprint assigned
- [ ] Implementation complete
- [ ] QA complete

## Scope

### In Scope
- "Say it clearly" / "Sag's klar" session type:
  - Barbara poses a topic question (from curated topic bank)
  - User writes a response (typed; voice input deferred to E5)
  - Barbara evaluates structural quality using rubric from E1
  - Specific, actionable feedback displayed
  - User revises; Barbara re-evaluates
  - Session ends with summary and progression signal
- "The elevator pitch" / "30 Sekunden" session type:
  - Timed variant (30–60 seconds)
  - User writes under time pressure
  - Evaluation focuses on prioritisation and top-down structure
- Topic bank: 30+ age-appropriate topics in both German and English,
  categorised by domain (everyday, school, society, technology)
- Persistent learner profile:
  - Current level (1–4)
  - Structural strengths and development areas
  - Session history with scores
  - Progression signals (Barbara's "level up" moments)
- Progress dashboard:
  - Current level visualisation
  - Recent session scores
  - Strengths/weaknesses radar
  - Session streak tracking
- Revision tracking: show the user their original vs. revised response
  side by side, highlighting structural improvements
- Adaptive difficulty: Barbara calibrates her expectations and topic
  complexity to the user's demonstrated level

## Out of Scope
- Break mode / text analysis exercises (that's E4)
- Voice input and output (that's E5)
- Visual pyramid builder drag-and-drop (that's E6)
- Level 3 and 4 evaluation rubrics (future expansion; E3 ships with L1 + L2)

### Success Criteria
- [ ] User can complete a full "Say it clearly" session: topic → write → feedback → revise → summary
- [ ] Barbara's feedback is specific and structural ("Your conclusion is in sentence 3. Move it to the front.")
- [ ] User's revised response scores measurably higher than their first attempt in 80%+ of sessions
- [ ] "Elevator pitch" mode enforces time pressure and evaluates accordingly
- [ ] Learner profile persists across sessions and accurately reflects demonstrated ability
- [ ] Progress dashboard shows meaningful data after 5+ sessions
- [ ] Barbara's difficulty calibration feels appropriate (not too easy, not frustrating)
- [ ] Topic bank covers enough variety that users don't see repeats for weeks

## Design Decisions
- **Revision loop is mandatory**: Barbara never accepts the first draft without comment. Even good responses get a "Good — now make it tighter." This normalises revision.
- **Structural scoring, not grading**: Scores are diagnostic (which elements are strong/weak), not a grade. Barbara doesn't say "7 out of 10" — she says "Your grouping is solid but your lead is buried."
- **Topic bank AND freeform**: Curated topics ensure age-appropriateness and allow calibrated difficulty. Users can also bring their own topics or paste their own text for Barbara's structural feedback ("Analyse my text"). Introduced early — family-only TestFlight means no content moderation risk. AI flags concerning input and logs for future learnings.
- **Level 1+2 only for V1**: Ship with foundations and grouping. Advanced structures (L3) and real-world application (L4) come later when the core loop is proven.

## Dependencies
- Depends on: E1 (system prompt, rubrics), E2 (app shell, API integration, chat UI)
- Blocked by: nothing beyond E1 + E2
- Enables: E4 (Break mode can reuse evaluation infrastructure), E5 (voice wraps around Build mode exercises)

## Technical Considerations
- Evaluation rubric passed as structured data in system prompt, not prose
- Barbara's feedback must reference specific parts of the user's text (sentence numbers, quoted phrases)
- Hidden metadata per turn: structural scores per dimension, overall assessment, level signal
- Learner profile: local JSON, updated after each session summary
- Topic bank: bundled JSON, categorised by language, domain, and difficulty
- Timer implementation for elevator pitch: countdown UI, auto-submit on expiry
- Revision diff: compute and display structural changes between attempts

## Open Questions
- [ ] Should Barbara allow more than one revision, or cap at two attempts per topic?
- [ ] How to handle users who just copy-paste their first response without changing it?
- [ ] Should the topic bank include "Barbara's choice" (she picks based on profile) and "your choice" (user picks from a list)?
- [ ] When does Barbara trigger a level transition? After N consistent high scores? Explicit assessment exercise?
- [ ] Should revision tracking persist in session history, or only show during the active session?

## Story Candidates
1. Topic bank: 30+ topics in DE and EN, categorised by domain and difficulty
2. "Say it clearly" session flow: topic selection → prompt → write → submit
3. Structural evaluation integration: send response + rubric to Claude, parse scores
4. Barbara feedback display: specific, structural, referencing user's text
5. Revision loop: show feedback → user edits → re-evaluate → compare
6. "Elevator pitch" session flow: timer UI, time-pressured variant
7. Learner profile schema and local persistence (JSON + Codable)
8. Learner profile update logic: extract progression signals from session metadata
9. Progress dashboard: level display, recent scores, strengths radar
10. Session history: list of past sessions with scores and Barbara's summary
11. Adaptive difficulty: Barbara adjusts topic complexity and evaluation strictness
12. Revision diff view: side-by-side or inline comparison of attempts
13. Level transition logic and Barbara's "promotion" dialogue

## References
- Primer parallel: The Primer's conversational teaching — asking questions,
  evaluating answers, pushing for better, celebrating growth.
- Bloom's mastery learning: Don't move on until the foundation is solid.
