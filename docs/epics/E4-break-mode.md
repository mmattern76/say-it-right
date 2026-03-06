# E4: Break Mode — Text Analysis & Pyramid Extraction

## Vision
The user reads a text and reverse-engineers its structure. Barbara presents
articles, arguments, and opinion pieces — some well-structured, some
deliberately messy — and the user must extract the pyramid: What's the main
claim? What supports it? Where's the evidence? Where does the structure
break down? This is the receptive counterpart to Build mode, and it
reinforces the same structural literacy from the opposite direction.

## Status
- [x] Epic defined
- [ ] Stories broken down (by Analyst)
- [ ] Sprint assigned
- [ ] Implementation complete
- [ ] QA complete

## Scope

### In Scope
- "Find the point" / "Finde den Punkt" session type:
  - Barbara presents a text
  - User identifies the governing thought in one sentence
  - Barbara evaluates the extraction
- "Fix this mess" / "Räum das auf" session type:
  - Barbara presents a badly structured argument
  - User restructures it (typed; drag-and-drop deferred to E6)
  - Barbara compares to the answer key and gives feedback
- "Spot the gap" / "Finde die Lücke" session type:
  - Barbara presents a seemingly solid argument with a hidden structural flaw
  - User identifies the weakness (missing group, logical leap, misaligned evidence)
  - Barbara confirms or hints and lets them try again
- "Decode and rebuild" / "Entschlüsseln und Neubauen" session type:
  - Full-cycle: read a text, extract the pyramid, re-present in own words
  - Combines Break and Build in one exercise
- Practice text library expansion:
  - AI-generated texts at 4 quality levels (well-structured, buried-lead, rambling, adversarial)
  - Each text includes difficulty metadata and hidden answer key
  - Texts in both German and English
  - 40+ texts at launch, expandable
- Text quality spectrum calibrated to user level:
  - Level 1 users get well-structured and buried-lead texts
  - Level 2 users add rambling texts
  - Level 3+ users encounter adversarial texts with hidden flaws
- Integration with learner profile: Break mode performance feeds into the
  same progression model as Build mode

### Out of Scope
- Visual drag-and-drop pyramid builder (that's E6 — "Fix this mess" uses typed restructuring here)
- User-submitted text analysis ("paste your own article") — included in E3 "Analyse my text" feature, not duplicated here
- Real-world text sourcing with licensing (AI-generated texts only for V1)
- Voice interaction (that's E5)

### Success Criteria
- [ ] User can complete each of the four session types
- [ ] "Find the point" accurately evaluates whether the user identified the governing thought
- [ ] "Fix this mess" meaningfully compares user's restructuring to the answer key
- [ ] "Spot the gap" provides progressive hints if the user misses the flaw
- [ ] "Decode and rebuild" successfully chains Break → Build in one session
- [ ] Practice texts feel natural and age-appropriate (not obviously AI-generated)
- [ ] Text difficulty calibration matches user level (not too easy, not overwhelming)
- [ ] Break mode performance correctly updates the learner profile

## Design Decisions
- **Answer keys are structured, not literal**: The answer key is a pyramid structure (governing thought + grouped supports + evidence), not a specific wording. Multiple valid extractions are accepted.
- **AI-generated texts only for V1**: Avoids licensing complexity. Quality-controlled through generation pipeline + human review.
- **Progressive hints for "Spot the gap"**: Barbara doesn't reveal the answer immediately — she narrows the search area. "The problem isn't in the evidence. Look at the grouping."
- **Combined mode last**: "Decode and rebuild" is the capstone exercise that only unlocks after the user demonstrates competence in both Build and Break individually.

## Dependencies
- Depends on: E1 (rubrics, text library seed), E2 (app shell), E3 (learner profile, progression model)
- Blocked by: E3 must ship first (Break mode extends the learner profile that Build mode establishes)
- Enables: E6 (visual pyramid builder adds a richer UI to "Fix this mess")

## Technical Considerations
- Answer key format: JSON pyramid structure with governing thought, support groups, and evidence nodes; each node has an ID for matching against user extraction
- Comparison algorithm: semantic similarity between user's extracted governing thought and the answer key's (Claude evaluates, not exact string match)
- Text generation pipeline: batch job generating texts with quality metadata, answer keys, and difficulty ratings; stored as bundled JSON
- "Spot the gap" hint system: 3-tier hints (area → narrower area → specific element), tracked in session state
- "Decode and rebuild" session chaining: Break result feeds as context into Build prompt
- Text deduplication: ensure users don't see the same text twice across sessions

## Open Questions
- [ ] Should "Find the point" accept multiple valid governing thoughts, or is there always one best answer?
- [ ] How to evaluate "Fix this mess" when there are multiple valid restructurings? (Score the structure, not the specific arrangement?)
- [ ] Should adversarial texts (Level 3+) have one flaw or multiple? (One is cleaner pedagogically)
- [ ] How many texts does the initial library need? (40 minimum to avoid repetition over 2–3 weeks of daily use)
- [ ] Should Barbara ever present real-world texts (news snippets, opinion columns) with fair use excerpts?
- [ ] When does "Decode and rebuild" unlock? After N successful Break + Build sessions each?

## Story Candidates
1. Practice text generation pipeline: batch script producing texts with answer keys at 4 quality levels
2. Practice text library: 40+ texts in DE and EN, bundled as JSON with metadata
3. "Find the point" session flow: present text → user extracts → Barbara evaluates
4. Answer key comparison logic: semantic matching of user extraction vs. structured answer
5. "Fix this mess" session flow: present broken text → user restructures → compare to answer key
6. "Spot the gap" session flow: present flawed text → user identifies weakness → progressive hints
7. "Spot the gap" hint system: 3-tier progressive narrowing
8. "Decode and rebuild" session flow: chained Break → Build with context passing
9. Text difficulty calibration: match text quality level to user's progression level
10. Text deduplication: track which texts the user has seen, avoid repeats
11. Learner profile integration: Break mode scores feed into unified progression model
12. Text library refresh strategy: mechanism for adding new texts via app update or content feed

## References
- Primer parallel: The Primer's ability to present stories and situations calibrated
  to the reader's current understanding, then test comprehension through interaction.
- Speed reading research: Structural awareness dramatically improves reading
  comprehension and retention — this is the structured-thinking equivalent.
