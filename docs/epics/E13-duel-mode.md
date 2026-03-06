# E13: Duel Mode

## Vision
Two users take the same topic and structure their arguments independently.
Then they see each other's pyramids side by side. Barbara judges — not who
has the better *opinion*, but who has the better *structure*. "You both
argued for the same position, but Player 1's grouping is tighter and their
evidence is better aligned. Player 2, your second and third points overlap."
This introduces a social dimension without compromising the structural
focus, and adds the competitive motivation that some learners need.

## Status
- [x] Epic defined
- [ ] Stories broken down (by Analyst)
- [ ] Sprint assigned
- [ ] Implementation complete
- [ ] QA complete

## Scope

### In Scope
- **Duel session flow**:
  - Player 1 initiates a duel and selects a topic (from curated bank)
  - Player 2 accepts (via share link / code / local handoff)
  - Both players write their structured response independently, with a time limit
  - Once both submit, Barbara evaluates each response's structure
  - Side-by-side comparison displayed with Barbara's comparative analysis
  - Barbara declares a structural winner (or tie) with specific reasoning
- **Local duel** (same device):
  - Pass-and-play: Player 1 writes, hands device to Player 2
  - Player 1's response is hidden during Player 2's turn
  - Reveal and comparison after both submit
- **Remote duel** (stretch goal):
  - Share link or code to invite opponent
  - Requires lightweight matchmaking (CloudKit or simple backend)
  - Async: both players have 24 hours to submit; Barbara judges when both are in
- **Duel topics**: Curated bank of debatable topics suitable for structural comparison
  - Both players argue the SAME position (structure comparison, not debate)
  - OR both players argue OPPOSITE positions (structure comparison across positions)
- **Barbara's comparative evaluation**:
  - Evaluates each pyramid independently using existing rubric
  - Then compares: whose lead is stronger? Whose grouping is cleaner?
  - "Player 1 led with a clear position. Player 2 buried theirs in sentence three.
    But Player 2's evidence grouping is tighter. Overall: Player 1 by a narrow margin."
- **Duel history**: Past duels visible in session history with outcomes

### Out of Scope
- Real-time simultaneous writing (both players work independently)
- Public matchmaking with strangers (friends/family only)
- ELO or ranking system (duels are for fun and practice, not competitive ladder)
- Voice interaction in duels (text only for fairness and comparison)
- Group duels (3+ players — too complex for V1)

### Success Criteria
- [ ] Local duel works end-to-end: topic → P1 writes → P2 writes → Barbara compares → winner declared
- [ ] Barbara's comparative analysis is specific and references both players' structures
- [ ] Neither player can see the other's response until both have submitted
- [ ] Duel adds engagement without undermining the learning focus
- [ ] Same-position duels work (pure structure comparison)
- [ ] Opposite-position duels work (structure comparison independent of opinion)
- [ ] Users report duels as more motivating than solo exercises

## Design Decisions
- **Structure, never content**: Barbara judges structure only. She never says one opinion is better than another. In opposite-position duels, the structurally weaker argument can win.
- **Same-position option**: Having both players argue the same position makes the structural comparison pure — you can't hide behind having a "better" opinion.
- **Local-first**: Same-device pass-and-play is the V1 experience. Remote duels are a stretch goal that adds infrastructure complexity.
- **Time-limited**: Both players get the same time limit (3–5 minutes). Prevents one player spending 20 minutes polishing while the other does 2 minutes.
- **No ranking**: Duels are practice, not competition. Barbara might track your duel win rate informally ("You've won 7 of your last 10 duels — your structure is getting consistent"), but there's no public leaderboard.

## Dependencies
- Depends on: E3 (Build mode evaluation infrastructure), E2 (app shell)
- Blocked by: E3 must be stable
- Enables: social engagement, word-of-mouth growth, sibling/classroom use
- Enhanced by: E6 (visual pyramid comparison would be stunning in Duel Mode)

## Technical Considerations
- Local duel: simple state machine (waiting_P1 → writing_P1 → waiting_P2 → writing_P2 → evaluation → results)
- Player isolation: P1's response stored securely and hidden from P2's view
- Comparative evaluation prompt: extends Barbara's system prompt with comparison directives and both responses
- Remote duel (stretch): CloudKit shared database or simple REST API for match state
- Share link: universal link (applinks) or share code
- Timer synchronisation: for remote duels, both players get same duration from acceptance time
- Duel history: stored in session history with participant labels and comparative scores

## Open Questions
- [ ] Should duels count toward level progression, or are they purely social practice?
- [ ] How to handle skill mismatch? (L1 player vs. L3 player — Barbara could handicap or just judge fairly)
- [ ] Should Barbara suggest duels? ("You've been practicing alone. Want to challenge someone?")
- [ ] Remote duels: CloudKit (free, Apple-only) or lightweight custom backend?
- [ ] Should "Decode and rebuild" mode have a duel variant? (Both players extract the same text's pyramid, compare extractions)
- [ ] Classroom use: should there be a "teacher creates a duel for the whole class" flow?

## Story Candidates
1. Duel session state machine: initiation → P1 turn → P2 turn → evaluation → results
2. Local duel UI: pass-and-play flow, player isolation, turn transitions
3. Duel topic bank: 30+ debatable topics suitable for both same- and opposite-position duels
4. Barbara's comparative evaluation prompt: evaluate two responses, compare, declare winner
5. Side-by-side comparison view: both responses + Barbara's structural analysis
6. Timer: shared time limit for both players
7. Duel history: storage, display in session history
8. Remote duel: share link / code generation (stretch)
9. Remote duel: CloudKit match state management (stretch)
10. Duel invitation flow: deep link or code entry

## References
- Primer parallel: Nell and the other girls who receive Primers — the
  parallel journeys and implicit comparison of how each reader develops.
- Überzeuge mich! DNA: Duel Mode shares argumentation DNA with the debate
  app, but here the focus is structure, not persuasion.
