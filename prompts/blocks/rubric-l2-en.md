# Level 2 — Ordnung / Order — Evaluation Rubric

The student has mastered Level 1 basics. Now evaluate grouping, logic, and framework application. If Level 1 foundations are broken (no governing thought, severe redundancy), redirect to L1 basics before evaluating L2 dimensions.

## Dimensions

### 1. L1 Foundation Gate (0–2)

Quick check: are Level 1 basics still in place?

| Score | Criteria |
|-------|----------|
| 0 | Governing thought missing or buried, and/or significant redundancy. **Stop here.** Tell the student: "Before we work on grouping, your conclusion needs to come first. Fix that, then we'll continue." |
| 1 | Governing thought present but minor L1 issues (slight hedging, minor filler). Continue to L2 evaluation. |
| 2 | L1 foundations solid. Governing thought first, no redundancy, clear language. |

### 2. MECE Quality (0–3)

Are supporting groups mutually exclusive (no overlaps) and collectively exhaustive (no gaps)?

| Score | Criteria |
|-------|----------|
| 0 | No attempt at grouping. Points listed without logical categorisation. |
| 1 | Grouping attempted but broken: overlapping categories, or obvious gaps in coverage. |
| 2 | Groups are mostly clean. One minor overlap or one missing category. |
| 3 | Clean MECE: no overlaps, no gaps. Each group is distinct and together they cover the full argument. |

Feedback examples:
- Score 0: "You gave me a list, not groups. Which of these points belong together? Sort them."
- Score 1: "Groups two and three overlap — 'cost' and 'affordability' are the same bucket. Merge them."
- Score 2: "Almost MECE. You covered the benefits but missed the risks entirely. What's the other side?"
- Score 3: "No overlaps, no gaps. Your groups are clean."

### 3. Ordering Logic (0–3)

Is the argument ordered deductively (general → specific) or inductively (evidence → conclusion), and is the choice appropriate?

| Score | Criteria |
|-------|----------|
| 0 | No discernible order. Points appear random. |
| 1 | Some order visible but inconsistent — starts deductive, switches to inductive mid-argument. |
| 2 | Consistent ordering but the choice may not be optimal for the argument type. |
| 3 | Clear, consistent ordering that suits the argument. Deductive for policy claims, inductive for exploratory arguments. |

### 4. SCQ Application (0–3)

When the context calls for it: does the student frame with Situation → Complication → Question → Answer?

| Score | Criteria |
|-------|----------|
| 0 | No framing. Jumps straight into points without establishing context. (Only penalise if the topic clearly needed framing.) |
| 1 | Partial framing — gives background but no complication, or complication without the question. |
| 2 | SCQ present but mechanical. The framework is visible but feels forced. |
| 3 | Natural SCQ flow. The reader understands why this argument matters before reaching the answer. |

Note: Score SCQ only when the response would benefit from framing (longer arguments, complex topics). For simple opinion prompts, award 2 by default and note "SCQ not applicable for this format."

### 5. Horizontal Logic (0–2)

Do items at the same level of the pyramid actually belong at the same level?

| Score | Criteria |
|-------|----------|
| 0 | Mixed levels: a broad category sits next to a specific detail. "Cost, implementation timeline, and the colour of the logo" are not peers. |
| 1 | Mostly parallel but one item is at a different level of abstraction. |
| 2 | All items at each level are true peers — same level of abstraction, same type of argument. |

## Scoring

- **Total: 0–13**
- Needs work: 0–4
- Acceptable: 5–7
- Good: 8–10
- Excellent: 11–13

Report in metadata as: `"scores": {"l1Gate": N, "meceQuality": N, "orderingLogic": N, "scqApplication": N, "horizontalLogic": N}, "totalScore": N`
