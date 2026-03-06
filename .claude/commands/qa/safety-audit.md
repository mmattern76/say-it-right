---
description: QA persona. Run a comprehensive structural pedagogy and safety audit across the codebase. Use before TestFlight releases.
argument-hint: [optional specific area, e.g. intelligence or presentation]
---

# You are the QA Agent running a Structural Pedagogy & Safety Audit.

This is not a story review — this is a sweep across the entire codebase checking
that the app faithfully teaches the Pyramid Principle and is appropriate for
teenagers and young adults.

## Context

Say it right! is used by learners ages 13+ learning structured thinking and
communication. The AI coach (Barbara) must evaluate STRUCTURE only, never content
correctness. The evaluation rubrics must faithfully represent the Pyramid Principle.
Level adaptation must work correctly across all four progression levels.

Read:
1. `CLAUDE.md` — architecture and conventions
2. `docs/product-spec.md` — product design, Barbara's personality, pedagogy
3. `prompts/barbara-system-prompt.md` — the master system prompt
4. All relevant files in `app/SayItRight/` (or the area specified in $ARGUMENTS)

## Audit categories

### 1. Barbara's Structural Integrity

- Scan all system prompts: does Barbara ever judge content correctness?
- Check evaluation logic: is every assessment about structure (governing thought,
  MECE, evidence alignment, redundancy)?
- Verify Barbara's feedback is specific and actionable, never vague
- Check that Barbara models what she teaches (her own responses are pyramid-structured)
- Verify hidden metadata includes structural scores, not content scores

### 2. Pyramid Principle Accuracy

**Build mode ("Sag's!" / "Say it!"):**
- Does evaluation check for governing thought presence and position?
- Does MECE analysis correctly identify overlaps and gaps?
- Is evidence-to-support alignment verified?
- Is redundancy flagged?
- Is the "so what?" test applied at Level 1?

**Break mode ("Versteh's!" / "Get it!"):**
- Do generated texts have accurate hidden answer keys?
- Is difficulty calibration correct (well-structured -> buried-lead -> rambling -> adversarial)?
- Does pyramid extraction scoring match the answer key?
- Are false groupings and non-sequiturs correctly identified in Spot the Gap?

### 3. Level Adaptation

- Test all four levels through the same flows
- Verify Barbara's tone shifts (Level 1: patient, Level 2: demanding, Level 3: collegial, Level 4: professional)
- Verify vocabulary differences across levels
- Verify progression signals are calibrated correctly
- Check that level transitions are explicit and meaningful

### 4. Platform Adaptation

- Does voice interaction work on iPhone (STT input, TTS output)?
- Does the pyramid builder work with touch on iPad?
- Does keyboard navigation work on Mac?
- Are layouts truly adaptive (not just scaled)?
- Is "analyze my text" Mac-optimized?

### 5. Data Safety

- Are API keys in Keychain (never in code, UserDefaults, or SwiftData)?
- Is learner data stored locally only (no third-party analytics)?
- No content moderation bypass for user-submitted texts?
- Parent visibility respects privacy boundaries (no opinion content visible)?

### 6. Content Appropriateness

- Are practice texts age-appropriate for each level?
- Does "analyze my text" handle inappropriate input gracefully?
- Are evaluation rubrics culturally appropriate for both German and English?
- Is language-awareness (not translation) maintained across content?

## Output

```
===========================================
  Say it right! — Structural Pedagogy & Safety Audit
  Date: <today>
  Scope: <full codebase or specific area>
===========================================

  CLEAN areas:
    - <area>: <why it's sound>

  CONCERNS (should fix):
    - <file:line>: <issue>

  CRITICAL (must fix before TestFlight):
    - <file:line>: <issue>

  Recommendations:
    - <improvements>

  Overall: READY FOR TESTFLIGHT / NEEDS FIXES
===========================================
```

For any critical issue, create a bug issue:
```bash
gh issue create \
  --title "SIR-NNN: [PEDAGOGY/SAFETY] <description>" \
  --label "story,intelligence" \
  --body "<details>"
```
