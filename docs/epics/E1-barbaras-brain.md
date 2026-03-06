# E1: Barbara's Brain

## Vision
Before writing a single line of Swift, prove that Barbara can actually
coach structured thinking effectively. Build the complete system prompt,
evaluation rubrics, progression model, and practice text library — then
test it as a Claude Project with real teenagers. If Barbara's feedback
makes someone restructure their argument and *feel the improvement*, the
pedagogy works.

## Status
- [x] Epic defined
- [ ] Stories broken down (by Analyst)
- [ ] Sprint assigned
- [ ] Implementation complete
- [ ] QA complete

## Scope

### In Scope
- Complete system prompt (modular blocks: Identity, Pedagogy, Evaluation
  Rubric, Learner Profile, Session Directive, Output Format)
- Barbara's personality definition and voice rules (strict-but-warm,
  structurally obsessive, economical with praise, models what she teaches)
- Structural evaluation rubric for Level 1 "Klartext" / "Plain Talk":
  - Governing thought present and positioned first?
  - Supports grouped logically?
  - Redundancy detected?
  - Appropriate complexity?
- Evaluation rubric for Level 2 "Ordnung" / "Order":
  - MECE grouping quality
  - Deductive vs. inductive ordering
  - SCQ framework application
- Practice text library: 10–15 texts at varying structural quality
  (well-structured, buried-lead, rambling) with hidden answer keys
- Session type prompt templates for "Say it clearly" and "Find the point"
- Hidden metadata output format (structural scores, progression signals)
- Working Claude Project for immediate testing in both German and English
- Language configuration logic (Barbara switches cleanly between DE and EN)

### Out of Scope
- Any iOS/SwiftUI code (that's E2)
- Level 3 "Architektur" and Level 4 "Meisterschaft" rubrics (that's E4 expansion)
- Visual pyramid builder mechanics (that's E6)
- Voice interaction (that's E5)
- Barbara character illustrations (parallel design work)

### Success Criteria
- [ ] Teenager completes a 10-minute "Say it clearly" session via Claude Project
- [ ] Barbara follows all personality rules (no content judgement, structural focus only)
- [ ] Barbara's feedback causes the user to visibly improve their structure on revision
- [ ] Barbara adapts her demands to match the user's current level
- [ ] Barbara generates valid hidden metadata JSON after each response
- [ ] Practice texts have clear answer keys that match what a skilled reader would extract
- [ ] Barbara works equally well in German and English
- [ ] At least 3 test users find Barbara's tone motivating rather than discouraging

## Design Decisions
- **Claude Project first, app later**: Prove the pedagogy before investing in UI
- **Modular prompt**: Each block (identity, rubric, profile) can be updated independently
- **Structure-only evaluation**: Barbara explicitly ignores grammar, style, factual accuracy
- **Hidden metadata in JSON**: Appended to each response, parsed by app later
- **Both languages from day one**: Not a translation — culturally appropriate examples in each

## Dependencies
- Depends on: nothing (this is the starting point)
- Blocked by: nothing
- Enables: E2 (iOS Shell), E3 (Build Mode), E4 (Break Mode), E5 (Voice), E6 (Pyramid Builder)

## Technical Considerations
- System prompt length: aim for < 4K tokens to leave room for conversation
- Evaluation rubric must be machine-parseable (structured scoring, not just prose feedback)
- Practice text generation: batch-generate with Claude, include difficulty metadata and answer keys
- Hidden metadata format: `<!-- BARBARA_META: {"structural_score": {...}} -->`
- Language handling: full prompt variants for DE and EN, not inline conditionals
- Barbara's own responses must consistently model pyramid structure (meta-consistency)

## Open Questions
- [ ] Should Barbara's first interaction include a diagnostic exercise to place the user at the right level?
- [ ] How detailed should the hidden metadata be? (Quick score vs. full structural breakdown per turn)
- [ ] Should the practice text answer keys include multiple valid pyramid interpretations?
- [ ] How to handle users who resist the strict tone? (Soften dynamically, or hold the line?)

## Story Candidates
1. Write Barbara's Identity block (personality, voice rules, sacred rules, what she never does)
2. Write the Pedagogical Rules block (evaluation loop, revision cycle, praise patterns)
3. Build Level 1 "Klartext" evaluation rubric (governing thought, support grouping, redundancy)
4. Build Level 2 "Ordnung" evaluation rubric (MECE, deductive/inductive, SCQ)
5. Define learner profile JSON schema (level, strengths, development areas, session history)
6. Create "Say it clearly" session template (topic prompt → response → evaluation → revision)
7. Create "Find the point" session template (text presented → extraction → feedback)
8. Generate practice text library: 5 well-structured, 5 buried-lead, 5 rambling (both languages)
9. Define hidden metadata output format (structural scores, level signals, progression data)
10. Write Session Directive logic (how Barbara decides difficulty, when to push, when to praise)
11. Assemble complete system prompt, test as Claude Project
12. Run 3+ test sessions with teenagers, iterate on prompt based on observations
13. Document what worked, what didn't, capture learnings for E2

## References
- Primer parallel: Building the Primer's pedagogical intelligence — the layer
  that understands what the student needs and adapts accordingly.
- Minto's Pyramid Principle: The core intellectual framework. Barbara embodies it.
