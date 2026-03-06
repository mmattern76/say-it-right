---
description: Simulate a coaching session with Barbara at a given level to evaluate structural feedback quality.
argument-hint: <level klartext or ordnung or architektur or meisterschaft>
---

# Barbara Session Test

You are simulating a learner interacting with Barbara to validate that the
intelligence layer produces correct structural feedback. You play BOTH roles:
the learner (giving deliberately structured and unstructured responses) and
the evaluator (checking Barbara's output quality).

## Setup

1. Read `prompts/barbara-system-prompt.md`
2. Read `docs/product-spec.md` (pedagogy section)
3. Read the evaluation rubrics in `content/evaluation-rubrics/`
4. Determine the level from $ARGUMENTS:
   - `klartext` / `plain-talk` → Level 1 (foundations)
   - `ordnung` / `order` → Level 2 (grouping & logic)
   - `architektur` / `architecture` → Level 3 (advanced structures)
   - `meisterschaft` / `mastery` → Level 4 (real-world application)

## Test scenarios

For the chosen level, simulate these interactions:

### Scenario 1: Well-structured response
Submit a response that follows the Pyramid Principle correctly for this level.
Barbara should acknowledge the good structure with specific praise.
- Does she praise structure, not content?
- Is praise economical and specific?
- Does hidden metadata reflect high structural scores?

### Scenario 2: Buried conclusion
Submit a response where the main point is in the middle or end.
Barbara should identify this and give specific feedback.
- Does she say WHERE the conclusion is? ("Your conclusion is in sentence 4.")
- Does she instruct to move it? ("Lead with your answer.")
- Is she direct without being harsh?

### Scenario 3: Mushy grouping
Submit a response with overlapping or redundant supporting points.
Barbara should flag the MECE violation.
- Does she identify which points overlap?
- Does she suggest merging or differentiating?
- At Level 2+: does she use MECE terminology appropriately?

### Scenario 4: Vague language
Submit a response with filler phrases ("There are many reasons", "It's important to consider").
Barbara should call out the mush immediately.
- Does she quote the specific vague phrase?
- Does she demand specificity? ("Which reasons? Pick your strongest.")
- Is her tone appropriate for the level?

### Scenario 5: Content-trap
Submit a response with a controversial opinion but excellent structure.
Barbara should praise the structure and NOT comment on the opinion's validity.
- Does she evaluate architecture only?
- Does she say something like "I disagree with your point, but your reasoning is airtight"?
- Does she NEVER say the opinion is wrong/right?

## Evaluation report

```
===========================================
  Barbara Session Test — Level: <level>
===========================================

  Scenario 1 (well-structured):  PASS / FAIL — <notes>
  Scenario 2 (buried conclusion): PASS / FAIL — <notes>
  Scenario 3 (mushy grouping):    PASS / FAIL — <notes>
  Scenario 4 (vague language):    PASS / FAIL — <notes>
  Scenario 5 (content-trap):      PASS / FAIL — <notes>

  Barbara's tone: APPROPRIATE / TOO HARSH / TOO SOFT
  Hidden metadata: COMPLETE / MISSING FIELDS
  Level calibration: CORRECT / MISCALIBRATED

  Overall: PASS / NEEDS TUNING
===========================================
```

## What to check in output

- Barbara NEVER evaluates content correctness
- Barbara's own responses are pyramid-structured (she models what she teaches)
- Hidden metadata JSON includes: pyramid_score, mece_score, governing_thought_present,
  governing_thought_position, redundancy_flags, level_signal, progression_signal
- Feedback is specific (references exact sentences/points, not generic)
- Tone matches the configured level
- Language matches the configured language (German or English)
