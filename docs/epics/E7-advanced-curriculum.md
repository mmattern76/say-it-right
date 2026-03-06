# E7: Advanced Curriculum (Level 3 + Level 4)

## Vision
Barbara stops pulling punches. Level 3 "Architektur" introduces issue
trees, vertical and horizontal logic, multi-source synthesis, and the
ability to spot false groupings in seemingly solid arguments. Level 4
"Meisterschaft" brings real-world application: executive summaries,
structured presentations, and the explicit connection between pyramid
thinking and effective LLM prompting. The user graduates from "learning
to structure" to "structuring instinctively."

## Status
- [x] Epic defined
- [ ] Stories broken down (by Analyst)
- [ ] Sprint assigned
- [ ] Implementation complete
- [ ] QA complete

## Scope

### In Scope
- **Level 3 "Architektur" / "Architecture" evaluation rubric**:
  - Issue trees and problem decomposition
  - Vertical logic (does each detail level support the level above?)
  - Horizontal logic (do items at the same level actually belong together?)
  - Synthesising multiple sources into one coherent structure
  - Governing thoughts vs. mere summaries
  - Grouping by structure vs. grouping by process
- **Level 4 "Meisterschaft" / "Mastery" evaluation rubric**:
  - Executive summary quality (can a busy reader get the point in 30 seconds?)
  - Presentation/pitch structure (opening, flow, conclusion)
  - Multi-stakeholder communication (same content, different structures for different audiences)
  - LLM prompt structuring (clarity, context, constraints, format specification)
  - Peer review through a structural lens
- **Extended topic bank**: 40+ additional topics for L3/L4, including:
  - Multi-perspective issues (climate policy, technology regulation, education reform)
  - Professional scenarios (project proposals, status reports, stakeholder emails)
  - LLM prompt challenges (ambiguous requests to restructure into effective prompts)
- **Extended practice text library**: 30+ additional texts for L3/L4:
  - Multi-source synthesis exercises (2–3 texts on the same topic, user builds unified pyramid)
  - Adversarial texts with subtle structural flaws for "Spot the gap"
  - Real-world style texts (op-eds, policy briefs, corporate memos)
- **Barbara's tone shift**: At L3/L4, Barbara becomes collegial rather than
  teacherly. "Your pyramid holds, but your governing thought is a summary,
  not an insight. What do those three factors *tell us*?"
- **Level transition ceremonies**: Barbara's "promotion" dialogues for L2→L3
  and L3→L4, including a capstone assessment exercise at each gate

### Out of Scope
- Actual LLM API calls for prompt testing (that's E10)
- Certification or external credentialing
- Content beyond the individual user (group exercises, classroom mode)

### Success Criteria
- [ ] L3 rubric correctly evaluates issue trees, vertical/horizontal logic, and synthesis quality
- [ ] L4 rubric correctly evaluates executive summaries, presentation structure, and prompt quality
- [ ] Barbara's tone noticeably shifts at L3 and L4 (more collegial, less teacherly)
- [ ] Multi-source synthesis exercises work end-to-end (present 2–3 texts → user synthesises → evaluate)
- [ ] Level transition assessments feel meaningful (not just "you did enough sessions")
- [ ] L3/L4 topics feel genuinely challenging for older teenagers and young adults
- [ ] LLM prompt exercises are practical and transferable to real-world prompt writing

## Design Decisions
- **Gate assessments, not automatic promotion**: L2→L3 and L3→L4 require Barbara to administer a capstone exercise. This prevents users from gaming the system with volume.
- **Synthesis as the L3 capstone skill**: The ability to read multiple sources and build one coherent pyramid is the defining skill of L3. Everything else supports it.
- **LLM prompting as applied pyramid thinking**: Not a separate module — Barbara shows that prompt structure IS pyramid structure. Context = situation, task = question, format = output specification.
- **Barbara's persona evolution**: She doesn't become a different character — she reveals more depth. Like a teacher who starts treating a maturing student more as an intellectual peer.

## Dependencies
- Depends on: E3 (Build mode with L1/L2), E4 (Break mode with practice text infrastructure)
- Blocked by: E3 and E4 must be validated with real users first
- Enables: E10 (LLM Prompt Workshop builds on L4 rubric and prompt exercises)

## Technical Considerations
- Multi-source synthesis requires presenting multiple texts in one session and tracking which text each part of the user's response references
- Issue tree evaluation: Claude must assess tree completeness and MECE quality at multiple levels, not just the top level
- L4 prompt evaluation: compare user's prompt to a "gold standard" restructured prompt and evaluate structural quality
- Barbara persona modulation: system prompt includes level-conditional tone directives
- Gate assessment exercises: special session type with pass/fail threshold and Barbara's detailed debrief

## Open Questions
- [ ] Should L3/L4 unlock new session types, or enhance existing ones with harder content?
- [ ] How to handle users who reach L4 quickly — is there an L5, or does L4 have infinite depth?
- [ ] Should multi-source synthesis use AI-generated source texts, or curated real-world excerpts?
- [ ] How explicit should the LLM prompting connection be? ("You're writing a prompt" vs. "Structure this request clearly")
- [ ] Should gate assessments be repeatable if failed, or does Barbara give targeted practice first?

## Story Candidates
1. Level 3 evaluation rubric: issue trees, vertical/horizontal logic, synthesis
2. Level 4 evaluation rubric: exec summaries, presentations, LLM prompts
3. L3 topic bank: 20+ multi-perspective topics in DE and EN
4. L4 topic bank: 20+ professional/applied topics in DE and EN
5. L3 practice texts: multi-source synthesis sets (2–3 related texts per exercise)
6. L4 practice texts: adversarial texts, real-world style documents
7. Barbara persona modulation: level-conditional tone in system prompt
8. L2→L3 gate assessment exercise design and implementation
9. L3→L4 gate assessment exercise design and implementation
10. Multi-source synthesis session flow: present multiple texts → user synthesises → evaluate
11. LLM prompt structuring exercises: ambiguous request → user restructures → evaluate
12. Level transition dialogues: Barbara's "promotion" conversations

## References
- Primer parallel: The Primer grows with the reader — what starts as a
  children's book becomes a tool for navigating adult complexity.
- Minto's original audience: McKinsey consultants. L4 reconnects with
  the professional origin of the Pyramid Principle.
